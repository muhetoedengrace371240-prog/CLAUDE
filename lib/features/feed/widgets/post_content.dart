import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/video_model.dart';
import 'video_player_item.dart';

/// Contenu principal d'une publication, selon son type : lecteur vidéo,
/// photos défilantes, carte document ou texte. Utilisé par l'écran de
/// lecture d'une publication ouverte depuis le profil.
///
/// [rightInset] et [bottomInset] gardent le texte à l'écart des éléments
/// posés par-dessus (légende en bas, boutons à droite).
class PostContent extends StatelessWidget {
  const PostContent({
    super.key,
    required this.video,
    this.itemKey,
    this.rightInset = 28,
    this.bottomInset = 160,
  });

  final VideoModel video;
  final String? itemKey;
  final double rightInset;
  final double bottomInset;

  /// Photos à afficher : `photoUrls`, ou à défaut la miniature seule.
  List<String> get _photoUrls {
    if (video.photoUrls.isNotEmpty) return video.photoUrls;
    if (video.thumbnailUrl.isNotEmpty) return [video.thumbnailUrl];
    return const [];
  }

  Future<void> _openDocument(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      if (video.documentUrl.isNotEmpty) {
        opened = await launchUrl(
          Uri.parse(video.documentUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.t('feed.openDocumentFailed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (video.postType) {
      case PostType.video:
        return VideoPlayerItem(
          videoUrl: video.videoUrl,
          thumbnailUrl: video.thumbnailUrl,
          itemKey: itemKey ?? video.id,
        );
      case PostType.photo:
        return _PhotoCarousel(urls: _photoUrls);
      case PostType.document:
        return _DocumentCard(
          video: video,
          onOpen: () => _openDocument(context),
          rightInset: rightInset,
          bottomInset: bottomInset,
        );
      case PostType.text:
        return _TextPost(
          text: video.caption,
          rightInset: rightInset,
          bottomInset: bottomInset,
        );
    }
  }
}

/// Photos d'un post : défilement horizontal, avec compteur "1/3" s'il y en
/// a plusieurs.
class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({required this.urls});

  final List<String> urls;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return const ColoredBox(
        color: AppColors.surface,
        child: Center(
          child: Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 48),
        ),
      );
    }

    return ColoredBox(
      color: AppColors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => CachedNetworkImage(
              imageUrl: widget.urls[i],
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 48),
              ),
            ),
          ),
          if (widget.urls.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 48,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_index + 1}/${widget.urls.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte d'un post document : icône, nom du fichier, bouton "Ouvrir".
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.video,
    required this.onOpen,
    required this.rightInset,
    required this.bottomInset,
  });

  final VideoModel video;
  final VoidCallback onOpen;
  final double rightInset;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isPdf = video.documentType == 'pdf';
    final name = video.documentName.isNotEmpty ? video.documentName : loc.t('create.document');

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.black],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 80, rightInset, bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
                color: AppColors.gold,
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(loc.t('feed.openDocument')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Post texte : le texte en grand, centré, sur fond sombre.
class _TextPost extends StatelessWidget {
  const _TextPost({
    required this.text,
    required this.rightInset,
    required this.bottomInset,
  });

  final String text;
  final double rightInset;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.black],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 80, rightInset, bottomInset),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 12,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}