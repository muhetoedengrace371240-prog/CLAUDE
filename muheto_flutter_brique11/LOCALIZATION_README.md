# MUHETO — Brique 9 : Localisation multilingue (Kirundi / Français / English / Kiswahili)

## Fichiers livrés

```
assets/lang/fr.json                                   → Français (langue de référence)
assets/lang/en.json                                    → English
assets/lang/sw.json                                    → Kiswahili
assets/lang/rn.json                                     → Kirundi

lib/core/localization/app_localizations.dart            → Chargement + accès aux traductions
lib/core/localization/locale_provider.dart               → ChangeNotifier, langue active + persistance

lib/features/settings/settings_screen.dart               → Écran Paramètres (langue, déconnexion)
lib/features/settings/language_selector_sheet.dart        → Bottom sheet Noir & Or de choix de langue
```

Modifications sur des fichiers existants :
- `pubspec.yaml` — ajout de `flutter_localizations` (déjà présent en fait,
  vérifié), `shared_preferences`, et activation du dossier `assets/lang/`.
- `lib/main_example.dart` — `ChangeNotifierProvider<LocaleProvider>` posé
  au-dessus de `MaterialApp`, `localizationsDelegates` et
  `supportedLocales` configurés.
- `lib/features/profile/profile_screen.dart` — le menu ⋮ ouvre maintenant
  `SettingsScreen` (langue + déconnexion) au lieu d'un simple popup
  "Se déconnecter".
- `lib/features/navigation/widgets/muheto_bottom_navbar.dart` — les 4
  labels (Accueil/Découvrir/Boîte/Profil) utilisent désormais
  `AppLocalizations`.
- `lib/features/auth/welcome_screen.dart` — boutons traduits + une icône
  🌐 en haut à droite permet de choisir la langue **avant même de se
  connecter** (le sélecteur complet reste aussi dans Profil → Paramètres).

## Comment ça marche

```
main() 
  └─ ChangeNotifierProvider(create: (_) => LocaleProvider()..init())
        └─ MuhetoApp
              └─ MaterialApp(
                    locale: localeProvider.locale,
                    localizationsDelegates: [AppLocalizationsDelegate(), ...delegates Flutter standards],
                    supportedLocales: kSupportedLocales, // rn, fr, en, sw
                  )
```

- `AppLocalizations.load(locale)` lit `assets/lang/{code}.json` au moment
  du changement de langue (via le mécanisme standard des
  `LocalizationsDelegate` de Flutter — aucune dépendance externe comme
  `easy_localization` n'était nécessaire, tout repose sur `flutter_localizations`
  + `provider`, déjà présents dans le projet).
- Dans n'importe quel widget :
  ```dart
  final loc = AppLocalizations.of(context);
  Text(loc.t('nav.home')); // "Accueil" / "Home" / "Nyumbani" / "Ahabanza"
  ```
- `loc.t('cle.inexistante')` retourne la clé elle-même plutôt que de
  crasher — pratique pour repérer un oubli de traduction en debug.
- `LocaleProvider.setLocale()` change la langue **instantanément dans
  toute l'app** (grâce à `Provider`/`notifyListeners()`) et persiste le
  choix via `SharedPreferences` — au prochain lancement, la langue
  choisie est restaurée automatiquement (ou celle du système si elle est
  supportée et qu'aucun choix n'a encore été fait, sinon le français par
  défaut).

## Format des clés de traduction

Clés à points, groupées par domaine — 76 clés au total dans chaque fichier :
`common.*` (boutons génériques), `nav.*` (navigation), `auth.*` (connexion/
inscription), `feed.*` (onglets du feed), `profile.*`, `chat.*` (messagerie),
`business.*` (page Business Locale), `settings.*`, et `lang.*` (noms des
langues elles-mêmes, utilisés dans le sélecteur).

Exemple :
```json
{
  "nav.home": "Accueil",
  "business.openNow": "Ouvert maintenant",
  "lang.rn": "Kirundi"
}
```

## ⚠️ Important — étendue réelle de cette brique

Pour rester réaliste sur ce qui a été fait : **l'infrastructure complète
est en place et fonctionnelle** (provider, chargement JSON, persistance,
sélecteur, 76 clés traduites dans les 4 langues), et elle est **branchée et
vérifiée sur la Navbar, l'écran Welcome, et les Paramètres**. En revanche,
les ~40 autres écrans de l'app (Feed, Chat, Business, formulaires...)
contiennent encore du texte français en dur — les traduire est un travail
**mécanique** avec le pattern déjà en place, mais représente un volume trop
important pour être fait exhaustivement en une seule brique. La marche à
suivre pour chaque écran restant :
1. `final loc = AppLocalizations.of(context);` en haut du `build()`.
2. Remplacer chaque `Text('Texte en dur')` par `Text(loc.t('cle.correspondante'))`.
3. Si la clé n'existe pas encore, l'ajouter aux 4 fichiers JSON (même clé,
   traduction adaptée dans chaque langue).

Les clés `business.*` et `chat.*` sont déjà prêtes dans les 4 fichiers pour
couvrir cette suite dès que tu veux l'entreprendre — dis-le-moi et on
enchaîne dessus comme prochaine brique dédiée si tu préfères que je le
fasse plutôt que de le laisser en tâche mécanique de ton côté.

## Qualité des traductions

- **Français / English** : relues, fiables.
- **Kiswahili** : traduction de bonne qualité mais pas relue par un
  locuteur natif professionnel — recommandé avant une mise en production
  à grande échelle visant la Tanzanie/le Kenya.
- **Kirundi** : traduction de meilleur effort. Le Kirundi est une langue
  bantoue peu représentée dans les données d'entraînement des modèles de
  langue ; **une relecture par un locuteur natif burundais est fortement
  recommandée avant publication**, en particulier pour les termes
  techniques (ex: "Business Local", "Publier ma page") qui n'ont pas
  toujours d'équivalent consacré.

## Intégration

1. Copie `assets/lang/` (les 4 fichiers JSON) à la racine de ton projet.
2. Copie `lib/core/localization/` et `lib/features/settings/`.
3. Applique les patches sur `pubspec.yaml`, `main.dart` (voir
   `main_example.dart`), `profile_screen.dart`, `muheto_bottom_navbar.dart`,
   `welcome_screen.dart`.
4. Ajoute `shared_preferences` (déjà dans le `pubspec.yaml` fourni), puis
   `flutter pub get`.
5. Vérifie que `assets: - assets/lang/` est bien déclaré sous `flutter:`
   dans ton `pubspec.yaml` (sinon les fichiers JSON ne seront pas
   embarqués dans le build).
6. Lance l'app, ouvre Profil → Paramètres → Langue, et vérifie que la
   Navbar change de langue instantanément.

## Prochaines briques possibles

1. Traduire les écrans restants (Feed, Chat, Business, formulaires) —
   volume important, mécanique avec le pattern déjà posé.
2. MUHETO Gold (abonnement premium)
3. Notifications push (Firebase Cloud Messaging)
4. Recherche plein-texte (Algolia / Typesense)

Dis-moi laquelle tu veux ensuite.
