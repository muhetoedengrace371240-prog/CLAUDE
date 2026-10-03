import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/video_model.dart';
import '../../services/upload_service.dart';
import 'widgets/category_selector.dart';
import 'widgets/scope_selector.dart';

/// Écran de publication d'un post photo (une ou plusieurs images), affiché
/// juste après la sélection dans la galerie. Sur le même modèle que
/// [PublishScreen] (vidéo), avec un aperçu en rangée horizontale au lieu
/// d'un lecteur vidéo.
class PublishPhotoScreen extends StatefulWidget {
  const PublishPhotoScreen({super.key, required this.photoFiles});

  final List<File> photoFiles;

  @override
  State<PublishPhotoScreen> createState() => _PublishPhotoScreenState();
}

class _PublishPhotoScreenState extends State<PublishPhotoScreen> {
  final _captionController = TextEditingController();
  final _hashtagsController = TextEditingController();
  final _uploadService = UploadService();

  String? _selectedCategory;
  ContentScope _selectedScope = ContentScope.burundi;
  bool _isBusinessPost = false;

  bool _isPublishing = false;
  PublishProgress _progress = const PublishProgress(PublishStage.uploadingVideo, 0);
  String? _errorMessage;

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagsController.dispose();
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
      setState(() => _errorMessage = 'Choisis une catégorie pour tes photos.');
      return;
    }

    setState(() {
      _isPublishing = true;
      _errorMessage = null;
    });

    try {
      await _uploadService.publishPhoto(
        photoFiles: widget.photoFiles,
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
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publication en ligne sur MUHETO !'),
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
        title: const Text('Nouvelle publication photo'),
      ),
      body: AbsorbPointer(
        absorbing: _isPublishing,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.photoFiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      widget.photoFiles[index],
                      width: 90,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              maxLines: 5,
              maxLength: 150,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Décris tes photos...',
                counterStyle: TextStyle(color: AppColors.textMuted),
              ),
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
                  'Affiche le badge "Business Local" sur la publication',
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
                value: _progress.progress,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
              const SizedBox(height: 8),
              Text(
                'Envoi des photos... ${(_progress.progress * 100).toStringAsFixed(0)}%',
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
}