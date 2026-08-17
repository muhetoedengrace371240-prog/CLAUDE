# MUHETO — Brique 10 : MUHETO Gold (Abonnement Premium)

## Fichiers livrés

```
lib/services/gold_service.dart                    → Statut Gold, essai gratuit, résiliation
lib/features/gold/gold_screen.dart                  → Écran d'offre ultra-premium Noir & Or
lib/features/gold/widgets/gold_badge.dart            → Badge VIP doré réutilisable
```

Modifications sur des fichiers existants :
- `lib/models/user_model.dart` — `goldExpirationDate` (Timestamp?) et le
  getter `isGoldActive` (statut réellement effectif à l'instant présent).
- `lib/models/chat_model.dart` — `otherIsGoldMember` (dénormalisé).
- `lib/models/comment_model.dart` — `isGoldMember` (dénormalisé).
- `lib/services/chat_service.dart` — dénormalise `isGoldMember` dans
  `participantsInfo` à la création d'une conversation.
- `lib/services/profile_service.dart` — nouvelle méthode `getUserOnce()`
  (lecture ponctuelle, utile pour dénormaliser au moment d'une action).
- `lib/features/profile/profile_screen.dart` — badge Gold via
  `isGoldActive` (plus fiable que l'ancien `isGoldMember` brut) + nouvelle
  carte d'accès à MUHETO Gold (upsell si non-membre, statut si actif).
- `lib/features/chat/chat_screen.dart` — badge Gold **live** dans l'en-tête
  (requête directe sur le profil de l'interlocuteur).
- `lib/features/inbox/widgets/chat_list_tile.dart` — badge Gold
  (dénormalisé) à côté du pseudo dans la liste des conversations.
- `lib/features/feed/feed_screen.dart` — badge Gold à côté du pseudo de
  chaque commentaire, **et ajout d'un vrai champ de saisie** pour publier
  un commentaire (il manquait à l'écran des commentaires depuis la
  Brique 1 — c'est maintenant corrigé, sinon le badge n'aurait jamais pu
  être testé de bout en bout).
- `lib/features/create/create_screen.dart` — vérifie le statut Gold avant
  d'ouvrir la caméra et adapte la durée max en conséquence.
- `lib/features/create/camera_capture_screen.dart` — la durée max
  d'enregistrement est maintenant un paramètre du widget
  (`kDefaultMaxRecordingSeconds` = 60s, `kGoldMaxRecordingSeconds` = 600s)
  au lieu d'une constante figée à 60s.
- `lib/main_example.dart` — `initializeDateFormatting('fr_FR')` ajouté
  (requis par `GoldScreen`, qui formate la date d'expiration avec
  `DateFormat('d MMMM yyyy', 'fr_FR')` — sans cette init, l'app plante au
  premier affichage d'un statut Gold actif).

## Statut Gold : `isGoldMember` vs `isGoldActive`

```dart
bool get isGoldActive {
  if (!isGoldMember) return false;
  if (goldExpirationDate == null) return true; // accès accordé manuellement, sans limite
  return goldExpirationDate!.isAfter(DateTime.now());
}
```

**Règle d'or (sans mauvais jeu de mots) : partout dans l'UI, utilise
toujours `isGoldActive`, jamais `isGoldMember` seul.** `isGoldMember` peut
rester à `true` en base après l'expiration réelle tant qu'aucun job ne l'a
remis à `false` — `isGoldActive` recalcule la vérité à chaque lecture, côté
client, sans dépendre d'un job serveur pour être correct dans l'UI.

## ⚠️ Portée réelle de cette brique — paiement NON intégré

**C'est le point le plus important de cette brique.** `GoldService`
implémente le **statut** Gold (structure de données, expiration, affichage)
mais **aucune passerelle de paiement réelle** (Mobile Money — Lumicash,
EcoCash —, carte bancaire, Stripe...) n'est branchée. `startFreeTrial()` et
`activateSubscription()` écrivent directement `isGoldMember`/
`goldExpirationDate` dans Firestore depuis le client.

**C'est volontaire et correct pour développer/démontrer l'expérience**,
mais ce serait une faille de sécurité béante en production : n'importe qui
pourrait ouvrir les DevTools ou intercepter l'appel réseau et s'attribuer
le statut Gold sans jamais payer. Avant toute mise en production réelle :

1. Intègre un vrai fournisseur de paiement (Mobile Money local recommandé
   pour le Burundi, ou Stripe pour les cartes internationales).
2. Fais confirmer le paiement côté serveur (webhook du fournisseur reçu
   par une Cloud Function).
3. C'est **cette Cloud Function**, authentifiée en tant qu'administrateur,
   qui doit écrire `isGoldMember: true` et `goldExpirationDate` — jamais le
   client directement.
4. Mets à jour les règles Firestore pour **interdire** à un utilisateur de
   modifier ces deux champs sur son propre document (voir plus bas).

## Règles Firestore à ajouter (durcit celles des Briques 1 et 5)

```
match /users/{uid} {
  allow update: if request.auth != null && request.auth.uid == uid &&
    !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny(['followersCount', 'followingCount', 'isGoldMember', 'goldExpirationDate']);
}
```

> En V1 (démo/développement), tu peux laisser `GoldService` écrire ces
> champs directement comme actuellement — mais dès que tu branches un vrai
> paiement, ajoute cette restriction et fais passer l'écriture par une
> Cloud Function avec des droits admin (`admin.firestore()`, qui contourne
> les règles de sécurité classiques).

## Avantages Gold déjà affichés (écran d'offre)

Badge premium doré, meilleure visibilité dans le Feed, mise en avant de la
page Business, vidéos plus longues (10 min), aucune publicité, analytics
avancées, téléchargement HD, support prioritaire.

**Actuellement câblé et fonctionnel :** badge doré (Profil/Chat/
Commentaires), vidéos 10 minutes pour les membres Gold actifs.
**Pas encore câblé** (juste affiché comme argument marketing) : meilleure
visibilité algorithmique dans le feed, mise en avant Business automatique
(à l'heure actuelle `isSponsored` reste un champ manuel sur `businesses`,
voir Brique 8), analytics avancées, téléchargement HD, absence de pub
(aucune pub n'existe encore dans l'app de toute façon), support prioritaire.
Ce sont des briques futures à part entière.

## Intégration

1. Copie `lib/services/gold_service.dart` et tout `lib/features/gold/`.
2. Applique les patches sur les 9 fichiers listés en haut de ce document.
3. Aucune nouvelle dépendance `pubspec.yaml` (tout repose sur
   `cloud_firestore`, `firebase_auth`, `intl`, déjà présents).
4. Ajoute `await initializeDateFormatting('fr_FR');` dans ton `main()`
   AVANT `runApp()` (import `package:intl/date_symbol_data_local.dart`).
5. Teste le flux : Profil → carte "Passe à MUHETO Gold ✨" → écran d'offre
   → "Essayer 7 jours gratuits" → retour au Profil, badge doré visible
   instantanément partout (Profil, Chat, commentaires).
6. Avant toute mise en ligne réelle : lis attentivement la section
   paiement ci-dessus et ne saute pas l'étape Cloud Function.

## Limites volontaires de cette brique (V1)

- Paiement non intégré (voir avertissement ci-dessus — c'est LA limite
  structurante de cette brique, pas un détail).
- Pas de renouvellement automatique (pas de job récurrent, cohérent avec
  l'absence de vraie facturation pour l'instant).
- Pas de notification push à l'approche de l'expiration (brique
  "Notifications push" à faire séparément).
- La mise en avant "Business" liée au statut Gold du propriétaire n'est
  pas automatique — `isSponsored` reste géré manuellement (Brique 8).

## Prochaines briques possibles

1. Passerelle de paiement réelle (Mobile Money / Stripe) + Cloud Function
2. Notifications push (Firebase Cloud Messaging)
3. Traduire les écrans restants (Feed, Chat, Business) — reste de la Brique 9
4. Recherche plein-texte (Algolia / Typesense)
5. Analytics créateur (vues, engagement dans le temps)

Dis-moi laquelle tu veux ensuite.
