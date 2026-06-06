# SUPFile — Guide de déploiement

Infrastructure 3 datacenters (Paris / New York / Toronto) — 17 VMs — Vagrant + VirtualBox.

---

## Repos Github :

Github App Frontend : https://github.com/MEVENGUE/SUPFile-VB-App
Github Vagrant Code : https://github.com/AymanMain/supfile


## Prérequis

| Outil | Version minimale |
|---|---|
| VirtualBox | 7.0+ |
| Vagrant | 2.4+ |
| RAM disponible | 10 Go (Paris seul) / 16 Go (Paris + NY) |
| Tailscale | Compte actif, authkey disponible |

Chaque site (Paris, NY, Toronto) tourne sur une machine physique distincte connectée via Tailscale.

---

## Architecture des sites

| Site | Machine | VMs |
|---|---|---|
| Paris | Poste Windows local | lb, web1, web2, storage1, storage2, storage3, db, proxysql |
| New York | Machine distante | lb, web1, web2, storage1, storage2, storage3, db, proxysql |
| Toronto | Serveur Debian (100.126.8.98) | backup, coldweb, db, monitor |

---

## Étape 1 — Démarrer le site Paris

```bash
SITE=paris vagrant up
```

Si RAM limitée (< 10 Go) :

```bash
LOW_RAM=true SITE=paris vagrant up
```

`LOW_RAM=true` désactive web2, storage2, storage3 et proxysql.

Vérifier que toutes les VMs sont up :

```bash
SITE=paris vagrant status
```

---

## Étape 2 — Démarrer le site New York

Sur la machine NY :

```bash
SITE=ny vagrant up
```

---

## Étape 3 — Démarrer Toronto

Sur le serveur Toronto (Debian 13, Nadia) :

```bash
SITE=toronto vagrant up
```

Toronto héberge backup, coldweb, db-toronto et monitor (Prometheus + Grafana).

---

## Étape 4 — Connecter Tailscale sur chaque VM

Tailscale assure la connectivité inter-sites (remplace WireGuard pour le POC).

Sur chaque VM fraîchement provisionnée :

```bash
vagrant ssh <vm-name>
sudo tailscale up --authkey=<votre-authkey>
tailscale ip -4    # noter l'IP Tailscale
```

Vérifier la connectivité depuis lb-paris :

```bash
vagrant ssh lb-paris
tailscale status   # toutes les VMs doivent apparaître
```

---

## Étape 5 — Bootstrap Galera (cluster MariaDB)

Ordre obligatoire : db-paris en premier.

**Sur db-paris :**

```bash
vagrant ssh db-paris
sudo bash /tmp/scripts/post-provision/galera-bootstrap.sh --primary
```

**Sur db-ny, puis db-toronto :**

```bash
vagrant ssh db-ny
sudo bash /tmp/scripts/post-provision/galera-bootstrap.sh
```

Vérifier le cluster :

```bash
mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# attendu : wsrep_cluster_size = 3
```

---

## Étape 6 — Initialiser GlusterFS

GlusterFS crée un volume distribué-répliqué 6 briques (3 Paris + 3 NY).

**Depuis storage1-paris (une seule fois) :**

```bash
vagrant ssh storage1-paris
sudo bash /tmp/scripts/post-provision/gluster-setup.sh
```

Le script probe les 5 autres nœuds via Tailscale, crée `supfile-vol` en replica 3, le démarre et monte `/mnt/supfile-storage`.

Vérifier :

```bash
gluster volume info supfile-vol
gluster volume status
# attendu : 6/6 bricks online, Status: Started
```

**Monter GlusterFS sur les web VMs :**

```bash
# Sur chaque web VM (web1-paris, web2-paris, web1-ny, web2-ny) :
sudo mount -t glusterfs storage1-paris:/supfile-vol /mnt/supfile-storage
```

---

## Étape 7 — Déployer les node exporters Prometheus

