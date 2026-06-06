# Kubernetes — Fleetman

<div align="center">
  <img src="./1page%20Application%20Fleetman.jpg" alt="Présentation Fleetman" width="900">
</div>

## 🎯 Mission

Déployer une application **microservices temps réel** sur un cluster **Kubernetes auto-hébergé**.

---

## 📦 Stack

| Rôle | Outil |
|---|---|
| Orchestration | Kubernetes (`kubeadm`) |
| Runtime | containerd / Docker |
| Framework | Spring Boot |
| Données | MongoDB |
| Messaging | ActiveMQ |
| Réseau / Ingress | Nginx |
| Virtualisation | Hyper-V |

---

## 🏗️ Architecture

```
master
├─ web1  →  Nginx + FastAPI front
├─ web2  →  Nginx + FastAPI front
├─ db    →  MongoDB (StatefulSet)
├─ broker → ActiveMQ
└─ storage → PersistentVolume
```

---

## ✅ Points clés

- **1 master + 2 workers**
- **Namespaces** séparés par responsabilité
- **StatefulSet** pour les services à état
- **Health probes** (liveness / readiness)
- **ConfigMap** + **Secrets** externalisés
- **StorageClass** + **PVC** persistants

---

## 📄 Livrables

- [Présentation Application Fleetman](./Présentation%20Application%20Fleetman.pdf)

---

*Projet fil rouge SUPINFO Paris — Architecture distribuée & orchestration.*
