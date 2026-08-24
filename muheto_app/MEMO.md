# MEMO.md — Carte d'identité technique de MUHETO

> ⚠️ **Règle d'usage** : coller ce fichier au début de CHAQUE nouvelle conversation
> avant de demander une nouvelle brique de code. Dire explicitement :
> "Voici les règles de mon app [colle ce fichier]. Respecte EXACTEMENT ces noms,
> ne renomme rien, n'invente pas de nouveaux champs sans me le signaler."
>
> Après chaque session qui ajoute un champ, une fonction ou une collection,
> **mettre à jour ce fichier** avant de fermer la conversation.

Dernière mise à jour : 21/08/2026

---

## 1. Identité du projet

- **Nom** : MUHETO — "la voix de l'Afrique"
- **Stack** : Flutter (Dart), Firebase (Auth + Firestore + Storage + Messaging)
- **Dépôt** : GitHub privé, branche `main`, dossier du projet Flutter : `muheto_app/`
- **CI/CD** : GitHub Actions (`.github/workflows/build.yml`), build APK debug automatique,
  artefact téléchargeable nommé `app-debug`

### Identifiants Android / Firebase (NE JAMAIS DÉSYNCHRONISER CES 3 VALEURS)
- `applicationId` (Android, dans `android/app/build.gradle.kts`) : `com.mycompany.muheto`
- `namespace` (Android, même fichier) : `com.example.muheto_app` *(legacy, ne pas toucher — différent de applicationId par choix historique)*
- Projet Firebase actif : **`muheto-app`** (Project ID : `muheto-a905ug`)
  - ⚠️ Il existe un second projet Firebase orphelin nommé `Muheto` (`muheto-db6d8`) — **NE PAS L'UTILISER**, il est vide et non connecté à l'app.
- Fichier de config Android : `android/app/google-services.json` (présent, lié à `com.mycompany.muheto`)
- Plugin Google Services déclaré dans `android/settings.gradle.kts` (version `4.4.2`) et activé dans `android/app/build.gradle.kts`

---

## 2. Langues et traduction

