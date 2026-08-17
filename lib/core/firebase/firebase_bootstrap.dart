import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      if (kDebugMode) {
        debugPrint('Firebase initialized successfully.');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Firebase initialization failed: $error');
      }
      rethrow;
    }
  }
}
