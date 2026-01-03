# 🚗 RideUp - Application de Covoiturage

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Application mobile de covoiturage développée avec Flutter pour le marché tunisien.

## ✨ Fonctionnalités

- 🔐 Authentification sécurisée
- 📍 Recherche de trajets avec géolocalisation
- 🗺️ Carte interactive OpenStreetMap
- ⭐ Système d'évaluation bidirectionnel
- 💬 Messagerie instantanée
- 🌐 Support bilingue français/arabe
- 🗑️ Suppression automatique des trajets expirés

## 📱 Screenshots

<img width="260" height="559" alt="image" src="https://github.com/user-attachments/assets/a78170a2-75d5-4c99-93d3-0b98395d17b3" />
<img width="252" height="542" alt="image" src="https://github.com/user-attachments/assets/70405809-7044-4e2e-89cd-547a36326bb1" />
<img width="275" height="586" alt="image" src="https://github.com/user-attachments/assets/c1213029-f51b-4dbb-a5b1-b9c40c8b4af7" />


## 🚀 Installation

### Prérequis
- Flutter SDK 3.0+
- Android Studio / Xcode
- Compte Firebase

### Étapes

1. Clonez le repository :
```bash
git clone https://github.com/Nour-Thabet/RideUp.git
cd RideUp
```

2. Installez les dépendances :
```bash
flutter pub get
```

3. **Configurez Firebase** :
   - Créez un projet sur [Firebase Console](https://console.firebase.google.com)
   - Téléchargez `google-services.json` (Android)
   - Placez-le dans `android/app/`
   - Générez `firebase_options.dart` :
```bash
   flutterfire configure
```

4. Lancez l'application :
```bash
flutter run
```

## 🔐 Configuration Firebase

⚠️ **Important** : Les fichiers de configuration Firebase ne sont pas inclus pour des raisons de sécurité. Vous devez créer votre propre projet Firebase et générer vos propres fichiers.

## 🏗️ Architecture

- **Frontend** : Flutter (Dart)
- **Backend** : Firebase (Firestore, Auth, Storage)
- **Maps** : OpenStreetMap + Nominatim
- **Architecture** : MVC (Model-View-Controller)

## 📦 Packages principaux

- `firebase_core` : Firebase SDK
- `cloud_firestore` : Base de données NoSQL
- `firebase_auth` : Authentification
- `flutter_map` : Affichage de cartes
- `geolocator` : Géolocalisation
- `http` : Requêtes API

## 🤝 Contribution

Les contributions sont les bienvenues !

1. Fork le projet
2. Créez une branche (`git checkout -b feature/AmazingFeature`)
3. Commit (`git commit -m 'Add AmazingFeature'`)
4. Push (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT - voir [LICENSE](LICENSE)

## 👨‍💻 Auteur

**Nour Thabet**
- GitHub: [@Nour-Thabet](https://github.com/Nour-Thabet)
- Email: nourthabet565@gmail.com

## 🙏 Remerciements

- OpenStreetMap pour les données cartographiques
- Firebase pour l'infrastructure backend
- La communauté Flutter

---

⭐ N'oubliez pas de mettre une étoile si ce projet vous a été utile !
