import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// Bloc d'informations affiché en bas à gauche de chaque vidéo :
/// @pseudo (+ badge vérifié doré), légende, hashtags, nom du son.
class VideoCaption extends StatelessWidget {
  const VideoCaption({
    super.key,
    required this.username,
    required this.isVerified,
    required this.caption,
    required this.hashtags,
    required this.musicName,
    this.isBusinessPost = false,
  });

  final String username;
  final bool isVerified;
  final String caption;
  final List<String> hashtags;
  final String musicName;
  final bool isBusinessPost;

  @override
  Widget build(BuildContext context) {
    final hashtagText = hashtags.map((h) => h.startsWith('#') ? h : '#$h').join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBusinessPost)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              AppLocalizations.of(context).t('feed.businessLabel'),
              style: TextStyle(
                color: AppColors.black,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        Row(
          children: [
            Text(
              '@$username',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: AppColors.gold, size: 16),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
          ),
        ),
        if (hashtagText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            hashtagText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.music_note, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                musicName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
