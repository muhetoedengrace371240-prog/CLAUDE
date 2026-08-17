import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'stat_card.dart';

/// Un point de donnée du graphique : libellé court + valeur réelle.
class BarChartPoint {
  const BarChartPoint({required this.label, required this.value});

  final String label;
  final int value;
}

/// Mini graphique en barres verticales, dessiné à la main (pas de
/// dépendance externe type fl_chart — inutile pour un besoin aussi simple
/// et ça garde le bundle léger). Les barres sont dorées, hauteur
/// proportionnelle à la valeur maximale du jeu de données affiché.
///
/// ⚠️ Affiche des données RÉELLES ponctuelles (ex: vues par vidéo), pas une
/// courbe d'évolution dans le temps — Firestore ne conserve pas
/// d'historique jour par jour par défaut (voir ANALYTICS_README.md pour la
/// marche à suivre si tu veux ajouter un vrai suivi temporel plus tard).
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.points, this.height = 140});

  final List<BarChartPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Pas encore de données à afficher', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
      );
    }

    final maxValue = points.map((p) => p.value).fold<int>(0, (a, b) => a > b ? a : b);
    final safeMax = maxValue == 0 ? 1 : maxValue;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((point) {
          final barHeightFraction = point.value / safeMax;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    StatCard.formatCount(point.value),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    height: (height - 46) * barHeightFraction.clamp(0.04, 1.0),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    point.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
