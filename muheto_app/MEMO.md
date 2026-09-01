# MEMO.md — Carte d'identité technique de MUHETO

> ⚠️ **Règle d'usage** : coller ce fichier au début de CHAQUE nouvelle conversation
> avant de demander une nouvelle brique de code. Dire explicitement :
> "Voici les règles de mon app [colle ce fichier]. Respecte EXACTEMENT ces noms,
> ne renomme rien, n'invente pas de nouveaux champs sans me le signaler."
>
> Après chaque session qui ajoute un champ, une fonction ou une collection,
> **mettre à jour ce fichier** avant de fermer la conversation.

Dernière mise à jour : 26/08/2026

> **Statut de complétude** : modèles Dart (User, Business, Chat, Message, Video, Comment) ET
> tous les services (`auth`, `business`, `chat`, `feed`, `gold`, `notification`, `profile`, `search`)
> sont documentés en détail. Ce fichier reflète fidèlement le code tel qu'il existait au 26/08/2026 —
> toute évolution du code doit être répercutée ici.

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
- **Second piège Kirundi (différent du précédent, découvert le 26/08/2026)** : le Kirundi n'est pas non plus une des langues nativement connues par les **widgets internes de Flutter** (`MaterialLocalizations`, `WidgetsLocalizations` — utilisés par `AppBar`, `TabBar`, etc., PAS par nos propres traductions). Sans correctif, tout écran utilisant une `AppBar` ou une `TabBar` plante avec *"No MaterialLocalizations found"* dès que la langue active est le Kirundi — même si nos propres traductions (`AppLocalizationsDelegate`) fonctionnent très bien. Un écran sans `AppBar`/`TabBar` (comme le Feed) ne déclenche pas l'erreur, ce qui peut faire croire à tort que seul cet écran est concerné.
  - **Corrigé** via `lib/core/localization/kirundi_fallback_delegates.dart` : deux classes (`KirundiMaterialLocalizationsDelegate`, `KirundiWidgetsLocalizationsDelegate`) qui font croire à Flutter qu'on est en français UNIQUEMENT pour ces réglages internes, quand la langue active est `'rn'`. Nos propres traductions restent bien en Kirundi (mécanisme totalement séparé). Ces 2 délégués sont ajoutés dans `main.dart`, dans la liste `localizationsDelegates`.

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

## 3bis. Modèle Business (`lib/models/business_model.dart`)

Collection Firestore : **`businesses/{businessId}`**

| Champ Dart | Type | Notes |
|---|---|---|
| `id` | `String` | = `doc.id` |
| `ownerId` | `String` | référence `users/{uid}` du compte Business propriétaire |
| `name` | `String` | |
| `category` | `String` | valeurs possibles : voir constante `kBusinessCategories` (Restaurant, Boutique, Beauté & Bien-être, Santé, Éducation, Technologie, Hôtellerie, Artisanat, Services, Autre) |
| `description` | `String` | |
| `logoUrl`, `bannerUrl` | `String` | Firebase Storage |
| `address`, `city` | `String` | `city` par défaut `"Bujumbura"` |
| `phoneNumber` | `String` | format international recommandé, ex. `"+25779123456"` |
| `whatsappNumber` | `String` | optionnel |
| `websiteUrl`, `instagramUrl`, `facebookUrl` | `String` | optionnels |
| `openingHours` | `Map<String, String>` | clé = jour en français (voir `kWeekDaysFr`), valeur = `"08:00-18:00"` ou `"Fermé"` |
| `isVerified` | `bool` | badge doré vérifié |
| `isSponsored` | `bool` | mis en avant en tête de liste (offre payante) |
| `createdAt` | `DateTime?` | |
| `viewsCount`, `callClicksCount`, `websiteClicksCount`, `whatsappClicksCount` | `int` | compteurs analytics (Brique 13), incrémentés par `BusinessService` |

**Champ auto-généré à l'écriture (pas dans la classe Dart)** : `nameLower` = `name.toLowerCase()`, écrit dans `toFirestore()` pour permettre la recherche par préfixe (Firestore compare les chaînes par ordre d'octets, donc la recherche a besoin d'une version normalisée).

**Getter calculé** : `isOpenNow` (bool?) — se base sur `openingHours[jour courant]`, retourne `null` si l'horaire du jour est absent ou mal formaté (l'UI n'affiche alors pas de badge).

---

## 3ter. Modèle Chat (`lib/models/chat_model.dart`)

Collection Firestore : **`chats/{chatId}`**

Vu du point de vue de l'utilisateur connecté — les champs `other*` désignent toujours l'interlocuteur.

