import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// Rangée horizontale scrollable de chips de filtre, avec une option
/// "Tous" toujours en premier (représentée par une sélection `null`).
/// Générique — réutilisable pour n'importe quelle liste de catégories.
///
/// [labelBuilder] permet de transformer une valeur stockée (ex: "Restaurant")
/// en texte affiché traduit. Si omis, la valeur brute est affichée telle
/// quelle (comportement d'origine, utile pour des listes déjà traduites).
class ChipFilterRow extends StatelessWidget {
  const ChipFilterRow({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.labelBuilder,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String Function(String category)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final allOptions = <String?>[null, ...categories];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = allOptions[index];
          final isSelected = option == selected;
          final label = option == null
              ? loc.t('common.all')
              : (labelBuilder?.call(option) ?? option);

          return GestureDetector(
            onTap: () => onSelected(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.goldGradient : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.surfaceElevated,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}