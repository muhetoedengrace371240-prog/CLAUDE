import 'package:flutter/material.dart';

import '../../models/video_model.dart';
import '../../services/notification_service.dart';
import '../create/create_screen.dart';
import '../discover/discover_screen.dart';
import '../feed/feed_screen.dart';
import '../inbox/inbox_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/muheto_bottom_navbar.dart';

/// Coquille de navigation principale de MUHETO.
///
/// Utilise un [IndexedStack] pour les 4 vrais onglets (Accueil, Découvrir,
/// Boîte, Profil) : chaque écran reste "en vie" en arrière-plan (le feed ne
/// recharge pas ses vidéos ni ne perd sa position de scroll en changeant
/// d'onglet). Le bouton central "+" ne fait PAS partie du IndexedStack : il
/// pousse [CreateScreen] en plein écran par-dessus, comme sur TikTok.
///
/// À placer comme `home:` de ton `MaterialApp` une fois l'utilisateur
/// authentifié (après le flow Login/Inscription de la Brique 1bis).
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key, this.feedScope});

  /// Univers choisi à l'onboarding, transmis au [FeedScreen].
  final ContentScope? feedScope;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  MuhetoTab _currentTab = MuhetoTab.accueil;
  final _notificationService = NotificationService();

  // Index dans l'IndexedStack pour chacun des 4 vrais onglets.
  static const _tabToIndex = {
    MuhetoTab.accueil: 0,
    MuhetoTab.decouvrir: 1,
    MuhetoTab.boite: 2,
    MuhetoTab.profil: 3,
  };

  late final List<Widget> _tabScreens = [
    FeedScreen(scope: widget.feedScope),
    const DiscoverScreen(),
    const InboxScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Brique 11 (Notifications Push) : ce widget n'est affiché QUE lorsque
    // l'utilisateur est authentifié — c'est donc le bon endroit pour
    // demander la permission, récupérer/sauvegarder le token FCM, et gérer
    // le cas où l'app a été ouverte directement depuis une notification
    // (cold start).
    _notificationService.registerDeviceToken();
    _notificationService.listenForegroundMessages();
    _notificationService.listenNotificationTapWhileBackgrounded();
    _notificationService.handleInitialMessageIfAny();
  }

  void _handleTabSelected(MuhetoTab tab) {
    if (tab == MuhetoTab.creer) {
      _openCreateScreen();
      return;
    }
    setState(() => _currentTab = tab);
  }

  Future<void> _openCreateScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateScreen(),
        fullscreenDialog: true,
      ),
    );
    // L'onglet actif ne change pas au retour : on reste là où on était.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabToIndex[_currentTab] ?? 0,
        children: _tabScreens,
      ),
      bottomNavigationBar: MuhetoBottomNavbar(
        currentTab: _currentTab,
        onTabSelected: _handleTabSelected,
      ),
    );
  }
}
