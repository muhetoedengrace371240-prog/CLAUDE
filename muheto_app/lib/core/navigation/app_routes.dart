import 'package:flutter/material.dart';
 
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/business/business_screen.dart';
import '../../features/create/create_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/feed/feed_screen.dart';
import '../../features/gold/gold_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/inbox/inbox_screen.dart';
import '../../features/navigation/main_navigation_shell.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const feed = '/feed';
  static const discover = '/discover';
  static const create = '/create';
  static const inbox = '/inbox';
  static const profile = '/profile';
  static const settings = '/settings';
  static const business = '/business';
  static const gold = '/gold';
  static const notifications = '/notifications';
  static const search = '/search';
  static const homeShell = '/home-shell';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const MainNavigationShell());
      case AppRoutes.feed:
        return MaterialPageRoute(builder: (_) => const FeedScreen());
      case AppRoutes.discover:
        return MaterialPageRoute(builder: (_) => const DiscoverScreen());
      case AppRoutes.create:
        return MaterialPageRoute(builder: (_) => const CreateScreen());
      case AppRoutes.inbox:
        return MaterialPageRoute(builder: (_) => const InboxScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.business:
        return MaterialPageRoute(builder: (_) => const BusinessScreen());
      case AppRoutes.gold:
        return MaterialPageRoute(builder: (_) => const GoldScreen());
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case AppRoutes.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case AppRoutes.homeShell:
        return MaterialPageRoute(builder: (_) => const HomeShell());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
