import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/video_model.dart';

/// Une tuile de la grille 3 colonnes du profil : miniature de la vidéo +
/// nombre de vues en surimpression, badge "Business" si applicable.
class VideoGridTile extends StatelessWidget {
  const VideoGridTile({super.key, required this.video, required this.onTap});

  final VideoModel video;
  final VoidCallback onTap;

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: video.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => const ColoredBox(color: AppColors.surface),
            errorWidget: (_, __, ___) => const ColoredBox(
              color: AppColors.surface,
              child: Icon(Icons.movie_creation_outlined, color: AppColors.textMuted),
            ),
          ),
          if (video.isBusinessPost)
            const Positioned(
              top: 5,
              left: 5,
              child: Icon(Icons.storefront_rounded, color: AppColors.gold, size: 16),
            ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 2),
                Text(
                  _formatCount(video.viewsCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