- **4 langues supportées**, dans cet ordre d'affichage :
  - `rn` = Kirundi
  - `fr` = Français (langue par défaut si rien n'est détecté)
  - `en` = English
  - `sw` = Kiswahili
- Déclarées dans `lib/core/localization/app_localizations.dart` → constante `kSupportedLocales`
- Fichiers de traduction : `assets/lang/{code}.json` (un JSON par langue, clés à points : `"settings.title"`, `"common.save"`, etc.)
- Usage dans le code : `AppLocalizations.of(context).t('clé.exacte')`
  - Si une clé manque, `t()` retourne la clé elle-même (pas de crash, mais visible en debug)
- Gestion de la langue active : `lib/core/localization/locale_provider.dart` → `LocaleProvider` (ChangeNotifier), persisté via `SharedPreferences` (clé `muheto_locale_code`)
- **Piège connu** : le Kirundi (`rn`) n'existe pas dans les données CLDR du package `intl` → se rabat sur `fr_FR` pour le formatage de dates. Ne pas essayer d'appeler `initializeDateFormatting('rn')`, ça n'existe pas.
- Locales `intl` initialisées dans `main.dart` : `fr_FR`, `en_US`, `sw_TZ` (les 3 sont obligatoires — sans elles, plantage `LocaleDataException` dès qu'un écran affiche une date dans cette langue, ex. écran Gold)

---

## 3. Modèle utilisateur (`lib/models/user_model.dart`)

Collection Firestore : **`users/{uid}`**

Champs réels de la classe `UserModel` (respecter ces noms EXACTEMENT, en camelCase) :

| Champ Dart | Type | Notes |
|---|---|---|
| `uid` | `String` | = `doc.id`, pas stocké dans le document lui-même |
| `username` | `String` | pseudonyme, normalisé en minuscules à l'inscription |
| `displayName` | `String` | nom affiché, peut garder la casse d'origine |
| `avatarUrl` | `String` | URL de l'avatar (vide au départ) |
| `bio` | `String` | |
| `isVerified` | `bool` | |
| `isBusinessAccount` | `bool` | |
| `isGoldMember` | `bool` | ⚠️ ne pas utiliser seul pour l'affichage — voir `isGoldActive` ci-dessous |
| `goldExpirationDate` | `DateTime?` | stocké comme `Timestamp?` côté Firestore |
| `followersCount` | `int` | |
| `followingCount` | `int` | |
| `likesCount` | `int` | |
| `country` | `String` | code pays, ex. `"BI"` |
| `language` | `String` | code langue, ex. `"fr"` |
| `createdAt` | — | écrit uniquement à la création (`FieldValue.serverTimestamp()`), pas de champ Dart correspondant dans la classe |

**Getter important** : `isGoldActive` (bool, calculé) = `isGoldMember == true` ET (`goldExpirationDate == null` OU `goldExpirationDate` dans le futur).
→ **Toujours utiliser `isGoldActive` dans l'UI**, jamais `isGoldMember` seul (peut rester `true` après expiration si aucun job ne l'a remis à `false`).

**Champ mentionné en commentaire mais PAS ENCORE implémenté** : `scope` (`"burundi" | "afrique" | "monde"`) — n'existe pas dans la classe Dart actuelle. Si une brique future en a besoin, il faut l'ajouter au modèle ET aux règles Firestore, pas juste au commentaire.

---

## 4. Authentification (`lib/services/auth_service.dart`)

Classe `AuthService`, méthodes disponibles :
- `signIn({email, password})`
- `signUp({username, email, password})` → vérifie d'abord l'unicité du username (lecture Firestore, doit rester accessible sans authentification — voir règles ci-dessous), crée le compte Firebase Auth, écrit le document `users/{uid}`
- `signOut()`
- `deleteAccount({password})` → ré-authentifie puis supprime le document Firestore ET le compte Auth. ⚠️ Ne supprime PAS en cascade les vidéos/chats/fiche Business (pas de conformité RGPD complète pour l'instant)
- `sendPasswordResetEmail(email)`
- `friendlyErrorMessage(error)` → messages d'erreur en français pour l'UI
- `currentUser` (getter), `authStateChanges` (Stream)

---

## 5. Règles de sécurité Firestore (état actuel, publié)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if true;
      allow create, update: if request.auth != null && request.auth.uid == userId;
      allow delete: if false;
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```
- Lecture de `users/*` : **ouverte à tous**, y compris non connectés (nécessaire pour la vérification d'unicité du pseudonyme à l'inscription)
- Écriture de `users/{userId}` : uniquement le propriétaire, connecté
- Suppression directe : jamais autorisée par les règles (passe par `deleteAccount()` côté app)
- **Toute autre collection future (posts, chats, business...) est bloquée par défaut** tant que des règles dédiées ne sont pas ajoutées ici.

---

## 6. Structure des dossiers (`lib/`)

```
lib/
  core/
    localization/   → app_localizations.dart, locale_provider.dart
    navigation/      → app_navigator_key.dart, app_routes.dart
    theme/           → app_theme.dart (AppColors, AppTheme.darkTheme)
    firebase/        → firebase_bootstrap.dart
  features/
    auth/            → splash_screen.dart, welcome_screen.dart, ...
    settings/        → settings_screen.dart, language_selector_sheet.dart
    (autres features par écran/domaine)
  models/            → user_model.dart, ...
  services/          → auth_service.dart, notification_service.dart, ...
  main.dart
```

---

## 7. `main.dart` — séquence d'initialisation obligatoire (ordre important)

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `FirebaseBootstrap.initialize()` (dans un try/catch — l'app peut continuer en mode dégradé si ça échoue, mais ça ne devrait plus arriver depuis la correction du 21/08/2026)
3. `timeago.setLocaleMessages('fr', ...)` + `'fr_short'` (requis pour les timestamps relatifs dans le Chat)
4. `initializeDateFormatting('fr_FR')`, `('en_US')`, `('sw_TZ')` — les 3, jamais une seule
5. `FirebaseMessaging.onBackgroundMessage(...)` — AVANT `runApp()`, doit être une fonction top-level
6. `runApp()` avec `ChangeNotifierProvider(create: (_) => LocaleProvider()..init())` englobant tout `MaterialApp`

`MaterialApp` utilise : `navigatorKey: appNavigatorKey`, `initialRoute` + `onGenerateRoute` via `AppRoutes`, les 4 `localizationsDelegates` standards + `AppLocalizationsDelegate()`.

---

## 8. État d'avancement (au 21/08/2026)

**Fonctionnel et testé sur appareil réel (Infinix HOT 40i, APK debug)** :
- Firebase correctement connecté (Auth + Firestore)
- Inscription / création de compte → testée avec succès de bout en bout
- Écran Paramètres : changement de langue, déconnexion, suppression de compte
- Traductions : Feed, Chat, Recherche, Paramètres, Gold + 14 écrans complétés (Profil, Création/Publication, Business, Analytics, etc.)

**Connu comme non implémenté / à faire** :
- Champ `scope` du modèle utilisateur (mentionné en commentaire seulement)
- Suppression de compte en cascade (RGPD complet, nécessite une Cloud Function)
- CGU réelles (actuellement un texte placeholder dans Paramètres)
- Passerelle de paiement réelle pour MUHETO Gold
- Firestore ne contient encore aucune collection autre que `users` (Feed vide, normal)
- 2 warnings CI persistants (dépréciation Node.js 20 / `setup-java@v3` dans `build.yml`, sans impact fonctionnel)
- Upload d'artefact APK configuré en `--debug`, pas encore en `--release`
