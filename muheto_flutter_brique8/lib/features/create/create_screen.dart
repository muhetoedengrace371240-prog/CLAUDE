import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import 'camera_capture_screen.dart';
import 'publish_screen.dart';

/// Écran ouvert en plein écran quand l'utilisateur tape sur "+" dans la
/// navbar. Point d'entrée vers la caméra ou la galerie ; une fois une vidéo
/// obtenue, enchaîne automatiquement sur [PublishScreen].
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _picker = ImagePicker();
  bool _isPicking = false;

  Future<void> _openCamera() async {
    final file = await Navigator.of(context).push<File>(
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen(), fullscreenDialog: true),
    );
    if (file != null) _goToPublish(file);
  }

  Future<void> _openGallery() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final XFile? picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // borne large ; Gold garde l'exclusivité au-delà de 60s en V1
      );
      if (picked != null) _goToPublish(File(picked.path));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _goToPublish(File file) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublishScreen(videoFile: file)),
    );
  }

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
                decoration: const BoxDecoration(
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
                'Vidéo verticale recommandée, 60 secondes maximum en version standard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openCamera,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Caméra'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isPicking ? null : _openGallery,
                      icon: _isPicking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.black,
                              ),
                            )
                          : const Icon(Icons.photo_library_outlined),
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
