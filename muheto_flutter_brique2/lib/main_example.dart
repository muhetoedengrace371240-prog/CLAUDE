import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // généré par `flutterfire configure`

import 'core/theme/app_theme.dart';
import 'features/navigation/main_navigation_shell.dart';

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
      // Remplace par ton flow Splash → Login → Inscription une fois prêt.
      // Ici on va directement à la coquille principale pour tester la Brique 2.
      home: const MainNavigationShell(),
    );
  }
}
