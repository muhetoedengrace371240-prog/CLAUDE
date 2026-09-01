# MUHETO — Brique 2 : Navigation globale & Navbar

## Fichiers livrés

```
lib/features/navigation/
  main_navigation_shell.dart        → Coquille principale (IndexedStack + navbar)
  widgets/muheto_bottom_navbar.dart → Navbar noir/or, bouton "+" central surélevé

lib/features/discover/discover_screen.dart   → Recherche + grille de catégories
lib/features/inbox/inbox_screen.dart         → Boîte de réception (Activité / Messages)
lib/features/profile/profile_screen.dart     → Profil + grille vidéos 3 colonnes
lib/features/create/create_screen.dart       → Écran plein écran ouvert par le "+"

lib/main_example.dart             → Exemple de branchement complet
```

## Comment ça marche

- **`MainNavigationShell`** est le nouvel écran racine post-connexion. Il gère
  4 "vrais" onglets via `IndexedStack` : **Accueil** (`FeedScreen` de la
  Brique 1), **Découvrir**, **Boîte**, **Profil**. `IndexedStack` garde tous
  les écrans montés en mémoire → en changeant d'onglet, le feed ne recharge
  pas ses vidéos et ne perd pas la position de scroll.
- Le bouton **"+"** n'est **pas** un onglet : il fait un
  `Navigator.push(fullscreenDialog: true)` vers `CreateScreen`, exactement
  comme sur TikTok (écran caméra/galerie par-dessus tout, avec un bouton
  fermer en haut à gauche).
- **`MuhetoBottomNavbar`** est un widget autonome et réutilisable : fond noir
  (`AppColors.black`), icônes dorées (`AppColors.gold`) quand actives, gris
  (`AppColors.textMuted`) sinon, avec transition animée. Le bouton central
  est un rectangle arrondi doré avec ombre portée, sans label — fidèle à la
  maquette.

## Intégration dans ton projet

1. Copie `lib/features/navigation`, `lib/features/discover`,
   `lib/features/inbox`, `lib/features/profile`, `lib/features/create`
   dans ton projet (à côté de `lib/features/feed` déjà en place).
2. Dans ton `main.dart` existant (celui qui appelle déjà
   `Firebase.initializeApp()`), remplace l'écran affiché après connexion par :
   ```dart
   home: const MainNavigationShell(),
   // ou, si tu utilises déjà go_router / Navigator 2.0 :
   // MaterialPageRoute(builder: (_) => const MainNavigationShell())
   ```
3. Si tu veux transmettre l'univers choisi à l'onboarding (Burundi / Afrique /
   Monde) :
   ```dart
   MainNavigationShell(feedScope: ContentScope.burundi)
   ```
4. Aucune nouvelle dépendance Firebase n'est nécessaire pour cette brique.
   Pour la brique Création (caméra + upload), on ajoutera `camera`,
   `image_picker` et `firebase_storage` (déjà présent dans ton pubspec).

## Ce qui est volontairement en placeholder (prochaines briques)

- `DiscoverScreen` : le tap sur une catégorie ne filtre pas encore Firestore.
- `InboxScreen` : liste de conversations vide (branchement Firestore à venir).
- `ProfileScreen` : données statiques ("@utilisateur", "128 abonnements"...) —
  à remplacer par un `StreamBuilder` sur `users/{uid}` et `videos` filtrées
  par `userId`.
- `CreateScreen` : les boutons Caméra/Galerie ont des `TODO` — capture réelle
  et upload à coder dans la brique "Création & Publication".

## Prochaines briques possibles

1. Splash / Login / Inscription (Firebase Auth)
2. Création & Publication (caméra, trim vidéo, upload Storage)
3. Profil dynamique (branché Firestore) + édition de profil
4. Page Business Locale
5. Messagerie temps réel (chat)
6. Localisation multilingue (rn / fr / en / sw)

Dis-moi laquelle tu veux ensuite.
