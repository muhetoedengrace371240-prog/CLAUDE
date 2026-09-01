# MUHETO — Brique 7 : Page Business Locale

## Fichiers livrés

```
lib/models/business_model.dart                     → Modèle commerce + calcul "ouvert maintenant"
lib/services/business_service.dart                  → Lecture/filtre/recherche/écriture Firestore

lib/features/business/business_screen.dart          → Liste filtrable par catégorie
lib/features/business/business_detail_screen.dart    → Fiche détaillée complète
lib/features/business/widgets/business_card.dart     → Carte de la liste
lib/features/business/widgets/chip_filter_row.dart    → Filtre catégories réutilisable
```

Petit ajustement corollaire :
- `discover_screen.dart` — la tuile de catégorie "Business" (déjà présente
  depuis la Brique 2) ouvre maintenant vraiment `BusinessScreen`.
- `pubspec.yaml` — ajout de `url_launcher` (appel téléphonique, WhatsApp,
  site web, réseaux sociaux).

## Structure Firestore

```
businesses/{businessId}
  - ownerId: string                          (uid du compte Business propriétaire)
  - name, category, description: string
  - logoUrl, bannerUrl: string                (Firebase Storage)
  - address, city: string
  - phoneNumber: string                       (format international, ex: "+25779123456")
  - whatsappNumber: string                    (optionnel)
  - websiteUrl, instagramUrl, facebookUrl: string (optionnels)
  - openingHours: map<jour, "08:00-18:00" | "Fermé">
  - isVerified: bool
  - isSponsored: bool                         (mis en avant en tête de liste)
  - createdAt: Timestamp
```

`category` doit être une des valeurs de `kBusinessCategories` (Restaurant,
Boutique, Beauté & Bien-être, Santé, Éducation, Technologie, Hôtellerie,
Artisanat, Services, Autre) pour que le filtre fonctionne correctement.

`openingHours` utilise les clés de `kWeekDaysFr` (Lundi → Dimanche). Exemple :
```json
{
  "Lundi": "08:00-18:00",
  "Mardi": "08:00-18:00",
  "Mercredi": "08:00-18:00",
  "Jeudi": "08:00-18:00",
  "Vendredi": "08:00-18:00",
  "Samedi": "09:00-14:00",
  "Dimanche": "Fermé"
}
```

## Fonctionnalités notables

- **Tri sponsorisé** : `watchBusinesses()` trie systématiquement
  `isSponsored desc` puis `createdAt desc` — les partenaires qui payent
  pour la mise en avant (offre "Publicité locale ciblée" de MUHETO
  Business) apparaissent toujours en premier, sans jamais mélanger les
  catégories.
- **Statut "Ouvert / Fermé" en direct** : `BusinessModel.isOpenNow` calcule
  côté client, à l'instant présent, si le commerce est ouvert en analysant
  `openingHours` du jour courant — visible à la fois sur la carte de liste
  et sur la fiche détaillée (avec le jour du jour mis en évidence en doré).
- **Actions directes** sur la fiche : Appeler (`tel:`), WhatsApp
  (`wa.me/...`), Site web, Instagram, Facebook — chacune n'apparaît que si
  le champ correspondant est renseigné.
- **Recherche par préfixe** (`searchBusinesses`) déjà prête côté service,
  pas encore branchée à une UI dédiée (bouton loupe en `TODO` dans
  `business_screen.dart`) — pour une recherche plein-texte plus robuste,
  envisager Algolia ou Typesense en complément de Firestore.

## Index composite Firestore requis

```
Collection: businesses
Fields indexed: isSponsored (Descending), createdAt (Descending)

Collection: businesses (variante filtrée par catégorie)
Fields indexed: category (Ascending), isSponsored (Descending), createdAt (Descending)
```

## Règles Firestore à ajouter

```
match /businesses/{businessId} {
  allow read: if true;
  allow create: if request.auth != null &&
    request.auth.uid == request.resource.data.ownerId;
  allow update, delete: if request.auth != null &&
    request.auth.uid == resource.data.ownerId;
}
```

> `isSponsored` et `isVerified` sont volontairement laissés modifiables par
> le propriétaire dans cette V1 pour rester simple. Si tu vends la mise en
> avant comme un vrai produit payant, migre ces deux champs vers une
> Cloud Function (validée après paiement) plutôt que de laisser le
> propriétaire se les attribuer lui-même.

## Jeu de données d'exemple (à coller dans Firestore Console pour tester)

```json
{
  "ownerId": "REMPLACE_PAR_UN_UID_REEL",
  "name": "Chez Kaze Restaurant",
  "category": "Restaurant",
  "description": "Cuisine burundaise traditionnelle et grillades, terrasse ombragée en plein cœur de Bujumbura.",
  "logoUrl": "",
  "bannerUrl": "",
  "address": "Avenue de la Plage, Rohero",
  "city": "Bujumbura",
  "phoneNumber": "+25779123456",
  "whatsappNumber": "+25779123456",
  "websiteUrl": "",
  "instagramUrl": "",
  "facebookUrl": "",
  "openingHours": {
    "Lundi": "08:00-22:00",
    "Mardi": "08:00-22:00",
    "Mercredi": "08:00-22:00",
    "Jeudi": "08:00-22:00",
    "Vendredi": "08:00-23:00",
    "Samedi": "10:00-23:00",
    "Dimanche": "Fermé"
  },
  "isVerified": true,
  "isSponsored": true,
  "createdAt": "(server timestamp)"
}
```

## Intégration

1. Copie `lib/models/business_model.dart`, `lib/services/business_service.dart`
   et tout `lib/features/business/`.
2. Applique le petit patch sur `discover_screen.dart` (tuile "Business").
3. Ajoute `url_launcher` à ton `pubspec.yaml`, puis `flutter pub get`.
4. **iOS** : ajoute dans `ios/Runner/Info.plist` les schémas nécessaires à
   `url_launcher` pour ouvrir des apps externes :
   ```xml
   <key>LSApplicationQueriesSchemes</key>
   <array>
     <string>tel</string>
     <string>https</string>
     <string>whatsapp</string>
   </array>
   ```
5. Crée les index composites ci-dessus et complète tes `firestore.rules`.
6. Ajoute quelques documents de test dans `businesses` (voir l'exemple
   ci-dessus) pour vérifier l'affichage avant de brancher un vrai
   formulaire de création.

## Limites volontaires de cette brique (V1)

- Le bouton "Ma page" (FAB doré) et l'icône recherche sont des `TODO` —
  la création/édition d'une fiche Business par son propriétaire est une
  brique à part entière (upload logo/bannière, choix des horaires,
  vérification du compte Business).
- Pas de tri par distance/géolocalisation pour l'instant — uniquement par
  catégorie et par mise en avant sponsorisée.
- Pas de système d'avis/notes clients dans cette version.

## Prochaines briques possibles

1. Créer/Éditer ma page Business (formulaire complet, upload logo/bannière)
2. MUHETO Gold (abonnement premium, paiement des mises en avant sponsorisées)
3. Localisation multilingue (rn / fr / en / sw)
4. Notifications push (Firebase Cloud Messaging)
5. Recherche plein-texte (Algolia / Typesense)

Dis-moi laquelle tu veux ensuite.
