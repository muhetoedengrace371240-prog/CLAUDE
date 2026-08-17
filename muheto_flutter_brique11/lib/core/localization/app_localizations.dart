import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Langues supportées par MUHETO, dans l'ordre d'affichage du sélecteur.
const List<Locale> kSupportedLocales = [
  Locale('rn'), // Kirundi
  Locale('fr'), // Français
  Locale('en'), // English
  Locale('sw'), // Kiswahili
];

/// Charge et expose les traductions du fichier `assets/lang/{code}.json`
/// correspondant à la langue active. Clés à points, ex: `common.save`,
/// `nav.home`, `business.openNow`.
///
/// Usage dans un widget :
/// ```dart
/// final loc = AppLocalizations.of(context);
/// Text(loc.t('nav.home'));
/// ```
class AppLocalizations {
  AppLocalizations(this.locale, this._strings);

  final Locale locale;
  final Map<String, String> _strings;

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'AppLocalizations non trouvé — vérifie localizationsDelegates.');
    return localizations!;
  }

  static Future<AppLocalizations> load(Locale locale) async {
    final jsonString = await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    final strings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    return AppLocalizations(locale, strings);
  }

  /// Traduit [key] (ex: `'nav.home'`). Retourne la clé elle-même si la
  /// traduction est manquante, pour repérer facilement un oubli en debug
  /// plutôt que de crasher l'app.
  String t(String key) => _strings[key] ?? key;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      kSupportedLocales.any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
