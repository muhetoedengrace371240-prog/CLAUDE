import 'package:cloud_firestore/cloud_firestore.dart';

/// Structure Firestore recommandée :
/// users/{uid}
///   - username, displayName, avatarUrl, bio
///   - isVerified: bool
///   - isBusinessAccount: bool
///   - followersCount / followingCount / likesCount: number
///   - country: string ("BI", ...)
///   - language: string ("rn" | "fr" | "en" | "sw")
///   - scope: string ("burundi" | "afrique" | "monde")
///   - isGoldMember: bool (abonnement MUHETO Gold)
///   - createdAt: Timestamp
class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final bool isVerified;
  final bool isBusinessAccount;
  final bool isGoldMember;

  final int followersCount;
  final int followingCount;
  final int likesCount;

  final String country;
  final String language;

  const UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    required this.isVerified,
    required this.isBusinessAccount,
    required this.isGoldMember,
    required this.followersCount,
    required this.followingCount,
    required this.likesCount,
    required this.country,
    required this.language,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel(
      uid: doc.id,
      username: data['username'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      isVerified: data['isVerified'] as bool? ?? false,
      isBusinessAccount: data['isBusinessAccount'] as bool? ?? false,
      isGoldMember: data['isGoldMember'] as bool? ?? false,
      followersCount: (data['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      country: data['country'] as String? ?? 'BI',
      language: data['language'] as String? ?? 'fr',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'isVerified': isVerified,
      'isBusinessAccount': isBusinessAccount,
      'isGoldMember': isGoldMember,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'likesCount': likesCount,
      'country': country,
      'language': language,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
