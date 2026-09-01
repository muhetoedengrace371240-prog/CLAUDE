/// Mappe la langue active de l'app vers une locale supportée par le
/// package `timeago`, de façon volontairement prudente : le package ne
/// garantit pas nativement de messages pour le Kirundi ('rn') ni,
/// selon la version installée, pour le Swahili ('sw') — passer une
/// locale non enregistrée à `timeago.format()` provoque une erreur au
/// lieu d'un repli silencieux.
///
/// Stratégie :
/// - `fr` et `rn` (Kirundi) → 'fr' (déjà enregistré dans `main()` depuis la
///   Brique 6/11, et linguistiquement plus proche pour un lecteur
///   d'Afrique de l'Est que l'anglais par défaut).
/// - Tout le reste (`en`, `sw`) → `null`, ce qui fait retomber `timeago`
///   sur l'anglais intégré par défaut, sans nécessiter d'enregistrement
///   — le choix le plus sûr tant que la prise en charge native du
///   Swahili par la version de `timeago` utilisée n'a pas été vérifiée.
///
/// Si tu veux du Swahili natif dans les horodatages, vérifie d'abord dans
/// la version installée du package (`timeago.SwMessages` existe-t-il ?),
/// puis enregistre-la dans `main()` comme pour le français, et ajoute
/// `'sw' → 'sw'` ci-dessous.
String? timeagoLocaleFor(String appLanguageCode) {
  if (appLanguageCode == 'fr' || appLanguageCode == 'rn') return 'fr';
  return null;
}
