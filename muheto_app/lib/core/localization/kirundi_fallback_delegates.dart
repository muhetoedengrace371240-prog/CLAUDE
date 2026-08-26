import 'package:flutter/material.dart';

/// Le Kirundi (rn) n'est pas une des langues nativement connues par les
/// widgets internes de Flutter (AppBar, TabBar, etc.) — contrairement à
/// nos propres traductions (AppLocalizationsDelegate), qui elles
/// supportent bien le Kirundi.
///
/// Sans ces 2 délégués de repli, tout widget interne à Flutter qui a
/// besoin de MaterialLocalizations/WidgetsLocalizations plante avec
/// "No MaterialLocalizations found" dès que la langue active est le
/// Kirundi. Solution : pour ces réglages internes UNIQUEMENT, on se
/// comporte comme si on était en français — nos propres traductions,
/// elles, restent bien en Kirundi (ça ne passe pas par ces classes).
class KirundiMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const KirundiMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rn';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(const Locale('fr'));

  @override
  bool shouldReload(KirundiMaterialLocalizationsDelegate old) => false;
}

class KirundiWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const KirundiWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rn';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      DefaultWidgetsLocalizations.load(const Locale('fr'));

  @override
  bool shouldReload(KirundiWidgetsLocalizationsDelegate old) => false;
}