import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../business/business_screen.dart';

/// Écran "Découvrir" : recherche + catégories (Humour, Musique, Business...).
/// Le grid de résultats vidéo sera branché sur Firestore dans une prochaine
/// brique (recherche par hashtag / catégorie / utilisateur). La catégorie
/// "Business" ouvre déjà la Page Business Locale (Brique 7).
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();

  static const _categories = [
    ('Humour', Icons.emoji_emotions_rounded),
    ('Musique', Icons.music_note_rounded),
    ('Danse', Icons.directions_walk_rounded),
    ('Actualité', Icons.article_rounded),
    ('Éducation', Icons.school_rounded),
    ('Business', Icons.work_rounded),
    ('Cuisine', Icons.restaurant_rounded),
    ('Sport', Icons.sports_soccer_rounded),
    ('Culture', Icons.groups_rounded),
    ('Lifestyle', Icons.star_rounded),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleCategoryTap(String label) {
    if (label == 'Business') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BusinessScreen()),
      );
      return;
    }
    // TODO: naviguer vers les résultats vidéo filtrés par cette catégorie.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('DÉCOUVRIR'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Rechercher un créateur, un hashtag...',
                prefixIcon: Icon(Icons.search, color: AppColors.gold),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Explore par catégories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final (label, icon) = _categories[index];
                  return _CategoryTile(
                    label: label,
                    icon: icon,
                    onTap: () => _handleCategoryTap(label),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceElevated),
            ),
            child: Icon(icon, color: AppColors.gold, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
