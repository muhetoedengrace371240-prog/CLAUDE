import '../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/video_model.dart';
import '../../services/profile_service.dart';
import 'widgets/simple_bar_chart.dart';
import 'widgets/stat_card.dart';

/// Dashboard Analytics Créateur : agrège en DIRECT les données réelles déjà
/// stockées (vidéos de l'utilisateur + son document profil) — aucune
/// donnée historique n'est inventée. Voir ANALYTICS_README.md pour la
/// marche à suivre si tu veux ajouter un vrai suivi jour par jour plus tard.
class CreatorAnalyticsScreen extends StatelessWidget {
  const CreatorAnalyticsScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(title: Text(AppLocalizations.of(context).t('analytics.creatorTitle'))),
      body: StreamBuilder<UserModel?>(
        stream: profileService.watchUser(uid),
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;

          return StreamBuilder<List<VideoModel>>(
            stream: profileService.watchUserVideos(uid),
            builder: (context, videosSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting ||
                  videosSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.gold));
              }

              final videos = videosSnapshot.data ?? const <VideoModel>[];

              final totalViews = videos.fold<int>(0, (sum, v) => sum + v.viewsCount);
              final totalLikes = videos.fold<int>(0, (sum, v) => sum + v.likesCount);
              final totalShares = videos.fold<int>(0, (sum, v) => sum + v.sharesCount);
              final totalComments = videos.fold<int>(0, (sum, v) => sum + v.commentsCount);

              // Les 8 vidéos les plus vues, pour le graphique — donnée
              // réelle et immédiatement disponible, contrairement à une
              // évolution jour par jour qui nécessiterait un historique
              // dédié (non stocké en V1).
              final topVideos = [...videos]..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
              final chartPoints = topVideos.take(8).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final video = entry.value;
                return BarChartPoint(label: 'V${index + 1}', value: video.viewsCount);
              }).toList();

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    videos.isEmpty
                        ? 'Publie ta première vidéo pour voir tes statistiques ici.'
                        : '${videos.length} vidéo${videos.length > 1 ? 's' : ''} publiée${videos.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        icon: Icons.play_circle_fill_rounded,
                        value: StatCard.formatCount(totalViews),
                        label: 'Vues cumulées',
                      ),
                      StatCard(
                        icon: Icons.favorite_rounded,
                        value: StatCard.formatCount(totalLikes),
                        label: "J'aime cumulés",
                      ),
                      StatCard(
                        icon: Icons.reply_rounded,
                        value: StatCard.formatCount(totalShares),
                        label: 'Partages cumulés',
                      ),
                      StatCard(
                        icon: Icons.mode_comment_rounded,
                        value: StatCard.formatCount(totalComments),
                        label: 'Commentaires',
                      ),
                      StatCard(
                        icon: Icons.people_alt_rounded,
                        value: StatCard.formatCount(user?.followersCount ?? 0),
                        label: 'Abonnés',
                      ),
                      StatCard(
                        icon: Icons.person_add_alt_1_rounded,
                        value: StatCard.formatCount(user?.followingCount ?? 0),
                        label: 'Abonnements',
                      ),
                    ],
                  ),
                  if (chartPoints.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    const Text(
                      'Vues par vidéo (top 8)',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    SimpleBarChart(points: chartPoints),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
