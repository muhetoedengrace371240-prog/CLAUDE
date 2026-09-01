import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Écran affiché aux utilisateurs non connectés : logo MUHETO + les deux
/// points d'entrée "Se connecter" / "S'inscrire", fidèle à la maquette.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
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
              const Text(
                'LA VOIX DE L\'AFRIQUE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 2.5,
                ),
              ),
              const Spacer(flex: 4),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Se connecter'),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text('S\'inscrire'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
