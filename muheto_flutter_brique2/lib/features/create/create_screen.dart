import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Écran ouvert en plein écran quand l'utilisateur tape sur "+".
/// Ici : point d'entrée vers la caméra / la galerie. L'intégration réelle
/// (package `camera` + upload vers Firebase Storage) sera faite dans la
/// brique "Création & Publication".
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Créer'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.videocam_rounded, color: AppColors.black, size: 38),
              ),
              const SizedBox(height: 20),
              const Text(
                'Filme ou importe ta vidéo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La capture caméra et l\'import galerie arrivent dans la prochaine brique.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: package `camera` — ouvrir la capture live.
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Caméra'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: package `image_picker` — importer depuis la galerie.
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galerie'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
