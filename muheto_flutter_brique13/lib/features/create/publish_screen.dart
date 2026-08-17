import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_theme.dart';
import '../../models/video_model.dart';
import '../../services/upload_service.dart';
import 'widgets/category_selector.dart';
import 'widgets/scope_selector.dart';

/// Écran affiché juste après la capture caméra ou l'import galerie.
/// Permet d'ajouter une légende, des hashtags, une catégorie, de choisir
/// l'univers de diffusion, puis de publier (upload Storage + Firestore).
class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key, required this.videoFile});

  final File videoFile;

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _captionController = TextEditingController();
  final _hashtagsController = TextEditingController();
  final _uploadService = UploadService();

  VideoPlayerController? _previewController;

  String? _selectedCategory;
  ContentScope _selectedScope = ContentScope.burundi;
  bool _isBusinessPost = false;

  bool _isPublishing = false;
  PublishProgress _progress = const PublishProgress(PublishStage.generatingThumbnail, 0);
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  Future<void> _initPreview() async {
    final controller = VideoPlayerController.file(widget.videoFile);
    await controller.initialize();
    controller
      ..setLooping(true)
      ..setVolume(0)
      ..play();
    if (!mounted) return;
    setState(() => _previewController = controller);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagsController.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  List<String> get _parsedHashtags {
    return _hashtagsController.text
        .split(RegExp(r'\s+'))
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .map((tag) => tag.startsWith('#') ? tag : '#$tag')
        .toList();
  }

  Future<void> _publish() async {
    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Choisis une catégorie pour ta vidéo.');
      return;
    }

    setState(() {
      _isPublishing = true;
      _errorMessage = null;
    });

    try {
      await _uploadService.publishVideo(
        videoFile: widget.videoFile,
        caption: _captionController.text,
        hashtags: _parsedHashtags,
        category: _selectedCategory!,
        scope: _selectedScope,
        language: 'fr', // TODO: brancher sur la langue active de l'app
        isBusinessPost: _isBusinessPost,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _progress = progress);
        },
      );

      if (!mounted) return;
      // Referme tous les écrans de création et retourne au feed.
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vidéo publiée ! Elle est maintenant en ligne sur MUHETO.'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        _errorMessage = "La publication a échoué. Vérifie ta connexion et réessaie.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _isPublishing ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text('Nouvelle publication'),
      ),
      body: AbsorbPointer(
        absorbing: _isPublishing,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aperçu vidéo en boucle, muet.
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 110,
                    height: 150,
                    child: _previewController != null &&
                            _previewController!.value.isInitialized
                        ? FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _previewController!.value.size.width,
                              height: _previewController!.value.size.height,
                              child: VideoPlayer(_previewController!),
                            ),
                          )
                        : const ColoredBox(
                            color: AppColors.surface,
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.gold),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    maxLines: 5,
                    maxLength: 150,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Décris ta vidéo...',
                      counterStyle: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hashtagsController,
              style: const TextStyle(color: AppColors.goldLight),
              decoration: const InputDecoration(
                hintText: '#Burundi #Culture #Muheto',
                prefixIcon: Icon(Icons.tag_rounded, color: AppColors.gold),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Catégorie',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            CategorySelector(
              selected: _selectedCategory,
              onSelected: (category) => setState(() => _selectedCategory = category),
            ),
            const SizedBox(height: 22),
            const Text(
              'Univers de diffusion',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            ScopeSelector(
              selected: _selectedScope,
              onSelected: (scope) => setState(() => _selectedScope = scope),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.gold,
                title: const Text(
                  'Publication Business',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: const Text(
                  'Affiche le badge "Business Local" sur la vidéo',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: _isBusinessPost,
                onChanged: (value) => setState(() => _isBusinessPost = value),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 26),
            if (_isPublishing) ...[
              LinearProgressIndicator(
                value: _progress.stage == PublishStage.uploadingVideo
                    ? _progress.progress
                    : null,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
              const SizedBox(height: 8),
              Text(
                _stageLabel(_progress.stage),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 14),
            ],
            ElevatedButton(
              onPressed: _isPublishing ? null : _publish,
              child: _isPublishing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.black,
                      ),
                    )
                  : const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }

  String _stageLabel(PublishStage stage) {
    switch (stage) {
      case PublishStage.generatingThumbnail:
        return 'Préparation de la miniature...';
      case PublishStage.uploadingVideo:
        return 'Envoi de la vidéo... ${(_progress.progress * 100).toStringAsFixed(0)}%';
      case PublishStage.uploadingThumbnail:
        return 'Envoi de la miniature...';
      case PublishStage.savingPost:
        return 'Publication en cours...';
    }
  }
}
