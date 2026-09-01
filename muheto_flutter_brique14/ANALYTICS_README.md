# MUHETO — Brique 13 : Statistiques & Analytics (Créateurs & Business)

## Fichiers livrés

```
lib/features/analytics/creator_analytics_screen.dart    → Dashboard Créateur
lib/features/analytics/business_analytics_screen.dart   → Dashboard Business
lib/features/analytics/widgets/stat_card.dart             → Carte de métrique réutilisable
lib/features/analytics/widgets/simple_bar_chart.dart       → Mini graphique en barres (fait main)
```

Modifications sur des fichiers existants :
- `lib/services/business_service.dart` — 4 nouvelles méthodes
  d'incrémentation atomique : `registerBusinessView`, `registerCallClick`,
  `registerWebsiteClick`, `registerWhatsappClick`.
- `lib/features/business/business_detail_screen.dart` — converti en
  `StatefulWidget` pour compter la vue de fiche une seule fois par
  ouverture d'écran ; les 3 boutons d'action tracent maintenant leur clic
  avant d'ouvrir le lien externe ; un bouton "Statistiques" (icône
  graphique) apparaît dans l'AppBar, uniquement pour le propriétaire.
- `lib/features/profile/profile_screen.dart` — bouton "Statistiques" ajouté
  à côté de "Modifier le profil", sur son propre profil uniquement.

`lib/models/business_model.dart` contenait déjà les champs `viewsCount`,
`callClicksCount`, `websiteClicksCount`, `whatsappClicksCount` (anticipés
en Brique 7/8) — cette brique les rend enfin réellement incrémentés et
visibles.

## ⚠️ Ce que ce dashboard montre vraiment (et ce qu'il ne montre PAS)

**Montré, avec des données 100% réelles :**
- Totaux cumulés (vues, likes, partages, commentaires) calculés en direct
  en sommant les compteurs déjà existants sur chaque vidéo du créateur.
- Abonnés / abonnements : lus directement depuis le document utilisateur
  (déjà tenus à jour depuis la Brique 4).
- Vues de fiche Business et clics par type de bouton : compteurs dédiés,
  incrémentés à chaque interaction réelle.
- Un graphique en barres des vues par vidéo (top 8) — classement réel,
  pas une moyenne inventée.

**PAS montré, et c'est volontaire plutôt qu'un oubli :**
- **Aucune courbe d'évolution dans le temps** ("+12% cette semaine",
  "vues des 7 derniers jours"...). Firestore, tel qu'utilisé jusqu'ici, ne
  conserve que des **compteurs cumulés instantanés** — pas d'historique
  jour par jour. Afficher un faux graphique d'évolution en inventant des
  points de données intermédiaires aurait été trompeur ; je préfère te
  montrer des totaux exacts plutôt que des tendances fabriquées.

## Comment ajouter un vrai suivi temporel plus tard (si tu en as besoin)

Deux approches standards, à faire dans une brique dédiée :

1. **Cloud Function planifiée (recommandée)** — une fonction
   `functions.pubsub.schedule('every 24 hours')` qui, chaque jour, lit les
   compteurs actuels de chaque créateur/commerce et écrit un instantané
   dans une nouvelle collection `analytics_snapshots/{uid}/{date}`. Le
   dashboard peut alors afficher une vraie courbe jour par jour en lisant
   cette collection, et calculer des vrais deltas ("+12% cette semaine").
2. **Incrément avec horodatage** — au lieu d'un seul compteur
   `viewsCount`, écrire un document par vue dans une sous-collection
   `views/{viewId}` avec un `createdAt`. Donne un historique complet et
   des requêtes flexibles (vues par jour/semaine/mois), mais coûte
   nettement plus de lectures/écritures Firestore à grande échelle — à
   réserver aux comptes à fort volume, ou agréger régulièrement vers des
   compteurs quotidiens.

## Taux de clic (Business)

`BusinessAnalyticsScreen` calcule un taux de clic simple :
`(clics totaux / vues de la fiche) × 100`. Affiche `—` tant qu'aucune vue
n'a encore été enregistrée (division par zéro évitée).

## Intégration

1. Copie `lib/features/analytics/` en entier.
2. Applique les patches sur `business_service.dart`, `business_detail_screen.dart`,
   `profile_screen.dart`.
3. Aucune nouvelle dépendance `pubspec.yaml` — le graphique en barres est
   fait main (`SimpleBarChart`), volontairement pour ne pas ajouter
   `fl_chart` ou équivalent pour un besoin aussi simple. Si tu veux des
   graphiques plus riches plus tard (courbes, camemberts, zoom...),
   `fl_chart` reste la référence Flutter pour ça.
4. Vérifie que les fiches Business déjà existantes en base s'affichent
   bien avec des compteurs à 0 (comportement attendu, géré par les valeurs
   par défaut de `BusinessModel.fromFirestore`).

## Limites volontaires de cette brique (V1)

- Pas de courbe d'évolution dans le temps (voir section dédiée ci-dessus).
- Pas d'export CSV/PDF des statistiques.
- Le taux de clic Business est une métrique globale depuis la création de
  la fiche, pas filtrable par période.
- Pas de comparaison avec d'autres créateurs/commerces (classements,
  percentiles) — uniquement les stats de son propre compte.

## Prochaines briques possibles

1. Suivi temporel réel (Cloud Function planifiée + collection de snapshots)
2. Recherche avancée via Algolia/Typesense
3. Passerelle de paiement réelle pour MUHETO Gold
4. Traduire les écrans restants (reste de la Brique 9)

Dis-moi laquelle tu veux ensuite.
