# 🚗 Application de Covoiturage - Tunisie

Application mobile de covoiturage développée avec Flutter pour faciliter le partage de trajets en Tunisie.

## ✨ Fonctionnalités

- 🔐 Authentification (inscription/connexion)
- 📍 Recherche de trajets avec géolocalisation
- 🗺️ Affichage sur carte interactive (OpenStreetMap)
- 🚙 Création et gestion de trajets (conducteur)
- 👥 Réservation de places (passager)
- ⭐ Système d'évaluation conducteurs/passagers
- 💬 Messagerie entre utilisateurs
- 🌐 Support multilingue (français/arabe)
- 🔔 Notifications en temps réel
- 🗑️ Suppression automatique des trajets expirés

## 🛠️ Technologies utilisées

- **Framework** : Flutter
- **Backend** : Firebase (Firestore, Authentication, Storage)
- **Cartes** : OpenStreetMap (flutter_map)
- **Géolocalisation** : Geolocator
- **État** : Provider / Bloc (selon votre choix)

## 📱 Captures d'écran

(Ajoutez vos captures d'écran ici)

## 🚀 Installation

### Prérequis

- Flutter SDK (version 3.0+)
- Dart SDK
- Android Studio / Xcode
- Compte Firebase

### Étapes d'installation

1. Clonez le repository :
```bash
git clone https://github.com/votre-username/covoiturage-tunisie.git
cd covoiturage-tunisie
```

2. Installez les dépendances :
```bash
flutter pub get
```

3. Configurez Firebase :
   - Créez un projet Firebase
   - Téléchargez `google-services.json` (Android) et `GoogleService-Info.plist` (iOS)
   - Placez-les dans les dossiers appropriés
   - Générez `firebase_options.dart` avec FlutterFire CLI

4. Lancez l'application :
```bash
flutter run
```

# covoiturage

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

