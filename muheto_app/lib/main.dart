import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/firebase/firebase_bootstrap.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/navigation/app_navigator_key.dart';
import 'core/navigation/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseBootstrap.initialize();
  } catch (_) {
    // L'application peut continuer en mode hors-ligne / sans Firebase local.
  }

  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('fr_short', timeago.FrShortMessages());
  await initializeDateFormatting('fr_FR');
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('sw_TZ');

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider()..init(),
      child: const MuhetoApp(),
    ),
  );
}

class MuhetoApp extends StatelessWidget {
  const MuhetoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    if (!localeProvider.isReady) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: Colors.black),
      );
    }

    return MaterialApp(
      title: 'MUHETO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: appNavigatorKey,
      locale: localeProvider.locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const SplashScreen(),
    );
  }
}
