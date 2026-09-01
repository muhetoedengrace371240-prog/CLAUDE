import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum SearchResultTab { users, videos, business }

/// Sélecteur segmenté à 3 options (Utilisateurs / Vidéos / Business),
/// même logique visuelle que [ScopeSelector] de la Brique 3.
class SearchTabSelector extends StatelessWidget {
  const SearchTabSelector({super.key, required this.selected, required this.onSelected});

  final SearchResultTab selected;
  final ValueChanged<SearchResultTab> onSelected;

  static const _config = {
    SearchResultTab.users: (label: 'Utilisateurs', icon: Icons.person_rounded),
    SearchResultTab.videos: (label: 'Vidéos', icon: Icons.video_library_rounded),
    SearchResultTab.business: (label: 'Business', icon: Icons.storefront_rounded),
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: SearchResultTab.values.map((tab) {
        final isSelected = tab == selected;
        final config = _config[tab]!;
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
                  color: isSelected ? Colors.transparent : AppColors.surfaceElevated,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    config.icon,
                    size: 18,
                    color: isSelected ? AppColors.black : Colors.white70,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    config.label,
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
