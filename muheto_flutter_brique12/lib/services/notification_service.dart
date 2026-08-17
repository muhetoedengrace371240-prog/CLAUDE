import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../core/navigation/app_navigator_key.dart';
import '../features/chat/chat_screen.dart';
import '../features/notifications/widgets/gold_notification_banner.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/single_video_screen.dart';
import 'feed_service.dart';

/// Types de notification supportés — doivent correspondre exactement à la
/// valeur du champ `type` envoyé dans le payload `data` par les Cloud
/// Functions (voir `functions/index.js`).
enum MuhetoNotificationType { chat, comment, follow, unknown }

MuhetoNotificationType _typeFromString(String? value) {
  switch (value) {
    case 'chat':
      return MuhetoNotificationType.chat;
    case 'comment':
      return MuhetoNotificationType.comment;
    case 'follow':
      return MuhetoNotificationType.follow;
    default:
      return MuhetoNotificationType.unknown;
  }
}

/// ⚠️ IMPORTANT : cette fonction doit être une fonction de NIVEAU FICHIER
/// (top-level), pas une méthode de classe — c'est une contrainte de
/// `firebase_messaging` : le handler d'arrière-plan tourne dans un isolate
/// séparé et Flutter doit pouvoir le retrouver par référence statique.
/// L'annotation `@pragma('vm:entry-point')` empêche le compilateur Dart de
/// la supprimer en mode release (tree-shaking) puisqu'elle semble "jamais
/// appelée" depuis le code visible.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ce handler tourne même si l'app est fermée. On ne fait volontairement
  // rien de lourd ici : Android/iOS affichent déjà la notification système
  // automatiquement tant que le payload contient un bloc `notification`
  // (voir les Cloud Functions) — ce handler ne sert qu'à des traitements
  // additionnels optionnels (ex: mise à jour d'un compteur local).
  // Note : Firebase.initializeApp() doit avoir été appelé avant d'enregistrer
  // ce handler dans main() ; comme il tourne dans un isolate séparé, il ne
  // partage pas l'état déjà initialisé du isolate principal et doit refaire
  // l'initialisation si jamais il a besoin d'accéder à Firebase ici.
}

/// Centralise toute la logique FCM : permissions, token, écoute des
/// messages en premier plan/arrière-plan, et navigation au clic sur une
/// notification.
class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _feedService = FeedService();

  /// À appeler une fois, juste après que l'utilisateur soit authentifié
  /// (ex: dans `initState()` de `MainNavigationShell`). Demande la
  /// permission d'envoyer des notifications, récupère le token FCM actuel,
  /// l'enregistre dans Firestore, et se ré-enregistre automatiquement si le
  /// token change (désinstallation/réinstallation, changement d'appareil...).
  Future<void> registerDeviceToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null) {
      await _saveToken(uid, token);
    }

    // Se déclenche si le token change pendant que l'app tourne — sans ça,
    // l'app pourrait continuer à envoyer des notifications vers un token
    // périmé après un certain temps.
    messaging.onTokenRefresh.listen((newToken) => _saveToken(uid, newToken));
  }

  Future<void> _saveToken(String uid, String token) {
    return _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  /// Supprime le token au moment de la déconnexion, pour éviter d'envoyer
  /// des notifications à un appareil sur lequel plus personne n'est
  /// identifié comme cet utilisateur.
  Future<void> clearDeviceToken(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({'fcmToken': FieldValue.delete()});
    } catch (_) {
      // Pas bloquant si ça échoue (ex: déjà déconnecté) — on n'interrompt
      // jamais un flux de déconnexion pour ça.
    }
  }

  /// Configure l'écoute des messages qui arrivent alors que l'app est
  /// **au premier plan** : FCM n'affiche jamais de notification système
  /// dans ce cas, donc on affiche notre propre bannière dorée, tappable
  /// pour naviguer directement vers le bon écran.
  void listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      showGoldNotificationBanner(
        appNavigatorKey,
        title: notification.title ?? 'MUHETO',
        body: notification.body ?? '',
        onTap: () => _navigateFromMessage(message),
      );
    });
  }

  /// Cas où l'app était en **arrière-plan** (pas fermée) et l'utilisateur
  /// tape sur la notification système pour revenir dans l'app — FCM
  /// notifie ce retour via `onMessageOpenedApp`.
  void listenNotificationTapWhileBackgrounded() {
    FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromMessage);
  }

  /// Cas où l'app était **totalement fermée** et a été ouverte directement
  /// en tapant sur la notification (cold start). À appeler une fois après
  /// le premier `runApp()`, quand la navigation est prête à recevoir un
  /// `push` (ex: dans `initState()` de `MainNavigationShell`).
  Future<void> handleInitialMessageIfAny() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Petit délai pour laisser le premier écran finir de se construire
      // avant de pousser une nouvelle route par-dessus.
      await Future.delayed(const Duration(milliseconds: 400));
      _navigateFromMessage(initialMessage);
    }
  }

  /// Lit `message.data['type']` et pousse l'écran correspondant via la
  /// clé de navigation globale (fonctionne même sans `BuildContext` local).
  Future<void> _navigateFromMessage(RemoteMessage message) async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    final data = message.data;
    final type = _typeFromString(data['type'] as String?);

    switch (type) {
      case MuhetoNotificationType.chat:
        final chatId = data['chatId'] as String?;
        final otherUserId = data['otherUserId'] as String?;
        if (chatId == null || otherUserId == null) return;
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUserId: otherUserId,
              otherUsername: data['otherUsername'] as String? ?? 'Utilisateur MUHETO',
              otherAvatarUrl: data['otherAvatarUrl'] as String? ?? '',
            ),
          ),
        );
        break;

      case MuhetoNotificationType.follow:
        final followerId = data['followerId'] as String?;
        if (followerId == null) return;
        navigator.push(
          MaterialPageRoute(builder: (_) => ProfileScreen(uid: followerId)),
        );
        break;

      case MuhetoNotificationType.comment:
        final videoId = data['videoId'] as String?;
        if (videoId == null) return;
        final video = await _feedService.getVideoOnce(videoId);
        if (video == null) return;
        navigator.push(
          MaterialPageRoute(builder: (_) => SingleVideoScreen(video: video)),
        );
        break;

      case MuhetoNotificationType.unknown:
        break;
    }
  }
}
