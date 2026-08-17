import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/video_model.dart';

/// Sélecteur segmenté pour choisir l'univers de diffusion de la vidéo
/// (mêmes 3 options que l'onboarding "Choisis ton univers").
class ScopeSelector extends StatelessWidget {
  const ScopeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ContentScope selected;
  final ValueChanged<ContentScope> onSelected;

  static const _labels = {
    ContentScope.burundi: 'Burundi',
    ContentScope.afrique: 'Afrique',
    ContentScope.monde: 'Monde',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ContentScope.values.map((scope) {
        final isSelected = scope == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(scope),
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
              alignment: Alignment.center,
              child: Text(
                _labels[scope]!,
                style: TextStyle(
                  color: isSelected ? AppColors.black : Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
