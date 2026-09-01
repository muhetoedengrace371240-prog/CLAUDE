import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Centralise tous les accès Firestore liés à la messagerie.
///
/// L'id d'un chat est généré de façon déterministe en triant les deux uid
/// participants et en les joignant par "_" (`uid1_uid2`, toujours dans le
/// même ordre alphabétique). Ça garantit qu'il n'existe jamais deux
/// conversations différentes entre les deux mêmes personnes.
class ChatService {
  ChatService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  String? get currentUid => _auth.currentUser?.uid;

  String _buildChatId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Retourne l'id du chat entre l'utilisateur connecté et [otherUid],
  /// en créant le document Firestore s'il n'existe pas encore.
  Future<String> getOrCreateChat(String otherUid) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Tu dois être connecté pour démarrer une conversation.');
    }
    if (uid == otherUid) {
      throw StateError('Tu ne peux pas discuter avec toi-même.');
    }

    final chatId = _buildChatId(uid, otherUid);
    final chatRef = _chats.doc(chatId);
    final existing = await chatRef.get();
    if (existing.exists) return chatId;

    final currentUserDoc = await _users.doc(uid).get();
    final otherUserDoc = await _users.doc(otherUid).get();
    final currentData = currentUserDoc.data() ?? <String, dynamic>{};
    final otherData = otherUserDoc.data() ?? <String, dynamic>{};

    await chatRef.set({
      'participants': [uid, otherUid],
      'participantsInfo': {
        uid: {
          'username': currentData['username'] ?? '',
          'avatarUrl': currentData['avatarUrl'] ?? '',
        },
        otherUid: {
          'username': otherData['username'] ?? '',
          'avatarUrl': otherData['avatarUrl'] ?? '',
        },
      },
      'lastMessage': '',
      'lastMessageSenderId': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts': {uid: 0, otherUid: 0},
      'createdAt': FieldValue.serverTimestamp(),
    });

    return chatId;
  }

  /// Flux temps réel de toutes les conversations de l'utilisateur connecté,
  /// triées par dernier message envoyé (les plus récentes en premier).
  Stream<List<ChatModel>> watchUserChats() {
    final uid = currentUid;
    if (uid == null) return Stream.value(const []);

    return _chats
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ChatModel.fromFirestore(doc, uid)).toList());
  }

  /// Flux temps réel des messages d'une conversation, du plus ancien au
  /// plus récent (à afficher dans un `ListView` inversé pour un scroll
  /// naturel bas de l'écran).
  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  /// Envoie un message texte et met à jour l'aperçu + le compteur non-lu
  /// du destinataire, de façon atomique.
  Future<void> sendMessage({required String chatId, required String text}) async {
    final uid = currentUid;
    if (uid == null || text.trim().isEmpty) return;

    final chatRef = _chats.doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    final chatSnap = await chatRef.get();
    final participants = List<String>.from(
      chatSnap.data()?['participants'] as List? ?? const [],
    );
    final otherUid = participants.firstWhere((id) => id != uid, orElse: () => '');

    await _db.runTransaction((tx) async {
      tx.set(messageRef, {
        'senderId': uid,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(chatRef, {
        'lastMessage': text.trim(),
        'lastMessageSenderId': uid,
        'lastMessageAt': FieldValue.serverTimestamp(),
        if (otherUid.isNotEmpty) 'unreadCounts.$otherUid': FieldValue.increment(1),
        'unreadCounts.$uid': 0,
      });
    });
  }

  /// Remet à zéro le compteur non-lu de l'utilisateur connecté pour ce
  /// chat — à appeler à l'ouverture de l'écran de conversation.
  Future<void> markChatAsRead(String chatId) async {
    final uid = currentUid;
    if (uid == null) return;
    await _chats.doc(chatId).update({'unreadCounts.$uid': 0});
  }
}
