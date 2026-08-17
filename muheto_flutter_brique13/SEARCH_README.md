# MUHETO — Brique 12 : Recherche plein-texte globale

## Fichiers livrés

```
lib/core/utils/search_keywords.dart                 → buildSearchKeywords() / parseSearchQuery()
lib/services/search_service.dart                     → Recherche utilisateurs + vidéos

lib/features/search/search_screen.dart               → Écran principal (barre + onglets + résultats)
lib/features/search/widgets/search_tab_selector.dart  → Sélecteur Utilisateurs/Vidéos/Business
lib/features/search/widgets/user_result_tile.dart     → Ligne de résultat utilisateur
```

Modifications sur des fichiers existants :
- `lib/models/business_model.dart` — ajout de `nameLower` (normalisé) dans
  `toFirestore()`, pour une recherche par préfixe fiable et insensible à
  la casse.
- `lib/services/business_service.dart` — `searchBusinesses()` interroge
  désormais `nameLower` au lieu de `name` (corrige un bug latent des
  Briques 7/8 : une recherche en minuscules ne remontait aucun résultat si
  le nom du commerce commençait par une majuscule).
- `lib/features/discover/discover_screen.dart` — le champ de recherche
  (jusqu'ici décoratif) ouvre maintenant `SearchScreen` au tap.
- `lib/features/business/business_screen.dart` — l'icône loupe (en `TODO`
  depuis la Brique 7) ouvre `SearchScreen` directement sur l'onglet
  Business.

## ⚠️ Ce n'est PAS une vraie recherche plein-texte — et c'est volontaire

Firestore ne propose nativement que deux mécanismes de requête utilisables
pour une recherche :
1. **Préfixe** (`orderBy` + `startAt`/`endAt`) — trouve "kaze" en tapant
   "ka", mais ne trouve jamais "kaze" en tapant "aze".
2. **Égalité exacte sur un tableau** (`arrayContains`/`arrayContainsAny`) —
   permet une recherche par mots-clés dénormalisés, mais reste une
   correspondance exacte mot par mot, pas une vraie tolérance aux fautes
   de frappe ni un classement par pertinence.

Cette brique combine les deux, en dénormalisant volontairement des données
supplémentaires à l'écriture :

| Collection  | Champ interrogé      | Mécanisme                          | Dénormalisé où ? |
|-------------|-----------------------|--------------------------------------|-------------------|
| `users`     | `username`             | Préfixe                              | Déjà en Brique 5 (pseudo stocké en minuscules) |
| `businesses`| `nameLower`            | Préfixe                              | Ajouté cette brique dans `BusinessModel.toFirestore()` |
| `videos`    | `hashtags` (si `#...`) | `arrayContains` (tag exact)           | Déjà en Brique 3 |
| `videos`    | `searchKeywords`        | `arrayContainsAny` (mots de la légende) | Déjà préparé en Brique 3 par `UploadService` via `buildSearchKeywords()` |

**Pour une recherche de production à grande échelle** (tolérance aux
fautes de frappe, recherche "n'importe où dans le texte", classement par
pertinence, recherche combinée multi-champs) : la marche à suivre standard
est d'indexer les mêmes données dans **Algolia** ou **Typesense** en
parallèle de Firestore (via une Cloud Function qui synchronise à chaque
écriture), et de faire interroger ce service tiers par l'app plutôt que
Firestore directement. C'est une brique à part entière, pas incluse ici.

## ⚠️ Les vidéos publiées AVANT cette brique ne sont pas cherchables

`searchKeywords` est calculé par `UploadService` au moment de la
publication (déjà en place depuis la Brique 3, en anticipation de cette
brique). Toute vidéo publiée avant l'activation de cette recherche ne
possède pas ce champ et ne remontera donc jamais dans une recherche par
mot-clé (la recherche par `#hashtag` fonctionne, elle, pour toutes les
vidéos, dès la Brique 3).

**Script de backfill à lancer une fois** si tu as déjà des vidéos en
production avant cette brique (à exécuter côté Cloud Functions / Admin
SDK, jamais côté client) :
```js
const admin = require('firebase-admin');
const { buildSearchKeywords } = require('./searchKeywordsHelper'); // à porter en JS depuis search_keywords.dart

const snap = await admin.firestore().collection('videos').get();
const batch = admin.firestore().batch();
snap.docs.forEach((doc) => {
  const data = doc.data();
  const keywords = buildSearchKeywords(data.caption || '', data.hashtags || []);
  batch.update(doc.ref, { searchKeywords: keywords });
});
await batch.commit();
```

## Index composites Firestore requis

```
Collection: users
Fields indexed: username (Ascending)  — simple index, généralement automatique

Collection: businesses
Fields indexed: nameLower (Ascending)  — simple index, généralement automatique

Collection: videos
Fields indexed: searchKeywords (Arrays)  — simple index, généralement automatique
Collection: videos
Fields indexed: hashtags (Arrays)  — simple index, généralement automatique
```

Aucun index composite complexe requis ici : chaque requête ne combine
qu'un seul filtre/tri à la fois (on trie côté client par date pour la
recherche vidéo, voir `SearchService._sortByCreatedAtDesc`).

## Expérience utilisateur

- **Debounce de 350ms** sur la saisie — évite de lancer une requête
  Firestore à chaque caractère tapé pendant que l'utilisateur écrit
  encore.
- **Aucune requête tant que le champ est vide** — évite de charger toute
  une collection par erreur ; à la place, un message d'invitation neutre
  s'affiche.
- **États de chargement et "aucun résultat"** gérés indépendamment pour
  chacun des 3 onglets.
- **Focus automatique** à l'ouverture de l'écran — l'utilisateur arrive
  ici pour taper immédiatement.

## Intégration

1. Copie `lib/core/utils/search_keywords.dart` (si pas déjà présent — il a
   été anticipé dès la Brique 3), `lib/services/search_service.dart`, et
   tout `lib/features/search/`.
2. Applique les patches sur `business_model.dart`, `business_service.dart`,
   `discover_screen.dart`, `business_screen.dart`.
3. Aucune nouvelle dépendance `pubspec.yaml`.
4. Si tu as déjà des commerces publiés avant cette brique : republie-les
   une fois (ou lance un script de backfill similaire à celui des vidéos)
   pour qu'ils reçoivent le champ `nameLower`.
5. Teste les 3 onglets avec des requêtes courtes (2-3 lettres) pour
   valider le préfixe, et avec un `#hashtag` pour valider la recherche
   vidéo exacte.

## Prochaines briques possibles

1. Recherche avancée via Algolia/Typesense (tolérance aux fautes, pertinence)
2. Passerelle de paiement réelle pour MUHETO Gold
3. Traduire les écrans restants (reste de la Brique 9)
4. Analytics créateur (vues, engagement dans le temps)

Dis-moi laquelle tu veux ensuite.
