import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

const _kLocalePrefsKey = 'muheto_locale_code';

/// ChangeNotifier qui gère la langue active de l'app et la persiste
/// localement (SharedPreferences) pour qu'elle soit restaurée au prochain
/// lancement. À placer au-dessus de `MaterialApp` via `ChangeNotifierProvider`.
///
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => LocaleProvider()..init(),
///   child: const MuhetoApp(),
/// )
/// ```
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr'); // Français par défaut si rien n'est enregistré.
  bool _isReady = false;

  Locale get locale => _locale;
  bool get isReady => _isReady;

  /// Charge la langue précédemment choisie (ou la langue du système si elle
  /// est supportée, sinon le français) — à appeler une fois au démarrage.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_kLocalePrefsKey);

    if (savedCode != null && kSupportedLocales.any((l) => l.languageCode == savedCode)) {
      _locale = Locale(savedCode);
    } else {
      final systemCode = PlatformDispatcher.instance.locale.languageCode;
      final matchesSystem = kSupportedLocales.any((l) => l.languageCode == systemCode);
      _locale = matchesSystem ? Locale(systemCode) : const Locale('fr');
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == _locale.languageCode) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocalePrefsKey, locale.languageCode);
  }
}
