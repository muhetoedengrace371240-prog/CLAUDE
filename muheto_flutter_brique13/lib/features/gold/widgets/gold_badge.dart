import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Badge VIP doré MUHETO Gold, réutilisé partout où un statut Gold doit
/// être signalé (Profil, Chat, commentaires du Feed) — cohérence visuelle
/// garantie en centralisant ce widget plutôt qu'en dupliquant l'icône.
class GoldBadge extends StatelessWidget {
  const GoldBadge({super.key, this.size = 15});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: size);
  }
}
