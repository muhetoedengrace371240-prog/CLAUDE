import 'package:cloud_firestore/cloud_firestore.dart';

/// Structure Firestore recommandée (sous-collection) :
/// videos/{videoId}/comments/{commentId}
///   - userId, username, avatarUrl, text
///   - isGoldMember: bool (dénormalisé au moment du commentaire, pour
///     afficher le badge VIP doré sans lecture supplémentaire par commentaire)
///   - likesCount: number
///   - createdAt: Timestamp
class CommentModel {
  final String id;
  final String userId;
  final String username;
  final String avatarUrl;
  final String text;
  final bool isGoldMember;
  final int likesCount;
  final DateTime? createdAt;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.text,
    required this.isGoldMember,
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
      isGoldMember: data['isGoldMember'] as bool? ?? false,
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
      'isGoldMember': isGoldMember,
      'likesCount': likesCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
