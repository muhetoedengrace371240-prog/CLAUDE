import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/video_model.dart';
import '../feed/widgets/video_caption.dart';
import '../feed/widgets/video_player_item.dart';

/// Lecture plein écran d'une seule vidéo, ouverte depuis la grille du
/// profil. Réutilise le même lecteur que le Feed principal pour une
/// expérience cohérente, sans le système de swipe vertical multi-vidéos.
class SingleVideoScreen extends StatelessWidget {
  const SingleVideoScreen({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayerItem(
            videoUrl: video.videoUrl,
            thumbnailUrl: video.thumbnailUrl,
            itemKey: 'single_${video.id}',
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 160,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.feedBottomScrim),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _RoundBackButton(onTap: () => Navigator.of(context).pop()),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: VideoCaption(
              username: video.username,
              isVerified: video.isVerified,
              caption: video.caption,
              hashtags: video.hashtags,
              musicName: video.musicName,
              isBusinessPost: video.isBusinessPost,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
