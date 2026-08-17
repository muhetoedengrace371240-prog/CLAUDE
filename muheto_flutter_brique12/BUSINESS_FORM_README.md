# MUHETO — Brique 8 : Création & Édition de la Page Business

## Fichiers livrés

```
lib/features/business/business_form_screen.dart            → Formulaire création/édition
lib/features/business/widgets/business_category_picker.dart → Sélecteur catégorie (single, obligatoire)
lib/features/business/widgets/opening_hours_editor.dart     → Édition des 7 jours + bascule "Fermé"
```

Modifications sur des fichiers existants :
- `lib/services/business_service.dart` — nouvelles méthodes `getMyBusiness()`,
  `newBusinessId()`, `createBusinessWithId()`, `isOwner()`.
- `lib/features/business/business_screen.dart` — le FAB "Ma page" est
  maintenant branché : il détecte si l'utilisateur a déjà une fiche
  (`getMyBusiness`) et ouvre le formulaire en mode création ou édition en
  conséquence.
- `lib/features/business/business_detail_screen.dart` — un bouton crayon
  apparaît dans l'AppBar **uniquement** si `business.ownerId` correspond à
  l'utilisateur connecté, et ouvre le formulaire pré-rempli.

## Flux complet

```
BusinessScreen (FAB "Ma page")
   │
   ├─ getMyBusiness(uid) trouve une fiche existante
   │      └──► BusinessFormScreen(existingBusiness: ...) — mode ÉDITION
   │
   └─ aucune fiche trouvée
          └──► BusinessFormScreen(existingBusiness: null) — mode CRÉATION

BusinessFormScreen
   ├─ 1. Génère (ou réutilise) l'id du document AVANT l'upload
   │      (même pattern que UploadService de la Brique 3)
   ├─ 2. Upload logo  → business_logos/{businessId}.jpg   (si modifié)
   ├─ 3. Upload bannière → business_banners/{businessId}.jpg (si modifiée)
   └─ 4. set()/update() du document businesses/{businessId}
```

## Gestion des permissions (3 niveaux de protection)

1. **Côté UI** : le bouton "Modifier" (crayon) sur `BusinessDetailScreen`
   n'est affiché QUE si `business.ownerId == FirebaseAuth.instance.currentUser?.uid`.
   Un visiteur normal ne voit jamais ce bouton.
2. **Côté service** : `BusinessService.isOwner()` est disponible pour toute
   vérification programmatique supplémentaire avant une action sensible.
3. **Côté Firestore (rempart final, non contournable)** — règles déjà
   posées en Brique 7, reproduites ici pour mémoire :
   ```
   match /businesses/{businessId} {
     allow read: if true;
     allow create: if request.auth != null &&
       request.auth.uid == request.resource.data.ownerId;
     allow update, delete: if request.auth != null &&
       request.auth.uid == resource.data.ownerId;
   }
   ```
   Même si quelqu'un contournait l'app (requête Firestore manuelle), il lui
   serait impossible de créer une fiche avec un `ownerId` différent du sien,
   ni de modifier la fiche de quelqu'un d'autre — Firestore refuse la
   requête au niveau serveur.

## Une seule fiche par utilisateur (V1)

`getMyBusiness(uid)` interroge `businesses where ownerId == uid limit 1`.
S'il existe déjà une fiche, le FAB ouvre toujours cette fiche en édition —
impossible de créer une deuxième page par erreur. Si tu veux autoriser
plusieurs fiches par utilisateur plus tard (ex: chaîne de magasins), il
suffira de transformer le FAB en une liste "Mes pages" + bouton "+".

## Règles Firebase Storage à ajouter (complète celles des Briques 3 et 5)

```
match /business_logos/{businessId}.jpg {
  allow read: if true;
  allow write: if request.auth != null &&
    request.auth.uid == firestore.get(/databases/(default)/documents/businesses/$(businessId)).data.ownerId
    && request.resource.size < 5 * 1024 * 1024
    && request.resource.contentType.matches('image/.*');
}

match /business_banners/{businessId}.jpg {
  allow read: if true;
  allow write: if request.auth != null &&
    request.auth.uid == firestore.get(/databases/(default)/documents/businesses/$(businessId)).data.ownerId
    && request.resource.size < 8 * 1024 * 1024
    && request.resource.contentType.matches('image/.*');
}
```

> ⚠️ Ces règles font une lecture croisée Firestore depuis Storage
> (`firestore.get(...)`), ce qui nécessite que le document `businesses/{id}`
> existe déjà **avant** l'upload de l'image. C'est exactement ce que fait
> `BusinessFormScreen` : à la création, le document est écrit avec
> `createBusinessWithId()` en même temps que les URLs d'image — si tu
> observes un rejet de règle en pratique lors d'une toute première
> création, une alternative plus simple et 100% fiable est de restreindre
> l'écriture par utilisateur connecté plutôt que par lecture croisée :
> ```
> match /business_logos/{businessId}.jpg {
>   allow write: if request.auth != null;
> }
> ```
> Le vrai verrou de sécurité reste de toute façon la règle Firestore sur le
> document lui-même — Storage sert surtout à valider taille/type ici.

## Intégration

1. Copie les 3 nouveaux fichiers de `lib/features/business/`.
2. Remplace `lib/services/business_service.dart`,
   `lib/features/business/business_screen.dart` et
   `lib/features/business/business_detail_screen.dart` par les versions
   mises à jour.
3. Aucune nouvelle dépendance `pubspec.yaml` (tout repose sur
   `image_picker`, `firebase_storage`, déjà présents depuis les briques
   précédentes).
4. Ajoute les règles Storage ci-dessus (ou la variante simplifiée) dans
   `storage.rules`.
5. Teste le flux complet : FAB → formulaire vide → upload logo/bannière →
   Publier → redirection vers la fiche fraîchement créée.

## Limites volontaires de cette brique (V1)

- `isVerified` et `isSponsored` restent hors du formulaire (valeurs
  préservées telles quelles en édition, `false` par défaut en création) —
  ces deux statuts doivent rester un privilège modéré par MUHETO, pas
  auto-attribuable, comme déjà noté dans `BUSINESS_README.md`.
- Pas de suppression de fiche depuis l'UI pour l'instant (possible
  directement dans Firestore Console en attendant).
- Le champ horaires reste un texte libre validé côté `BusinessModel.isOpenNow`
  au format strict `HH:mm-HH:mm` — un horaire mal saisi ne casse rien mais
  n'affichera simplement pas de badge Ouvert/Fermé (retour `null`).

## Prochaines briques possibles

1. MUHETO Gold (abonnement premium, paiement des mises en avant sponsorisées)
2. Localisation multilingue (rn / fr / en / sw)
3. Notifications push (Firebase Cloud Messaging)
4. Recherche plein-texte (Algolia / Typesense)
5. Statistiques Business (vues de la fiche, clics "Appeler"...)

Dis-moi laquelle tu veux ensuite.
