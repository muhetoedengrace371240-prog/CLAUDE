import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

/// Écran cœur de l'app : flux de vidéos courtes verticales en plein écran,
/// défilement vertical type TikTok/Reels, alimenté par Firestore.
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
    try {
      await _feedService.toggleLike(video.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connecte-toi pour aimer une vidéo.')),
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
                return const Center(
                  child: Text(
                    'Impossible de charger le feed.\nVérifie ta connexion.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final videos = snapshot.data ?? const [];
              if (videos.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucune vidéo pour le moment.\nSois le premier à publier !',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
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
                            _tabLabel(tab),
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

  String _tabLabel(FeedTab tab) {
    switch (tab) {
      case FeedTab.pourToi:
        return 'Pour Toi';
      case FeedTab.abonnements:
        return 'Abonnements';
      case FeedTab.tendances:
        return 'Tendances';
    }
  }
}

/// Une page complète du feed : vidéo plein écran + actions + légende.
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onDoubleTap: onLike,
          child: VideoPlayerItem(
            videoUrl: video.videoUrl,
            thumbnailUrl: video.thumbnailUrl,
            itemKey: video.id,
            onBecameVisible: () => feedService.registerView(video.id),
          ),
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

        // Légende en bas à gauche.
        Positioned(
          left: 16,
          right: 90,
          bottom: 100,
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
        username: author?.username ?? 'Utilisateur MUHETO',
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
        const SnackBar(content: Text("Le commentaire n'a pas pu être publié.")),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              '${widget.video.commentsCount} commentaires',
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
                    return const Center(
                      child: Text(
                        'Sois le premier à commenter.',
                        style: TextStyle(color: Colors.white54),
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
                        decoration: const InputDecoration(
                          hintText: 'Ajoute un commentaire...',
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
