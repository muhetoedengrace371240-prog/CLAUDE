import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/comment_model.dart';
import '../models/video_model.dart';

/// Centralise tous les accès Firestore liés au Feed (collection `videos`).
///
/// Indexes composites Firestore à créer côté console (Firestore > Indexes)
/// si tu combines `scope` + `orderBy(createdAt)` :
///   videos: scope ASC, createdAt DESC
class FeedService {
  FeedService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _videos => _db.collection('videos');

  String? get _currentUid => _auth.currentUser?.uid;

  /// Lecture ponctuelle d'une vidéo par id — utilisée notamment par le
  /// deep-link depuis une notification "nouveau commentaire" (Brique 11),
  /// pour ouvrir directement la vidéo concernée sans écouter tout le feed.
  Future<VideoModel?> getVideoOnce(String videoId) async {
    final doc = await _videos.doc(videoId).get();
    return doc.exists ? VideoModel.fromFirestore(doc) : null;
  }

  /// Flux temps réel du feed "Pour Toi", filtré par univers (scope) si fourni.
  /// [pageSize] limite le nombre de documents chargés d'un coup ; on
  /// complète via [fetchMoreVideos] pour la pagination infinie.
  Stream<List<VideoModel>> watchFeed({ContentScope? scope, int pageSize = 10}) {
    Query<Map<String, dynamic>> query = _videos.orderBy('createdAt', descending: true);

    if (scope != null) {
      query = query.where('scope', isEqualTo: contentScopeToString(scope));
    }

    return query.limit(pageSize).snapshots().map(
          (snap) => snap.docs.map(VideoModel.fromFirestore).toList(),
        );
  }

  /// Pagination "charger plus" à utiliser quand l'utilisateur approche de
  /// la fin de la pile de vidéos déjà chargées.
  Future<List<VideoModel>> fetchMoreVideos({
    required DateTime after,
    ContentScope? scope,
    int pageSize = 10,
  }) async {
    Query<Map<String, dynamic>> query = _videos
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(after)])
        .limit(pageSize);

    if (scope != null) {
      query = query.where('scope', isEqualTo: contentScopeToString(scope));
    }

    final snap = await query.get();
    return snap.docs.map(VideoModel.fromFirestore).toList();
  }

  /// Bascule le like d'une vidéo pour l'utilisateur connecté.
  /// Le like est tracé dans videos/{id}/likes/{uid} pour éviter les doublons,
  /// et likesCount est incrémenté/décrémenté de façon atomique.
  Future<bool> toggleLike(String videoId) async {
    final uid = _currentUid;
    if (uid == null) {
      throw StateError('Utilisateur non connecté.');
    }

    final videoRef = _videos.doc(videoId);
    final likeRef = videoRef.collection('likes').doc(uid);

    return _db.runTransaction<bool>((tx) async {
      final likeSnap = await tx.get(likeRef);
      final alreadyLiked = likeSnap.exists;

      if (alreadyLiked) {
        tx.delete(likeRef);
        tx.update(videoRef, {'likesCount': FieldValue.increment(-1)});
        return false;
      } else {
        tx.set(likeRef, {'userId': uid, 'createdAt': FieldValue.serverTimestamp()});
        tx.update(videoRef, {'likesCount': FieldValue.increment(1)});
        return true;
      }
    });
  }

  /// Vérifie si l'utilisateur connecté a déjà liké la vidéo.
  Stream<bool> watchIsLiked(String videoId) {
    final uid = _currentUid;
    if (uid == null) return Stream.value(false);

    return _videos
        .doc(videoId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Incrémente le compteur de vues (à appeler quand une vidéo devient
  /// visible à > 60% de l'écran pendant au moins 1-2 secondes).
  Future<void> registerView(String videoId) {
    return _videos.doc(videoId).update({'viewsCount': FieldValue.increment(1)});
  }

  /// Incrémente le compteur de partages.
  Future<void> registerShare(String videoId) {
    return _videos.doc(videoId).update({'sharesCount': FieldValue.increment(1)});
  }

  /// Flux des commentaires d'une vidéo, du plus récent au plus ancien.
  Stream<List<CommentModel>> watchComments(String videoId) {
    return _videos
        .doc(videoId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CommentModel.fromFirestore).toList());
  }

  /// Ajoute un commentaire et incrémente commentsCount de façon atomique.
  Future<void> addComment(String videoId, CommentModel comment) async {
    final videoRef = _videos.doc(videoId);
    final commentRef = videoRef.collection('comments').doc();

    await _db.runTransaction((tx) async {
      tx.set(commentRef, comment.toFirestore());
      tx.update(videoRef, {'commentsCount': FieldValue.increment(1)});
    });
  }
}
