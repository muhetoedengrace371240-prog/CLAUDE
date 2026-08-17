import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // généré par `flutterfire configure`

import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';

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