| Champ Dart | Type | Notes |
|---|---|---|
| `id` | `String` | |
| `participants` | `List<String>` | les 2 uid |
| `otherUserId`, `otherUsername`, `otherAvatarUrl`, `otherIsGoldMember` | — | dérivés de `participantsInfo[otherUid]` (dénormalisé côté Firestore) |
| `lastMessage`, `lastMessageSenderId`, `lastMessageAt` | — | |
| `unreadCount` | `int` | dérivé de `unreadCounts[currentUid]` |

**Structure Firestore réelle** (pas 1:1 avec la classe Dart, car dénormalisée) :
```
chats/{chatId}
  participants: array<string>
  participantsInfo: map<uid, {username, avatarUrl, isGoldMember}>
  lastMessage, lastMessageSenderId, lastMessageAt
  unreadCounts: map<uid, number>
  createdAt: Timestamp
```

### Sous-collection Messages (`lib/models/message_model.dart`)
**`chats/{chatId}/messages/{messageId}`**

| Champ Dart | Type |
|---|---|
| `id`, `senderId`, `text`, `createdAt` | `String` / `DateTime?` |

---

## 3quater. Modèle Video (`lib/models/video_model.dart`)

Collection Firestore : **`videos/{videoId}`**

| Champ Dart | Type | Notes |
|---|---|---|
| `id`, `userId`, `username`, `userAvatarUrl`, `isVerified` | — | dénormalisé depuis l'auteur |
| `videoUrl`, `thumbnailUrl` | `String` | |
| `caption` | `String` | |
| `hashtags` | `List<String>` | |
| `musicName` | `String` | défaut `"Son original - Muheto"` |
| `category` | `String` | ex. `"humour"`, `"musique"`, `"business"` |
| `scope` | `ContentScope` (enum) | **`burundi` \| `afrique` \| `monde`** — choisi à l'onboarding ("Choisis ton univers"). ⚠️ Ce `scope` est celui de la vidéo, PAS un champ de `UserModel` (qui n'a pas encore ce champ, voir section 3) |
| `language` | `String` | `"rn" \| "fr" \| "en" \| "sw"` |
| `likesCount`, `commentsCount`, `sharesCount`, `viewsCount` | `int` | |
| `createdAt` | `DateTime?` | |
| `isBusinessPost` | `bool` | |
| `searchKeywords` | `List<String>` | dénormalisé (légende + hashtags en minuscules) pour la recherche plein-texte (Brique 12), voir `buildSearchKeywords` |

Méthode utilitaire : `copyWith({likesCount, commentsCount, sharesCount})` pour mises à jour optimistes côté UI.

### Sous-collection Comments (`lib/models/comment_model.dart`)
**`videos/{videoId}/comments/{commentId}`**

| Champ Dart | Type | Notes |
|---|---|---|
| `id`, `userId`, `username`, `avatarUrl`, `text` | — | |
| `isGoldMember` | `bool` | dénormalisé au moment du commentaire (évite une lecture supplémentaire par commentaire pour afficher le badge VIP) |
| `likesCount` | `int` | |
| `createdAt` | `DateTime?` | |

---

## 4. Services (`lib/services/`)

### 4.1 `AuthService` (`auth_service.dart`)
- `signIn({email, password})`
- `signUp({username, email, password})` → vérifie d'abord l'unicité du username (lecture Firestore, doit rester accessible sans authentification), crée le compte Firebase Auth, écrit le document `users/{uid}`
- `signOut()`
- `deleteAccount({password})` → ré-authentifie puis supprime le document Firestore ET le compte Auth. ⚠️ Ne supprime PAS en cascade les vidéos/chats/fiche Business (pas de conformité RGPD complète)
- `sendPasswordResetEmail(email)`
- `friendlyErrorMessage(error)` → messages d'erreur en français pour l'UI
- `currentUser` (getter), `authStateChanges` (Stream)

