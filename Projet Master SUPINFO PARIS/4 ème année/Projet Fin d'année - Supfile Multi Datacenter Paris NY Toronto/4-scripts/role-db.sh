#!/bin/bash
# role-db.sh — MariaDB Galera node + full schema
set -euo pipefail; export DEBIAN_FRONTEND=noninteractive
echo "▶ db: ${SITE} (${WEB_IP} / mgmt=${MGMT_IP})"
apt-get install -yq mariadb-server galera-4 rsync

cat > /etc/mysql/mariadb.conf.d/60-galera.cnf <<EOF
[mysqld]
bind-address             = 0.0.0.0
binlog_format            = ROW
default_storage_engine   = InnoDB
innodb_autoinc_lock_mode = 2

[galera]
wsrep_on              = ON
wsrep_provider        = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_name    = supfile_cluster
# Three nodes — uses Tailscale IPs for cross-DC (toronto consolidated on single VM: 100.126.8.98)
wsrep_cluster_address = gcomm://100.126.63.76,100.105.116.110,100.126.8.98
wsrep_sst_method      = rsync
wsrep_node_address    = ${MGMT_IP}
wsrep_node_name       = db-${SITE}
wsrep_slave_threads   = 4
wsrep_sst_auth        = sstuser:SSTPass2024!
EOF

ufw allow from 10.10.0.0/16    to any port 3306 comment "mysql"
ufw allow from 192.168.99.0/24 to any port 3306,4444,4567,4568 comment "galera"

# Full schema — applied on Paris primary only during galera-bootstrap.sh
cat > /tmp/supfile-schema.sql <<'SQL'
CREATE DATABASE IF NOT EXISTS supfile CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE supfile;

