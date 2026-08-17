import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Écran Profil : infos utilisateur + grille de vidéos publiées (3 colonnes).
/// Les données réelles (Firestore `users/{uid}` + `videos` où userId == uid)
/// seront branchées dans la brique Profil dédiée ; ceci pose déjà la
/// structure visuelle et la navigation.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.menu_rounded, color: Colors.white),
          ),
        ],
      ),
      body: ListView(
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
              child: const CircleAvatar(
                backgroundColor: AppColors.surface,
                child: Icon(Icons.person, color: AppColors.gold, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '@utilisateur',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.verified, color: AppColors.gold, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Créateur de contenu | Burundi 🇧🇮',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProfileStat(value: '128', label: 'Abonnements'),
              _ProfileStat(value: '15.6K', label: 'Abonnés'),
              _ProfileStat(value: '320.2K', label: 'J\'aime'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Modifier le profil'),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.surfaceElevated),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.share_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 22),
          DefaultTabController(
            length: 3,
            child: SizedBox(
              height: 460,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: AppColors.gold,
                    labelColor: AppColors.gold,
                    unselectedLabelColor: AppColors.textMuted,
                    tabs: [
                      Tab(icon: Icon(Icons.grid_on_rounded)),
                      Tab(icon: Icon(Icons.video_library_rounded)),
                      Tab(icon: Icon(Icons.lock_outline_rounded)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _VideoGrid(),
                        Center(
                          child: Text('Aucune vidéo likée',
                              style: TextStyle(color: Colors.white38)),
                        ),
                        Center(
                          child: Text('Contenu privé',
                              style: TextStyle(color: Colors.white38)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

/// Grille 3 colonnes des vidéos publiées.
/// TODO : remplacer les tuiles par un StreamBuilder sur
/// `videos` where userId == uid, orderBy createdAt desc.
class _VideoGrid extends StatelessWidget {
  const _VideoGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        return Container(
          color: AppColors.surface,
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(6),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
              SizedBox(width: 2),
              Text('12.4K', style: TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}
