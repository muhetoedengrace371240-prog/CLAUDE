import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Catégories de contenu disponibles sur MUHETO (identiques à celles de
/// l'écran Découvrir pour rester cohérent dans tout le catalogue).
const kMuhetoCategories = [
  'Humour',
  'Musique',
  'Danse',
  'Actualité',
  'Éducation',
  'Business',
  'Cuisine',
  'Sport',
  'Culture',
  'Lifestyle',
];

/// Rangée de chips permettant de choisir une catégorie unique.
/// Sélection dorée quand active, contour discret sinon.
class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kMuhetoCategories.map((category) {
        final isSelected = category == selected;
        return GestureDetector(
          onTap: () => onSelected(category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.goldGradient : null,
              color: isSelected ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.surfaceElevated,
              ),
            ),
            child: Text(
              category,
              style: TextStyle(
                color: isSelected ? AppColors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
