import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../settings/language_selector_sheet.dart';

/// Écran affiché aux utilisateurs non connectés : logo MUHETO + les deux
/// points d'entrée "Se connecter" / "S'inscrire", fidèle à la maquette.
/// Une icône langue en haut à droite permet de choisir sa langue dès ce
/// premier écran, avant même de se connecter (le sélecteur complet reste
/// aussi disponible depuis Profil → Paramètres une fois connecté).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 4,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.language_rounded, color: AppColors.gold),
                tooltip: loc.t('settings.language'),
                onPressed: () => showLanguageSelectorSheet(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
                    child: const Text(
                      'M',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
                    child: const Text(
                      'MUHETO',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.t('app_tagline').toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const Spacer(flex: 4),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
                    child: Text(loc.t('auth.login')),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.register),
                    child: Text(loc.t('auth.register')),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
