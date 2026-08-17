import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // généré par `flutterfire configure`

import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';

/// ⚠️ Exemple d'intégration — fusionne ceci avec ton main.dart existant,
/// ne l'écrase pas (ta config Firebase / Auth est déjà en place).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(const MuhetoApp());
}

class MuhetoApp extends StatelessWidget {
  const MuhetoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MUHETO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Le Splash décide seul, après un court instant, de rediriger vers
      // WelcomeScreen (non connecté) ou MainNavigationShell (déjà connecté).
      home: const SplashScreen(),
    );
  }
}
