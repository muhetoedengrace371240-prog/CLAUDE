import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralise les actions de modération réservées aux comptes `isAdmin: true`.
/// Les règles Firestore vérifient déjà côté serveur que seul un admin peut
/// effectuer ces actions — ce service ne fait qu'appeler Firestore normalement.
class AdminService {
  AdminService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Les 30 dernières vidéos publiées, toutes confondues (pas de filtre par scope).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentVideos() {
    return _db.collection('videos').orderBy('createdAt', descending: true).limit(30).snapshots();
  }

  Future<void> deleteVideo(String videoId) {
    return _db.collection('videos').doc(videoId).delete();
  }
}