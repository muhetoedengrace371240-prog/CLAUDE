import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// Les 5 destinations de la navigation principale.
/// [creer] n'est pas un "onglet" à proprement parler : il déclenche
/// l'ouverture de l'écran de création en plein écran (voir [MainNavigationShell]).
enum MuhetoTab { accueil, decouvrir, creer, boite, profil }

/// Barre de navigation basse au style MUHETO : fond noir profond,
/// icônes dorées quand sélectionnées, bouton central "+" surélevé en or plein.
class MuhetoBottomNavbar extends StatelessWidget {
  const MuhetoBottomNavbar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  /// Onglet actif parmi accueil / decouvrir / boite / profil.
  /// [MuhetoTab.creer] n'est jamais "actif" puisqu'il ouvre un écran séparé.
  final MuhetoTab currentTab;
  final ValueChanged<MuhetoTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(
          top: BorderSide(color: AppColors.surfaceElevated, width: 0.6),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavIcon(
                icon: Icons.home_rounded,
                label: loc.t('nav.home'),
                isSelected: currentTab == MuhetoTab.accueil,
                onTap: () => onTabSelected(MuhetoTab.accueil),
              ),
              _NavIcon(
                icon: Icons.explore_rounded,
                label: loc.t('nav.discover'),
                isSelected: currentTab == MuhetoTab.decouvrir,
                onTap: () => onTabSelected(MuhetoTab.decouvrir),
              ),
              _CreateButton(onTap: () => onTabSelected(MuhetoTab.creer)),
              _NavIcon(
                icon: Icons.chat_bubble_rounded,
                label: loc.t('nav.inbox'),
                isSelected: currentTab == MuhetoTab.boite,
                onTap: () => onTabSelected(MuhetoTab.boite),
              ),
              _NavIcon(
                icon: Icons.person_rounded,
                label: loc.t('nav.profile'),
                isSelected: currentTab == MuhetoTab.profil,
                onTap: () => onTabSelected(MuhetoTab.profil),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.gold : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton central "+" — cercle plein or, légèrement surélevé, sans label,
/// identique à la maquette (icône ajout de vidéo).
class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Transform.translate(
        offset: const Offset(0, -6),
        child: Container(
          width: 46,
          height: 34,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: AppColors.black, size: 26),
        ),
      ),
    );
  }
}
