import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../business/business_screen.dart';
import '../search/search_screen.dart';

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

  // La clé de traduction (2e élément) reste stable, quelle que soit la
  // langue affichée. C'est elle qu'on utilise pour la logique (ex: savoir
  // si on a tapé sur "Business"), jamais le texte affiché.
  static const _categories = [
    ('category.humor', Icons.emoji_emotions_rounded),
    ('category.music', Icons.music_note_rounded),
    ('category.dance', Icons.directions_walk_rounded),
    ('category.news', Icons.article_rounded),
    ('category.education', Icons.school_rounded),
    ('category.business', Icons.work_rounded),
    ('category.cuisine', Icons.restaurant_rounded),
    ('category.sport', Icons.sports_soccer_rounded),
    ('category.culture', Icons.groups_rounded),
    ('category.lifestyle', Icons.star_rounded),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleCategoryTap(String categoryKey) {
    if (categoryKey == 'category.business') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BusinessScreen()),
      );
      return;
    }
    // TODO: naviguer vers les résultats vidéo filtrés par cette catégorie.
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: Text(loc.t('nav.discover').toUpperCase()),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              readOnly: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: loc.t('discover.searchHint'),
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              loc.t('discover.exploreCategories'),
              style: const TextStyle(
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
                  final (categoryKey, icon) = _categories[index];
                  return _CategoryTile(
                    label: loc.t(categoryKey),
                    icon: icon,
                    onTap: () => _handleCategoryTap(categoryKey),
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