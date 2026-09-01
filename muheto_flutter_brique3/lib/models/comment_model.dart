import 'package:cloud_firestore/cloud_firestore.dart';

/// Structure Firestore recommandée (sous-collection) :
/// videos/{videoId}/comments/{commentId}
///   - userId, username, avatarUrl, text
///   - likesCount: number
///   - createdAt: Timestamp
class CommentModel {
  final String id;
  final String userId;
  final String username;
  final String avatarUrl;
  final String text;
  final int likesCount;
  final DateTime? createdAt;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.text,
    required this.likesCount,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CommentModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      text: data['text'] as String? ?? '',
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'text': text,
      'likesCount': likesCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