-- ── TABLES ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS storage_nodes (
    id          INT          NOT NULL AUTO_INCREMENT,
    hostname    VARCHAR(100) NOT NULL,
    site        ENUM('paris','ny','toronto') NOT NULL,
    san_ip      VARCHAR(45),
    total_bytes BIGINT       NOT NULL DEFAULT 0,
    used_bytes  BIGINT       NOT NULL DEFAULT 0,
    is_active   TINYINT(1)   NOT NULL DEFAULT 1,
    last_seen   DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_hostname (hostname)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS users (
    id              CHAR(36)     NOT NULL DEFAULT (UUID()),
    email           VARCHAR(255) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    display_name    VARCHAR(100),
    quota_bytes     BIGINT       NOT NULL DEFAULT 32212254720,
    used_bytes      BIGINT       NOT NULL DEFAULT 0,
    storage_node_id INT,
    is_active       TINYINT(1)   NOT NULL DEFAULT 1,
    is_banned       TINYINT(1)   NOT NULL DEFAULT 0,
    ban_reason      VARCHAR(255),
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_email (email),
    KEY idx_node (storage_node_id),
    KEY idx_banned (is_banned),
    CONSTRAINT fk_user_node FOREIGN KEY (storage_node_id) REFERENCES storage_nodes(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sessions (
    id          CHAR(36)     NOT NULL DEFAULT (UUID()),
    user_id     CHAR(36)     NOT NULL,
    token_hash  VARCHAR(255) NOT NULL,
    ip_address  VARCHAR(45),
    user_agent  VARCHAR(500),
    expires_at  DATETIME     NOT NULL,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_token (token_hash),
    KEY idx_user (user_id),
    KEY idx_exp (expires_at),
    CONSTRAINT fk_sess_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS files (
    id              CHAR(36)     NOT NULL DEFAULT (UUID()),
    user_id         CHAR(36)     NOT NULL,
    name            VARCHAR(255) NOT NULL,
    mime_type       VARCHAR(100),
    size_bytes      BIGINT       NOT NULL DEFAULT 0,
    storage_path    TEXT,
    parent_id       CHAR(36)     DEFAULT NULL,
    storage_node_id INT,
    is_folder       TINYINT(1)   NOT NULL DEFAULT 0,
    is_deleted      TINYINT(1)   NOT NULL DEFAULT 0,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_user_parent (user_id, parent_id),
    KEY idx_deleted (is_deleted),
    CONSTRAINT fk_file_user   FOREIGN KEY (user_id)   REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_file_parent FOREIGN KEY (parent_id) REFERENCES files(id) ON DELETE CASCADE,
    CONSTRAINT fk_file_node   FOREIGN KEY (storage_node_id) REFERENCES storage_nodes(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS share_links (
    id             CHAR(36)    NOT NULL DEFAULT (UUID()),
    file_id        CHAR(36)    NOT NULL,
    created_by     CHAR(36)    NOT NULL,
    token          VARCHAR(64) NOT NULL,
    expires_at     DATETIME    DEFAULT NULL,
    download_count INT         NOT NULL DEFAULT 0,
    created_at     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_token (token),
    CONSTRAINT fk_share_file FOREIGN KEY (file_id)    REFERENCES files(id) ON DELETE CASCADE,
    CONSTRAINT fk_share_user FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ip_bans (
    id         INT         NOT NULL AUTO_INCREMENT,
    ip_address VARCHAR(45) NOT NULL,
    reason     VARCHAR(255),
    banned_by  CHAR(36),
    banned_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME    DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_ip (ip_address)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS audit_log (
    id         BIGINT      NOT NULL AUTO_INCREMENT,
    user_id    CHAR(36),
    action     VARCHAR(50) NOT NULL,
    ip_address VARCHAR(45),
    resource   CHAR(36),
    detail     JSON,
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_user   (user_id),
    KEY idx_action (action),
    KEY idx_ts     (created_at)
) ENGINE=InnoDB;

-- ── VIEWS ─────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_user_storage AS
SELECT u.id, u.email, u.display_name,
       u.quota_bytes, u.used_bytes,
       ROUND(u.used_bytes/u.quota_bytes*100,2) AS pct_used,
       u.quota_bytes - u.used_bytes            AS free_bytes,
       sn.hostname AS node, sn.site
FROM   users u
LEFT JOIN storage_nodes sn ON u.storage_node_id = sn.id
WHERE  u.is_active = 1;

CREATE OR REPLACE VIEW v_active_sessions AS
SELECT s.id, u.email, s.ip_address, s.created_at AS login_at,
       s.expires_at,
       TIMESTAMPDIFF(MINUTE, NOW(), s.expires_at) AS minutes_left
FROM   sessions s
JOIN   users u ON s.user_id = u.id
WHERE  s.expires_at > NOW() AND u.is_active = 1 AND u.is_banned = 0;

CREATE OR REPLACE VIEW v_file_listing AS
SELECT f.id, f.user_id, f.name, f.mime_type, f.size_bytes,
       f.parent_id, f.is_folder, f.created_at, f.updated_at,
       (SELECT COUNT(*) FROM share_links sl WHERE sl.file_id = f.id) AS shares
FROM   files f
WHERE  f.is_deleted = 0;

CREATE OR REPLACE VIEW v_node_capacity AS
SELECT id, hostname, site,
       total_bytes, used_bytes,
       total_bytes - used_bytes             AS free_bytes,
       ROUND(used_bytes/total_bytes*100,1)  AS pct_used,
       is_active
FROM   storage_nodes
ORDER  BY used_bytes ASC;

-- ── STORED PROCEDURES ─────────────────────────────────────────

DELIMITER $$

-- sp_register_user: assigns user to least-used storage node (brief requirement)
CREATE OR REPLACE PROCEDURE sp_register_user(
    IN  p_email    VARCHAR(255),
    IN  p_pwhash   VARCHAR(255),
    IN  p_name     VARCHAR(100),
    OUT p_uid      CHAR(36),
    OUT p_node     VARCHAR(100)
)
BEGIN
    DECLARE v_node_id INT;
    DECLARE v_uid CHAR(36) DEFAULT (UUID());
    SELECT id, hostname INTO v_node_id, p_node
    FROM   v_node_capacity WHERE is_active=1 LIMIT 1;
    IF v_node_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='No storage node available';
    END IF;
    INSERT INTO users(id,email,password_hash,display_name,storage_node_id)
    VALUES(v_uid, p_email, p_pwhash, p_name, v_node_id);
    UPDATE storage_nodes SET used_bytes=used_bytes+32212254720 WHERE id=v_node_id;
    INSERT INTO files(id,user_id,name,is_folder)
    VALUES(UUID(),v_uid,'/',1);
    INSERT INTO audit_log(user_id,action,detail)
    VALUES(v_uid,'register',JSON_OBJECT('node',p_node,'email',p_email));
    SET p_uid = v_uid;
END$$

-- sp_ban_ip: bans IP in DB; ban-sync cron pushes to HAProxy within 5 min
CREATE OR REPLACE PROCEDURE sp_ban_ip(
    IN p_ip     VARCHAR(45),
    IN p_reason VARCHAR(255),
    IN p_admin  CHAR(36),
    IN p_hours  INT
)
BEGIN
    DECLARE v_exp DATETIME DEFAULT NULL;
    IF p_hours > 0 THEN SET v_exp = DATE_ADD(NOW(), INTERVAL p_hours HOUR); END IF;
    INSERT INTO ip_bans(ip_address,reason,banned_by,expires_at)
    VALUES(p_ip, p_reason, p_admin, v_exp)
    ON DUPLICATE KEY UPDATE reason=p_reason, banned_at=NOW(), expires_at=v_exp;
    INSERT INTO audit_log(action,ip_address,detail)
    VALUES('ip_ban',p_ip,JSON_OBJECT('reason',p_reason,'hours',p_hours));
END$$

-- sp_update_quota: called by app after upload/delete
CREATE OR REPLACE PROCEDURE sp_update_quota(
    IN p_uid   CHAR(36),
    IN p_delta BIGINT
)
BEGIN
    UPDATE users SET used_bytes=GREATEST(0,used_bytes+p_delta) WHERE id=p_uid;
    UPDATE storage_nodes sn JOIN users u ON sn.id=u.storage_node_id
    SET    sn.used_bytes=GREATEST(0,sn.used_bytes+p_delta)
    WHERE  u.id=p_uid;
END$$

DELIMITER ;

-- ── DB USERS (4 privilege levels) ────────────────────────────

-- App user: DML only on supfile schema
CREATE USER IF NOT EXISTS 'supfile_app'@'10.10.%'   IDENTIFIED BY 'AppPass2024!';
CREATE USER IF NOT EXISTS 'supfile_app'@'192.168.%' IDENTIFIED BY 'AppPass2024!';
GRANT SELECT,INSERT,UPDATE,DELETE,EXECUTE ON supfile.* TO 'supfile_app'@'10.10.%';
GRANT SELECT,INSERT,UPDATE,DELETE,EXECUTE ON supfile.* TO 'supfile_app'@'192.168.%';

-- Read-only: monitoring, Prometheus mysql_exporter
CREATE USER IF NOT EXISTS 'supfile_ro'@'%' IDENTIFIED BY 'ReadOnly2024';
GRANT SELECT,PROCESS,REPLICATION CLIENT ON *.* TO 'supfile_ro'@'%';

-- Galera SST user
CREATE USER IF NOT EXISTS 'sstuser'@'localhost' IDENTIFIED BY 'SSTPass2024!';
GRANT RELOAD,LOCK TABLES,PROCESS,REPLICATION CLIENT ON *.* TO 'sstuser'@'localhost';

-- ProxySQL monitor
CREATE USER IF NOT EXISTS 'proxysql_mon'@'10.10.%' IDENTIFIED BY 'ProxyMon2024!';
GRANT REPLICATION CLIENT ON *.* TO 'proxysql_mon'@'10.10.%';

FLUSH PRIVILEGES;

-- Seed storage nodes
INSERT IGNORE INTO storage_nodes(id,hostname,site,san_ip,total_bytes) VALUES
(1,'storage1-paris','paris','192.168.1.21',8589934592),
(2,'storage2-paris','paris','192.168.1.22',8589934592),
(3,'storage3-paris','paris','192.168.1.23',8589934592),
(4,'storage1-ny',   'ny',   '192.168.2.21',8589934592),
(5,'storage2-ny',   'ny',   '192.168.2.22',8589934592),
(6,'storage3-ny',   'ny',   '192.168.2.23',8589934592);
SQL

systemctl stop mariadb 2>/dev/null || true
systemctl disable mariadb  # Bootstrap manually — see README Phase 6
echo "▶ db done: schema ready at /tmp/supfile-schema.sql — DO NOT start yet"
