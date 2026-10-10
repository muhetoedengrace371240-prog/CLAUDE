import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/comment_model.dart';
import '../../models/video_model.dart';
import '../../services/feed_service.dart';
import '../../services/profile_service.dart';
import '../gold/widgets/gold_badge.dart';
import '../profile/profile_screen.dart';
import 'widgets/video_action_column.dart';
import 'widgets/video_caption.dart';
import 'widgets/video_player_item.dart';

enum FeedTab { pourToi, abonnements, tendances }

/// Écran cœur de l'app : flux de publications verticales en plein écran
/// (vidéo, photo, document, texte), défilement vertical type TikTok/Reels,
/// alimenté par Firestore.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.scope});

  /// Univers choisi à l'onboarding ("Burundi" / "Afrique" / "Monde").
  /// Laisse à `null` pour un flux global non filtré.
  final ContentScope? scope;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FeedService _feedService = FeedService();
  final PageController _pageController = PageController();

  FeedTab _selectedTab = FeedTab.pourToi;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleLike(VideoModel video) async {
    final loc = AppLocalizations.of(context);
    try {
      await _feedService.toggleLike(video.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('feed.likeLoginRequired'))),
      );
    }
  }

  void _handleShare(VideoModel video) {
    _feedService.registerShare(video.id);
    // TODO: brancher share_plus pour ouvrir la feuille de partage native.
  }

  void _openComments(VideoModel video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentsSheet(video: video, feedService: _feedService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          StreamBuilder<List<VideoModel>>(
            stream: _feedService.watchFeed(scope: widget.scope),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    loc.t('feed.loadError'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              final videos = snapshot.data ?? const [];
              if (videos.isEmpty) {
                return Center(
                  child: Text(
                    loc.t('feed.empty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return _FeedPage(
                    video: video,
                    feedService: _feedService,
                    onLike: () => _handleLike(video),
                    onComment: () => _openComments(video),
                    onShare: () => _handleShare(video),
                  );
                },
              );
            },
          ),

          // Barre d'onglets supérieure : Pour Toi / Abonnements / Tendances.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: FeedTab.values.map((tab) {
                  final isSelected = tab == _selectedTab;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = tab),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _tabLabel(loc, tab),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isSelected)
                            Container(
                              width: 22,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tabLabel(AppLocalizations loc, FeedTab tab) {
    switch (tab) {
      case FeedTab.pourToi:
        return loc.t('feed.forYou');
      case FeedTab.abonnements:
        return loc.t('feed.following');
      case FeedTab.tendances:
        return loc.t('feed.trending');
    }
  }
}

/// Une page complète du feed : contenu (selon le type de publication) +
/// actions + légende.
class _FeedPage extends StatelessWidget {
  const _FeedPage({
    required this.video,
    required this.feedService,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  final VideoModel video;
  final FeedService feedService;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

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

  Widget _buildContent(BuildContext context) {
    switch (video.postType) {
      case PostType.video:
        return VideoPlayerItem(
          videoUrl: video.videoUrl,
          thumbnailUrl: video.thumbnailUrl,
          itemKey: video.id,
          onBecameVisible: () => feedService.registerView(video.id),
        );
      case PostType.photo:
        return _PhotoCarousel(urls: _photoUrls);
      case PostType.document:
        return _DocumentCard(
          video: video,
          onOpen: () => _openDocument(context),
        );
      case PostType.text:
        return _TextPost(text: video.caption);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onDoubleTap: onLike,
          child: _buildContent(context),
        ),

        // Voile dégradé bas pour garder la légende lisible.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 220,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.feedBottomScrim),
            ),
          ),
        ),

        // Colonne d'actions à droite.
        Positioned(
          right: 12,
          bottom: 100,
          child: StreamBuilder<bool>(
            stream: feedService.watchIsLiked(video.id),
            builder: (context, likedSnap) {
              return VideoActionColumn(
                avatarUrl: video.userAvatarUrl,
                isLiked: likedSnap.data ?? false,
                likesCount: video.likesCount,
                commentsCount: video.commentsCount,
                sharesCount: video.sharesCount,
                onAvatarTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(uid: video.userId),
                    ),
                  );
                },
                onLikeTap: onLike,
                onCommentTap: onComment,
                onShareTap: onShare,
              );
            },
          ),
        ),

        // Légende en bas à gauche. Pour un post texte, le texte est déjà
        // affiché au centre : on ne le répète pas ici.
        Positioned(
          left: 16,
          right: 90,
          bottom: 100,
          child: VideoCaption(
            username: video.username,
            isVerified: video.isVerified,
            caption: video.postType == PostType.text ? '' : video.caption,
            hashtags: video.hashtags,
            musicName: video.musicName,
            isBusinessPost: video.isBusinessPost,
          ),
        ),
      ],
    );
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
  const _DocumentCard({required this.video, required this.onOpen});

  final VideoModel video;
  final VoidCallback onOpen;

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
          padding: const EdgeInsets.fromLTRB(28, 80, 90, 220),
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
  const _TextPost({required this.text});

  final String text;

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
          padding: const EdgeInsets.fromLTRB(28, 80, 90, 220),
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

/// Panneau de commentaires (bottom sheet) branché sur Firestore en temps réel,
/// avec zone de saisie pour publier un nouveau commentaire.
class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.video, required this.feedService});

  final VideoModel video;
  final FeedService feedService;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _profileService = ProfileService();
  final _textController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final loc = AppLocalizations.of(context);
    final text = _textController.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (text.isEmpty || uid == null || _isSending) return;

    setState(() => _isSending = true);
    try {
      // Dénormalise les infos actuelles de l'auteur (dont son statut Gold)
      // au moment précis de l'envoi, pour que le badge affiché reflète son
      // statut réel à cet instant.
      final author = await _profileService.getUserOnce(uid);
      final comment = CommentModel(
        id: '',
        userId: uid,
        username: author?.username ?? loc.t('feed.defaultUsername'),
        avatarUrl: author?.avatarUrl ?? '',
        isGoldMember: author?.isGoldActive ?? false,
        text: text,
        likesCount: 0,
        createdAt: null,
      );
      await widget.feedService.addComment(widget.video.id, comment);
      _textController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('feed.commentFailed'))),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Text(
              '${widget.video.commentsCount} ${loc.t('feed.commentsLabel')}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const Divider(color: AppColors.surfaceElevated, height: 20),
            Expanded(
              child: StreamBuilder<List<CommentModel>>(
                stream: widget.feedService.watchComments(widget.video.id),
                builder: (context, snapshot) {
                  final comments = snapshot.data ?? const [];
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        loc.t('feed.beFirstComment'),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceElevated,
                          backgroundImage: c.avatarUrl.isNotEmpty
                              ? NetworkImage(c.avatarUrl)
                              : null,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                c.username,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (c.isGoldMember) ...[
                              const SizedBox(width: 4),
                              const GoldBadge(size: 13),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          c.text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: loc.t('feed.addCommentHint'),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.gold),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send_rounded, color: AppColors.gold),
                            onPressed: _send,
                          ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}