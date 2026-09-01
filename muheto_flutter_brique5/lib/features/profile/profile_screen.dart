import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/video_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../auth/welcome_screen.dart';
import 'edit_profile_screen.dart';
import 'single_video_screen.dart';
import 'widgets/profile_stat.dart';
import 'widgets/video_grid_tile.dart';

/// Écran Profil, branché en direct sur Firestore.
///
/// - Si [uid] est `null`, affiche le profil de l'utilisateur connecté
///   (bouton "Modifier le profil", pas de bouton Suivre).
/// - Si [uid] pointe vers un autre utilisateur, affiche un bouton
///   Suivre/Abonné basé sur la relation réelle Firestore.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.uid});

  final String? uid;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _authService = AuthService();

  late final String? _viewedUid = widget.uid ?? FirebaseAuth.instance.currentUser?.uid;

  bool get _isOwnProfile =>
      _viewedUid != null && _viewedUid == FirebaseAuth.instance.currentUser?.uid;

  Future<void> _handleFollowTap() async {
    final targetUid = _viewedUid;
    if (targetUid == null) return;
    try {
      await _profileService.toggleFollow(targetUid);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('StateError: ', ''))),
      );
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _viewedUid;

    if (uid == null) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: Text(
            'Connecte-toi pour voir ton profil.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: StreamBuilder<UserModel?>(
          stream: _profileService.watchUser(uid),
          builder: (context, snap) => Text(snap.data?.username ?? 'Profil'),
        ),
        automaticallyImplyLeading: !_isOwnProfile,
        actions: [
          if (_isOwnProfile)
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'logout') _signOut();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'logout',
                  child: Text('Se déconnecter', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _profileService.watchUser(uid),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          final user = userSnap.data;
          if (user == null) {
            return const Center(
              child: Text('Utilisateur introuvable.', style: TextStyle(color: Colors.white70)),
            );
          }

          return _ProfileBody(
            uid: uid,
            user: user,
            isOwnProfile: _isOwnProfile,
            profileService: _profileService,
            onFollowTap: _handleFollowTap,
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.uid,
    required this.user,
    required this.isOwnProfile,
    required this.profileService,
    required this.onFollowTap,
  });

  final String uid;
  final UserModel user;
  final bool isOwnProfile;
  final ProfileService profileService;
  final VoidCallback onFollowTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VideoModel>>(
      stream: profileService.watchUserVideos(uid),
      builder: (context, videosSnap) {
        final videos = videosSnap.data ?? const <VideoModel>[];
        // Total de likes reçus = somme des likesCount de toutes les vidéos
        // de l'utilisateur, calculée en direct à partir du flux ci-dessus.
        final totalLikes = videos.fold<int>(0, (sum, v) => sum + v.likesCount);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 2.5),
                ),
                child: ClipOval(
                  child: user.avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const _AvatarFallback(),
                        )
                      : const _AvatarFallback(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: AppColors.gold, size: 18),
                  ],
                  if (user.isGoldMember) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 17),
                  ],
                ],
              ),
            ),
            if (user.bio.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                user.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ProfileStat(value: user.followingCount, label: 'Abonnements'),
                ProfileStat(value: user.followersCount, label: 'Abonnés'),
                ProfileStat(value: totalLikes, label: "J'aime"),
              ],
            ),
            const SizedBox(height: 18),
            if (isOwnProfile)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
                        );
                      },
                      child: const Text('Modifier le profil'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SquareIconButton(icon: Icons.share_outlined, onTap: () {}),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<bool>(
                      stream: profileService.watchIsFollowing(uid),
                      builder: (context, followSnap) {
                        final isFollowing = followSnap.data ?? false;
                        return isFollowing
                            ? OutlinedButton(
                                onPressed: onFollowTap,
                                child: const Text('Abonné'),
                              )
                            : ElevatedButton(
                                onPressed: onFollowTap,
                                child: const Text('Suivre'),
                              );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SquareIconButton(icon: Icons.chat_bubble_outline_rounded, onTap: () {}),
                ],
              ),
            const SizedBox(height: 22),
            DefaultTabController(
              length: 1,
              child: SizedBox(
                height: 500,
                child: Column(
                  children: [
                    const TabBar(
                      indicatorColor: AppColors.gold,
                      labelColor: AppColors.gold,
                      unselectedLabelColor: AppColors.textMuted,
                      tabs: [Tab(icon: Icon(Icons.grid_on_rounded))],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _VideosGrid(videos: videos, isLoading: videosSnap.connectionState == ConnectionState.waiting),
                        ],
                      ),
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

class _VideosGrid extends StatelessWidget {
  const _VideosGrid({required this.videos, required this.isLoading});

  final List<VideoModel> videos;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (videos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off_outlined, color: AppColors.textMuted, size: 36),
              SizedBox(height: 10),
              Text(
                'Aucune vidéo publiée pour le moment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: videos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        final video = videos[index];
        return VideoGridTile(
          video: video,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SingleVideoScreen(video: video)),
            );
          },
        );
      },
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surface,
      child: Icon(Icons.person, color: AppColors.gold, size: 40),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.surfaceElevated),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
