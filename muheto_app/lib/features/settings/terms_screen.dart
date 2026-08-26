import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';

/// Écran des Conditions d'utilisation. Le contenu vient entièrement des
/// fichiers de traduction (`settings.termsBody`) — un texte d'exemple à
/// remplacer impérativement par de vraies CGU/Politique de confidentialité
/// avant toute mise en production (voir SETTINGS_README.md).
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(title: Text(loc.t('settings.termsTitle'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          loc.t('settings.termsBody'),
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}