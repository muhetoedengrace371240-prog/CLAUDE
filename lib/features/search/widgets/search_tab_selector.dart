import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

enum SearchResultTab { users, videos, business }

/// Sélecteur segmenté à 3 options (Utilisateurs / Publications / Business),
/// même logique visuelle que [ScopeSelector] de la Brique 3.
///
/// ⚠️ La valeur d'énumération `videos` garde son nom historique : elle
/// désigne désormais toutes les publications (vidéo, photo, document,
/// texte). Seul le libellé affiché a changé.
class SearchTabSelector extends StatelessWidget {
  const SearchTabSelector(
      {super.key, required this.selected, required this.onSelected});

  final SearchResultTab selected;
  final ValueChanged<SearchResultTab> onSelected;

  static const _icons = {
    SearchResultTab.users: Icons.person_rounded,
    SearchResultTab.videos: Icons.video_library_rounded,
    SearchResultTab.business: Icons.storefront_rounded,
  };

  static const _labelKeys = {
    SearchResultTab.users: 'search.tabUsers',
    SearchResultTab.videos: 'search.tabPosts',
    SearchResultTab.business: 'search.tabBusiness',
  };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Row(
      children: SearchResultTab.values.map((tab) {
        final isSelected = tab == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(tab),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.goldGradient : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.surfaceElevated,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _icons[tab]!,
                    size: 18,
                    color: isSelected ? AppColors.black : Colors.white70,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    loc.t(_labelKeys[tab]!),
                    style: TextStyle(
                      color: isSelected ? AppColors.black : Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
