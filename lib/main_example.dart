import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // généré par `flutterfire configure`

import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/navigation/app_navigator_key.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';
import 'services/notification_service.dart';

/// ⚠️ Exemple d'intégration — fusionne ceci avec ton main.dart existant,
/// ne l'écrase pas (ta config Firebase / Auth est déjà en place).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Requis par la Brique 6 (Messagerie) : sans ça, timeago.format(locale: 'fr')
  // dans chat_list_tile.dart et message_bubble.dart plante au premier appel.
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('fr_short', timeago.FrShortMessages());

  // Requis par la Brique 10 (MUHETO Gold) : GoldScreen formate la date
  // d'expiration avec DateFormat('d MMMM yyyy', 'fr_FR') — sans cette
  // initialisation, l'app plante (LocaleDataException) au premier affichage
  // d'un statut Gold actif.
  await initializeDateFormatting('fr_FR');

  // Requis par la Brique 11 (Notifications Push) : enregistre le handler
  // d'arrière-plan AVANT runApp(). Doit être une fonction top-level (voir
  // le commentaire dans notification_service.dart) et Firebase doit déjà
  // être initialisé à ce stade (décommente Firebase.initializeApp() ci-dessus
  // en premier).
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    // Requis par la Brique 9 (Localisation) : LocaleProvider doit englober
    // tout MaterialApp pour que le changement de langue se propage
    // instantanément à tout l'arbre de widgets.
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

    // Tant que la langue sauvegardée n'est pas encore chargée depuis
    // SharedPreferences, on affiche un écran noir neutre (quasi instantané
    // en pratique, mais évite un flash de la mauvaise langue).
    if (!localeProvider.isReady) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: AppColors.black),
      );
    }

    return MaterialApp(
      title: 'MUHETO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Requis par la Brique 11 : permet à NotificationService de naviguer
      // depuis un callback FCM qui n'a pas de BuildContext local.
      navigatorKey: appNavigatorKey,
      locale: localeProvider.locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Le Splash décide seul, après un court instant, de rediriger vers
      // WelcomeScreen (non connecté) ou MainNavigationShell (déjà connecté).
      home: const SplashScreen(),
    );
  }
}
