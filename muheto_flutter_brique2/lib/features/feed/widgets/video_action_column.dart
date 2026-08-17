import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Colonne verticale d'actions affichée à droite de chaque vidéo :
/// avatar créateur, Like, Commentaire, Partage.
class VideoActionColumn extends StatelessWidget {
  const VideoActionColumn({
    super.key,
    required this.avatarUrl,
    required this.isLiked,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.onAvatarTap,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
  });

  final String avatarUrl;
  final bool isLiked;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;

  final VoidCallback onAvatarTap;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: AppColors.surfaceElevated,
                  child: Icon(Icons.person, color: AppColors.gold),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _ActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          iconColor: isLiked ? AppColors.gold : Colors.white,
          label: _formatCount(likesCount),
          onTap: onLikeTap,
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: Icons.mode_comment_rounded,
          label: _formatCount(commentsCount),
          onTap: onCommentTap,
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: Icons.reply_rounded,
          label: _formatCount(sharesCount),
          onTap: onShareTap,
        ),
        const SizedBox(height: 18),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.goldGradient,
          ),
          child: const Icon(Icons.music_note, size: 16, color: AppColors.black),
        ),
      ],
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 34),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
