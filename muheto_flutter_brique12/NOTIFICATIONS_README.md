# MUHETO — Brique 11 : Notifications Push (Firebase Cloud Messaging)

## Fichiers livrés

```
lib/core/navigation/app_navigator_key.dart                    → Clé de navigation globale
lib/services/notification_service.dart                         → Permissions, token, écoute, routage
lib/features/notifications/widgets/gold_notification_banner.dart → Bannière dorée premier plan

functions/package.json                                          → Dépendances Cloud Functions
functions/index.js                                               → Déclencheurs d'envoi (Node.js)
```

Modifications sur des fichiers existants :
- `pubspec.yaml` — ajout de `firebase_messaging`.
- `lib/main_example.dart` — `navigatorKey: appNavigatorKey` sur le
  `MaterialApp`, et `FirebaseMessaging.onBackgroundMessage(...)` enregistré
  avant `runApp()`.
- `lib/features/navigation/main_navigation_shell.dart` — au premier
  affichage (utilisateur authentifié), demande la permission, enregistre
  le token FCM, et gère le cas où l'app a été ouverte directement depuis
  une notification (cold start).
- `lib/features/settings/settings_screen.dart` — supprime le token FCM
  de Firestore juste avant la déconnexion effective.

## Architecture : pourquoi client et serveur sont séparés

```
┌─────────────────────────────┐         ┌──────────────────────────────┐
│  APP FLUTTER (client)        │         │  CLOUD FUNCTIONS (serveur)     │
│                              │         │                                │
│  • Demande la permission      │         │  • Écoute les écritures        │
│  • Récupère le token FCM      │────────►│    Firestore (nouveau message, │
│    et le sauvegarde dans      │ stocke  │    commentaire, follower)      │
│    users/{uid}.fcmToken       │  token  │  • Envoie la notification via  │
│  • Écoute les messages         │         │    Admin SDK (droits serveur)  │
│    entrants (premier plan,    │◄────────│  • JAMAIS de clé sensible       │
│    tap sur notification)      │  FCM    │    exposée côté client          │
└─────────────────────────────┘         └──────────────────────────────┘
```

**Le client ne peut PAS envoyer de notification à un autre utilisateur** —
et ce n'est pas une limitation de cette brique, c'est une règle de sécurité
non négociable : envoyer via FCM à un tiers nécessite les droits admin
Firebase, qui ne doivent jamais être embarqués dans une app mobile
(n'importe qui pourrait les extraire et notifier n'importe qui). C'est
pour ça que le point 3 de la demande ("déclencheur d'envoi") est implémenté
comme une **Cloud Function côté serveur**, dans `functions/index.js`,
déclenchée automatiquement par Firestore — jamais appelée directement par
l'app.

## `NotificationService` en détail

- `registerDeviceToken()` — demande la permission, récupère le token FCM
  actuel, le sauvegarde dans `users/{uid}.fcmToken`, et écoute
  `onTokenRefresh` pour rester à jour automatiquement (le token peut
  changer, par exemple après une longue période d'inactivité).
- `listenForegroundMessages()` — FCM n'affiche **jamais** de notification
  système quand l'app est au premier plan (comportement standard sur
  Android et iOS). C'est pour ça qu'on affiche notre propre
  **bannière dorée** ([GoldNotificationBanner]) qui slide depuis le haut,
  tappable pour naviguer directement, avec disparition automatique après
  5 secondes ou balayage vers le haut.
- `listenNotificationTapWhileBackgrounded()` — l'app était ouverte en
  arrière-plan (pas fermée), l'utilisateur tape sur la notification
  système : `onMessageOpenedApp` se déclenche et on navigue directement
  vers le bon écran.
- `handleInitialMessageIfAny()` — cas le plus délicat : l'app était
  **totalement fermée** et s'est ouverte parce que l'utilisateur a tapé
  sur la notification (cold start). `getInitialMessage()` récupère ce
  message une fois, au démarrage de `MainNavigationShell`.
- `firebaseMessagingBackgroundHandler` — fonction top-level obligatoire
  (contrainte technique de `firebase_messaging` : elle tourne dans un
  isolate séparé). Volontairement minimale : Android/iOS affichent déjà la
  notification système automatiquement tant que le payload contient un
  bloc `notification` (ce que fait toujours `functions/index.js`).

## Routage au clic (`_navigateFromMessage`)

Le payload `data` de chaque notification contient un champ `type` qui
détermine l'écran ouvert :

| `type`    | Champs `data` attendus                                    | Écran ouvert       |
|-----------|-------------------------------------------------------------|--------------------|
| `chat`    | `chatId`, `otherUserId`, `otherUsername`, `otherAvatarUrl`  | `ChatScreen`        |
| `comment` | `videoId`                                                    | `SingleVideoScreen` |
| `follow`  | `followerId`                                                 | `ProfileScreen`     |

