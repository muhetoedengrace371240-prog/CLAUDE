# MUHETO — Brique 4 : Profil connecté en direct sur Firestore

## Fichiers livrés

```
lib/services/profile_service.dart                → Lecture profil, vidéos, follow/unfollow

lib/features/profile/profile_screen.dart          → Écran profil (réécrit, branché Firestore)
lib/features/profile/single_video_screen.dart     → Lecture plein écran depuis la grille
lib/features/profile/widgets/profile_stat.dart    → Compteur formaté (15.6K, 320.2K...)
lib/features/profile/widgets/video_grid_tile.dart → Tuile de la grille 3 colonnes
```

Petit ajustement corollaire : `feed_screen.dart` ouvre maintenant vraiment
`ProfileScreen(uid: video.userId)` quand on tape sur l'avatar d'un créateur
dans le feed (c'était un `TODO` dans la Brique 1).

## Ce qui est branché en direct

- **Infos profil** (avatar, pseudo, bio, badge vérifié, badge Gold) via
  `ProfileService.watchUser(uid)` — `StreamBuilder` donc mise à jour en
  temps réel si le profil change ailleurs dans l'app.
- **Grille de vidéos** via `watchUserVideos(uid)` — requête Firestore
  `videos where userId == uid orderBy createdAt desc`, live.
- **Abonnés / Abonnements** : lus directement depuis `followersCount` /
  `followingCount` sur le document utilisateur, tenus à jour par
  `toggleFollow()` (transaction atomique, aucune Cloud Function requise).
- **Total des "J'aime"** : calculé en direct côté client en sommant
  `likesCount` de toutes les vidéos de l'utilisateur (pas de champ dénormalisé
  séparé à maintenir — simple et suffisant pour le volume de la V1).
- **Bouton Suivre / Abonné** : n'apparaît que sur le profil d'un *autre*
  utilisateur ; reflète l'état réel via `watchIsFollowing(uid)`.
- **Grille tappable** : chaque vignette ouvre `SingleVideoScreen`, qui
  réutilise le lecteur du Feed principal.

## Système de suivi (follow) — structure Firestore

```
users/{uid}/followers/{followerUid}  → { userId, createdAt }
users/{uid}/following/{targetUid}    → { userId, createdAt }
```

`toggleFollow()` fait tout en une seule transaction : écrit/supprime les deux
sous-documents ET incrémente/décrémente `followersCount` (côté profil ciblé)
et `followingCount` (côté profil courant) — jamais désynchronisés.

## Index composite Firestore requis

```
Collection: videos
Fields indexed: userId (Ascending), createdAt (Descending)
```
Firestore te proposera normalement un lien direct pour le créer dans les
logs de la console dès la première requête exécutée si l'index manque.

## Règles Firestore à ajouter (complète celles des Briques 1 et 3)

```
match /users/{uid} {
  allow read: if true;
  allow update: if request.auth != null && request.auth.uid == uid &&
    // empêche un utilisateur de modifier ses propres compteurs directement
    !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny(['followersCount', 'followingCount']);

  match /followers/{followerUid} {
    allow read: if true;
    allow write: if request.auth != null && request.auth.uid == followerUid;
  }

  match /following/{targetUid} {
    allow read: if true;
    allow write: if request.auth != null && request.auth.uid == uid;
  }
}
```

> Comme `toggleFollow` écrit sur `followersCount`/`followingCount` via une
> transaction lancée par l'utilisateur connecté (pas par un Cloud Function
> admin), ces règles autorisent explicitement les sous-collections
> `followers`/`following` en écriture pour le bon utilisateur, tout en
> bloquant la modification directe des compteurs sur le document `users`
> lui-même en dehors de ce chemin.

## Intégration

1. Copie `lib/services/profile_service.dart` et tout `lib/features/profile/`
   (remplace le placeholder de la Brique 2).
2. Aucune nouvelle dépendance `pubspec.yaml` — tout repose sur
   `cloud_firestore` et `firebase_auth`, déjà présents.
3. Crée l'index composite `videos: userId ASC, createdAt DESC`.
4. Complète tes `firestore.rules` avec le bloc ci-dessus.
5. Assure-toi qu'un document `users/{uid}` existe bien à l'inscription
   (créé normalement par ton flow Firebase Auth existant) — sinon
   `ProfileScreen` affichera "Utilisateur introuvable."

## Limites volontaires de cette brique (V1)

- Pas d'écran d'édition de profil dédié pour l'instant (bouton "Modifier le
  profil" en `TODO`) — à faire dans une brique dédiée (upload avatar,
  modification bio, changement de langue).
- Le total de likes est recalculé à chaque frame depuis la liste de vidéos
  déjà chargée (pas de pagination pour l'instant sur la grille profil) —
  suffisant tant qu'un créateur n'a pas des centaines de vidéos ; à revoir
  avec une pagination + champ dénormalisé si besoin plus tard.

## Prochaines briques possibles

1. Splash / Login / Inscription (Firebase Auth)
2. Édition de profil (avatar, bio, langue)
3. Page Business Locale
4. Messagerie temps réel
5. MUHETO Gold (abonnement premium)
6. Localisation multilingue (rn / fr / en / sw)

Dis-moi laquelle tu veux ensuite.