### 4.2 `BusinessService` (`business_service.dart`) — collection `businesses`
- Id de document **généré à l'avance** via `newBusinessId()` (PAS l'uid du propriétaire) — permet d'uploader logo/bannière vers Storage avant que le document existe.
- Règle "une seule fiche Business par utilisateur" appliquée **côté applicatif uniquement** (via `getMyBusiness(uid)`), pas dans les règles Firestore.
- `watchBusinesses({category})` — tri : sponsorisés d'abord (`isSponsored desc`), puis `createdAt desc`.
- `searchBusinesses(query)` — recherche par préfixe sur `nameLower` (champ dénormalisé, auto-généré par `_withNameLower()` à chaque create/update).
- `createBusinessWithId(id, business)`, `updateBusiness(id, data)`, `isOwner(id, uid)`.
- Analytics (Brique 13) : `registerBusinessView`, `registerCallClick`, `registerWebsiteClick`, `registerWhatsappClick` — tous via `FieldValue.increment(1)` isolé, jamais via `updateBusiness()` (évite d'écraser un compteur avec une valeur périmée).
- **Index composite Firestore requis** : `businesses: category ASC, isSponsored DESC, createdAt DESC`

### 4.3 `ChatService` (`chat_service.dart`) — collection `chats`
- **Id de chat déterministe** : les 2 uid triés alphabétiquement, joints par `_` (`uid1_uid2`) → garantit une seule conversation possible entre deux personnes, jamais de doublon.
- `getOrCreateChat(otherUid)` — crée le document avec `participantsInfo` dénormalisé (username/avatar/isGoldMember des deux) si le chat n'existe pas encore.
- `watchUserChats()` — triées par `lastMessageAt desc`.
- `watchMessages(chatId)` — sous-collection `chats/{chatId}/messages`.
- `sendMessage({chatId, text})` — via `runTransaction` : écrit le message, met à jour `lastMessage`/`lastMessageAt`, incrémente `unreadCounts.{otherUid}`, remet `unreadCounts.{uid}` à 0.
- `markChatAsRead(chatId)` — à appeler à l'ouverture de l'écran de conversation.

### 4.4 `FeedService` (`feed_service.dart`) — collection `videos`
- `watchFeed({scope, pageSize})` + `fetchMoreVideos({after, scope, pageSize})` pour la pagination infinie.
- `toggleLike(videoId)` — sous-collection `videos/{id}/likes/{uid}` (trace anti-doublon) + `likesCount` incrémenté/décrémenté via `runTransaction`.
- `watchIsLiked(videoId)`, `registerView(videoId)`, `registerShare(videoId)`.
- `watchComments(videoId)` / `addComment(videoId, comment)` — sous-collection `videos/{id}/comments`, `runTransaction` pour incrémenter `commentsCount`.
- `getVideoOnce(videoId)` — lecture ponctuelle, utilisée par les deep-links de notification.
- **Index composite Firestore requis** : `videos: scope ASC, createdAt DESC`

### 4.5 `GoldService` (`gold_service.dart`) — statut Gold sur `users/{uid}`
> ⚠️⚠️ **FAILLE DE SÉCURITÉ CONNUE, NON CORRIGÉE** : `startFreeTrial()` et `activateSubscription()`
> écrivent DIRECTEMENT `isGoldMember`/`goldExpirationDate` dans Firestore, **sans aucune vérification
> de paiement réelle**. N'importe quel utilisateur peut actuellement s'auto-attribuer le statut Gold.
> **Ne jamais considérer ces méthodes comme sûres pour la production** tant qu'elles n'ont pas été
> remplacées par un appel à une Cloud Function qui valide un webhook de paiement avant d'écrire.
- `watchGoldStatus(uid)`, `startFreeTrial(uid)` (7 jours), `activateSubscription(uid, {duration=30 jours})` (prolonge depuis la date d'expiration actuelle si encore active, sinon depuis aujourd'hui), `cancelSubscription(uid)`.

### 4.6 `NotificationService` (`notification_service.dart`)
- Champ `fcmToken` stocké/supprimé sur `users/{uid}` via `registerDeviceToken()` / `clearDeviceToken(uid)`.
- `firebaseMessagingBackgroundHandler` : **fonction top-level obligatoire** (pas une méthode de classe), annotée `@pragma('vm:entry-point')` pour survivre au tree-shaking en release. Tourne dans un isolate séparé — si besoin de Firebase dedans, il faut le ré-initialiser (le isolate principal ne partage pas son état).
- 3 cas de réception gérés séparément : `listenForegroundMessages()` (bannière dorée custom), `listenNotificationTapWhileBackgrounded()` (`onMessageOpenedApp`), `handleInitialMessageIfAny()` (cold start, `getInitialMessage()`).
- `enum MuhetoNotificationType { chat, comment, follow, unknown }` — la valeur du champ `type` dans le payload `data` doit correspondre exactement à ce qu'envoient les Cloud Functions (`functions/index.js`).
- Navigation faite via `appNavigatorKey` global (pas besoin de `BuildContext` local).

### 4.7 `ProfileService` (`profile_service.dart`)
- Sous-collections : `users/{uid}/followers/{followerUid}` et `users/{uid}/following/{targetUid}` (chacune `{ createdAt }`).
- `toggleFollow(targetUid)` — via `runTransaction`, met à jour les 2 sous-collections + `followersCount`/`followingCount` de façon atomique.
- `watchUser(uid)` (stream), `getUserOnce(uid)` (lecture ponctuelle, pour dénormaliser sans listener permanent).
- `watchUserVideos(uid)` — alimente la grille 3 colonnes du profil.
- `isUsernameTaken(username, {excludingUid})` — utilisé à l'édition de profil.
- `updateProfile({uid, username?, displayName?, bio?, avatarUrl?})`.
- **Index composite Firestore requis** : `videos: userId ASC, createdAt DESC`

### 4.8 `SearchService` (`search_service.dart`) — Brique 12
- Recherche par **préfixe / mots-clés**, PAS de vraie recherche plein-texte (limitation Firestore native). Pas de tolérance aux fautes de frappe.
- `searchUsers(query)` — préfixe sur `username` (déjà normalisé en minuscules depuis la Brique 5).
- `searchVideos(query)` :
  - si la requête commence par `#` → `arrayContains` exact sur `hashtags`
  - sinon → `arrayContainsAny` sur `searchKeywords` (champ dénormalisé légende+hashtags, calculé à la publication par `UploadService`)
  - ⚠️ **Backfill manquant** : les vidéos publiées AVANT la Brique 12 n'ont pas de `searchKeywords` et ne remontent pas dans la recherche tant qu'un script rétroactif ne le leur ajoute pas.
  - Tri par date fait **côté client** (pas de `orderBy` combiné à `arrayContains*` sans index composite dédié).
- La recherche de commerces reste dans `BusinessService.searchBusinesses` (pas dans ce service).
- Piste d'évolution documentée dans le code : Algolia/Typesense pour une vraie recherche plein-texte à plus grande échelle.

---

### 4.9 Firebase Storage — ⚠️ NON FONCTIONNEL, plan Blaze requis (découvert le 26/08/2026)
- Chemins Storage utilisés dans le code (via `UploadService`, `BusinessFormScreen`, `EditProfileScreen`) :
  - `videos/{uid}/{videoId}.mp4`
  - `thumbnails/{uid}/{videoId}.jpg`
  - `business_logos/{businessId}.jpg`
  - `business_banners/{businessId}.jpg`
  - `avatars/{uid}.jpg`
- **Blocage actuel** : le projet Firebase est sur le plan gratuit **Spark**, qui ne permet PAS d'activer Cloud Storage du tout (pas juste une question de règles de sécurité — le service lui-même n'est pas activable). Il faut passer sur le plan **Blaze** (paiement à l'usage), ce qui nécessite de lier une carte bancaire (même virtuelle/prépayée) au compte Google Cloud — même si en pratique aucun frais n'est prélevé tant qu'on reste sous les quotas gratuits (5 Go de stockage, 1 Go de téléchargement/jour, renouvelés chaque mois).
- **Conséquence concrète tant que ce n'est pas fait** : toute action qui upload un fichier (publier une vidéo, changer d'avatar, ajouter un logo/bannière Business) échoue avec un message générique côté UI (ex. *"La publication a échoué. Vérifie ta connexion et réessaie."* dans `publish_screen.dart`) — le vrai message d'erreur Firebase est avalé, pas affiché.
- **Pas encore fait au 26/08/2026** : carte bancaire pas encore disponible côté porteur du projet. Ni les règles de sécurité Storage (`storage.rules`, différentes des règles Firestore) n'ont été écrites — à faire une fois Blaze activé, en s'inspirant des chemins listés ci-dessus (lecture publique, écriture réservée au `{uid}`/`{businessId}` concerné).