```bash
vagrant ssh monitor-toronto
sudo bash /tmp/scripts/post-provision/deploy-node-exporters.sh
```

---

## Étape 8 — Configurer Grafana

```bash
vagrant ssh monitor-toronto
sudo bash /tmp/scripts/setup-grafana-dashboard-v2.sh
```

Grafana accessible sur `http://100.126.8.98:3000` (admin / admin).

---

## Étape 9 — Vérifier l'application

Test health Paris :

```bash
curl http://10.10.1.10/health
# attendu : {"status":"healthy","node":"web1-paris",...}
```

Test health NY :

```bash
curl http://10.10.2.10/health
# attendu : {"status":"healthy","node":"web1-ny",...}
```

Test active/active (les deux datacenters répondent simultanément) :

```bash
for i in $(seq 1 6); do curl -s http://10.10.1.10/health | jq .node; done
```

---

## Étape 10 — Tester le failover

Failover intra-DC (web1 tombe, web2 prend le relais) :

```bash
vagrant ssh web1-paris
sudo systemctl stop nginx
# Depuis lb-paris : curl http://10.10.1.100/health — doit rester healthy via web2
```

Failover inter-sites (NY indisponible, Toronto prend le relais) :

```bash
sudo bash /tmp/scripts/post-provision/drp-activate.sh
```

---

## Résumé des scripts disponibles

| Script | Rôle |
|---|---|
| `base.sh` | Provision commune à toutes les VMs |
| `role-lb.sh` | HAProxy + Keepalived VIP + WireGuard gateway |
| `role-web1.sh` / `role-web2.sh` | Nginx + FastAPI SUPFile |
| `role-storage1/2/3.sh` | GlusterFS brique + iSCSI target + RAID-1 |
| `role-db.sh` | MariaDB Galera node |
| `role-proxysql.sh` | ProxySQL read/write split |
| `role-monitor.sh` | Prometheus + Grafana + dnsmasq GSLB |
| `role-backup.sh` | Backup quotidien cron + rsync vers Toronto |
| `role-coldweb.sh` | Site de repli froid Toronto |
| `post-provision/galera-bootstrap.sh` | Bootstrap cluster Galera 3 nœuds |
| `post-provision/gluster-setup.sh` | Création volume GlusterFS 6 briques |
| `post-provision/deploy-node-exporters.sh` | Installation node_exporter sur toutes les VMs |
| `post-provision/drp-activate.sh` | Activation plan DRP Toronto |
| `setup-grafana-dashboard-v2.sh` | Déploiement dashboard Grafana 19 panels |
| `setup-haproxy-toronto.sh` | GSLB HAProxy Toronto (DNS failover) |
| `deploy-app-to-ny.sh` | Déploiement application SUPFile sur NY |
| `fix-ny-haproxy-prometheus.sh` | Correctif HAProxy + Prometheus NY |

---

## Dépannage

**GlusterFS : `Transport endpoint is not connected`**

```bash
sudo umount /mnt/supfile-storage
sudo mount -t glusterfs storage1-paris:/supfile-vol /mnt/supfile-storage
```

**Galera : cluster non formé au démarrage**

```bash
# Sur db-paris uniquement :
sudo galera_new_cluster
# Sur db-ny et db-toronto :
sudo systemctl restart mariadb
```

**Tailscale non connecté**

```bash
sudo tailscale up --authkey=<authkey>
tailscale status
```

**Suricata arrêté (contrainte RAM POC)**

```bash
sudo systemctl start suricata
sudo systemctl status suricata
```

---

## Disclaimer

Infrastructure POC — environnement Vagrant/VirtualBox sur matériel limité. Certaines contraintes (RAID-1 dégradé sur disque 10 Mo Vagrant, Suricata arrêté sur web1-paris pour libérer de la RAM) sont documentées et sans impact sur la démonstration des mécanismes de résilience.
