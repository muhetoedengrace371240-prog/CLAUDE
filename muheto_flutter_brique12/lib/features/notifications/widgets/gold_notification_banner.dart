import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Bannière dorée affichée en haut de l'écran quand une notification arrive
/// alors que l'app est déjà ouverte (premier plan). FCM n'affiche jamais de
/// notification système automatique dans ce cas — c'est à l'app de montrer
/// quelque chose, d'où cette bannière custom cohérente avec la charte
/// Noir & Or plutôt qu'un SnackBar Material générique.
///
/// Usage : [showGoldNotificationBanner] insère la bannière dans l'[Overlay]
/// racine (via `appNavigatorKey`), donc fonctionne même sans `BuildContext`
/// d'écran précis.
class GoldNotificationBanner extends StatefulWidget {
  const GoldNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    required this.onDismiss,
    this.onTap,
    this.leadingImageUrl,
  });

  final String title;
  final String body;
  final String? leadingImageUrl;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  @override
  State<GoldNotificationBanner> createState() => _GoldNotificationBannerState();
}

class _GoldNotificationBannerState extends State<GoldNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, -1.2),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _autoDismissTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SlideTransition(
        position: _offset,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                widget.onTap?.call();
                _dismiss();
              },
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) < 0) _dismiss();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: AppColors.goldGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_rounded, color: AppColors.black, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Insère la bannière dans l'Overlay racine de l'app (via `appNavigatorKey`)
/// et la retire automatiquement après sa propre animation de sortie.
void showGoldNotificationBanner(
  GlobalKey<NavigatorState> navigatorKey, {
  required String title,
  required String body,
  VoidCallback? onTap,
  String? leadingImageUrl,
}) {
  final overlayState = navigatorKey.currentState?.overlay;
  if (overlayState == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: GoldNotificationBanner(
        title: title,
        body: body,
        leadingImageUrl: leadingImageUrl,
        onTap: onTap,
        onDismiss: () => entry.remove(),
      ),
    ),
  );

  overlayState.insert(entry);
}
