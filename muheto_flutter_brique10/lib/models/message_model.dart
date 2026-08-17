import 'package:cloud_firestore/cloud_firestore.dart';

/// Structure Firestore :
/// chats/{chatId}/messages/{messageId}
///   - senderId: string
///   - text: string
///   - createdAt: Timestamp
class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
