# ☸️ Kubernetes - Déploiement Application Fleetman 

- 🔗[Github Projet Technique]  https://github.com/MEVENGUE/K8S

## 📋 Description

L'objectif de ce mini-projet est de déployer une application microservices réelle, Fleetman, sur un cluster Kubernetes composé d'un nœud master et de deux nœuds workers, créés et hébergés sur Hyper-V. L'application Fleetman simule la position de véhicules en temps réel et affiche ces positions sur une interface web.

Elle s'appuie sur plusieurs technologies : microservices Spring Boot, MongoDB, ActiveMQ, Nginx et bien sûr Kubernetes pour l'orchestration.

## 🎯 Objectifs du Projet

### Technique
Mettre en œuvre un déploiement complet d'une application microservices sur un cluster Kubernetes auto-hébergé (kubeadm), y compris la gestion du stockage, du réseau, des services et des probes de santé.

### Pédagogique
Comprendre les bonnes pratiques de déploiement (namespace, StatefulSet, Deployments, Services, ConfigMaps), documenter la procédure et être capable de la présenter lors de la soutenance.

## 🛠️ Technologies Utilisées

- **Kubernetes** - Orchestration de conteneurs
- **Microservices** - Architecture distribuée
- **Spring Boot** - Framework Java
- **MongoDB** - Base de données NoSQL
- **ActiveMQ** - Message broker
- **Nginx** - Reverse proxy et load balancer
- **Hyper-V** - Virtualisation

## 📊 Architecture

### Cluster Kubernetes
- 1 nœud master
- 2 nœuds workers
- Déployé sur Hyper-V

### Application Fleetman
- Microservices Spring Boot
- Base de données MongoDB
- Message broker ActiveMQ
- Interface web avec Nginx
- Suivi de véhicules en temps réel

## 📊 Bonnes Pratiques Implémentées

- **Namespaces** - Organisation des ressources
- **StatefulSet** - Gestion des applications avec état
- **Deployments** - Déploiement et mise à jour
- **Services** - Exposition des applications
- **ConfigMaps** - Configuration externalisée
- **Probes de santé** - Monitoring et disponibilité

## 📄 Documentation

- [Présentation Application Fleetman](./Présentation%20Application%20Fleetman.pdf)

## 🎯 Compétences Développées

- Orchestration Kubernetes
- Déploiement de microservices
- Gestion de cluster Kubernetes
- Configuration de stockage et réseau
- Monitoring et probes de santé
- Documentation technique
