import 'package:cloud_firestore/cloud_firestore.dart';

/// Univers de contenu choisi à l'onboarding ("Choisis ton univers").
enum ContentScope { burundi, afrique, monde }

ContentScope contentScopeFromString(String? value) {
  switch (value) {
    case 'afrique':
      return ContentScope.afrique;
    case 'monde':
      return ContentScope.monde;
    case 'burundi':
    default:
      return ContentScope.burundi;
  }
}

String contentScopeToString(ContentScope scope) => scope.name;

/// Représente un document de la collection Firestore `videos`.
///
/// Structure Firestore recommandée :
/// videos/{videoId}
///   - userId: string (référence vers users/{uid})
///   - videoUrl: string (Firebase Storage / CDN)
///   - thumbnailUrl: string
///   - caption: string
///   - hashtags: array<string>
///   - musicName: string
///   - category: string (ex: "humour", "musique", "business"...)
///   - scope: string ("burundi" | "afrique" | "monde")
///   - language: string ("rn" | "fr" | "en" | "sw")
///   - likesCount / commentsCount / sharesCount / viewsCount: number
///   - createdAt: Timestamp
///   - isBusinessPost: bool
class VideoModel {
  final String id;
  final String userId;
  final String username;
  final String userAvatarUrl;
  final bool isVerified;

  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final List<String> hashtags;
  final String musicName;

  final String category;
  final ContentScope scope;
  final String language;

  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;

  final DateTime? createdAt;
  final bool isBusinessPost;

  /// Mots-clés dénormalisés (légende + hashtags, minuscules) pour la
  /// recherche plein-texte (Brique 12) — voir `buildSearchKeywords`.
  final List<String> searchKeywords;

  const VideoModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.isVerified,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.hashtags,
    required this.musicName,
    required this.category,
    required this.scope,
    required this.language,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.viewsCount,
    required this.createdAt,
    required this.isBusinessPost,
    this.searchKeywords = const [],
  });

  factory VideoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return VideoModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? 'Utilisateur MUHETO',
      userAvatarUrl: data['userAvatarUrl'] as String? ?? '',
      isVerified: data['isVerified'] as bool? ?? false,
      videoUrl: data['videoUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      hashtags: List<String>.from(data['hashtags'] as List? ?? const []),
      musicName: data['musicName'] as String? ?? 'Son original - Muheto',
      category: data['category'] as String? ?? 'general',
      scope: contentScopeFromString(data['scope'] as String?),
      language: data['language'] as String? ?? 'fr',
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      sharesCount: (data['sharesCount'] as num?)?.toInt() ?? 0,
      viewsCount: (data['viewsCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isBusinessPost: data['isBusinessPost'] as bool? ?? false,
      searchKeywords: List<String>.from(data['searchKeywords'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userAvatarUrl': userAvatarUrl,
      'isVerified': isVerified,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'hashtags': hashtags,
      'musicName': musicName,
      'category': category,
      'scope': contentScopeToString(scope),
      'language': language,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'viewsCount': viewsCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isBusinessPost': isBusinessPost,
      'searchKeywords': searchKeywords,
    };
  }

  VideoModel copyWith({int? likesCount, int? commentsCount, int? sharesCount}) {
    return VideoModel(
      id: id,
      userId: userId,
      username: username,
      userAvatarUrl: userAvatarUrl,
      isVerified: isVerified,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      hashtags: hashtags,
      musicName: musicName,
      category: category,
      scope: scope,
      language: language,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount,
      createdAt: createdAt,
      isBusinessPost: isBusinessPost,
      searchKeywords: searchKeywords,
    );
  }
}
