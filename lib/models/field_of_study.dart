/// Domaine d'études ou de métier. Les noms sont les valeurs enregistrées
/// dans Firestore : ne jamais les renommer. Pour afficher, passer par
/// `fieldOfStudyKey` (traduction).
enum FieldOfStudy {
  health,
  engineering,
  informatics,
  education,
  businessManagement,
  agriculture,
  law,
  communication,
  arts,
  services,
  other,
}

/// Lit une valeur enregistrée. Retourne `null` si absente ou inconnue.
FieldOfStudy? fieldOfStudyFromString(String? value) {
  if (value == null) return null;
  for (final field in FieldOfStudy.values) {
    if (field.name == value) return field;
  }
  return null;
}

/// Clé de traduction à utiliser pour AFFICHER le domaine.
String fieldOfStudyKey(FieldOfStudy field) => 'field.${field.name}';
