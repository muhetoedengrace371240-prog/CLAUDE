# MUHETO App

Application Flutter unifiée issue de la fusion des briques fonctionnelles MUHETO : auth, feed vidéo, profil, chat, business local, gold, notifications, search, analytics et localisation.

## Aperçu

MUHETO App est une application mobile/web multiplateforme pensée pour la diffusion de contenus courts, la découverte de profils, la publication, la messagerie et la monétisation via MUHETO Gold.

## Architecture

- Core : thème, localisation, navigation, bootstrap Firebase
- Features : auth, feed, discover, create, inbox, profile, business, gold, notifications, search, analytics
- Services : Auth, Feed, Profile, Chat, Business, Notification, Upload
- Models : User, Video, Comment, Message, Chat, Business

## Prérequis

- Flutter SDK 3.3+ installé et configuré
- Android Studio / Xcode selon la plateforme cible
- Firebase project configuré avec :
  - Authentication
  - Firestore
  - Storage
  - Cloud Messaging

## Installation

1. Cloner le dépôt / ouvrir le dossier du projet
2. Installer les dépendances :

```bash
flutter pub get
```

3. Configurer Firebase (si ce n’est pas déjà fait) :

```bash
flutterfire configure
```

4. Ajouter les fichiers de configuration Firebase générés dans le projet si nécessaire :
   - lib/firebase_options.dart
   - android/app/google-services.json
   - ios/Runner/GoogleService-Info.plist

## Lancement

### Android / iOS

```bash
flutter run
```

### Web

```bash
flutter run -d chrome
```

### Analyse du projet

```bash
flutter analyze
```

### Tests

```bash
flutter test
```

## Structure du projet

```text
lib/
  core/
    firebase/
    localization/
    navigation/
    theme/
  features/
    auth/
    analytics/
    business/
    chat/
    create/
    discover/
    feed/
    gold/
    home/
    inbox/
    navigation/
    notifications/
    profile/
    search/
    settings/
  models/
  services/
main.dart
```

## Fonctionnalités couvertes

- Authentification Firebase
- Flux vidéo vertical
- Profil utilisateur
- Chat / inbox
- Business local / annuaire
- MUHETO Gold
- Notifications push
- Recherche
- Analytics
- Localisation multilingue

## Notes importantes

- Les écrans sont branchés sur les services Firebase et Firestore existants dans le projet.
- Les routes sont centralisées dans la navigation nommée du dossier core/navigation.
- Si Firebase n’est pas encore configuré sur votre machine, l’application peut démarrer partiellement, mais les flux Auth/Firestore seront limités.