## Cloud Functions (`functions/index.js`)

Trois déclencheurs Firestore (`onDocumentCreated`) :

1. **`onNewChatMessage`** — LE déclencheur demandé explicitement (point 3).
   Se déclenche sur `chats/{chatId}/messages/{messageId}`, retrouve le
   destinataire (l'autre participant), et lui envoie une notification avec
   le pseudo et l'avatar de l'expéditeur (déjà dénormalisés dans
   `participantsInfo` depuis la Brique 6).
2. **`onNewComment`** — extension mentionnée dans le message d'intro de la
   brique. Notifie l'auteur de la vidéo (sauf s'il commente sa propre
   vidéo).
3. **`onNewFollower`** — extension également mentionnée. Notifie
   l'utilisateur suivi.

Chaque envoi passe par `sendToUser()`, qui gère proprement l'absence de
token (utilisateur n'ayant jamais autorisé les notifications — pas une
erreur) et **nettoie automatiquement les tokens devenus invalides**
(désinstallation de l'app) pour éviter de retenter indéfiniment.

## ⚠️ Configuration native obligatoire

### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<!-- Android 13+ (API 33) exige cette permission explicite pour les notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Optionnel mais recommandé — icône et couleur par défaut des notifications
système (dans la balise `<application>`) :
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/gold_accent" />
```

### iOS — Apple Push Notification service (APNs)

1. Active la capacité **Push Notifications** dans Xcode
   (Runner → Signing & Capabilities).
2. Génère une clé APNs (ou un certificat) dans ton compte Apple Developer,
   et importe-la dans Firebase Console → Project Settings → Cloud Messaging
   → Apple app configuration.
3. Les notifications push ne fonctionnent **jamais** sur le simulateur iOS
   — teste toujours sur un appareil physique.

### Firebase Console

Active **Cloud Messaging** dans la console si ce n'est pas déjà fait
(Project Settings → Cloud Messaging) — aucune clé serveur à copier dans
l'app, tout passe par les Cloud Functions avec les droits admin natifs.

## Déploiement des Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

Nécessite le plan **Blaze** (pay-as-you-go) — les fonctions avec appels
réseau sortants (comme l'envoi FCM) ne sont pas disponibles sur le plan
gratuit Spark. Le quota gratuit mensuel reste généreux pour un volume de
lancement.

## Tester sans attendre un vrai message/commentaire/follower

Firebase Console → Cloud Messaging → "Créer votre première campagne" te
permet d'envoyer une notification de test directement à un token FCM
donné (visible dans Firestore, champ `users/{uid}.fcmToken`, une fois
qu'un utilisateur a autorisé les notifications dans l'app) — pratique
pour valider l'affichage système et la bannière dorée sans passer par un
vrai flux chat.

## Limites volontaires de cette brique (V1)

- **Un seul token par utilisateur** (`fcmToken` en champ simple, pas un
  tableau). Un utilisateur connecté sur plusieurs appareils ne recevra les
  notifications que sur le dernier appareil ayant enregistré son token.
  Pour du multi-device, transformer en `fcmTokens: array<string>` et
  boucler dessus côté Cloud Function (`messaging.sendEachForMulticast`).
- Pas de préférences de notification par type (ex: désactiver "nouveau
  follower" mais garder "nouveau message") — tout ou rien pour l'instant.
- Pas de badge de compteur sur l'icône de l'app (iOS) — ajoutable via le
  champ `apns.payload.aps.badge` dans les Cloud Functions.

## Intégration

1. Copie `lib/core/navigation/`, `lib/services/notification_service.dart`,
   `lib/features/notifications/`.
2. Applique les patches sur `pubspec.yaml`, `main.dart`,
   `main_navigation_shell.dart`, `settings_screen.dart`.
3. Ajoute la permission Android et configure APNs pour iOS (voir ci-dessus).
4. Copie le dossier `functions/` à la racine de ton projet Firebase (à
   côté de `firebase.json`, pas dans le projet Flutter lui-même) et
   déploie-le.
5. Teste sur un vrai appareil (obligatoire pour iOS, recommandé pour
   Android) : envoie-toi un message via le Chat depuis un second compte et
   vérifie que la notification arrive.

## Prochaines briques possibles

1. Passerelle de paiement réelle pour MUHETO Gold (Mobile Money / Stripe)
2. Traduire les écrans restants (reste de la Brique 9)
3. Recherche plein-texte (Algolia / Typesense)
4. Préférences de notification par type
5. Support multi-device (tableau de tokens FCM)

Dis-moi laquelle tu veux ensuite.
