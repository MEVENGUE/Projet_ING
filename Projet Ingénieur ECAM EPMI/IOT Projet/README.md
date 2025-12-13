# 🌡️ Projet IoT - Système de Monitoring Aquatique

## 📋 Description

Ce projet utilise un ESP32 pour mesurer la température de l'eau avec un capteur de température DS18B20 et le niveau d'eau à l'aide d'un capteur à ultrasons HC-SR04. Les données recueillies par les capteurs sont affichées à la fois sur le moniteur série et sur un écran LCD I2C 16x2 pour une lecture facile.

## 🛠️ Technologies Utilisées

- **ESP32** - Microcontrôleur principal
- **Arduino** - Environnement de développement
- **Wokwi** - Simulation en ligne
- **DS18B20** - Capteur de température
- **HC-SR04** - Capteur ultrasonique
- **LCD I2C 16x2** - Affichage des données

## 🔧 Composants

### Matériel
- ESP32 Development Board
- Capteur de température DS18B20 (résistance)
- Capteur à ultrasons HC-SR04
- Écran LCD I2C 16x2
- Résistances et câbles de connexion

### Logiciel
- Arduino IDE
- Bibliothèques : OneWire, DallasTemperature, LiquidCrystal_I2C
- Simulation Wokwi

## 📊 Fonctionnalités

- ✅ Mesure de la température de l'eau en temps réel
- ✅ Détection du niveau d'eau par ultrasons
- ✅ Affichage simultané sur LCD et moniteur série
- ✅ Simulation complète sur Wokwi avant déploiement

## 🖼️ Présentation

<div align="center">
  <img src="./Matériel%20IOT.png" alt="Matériel IoT" width="600" style="max-width: 100%; border-radius: 8px;">
  <br><br>
  <img src="./Matériel%20IOT%202.png" alt="Matériel IoT 2" width="600" style="max-width: 100%; border-radius: 8px;">
  <br><br>
  <img src="./PC%20Détection%20Mouvement.png" alt="PC Détection Mouvement" width="600" style="max-width: 100%; border-radius: 8px;">
</div>

## 📁 Fichiers du Projet

- `sketch.ino` - Code source Arduino
- `diagram.json` - Schéma de connexion Wokwi
- `libraries.txt` - Liste des bibliothèques nécessaires
- `wokwi-project.txt` - Configuration du projet Wokwi

## 📄 Documentation

- [Rapport complet du projet](./Projet%201%20IOT.pdf)

## 🔌 Schéma de Connexion

Le projet utilise une architecture simple :
- DS18B20 connecté via OneWire sur GPIO
- HC-SR04 connecté sur GPIO (Trigger et Echo)
- LCD I2C connecté via bus I2C (SDA/SCL)

## 🎯 Objectifs

- Maîtriser la programmation embarquée avec ESP32
- Intégrer plusieurs capteurs sur une même plateforme
- Afficher les données de manière lisible
- Simuler avant de déployer en réel

## 📚 Compétences Développées

- Programmation embarquée (Arduino/ESP32)
- Intégration de capteurs
- Communication I2C
- Simulation de systèmes IoT
- Interface utilisateur simple (LCD)
