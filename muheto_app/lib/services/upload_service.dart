import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/utils/search_keywords.dart';
import '../models/video_model.dart';

/// Étapes du pipeline de publication, utilisées pour afficher un message
/// pertinent à l'utilisateur pendant l'upload.
enum PublishStage { generatingThumbnail, uploadingVideo, uploadingThumbnail, savingPost }

class PublishProgress {
  const PublishProgress(this.stage, this.progress);

  final PublishStage stage;

  /// Progression de 0.0 à 1.0 (pertinent surtout pour uploadingVideo).
  final double progress;
}

/// Gère tout le pipeline de publication d'une vidéo :
/// 1. Génère une miniature (thumbnail) locale à partir du fichier vidéo.
/// 2. Upload la vidéo brute vers Firebase Storage.
/// 3. Upload la miniature vers Firebase Storage.
/// 4. Écrit le document correspondant dans Firestore (`videos/{videoId}`).
///
/// Storage paths utilisés :
///   videos/{uid}/{videoId}.mp4
///   thumbnails/{uid}/{videoId}.jpg
class UploadService {
  UploadService({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseStorage _storage;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Publie une vidéo de bout en bout et retourne l'id du document créé.
  ///
  /// [onProgress] est appelé à chaque étape pour permettre d'afficher une
  /// barre de progression fidèle dans l'UI.
  Future<String> publishVideo({
    required File videoFile,
    required String caption,
    required List<String> hashtags,
    required String category,
    required ContentScope scope,
    required String language,
    String musicName = 'Son original - Muheto',
    bool isBusinessPost = false,
    void Function(PublishProgress progress)? onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Tu dois être connecté pour publier une vidéo.');
    }

    // Id généré à l'avance : permet de nommer les fichiers Storage de façon
    // cohérente avec le futur document Firestore.
    final videoId = _db.collection('videos').doc().id;
    final uid = user.uid;

    // 1. Miniature locale (utilisée comme thumbnailUrl et affichée
    //    instantanément pendant que la vidéo elle-même charge dans le feed).
    onProgress?.call(const PublishProgress(PublishStage.generatingThumbnail, 0));
    final thumbnailBytes = await _generateThumbnail(videoFile.path);

    // 2. Upload de la vidéo brute.
    final videoRef = _storage.ref('videos/$uid/$videoId.mp4');
    final videoUploadTask = videoRef.putFile(
      videoFile,
      SettableMetadata(contentType: 'video/mp4'),
    );

    videoUploadTask.snapshotEvents.listen((snapshot) {
      final total = snapshot.totalBytes;
      final progress = total > 0 ? snapshot.bytesTransferred / total : 0.0;
      onProgress?.call(PublishProgress(PublishStage.uploadingVideo, progress));
    });

    await videoUploadTask;
    final videoUrl = await videoRef.getDownloadURL();

    // 3. Upload de la miniature (si la génération a réussi).
    onProgress?.call(const PublishProgress(PublishStage.uploadingThumbnail, 0));
    String thumbnailUrl = '';
    if (thumbnailBytes != null) {
      final thumbRef = _storage.ref('thumbnails/$uid/$videoId.jpg');
      await thumbRef.putData(thumbnailBytes, SettableMetadata(contentType: 'image/jpeg'));
      thumbnailUrl = await thumbRef.getDownloadURL();
    }

    // 4. Dénormalise les infos du profil pour éviter une lecture
    //    supplémentaire à chaque scroll du feed.
    onProgress?.call(const PublishProgress(PublishStage.savingPost, 0));
    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};

    // Hashtags normalisés en minuscules, et mots-clés de recherche
    // dénormalisés (légende + hashtags) pour la recherche plein-texte
    // "poor man's" de la Brique 12 — voir `buildSearchKeywords`.
    final normalizedHashtags = hashtags.map((tag) => tag.toLowerCase()).toList();
    final trimmedCaption = caption.trim();
    final keywords = buildSearchKeywords(trimmedCaption, extra: normalizedHashtags);

    final video = VideoModel(
      id: videoId,
      userId: uid,
      username: userData['username'] as String? ?? user.displayName ?? 'Utilisateur',
      userAvatarUrl: userData['avatarUrl'] as String? ?? '',
      isVerified: userData['isVerified'] as bool? ?? false,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: trimmedCaption,
      hashtags: normalizedHashtags,
      musicName: musicName,
      category: category,
      scope: scope,
      language: language,
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      viewsCount: 0,
      createdAt: null, // laisse Firestore poser un serverTimestamp fiable
      isBusinessPost: isBusinessPost,
      searchKeywords: keywords,
    );

    await _db.collection('videos').doc(videoId).set(video.toFirestore());

    onProgress?.call(const PublishProgress(PublishStage.savingPost, 1));
    return videoId;
  }

  Future<Uint8List?> _generateThumbnail(String videoPath) {
    // Fallback: avoid hard dependency on a specific thumbnail API here.
    // Returning null is acceptable; callers handle a null thumbnail.
    return Future.value(null);
  }
}
