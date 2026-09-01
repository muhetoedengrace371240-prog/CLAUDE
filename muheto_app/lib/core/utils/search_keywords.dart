/// Firestore ne propose pas de recherche plein-texte native — seule la
/// correspondance par préfixe (`startAt`/`endAt`) ou par égalité exacte sur
/// un tableau (`array-contains-any`) est possible côté requête. Pour rendre
/// la recherche réellement utile sur du texte libre (légende de vidéo,
/// description de commerce...), on dénormalise à l'écriture un tableau de
/// mots-clés en minuscules, puis on interroge avec `array-contains-any` à
/// la lecture — c'est l'approche standard "poor man's full-text search" sur
/// Firestore, sans dépendre d'un service tiers (Algolia/Typesense).
///
/// Exemple :
/// ```dart
/// buildSearchKeywords("Danse traditionnelle burundaise", extra: ["#Culture", "#Muheto"])
/// // → ['danse', 'traditionnelle', 'burundaise', 'culture', 'muheto']
/// ```
List<String> buildSearchKeywords(String text, {List<String> extra = const []}) {
  final combinedText = [text, ...extra].join(' ').toLowerCase();
  final rawWords = combinedText.split(RegExp(r'[^a-z0-9à-ÿ]+'));

  final keywords = <String>{};
  for (final word in rawWords) {
    final cleaned = word.replaceAll('#', '').trim();
    if (cleaned.length >= 2) keywords.add(cleaned);
  }
  return keywords.toList();
}

/// Découpe une requête utilisateur en mots-clés normalisés pour interroger
/// avec `array-contains-any` (limité à 10 valeurs maximum par Firestore).
List<String> parseSearchQuery(String query) {
  final keywords = buildSearchKeywords(query);
  return keywords.take(10).toList();
}
