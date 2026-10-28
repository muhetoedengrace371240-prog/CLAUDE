/// Niveau de diplôme, du plus bas au plus élevé, puis `other`.
///
/// ⚠️ L'ORDRE DES VALEURS COMPTE pour les 6 premiers niveaux : il sert à
/// comparer deux niveaux (`level.index`). `other` doit rester EN DERNIER et
/// n'est jamais comparé (voir [isComparable]) : il signifie "autre diplôme,
/// à préciser en texte libre". Ne jamais réordonner ni insérer au milieu
/// sans vérifier tout ce qui compare des niveaux. Les noms (`bachelor`...)
/// sont les valeurs enregistrées dans Firestore : ne jamais les renommer.
enum DiplomaLevel {
  primary,
  secondary,
  vocational,
  bachelor,
  master,
  doctorate,
  other
}

extension DiplomaLevelCompare on DiplomaLevel {
  /// Faux pour `other` : on ne sait pas où le placer dans l'échelle.
  bool get isComparable => this != DiplomaLevel.other;
}

/// Lit une valeur enregistrée. Retourne `null` si absente ou inconnue.
DiplomaLevel? diplomaLevelFromString(String? value) {
  if (value == null) return null;
  for (final level in DiplomaLevel.values) {
    if (level.name == value) return level;
  }
  return null;
}

/// Clé de traduction à utiliser pour AFFICHER le niveau.
String diplomaLevelKey(DiplomaLevel level) => 'diploma.${level.name}';
