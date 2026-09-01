# MUHETO — Brique 5 : Authentification & Édition de profil

## Fichiers livrés

```
lib/services/auth_service.dart                  → Firebase Auth + création du doc users/{uid}

lib/features/auth/splash_screen.dart             → Logo doré animé + redirection auto
lib/features/auth/welcome_screen.dart            → "Se connecter" / "S'inscrire"
lib/features/auth/login_screen.dart              → Connexion + mot de passe oublié
lib/features/auth/register_screen.dart           → Inscription + création profil Firestore

lib/features/profile/edit_profile_screen.dart    → Avatar, pseudo, bio → Storage + Firestore
```

Modifications sur des fichiers existants :
- `lib/services/profile_service.dart` — `updateProfile()` accepte maintenant
  `username`, + nouvelle méthode `isUsernameTaken()`.
- `lib/features/profile/profile_screen.dart` — le bouton "Modifier le
  profil" ouvre vraiment `EditProfileScreen` ; le menu ⋮ propose
  "Se déconnecter" (ramène vers `WelcomeScreen`).
- `lib/main_example.dart` — démarre maintenant sur `SplashScreen` au lieu
  d'aller directement à `MainNavigationShell`.

## Flux complet

```
SplashScreen (logo animé, ~2s)
   │
   ├─ utilisateur déjà connecté ─────────────► MainNavigationShell
   │
   └─ non connecté ──► WelcomeScreen
                           ├─ "Se connecter" ──► LoginScreen ──► MainNavigationShell
                           └─ "S'inscrire"   ──► RegisterScreen ──► MainNavigationShell
                                                      │
                                                      └─ crée users/{uid} dans Firestore

ProfileScreen (bouton "Modifier le profil")
   └──► EditProfileScreen ──► Storage (avatars/{uid}.jpg) + Firestore (users/{uid})
```

## `AuthService` en détail

- `signIn()` — connexion email/mot de passe classique.
- `signUp()` — **vérifie d'abord que le pseudonyme n'est pas pris**, crée le
  compte Firebase Auth, met à jour `displayName`, puis crée le document
  `users/{uid}` en réutilisant `UserModel.toFirestore()` (mêmes valeurs par
  défaut que dans les briques précédentes : `followersCount: 0`, `country:
  'BI'`, `language: 'fr'`, etc.).
- `sendPasswordResetEmail()` — branché sur le lien "Mot de passe oublié ?"
  du `LoginScreen`.
- `friendlyErrorMessage()` — traduit les codes d'erreur Firebase
  (`user-not-found`, `wrong-password`, `email-already-in-use`,
  `weak-password`...) en messages compréhensibles, affichés directement
  sous les formulaires.

## Édition de profil

- Le champ pseudonyme est revalidé côté client (regex, 3 caractères min.)
  ET côté Firestore (`isUsernameTaken`, en excluant l'utilisateur courant
  de la recherche) avant tout enregistrement.
- Si une nouvelle photo est choisie (`image_picker`, source galerie), elle
  est uploadée vers `avatars/{uid}.jpg` puis l'URL est écrite dans
  `avatarUrl` — sinon ce champ n'est pas modifié.
- Un seul appel `ProfileService.updateProfile()` regroupe pseudo, bio et
  avatar en une seule écriture Firestore.

## ⚠️ Rappel important

`RegisterScreen` ne stocke le mot de passe nulle part côté app ou Firestore
— Firebase Auth s'en charge nativement (hashing, stockage sécurisé côté
serveur). Aucune action requise de ta part sur ce point.

## Règles Firestore à ajouter (complète Briques 1, 3 et 4)

```
match /users/{uid} {
  allow read: if true;
  // Un utilisateur ne peut créer QUE son propre document, au moment de l'inscription.
  allow create: if request.auth != null && request.auth.uid == uid;
  allow update: if request.auth != null && request.auth.uid == uid &&
    !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny(['followersCount', 'followingCount']);
}
```

## Règles Firebase Storage à ajouter (complète celles de la Brique 3)

```
match /avatars/{uid}.jpg {
  allow read: if true;
  allow write: if request.auth != null && request.auth.uid == uid
               && request.resource.size < 5 * 1024 * 1024 // 5 Mo max
               && request.resource.contentType.matches('image/.*');
}
```

## Intégration

1. Copie `lib/services/auth_service.dart` et tout `lib/features/auth/`.
2. Remplace `lib/features/profile/profile_screen.dart` et
   `lib/services/profile_service.dart` par les versions mises à jour (ou
   applique le même diff si tu as déjà personnalisé les tiens).
3. Ajoute `lib/features/profile/edit_profile_screen.dart`.
4. Dans ton `main.dart` réel, démarre sur `SplashScreen` au lieu de
   `MainNavigationShell` directement — regarde `lib/main_example.dart`.
5. Aucune nouvelle dépendance `pubspec.yaml` (tout repose sur
   `firebase_auth`, `cloud_firestore`, `firebase_storage`, `image_picker`,
   déjà présents depuis les briques précédentes).
6. Complète tes `firestore.rules` et `storage.rules` avec les blocs
   ci-dessus.
7. Active la méthode **Email/Mot de passe** dans Firebase Console →
   Authentication → Sign-in method, si ce n'est pas déjà fait.

## Limites volontaires de cette brique (V1)

- Pas de connexion via Google/Facebook/Apple pour l'instant — uniquement
  email/mot de passe. Facile à ajouter plus tard (`AuthService` est déjà
  structuré pour ça).
- Pas de vérification d'email obligatoire avant d'utiliser l'app.
- Le Splash a une durée fixe de 2 secondes ; si tu ajoutes un vrai logo
  animé (Lottie, etc.), ajuste ou supprime ce délai.

## Prochaines briques possibles

1. Page Business Locale
2. Messagerie temps réel
3. MUHETO Gold (abonnement premium, paiement)
4. Localisation multilingue (rn / fr / en / sw)
5. Connexion Google / réseaux sociaux

Dis-moi laquelle tu veux ensuite.
