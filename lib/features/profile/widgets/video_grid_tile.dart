import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/video_model.dart';

/// Une tuile de la grille 3 colonnes du profil. S'adapte au type de la
/// publication : miniature (vidéo, photo), carte fichier (document) ou
/// extrait du texte (post texte). Badge "Business" si applicable.
class VideoGridTile extends StatelessWidget {
  const VideoGridTile({super.key, required this.video, required this.onTap});

  final VideoModel video;
  final VoidCallback onTap;

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  IconData get _typeIcon {
    switch (video.postType) {
      case PostType.video:
        return Icons.movie_creation_outlined;
      case PostType.photo:
        return Icons.image_outlined;
      case PostType.document:
        return video.documentType == 'pdf'
            ? Icons.picture_as_pdf_rounded
            : Icons.insert_drive_file_rounded;
      case PostType.text:
        return Icons.text_fields_rounded;
    }
  }

  Widget _buildBackground() {
    switch (video.postType) {
      case PostType.video:
      case PostType.photo:
        return _thumbnail();
      case PostType.document:
        return _documentCard();
      case PostType.text:
        return _textCard();
    }
  }

  Widget _thumbnail() {
    final placeholder = ColoredBox(
      color: AppColors.surface,
      child: Center(child: Icon(_typeIcon, color: AppColors.textMuted)),
    );
    // Pas de miniature (adresse vide) : on n'appelle pas le chargeur réseau.
    if (video.thumbnailUrl.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: video.thumbnailUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ColoredBox(color: AppColors.surface),
      errorWidget: (_, __, ___) => placeholder,
    );
  }

  Widget _documentCard() {
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_typeIcon, color: AppColors.gold, size: 30),
            if (video.documentName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                video.documentName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 10.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _textCard() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.black],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 24),
        child: Center(
          child: Text(
            video.caption,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 15),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
          ),
        ),
      ],
    );
  }

  /// Vidéo : ▶ + vues. Photos multiples : nombre de photos. Sinon rien
  /// (les vues ne sont comptées que pour les vidéos).
  Widget? _buildBadge() {
    switch (video.postType) {
      case PostType.video:
        return _badge(Icons.play_arrow_rounded, _formatCount(video.viewsCount));
      case PostType.photo:
        return video.photoUrls.length > 1
            ? _badge(Icons.collections_rounded, '${video.photoUrls.length}')
            : null;
      case PostType.document:
      case PostType.text:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _buildBadge();

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          if (video.isBusinessPost)
            const Positioned(
              top: 5,
              left: 5,
              child: Icon(Icons.storefront_rounded, color: AppColors.gold, size: 16),
            ),
          if (badge != null)
            Positioned(
              left: 6,
              bottom: 6,
              child: badge,
            ),
        ],
      ),
    );
  }
}