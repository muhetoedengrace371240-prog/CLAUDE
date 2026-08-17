import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/theme/app_theme.dart';

/// Une "page" du feed vertical : lit la vidéo en boucle quand elle occupe
/// une grande partie de l'écran, sinon la met en pause (économie data/batterie).
class VideoPlayerItem extends StatefulWidget {
  const VideoPlayerItem({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.itemKey,
    this.onBecameVisible,
  });

  final String videoUrl;
  final String thumbnailUrl;

  /// Clé unique passée au [VisibilityDetector] (ex: l'id de la vidéo).
  final String itemKey;

  /// Callback déclenché une fois quand la vidéo devient majoritairement
  /// visible — pratique pour incrémenter les vues côté Firestore.
  final VoidCallback? onBecameVisible;

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _viewCounted = false;
  bool _showPauseIcon = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleVisibility(VisibilityInfo info) {
    final visibleFraction = info.visibleFraction;
    final controller = _controller;
    if (controller == null || !_initialized) return;

    if (visibleFraction > 0.65) {
      controller.play();
      if (!_viewCounted) {
        _viewCounted = true;
        widget.onBecameVisible?.call();
      }
    } else {
      controller.pause();
    }
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !_initialized) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _showPauseIcon = true;
      } else {
        controller.play();
        _showPauseIcon = false;
      }
    });

    if (_showPauseIcon) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showPauseIcon = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.itemKey),
      onVisibilityChanged: _handleVisibility,
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Miniature affichée pendant le chargement du flux vidéo.
            CachedNetworkImage(
              imageUrl: widget.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(color: AppColors.blackSoft),
              errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.blackSoft),
            ),
            if (_initialized && _controller != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            AnimatedOpacity(
              opacity: _showPauseIcon ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white70,
                  size: 84,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
