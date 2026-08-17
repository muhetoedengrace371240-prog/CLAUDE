import 'package:cloud_firestore/cloud_firestore.dart';

/// Représente un document de la collection Firestore `chats`, vu du point
/// de vue de l'utilisateur connecté (les champs "other*" désignent
/// toujours l'interlocuteur, jamais soi-même).
///
/// Structure Firestore :
/// chats/{chatId}
///   - participants: array<string>            (les 2 uid, triés)
///   - participantsInfo: map<uid, {username, avatarUrl}>  (dénormalisé)
///   - lastMessage: string
///   - lastMessageSenderId: string
///   - lastMessageAt: Timestamp
///   - unreadCounts: map<uid, number>          (compteur non-lu par utilisateur)
///   - createdAt: Timestamp
class ChatModel {
  final String id;
  final List<String> participants;

  final String otherUserId;
  final String otherUsername;
  final String otherAvatarUrl;

  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatModel({
    required this.id,
    required this.participants,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherAvatarUrl,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String currentUid,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final participants = List<String>.from(data['participants'] as List? ?? const []);
    final otherUid = participants.firstWhere(
      (id) => id != currentUid,
      orElse: () => currentUid,
    );

    final participantsInfo = Map<String, dynamic>.from(
      data['participantsInfo'] as Map? ?? const {},
    );
    final otherInfo = Map<String, dynamic>.from(
      participantsInfo[otherUid] as Map? ?? const {},
    );

    final unreadCounts = Map<String, dynamic>.from(
      data['unreadCounts'] as Map? ?? const {},
    );

    return ChatModel(
      id: doc.id,
      participants: participants,
      otherUserId: otherUid,
      otherUsername: otherInfo['username'] as String? ?? 'Utilisateur MUHETO',
      otherAvatarUrl: otherInfo['avatarUrl'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] as String? ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: (unreadCounts[currentUid] as num?)?.toInt() ?? 0,
    );
  }
}
