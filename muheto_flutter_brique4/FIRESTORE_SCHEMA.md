# MUHETO — Schéma Firestore & Guide d'intégration (Brique 1 : Feed Principal)

## 1. Collections Firestore

### `users/{uid}`
| Champ | Type | Description |
|---|---|---|
| username | string | @pseudo unique |
| displayName | string | Nom affiché |
| avatarUrl | string | URL Firebase Storage |
| bio | string | Description profil |
| isVerified | bool | Badge doré vérifié |
| isBusinessAccount | bool | Compte Business local |
| isGoldMember | bool | Abonnement MUHETO Gold actif |
| followersCount / followingCount / likesCount | number | Compteurs |
| country | string | ex: "BI" |
| language | string | "rn" \| "fr" \| "en" \| "sw" |
| createdAt | timestamp | |

### `videos/{videoId}`
| Champ | Type | Description |
|---|---|---|
| userId | string | Référence vers `users/{uid}` |
| username, userAvatarUrl, isVerified | — | Dénormalisés pour éviter une lecture supplémentaire au scroll |
| videoUrl | string | Firebase Storage / CDN |
| thumbnailUrl | string | Image affichée pendant le chargement |
| caption | string | Description |
| hashtags | array\<string\> | |
| musicName | string | |
| category | string | "humour", "musique", "business", ... |
| scope | string | "burundi" \| "afrique" \| "monde" (univers choisi à l'onboarding) |
| language | string | |
| likesCount / commentsCount / sharesCount / viewsCount | number | Compteurs dénormalisés |
| isBusinessPost | bool | Affiche le badge "BUSINESS LOCAL" |
| createdAt | timestamp | |

Sous-collections :
- `videos/{videoId}/likes/{uid}` → `{ userId, createdAt }` (évite les doublons de like)
- `videos/{videoId}/comments/{commentId}` → `{ userId, username, avatarUrl, text, likesCount, createdAt }`

## 2. Index composite requis

Si tu filtres par `scope` ET trie par `createdAt`, crée dans Firestore Console → Indexes :

```
Collection: videos
Fields indexed: scope (Ascending), createdAt (Descending)
```

## 3. Règles de sécurité Firestore (à adapter dans `firestore.rules`)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{uid} {
      allow read: if true;
      allow create: if request.auth != null && request.auth.uid == uid;
      allow update: if request.auth != null && request.auth.uid == uid;
    }

    match /videos/{videoId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['likesCount', 'commentsCount', 'sharesCount', 'viewsCount']);
      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;

      match /likes/{uid} {
        allow read: if true;
        allow write: if request.auth != null && request.auth.uid == uid;
      }

      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow update, delete: if request.auth != null &&
          request.auth.uid == resource.data.userId;
      }
    }
  }
}
```

## 4. Intégration dans ton projet FlutterFlow existant

1. Copie les dossiers `lib/core`, `lib/models`, `lib/services`, `lib/features/feed` dans ton projet local.
2. Ajoute les dépendances de `pubspec.yaml` (fusionne avec les tiennes, ne remplace pas ta config Firebase existante).
3. Applique `AppTheme.darkTheme` dans ton `MaterialApp` :
   ```dart
   MaterialApp(
     theme: AppTheme.darkTheme,
     home: const FeedScreen(),
   )
   ```
4. Lance `flutter pub get`.
5. Assure-toi que `Firebase.initializeApp()` est bien appelé avant `runApp()` (déjà fait chez toi normalement).

## 5. Prochaines briques possibles

- Écrans Splash / Login / Inscription (Firebase Auth)
- Navbar bas (Accueil, Découvrir, +, Boîte, Profil)
- Page Profil créateur (grille 3 colonnes)
- Page Business Locale
- Localisation multilingue (fichiers `.arb` : rn, fr, en, sw)

Dis-moi laquelle tu veux ensuite.
