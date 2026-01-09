# Sign Scan - Application Mobile

Application Flutter pour la détection et la collecte de panneaux de signalisation.

## Fonctionnalités

- 📸 **Scan & Détection** : Détection d'objets en temps réel via la caméra (YOLO/API Python).
- 🗂️ **Catégories** : Organisation automatique des panneaux par type.
- 👤 **Profil Utilisateur** : Gestion de compte et historique des scans.
- 🔍 **Recherche** : Filtrage et recherche de panneaux dans la base de données.
- 📱 **Multi-plateforme** : Compatible Android, iOS et Web.

## Installation

1. S'assurer d'avoir le [Flutter SDK](https://flutter.dev/docs/get-started/install) installé.
2. Cloner le projet.
3. Installer les dépendances :
   ```bash
   flutter pub get
   ```

## Lancement

### Mobile (Android/iOS)
Connectez votre appareil ou lancez un émulateur, puis :
```bash
flutter run
```

### Web
```bash
flutter run -d chrome
```

## Pour les développeurs

### Tests
Lancer la suite de tests unitaires et widgets :
```bash
flutter test
```

### Génération des icônes
Si vous changez le logo dans `assets/icon/icon.png`, lancez :
```bash
dart run flutter_launcher_icons
```