---

## 5. Règles de sécurité Firestore (état actuel, publié le 24/08/2026)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if true;
      allow create, update: if request.auth != null && request.auth.uid == userId;
      allow delete: if false;
      match /followers/{followerId} {
        allow read: if true;
        allow write: if request.auth != null;
      }
      match /following/{targetId} {
        allow read: if true;
        allow write: if request.auth != null;
      }
    }
    match /businesses/{businessId} {
      allow read: if true;
      allow create: if request.auth != null && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null && resource.data.ownerId == request.auth.uid;
    }
    match /videos/{videoId} {
      allow read: if true;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update: if request.auth != null;
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
      match /likes/{likeUserId} {
        allow read: if true;
        allow create, delete: if request.auth != null && request.auth.uid == likeUserId;
      }
      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
        allow update, delete: if false;
      }
    }
    match /chats/{chatId} {
      allow read, write: if request.auth != null && request.auth.uid in resource.data.participants;
      allow create: if request.auth != null && request.auth.uid in request.resource.data.participants;
      match /messages/{messageId} {
        allow read, write: if request.auth != null &&
          request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
      }
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```
- `users`, `businesses`, `videos` : lecture ouverte à tous ; écriture réservée au propriétaire (`uid`/`ownerId`/`userId` selon la collection)
- `videos/{id}/likes/{uid}` : un utilisateur ne peut créer/supprimer que **son propre** like (id du doc = son uid)
- `videos/{id}/comments` : lecture ouverte, création réservée à un utilisateur connecté déclarant son propre `userId`, aucune modification/suppression possible via les règles
- `chats` et `chats/{id}/messages` : réservés strictement aux `participants` du chat (vérifié via `resource.data.participants` en lecture, `request.resource.data.participants` en création)
- `users/{uid}/followers` et `/following` : lecture ouverte, écriture par tout utilisateur connecté (pas de vérification fine de "qui peut suivre qui" au niveau des règles — repose sur la logique applicative de `ProfileService.toggleFollow`)
- ⚠️ `videos update` : actuellement ouvert à **tout utilisateur connecté**, pas seulement l'auteur — nécessaire pour permettre les compteurs (`likesCount`, `commentsCount`, `viewsCount`, `sharesCount`) incrémentés par d'autres utilisateurs que l'auteur. Pas de vérification fine que seuls ces champs-là sont modifiés — un utilisateur connecté pourrait techniquement modifier `caption` ou `videoUrl` d'une vidéo qui n'est pas la sienne. À durcir avant la production (ex: `request.resource.data.diff(resource.data).affectedKeys()` limité aux compteurs).
- **Toute collection non listée ci-dessus reste bloquée par défaut.**

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

## 8. État d'avancement (au 26/08/2026)

**Fonctionnel et testé sur appareil réel (Infinix HOT 40i, APK debug)** :
- Firebase correctement connecté (Auth + Firestore)
- Inscription / création de compte → testée avec succès de bout en bout
- Connexion avec un compte existant → testée avec succès
- Navigation entre TOUS les onglets (Ahabanza, Menya, Ubutumwa, Umwirondoro) sans plantage — bug Kirundi/MaterialLocalizations corrigé le 26/08
- Écran Paramètres complet : changement de langue, déconnexion, **Conditions d'utilisation** (nouveau, texte affiché avec succès), suppression de compte
- Traductions : Feed, Chat, Recherche, Paramètres, Gold + 14 écrans complétés (Profil, Création/Publication, Business, Analytics, etc.)
- Règles Firestore complètes publiées (users, businesses, videos+likes+comments, chats+messages, followers/following)

**Bugs corrigés le 26/08/2026** :
- Écran rouge "No MaterialLocalizations found" sur tous les onglets sauf le Feed → voir section 2 (délégués de repli Kirundi)
- `comment_model.dart` s'était retrouvé accidentellement écrasé par le contenu de ce fichier MEMO.md (probable copier-coller malheureux entre onglets VS Code) → restauré. **Leçon apprise : après toute session de gros copier-coller entre plusieurs fichiers ouverts simultanément, vérifier rapidement le début de chaque fichier concerné avant de commit/push.**

**Bloqué / en attente** :
- **Publication de vidéo, changement d'avatar, logo/bannière Business** : tous impossibles tant que Firebase Storage n'est pas activé (nécessite le plan Blaze + carte bancaire) — voir section 4.9. Message d'erreur générique côté UI, ne pas confondre avec un bug de code.

**Connu comme non implémenté / à faire** :
- Champ `scope` du modèle utilisateur (mentionné en commentaire seulement)
- Suppression de compte en cascade (RGPD complet, nécessite une Cloud Function)
- Vraies CGU validées par un professionnel du droit (le texte actuel dans `settings.termsBody` est un modèle de départ fonctionnel mais non juridiquement validé)
- Passerelle de paiement réelle pour MUHETO Gold (voir faille de sécurité section 4.5)
- Règles de sécurité Storage (`storage.rules`) — à écrire une fois Blaze activé
- Règle `videos update` trop permissive (tout utilisateur connecté, pas seulement l'auteur) — à durcir avant production, voir section 5
- 2 warnings CI persistants (dépréciation Node.js 20 / `setup-java@v3` dans `build.yml`, sans impact fonctionnel)
- Upload d'artefact APK configuré en `--debug`, pas encore en `--release`
