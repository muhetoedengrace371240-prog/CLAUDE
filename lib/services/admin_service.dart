import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralise les actions de modération réservées aux comptes `isAdmin: true`.
/// Les règles Firestore vérifient déjà côté serveur que seul un admin peut
/// effectuer ces actions — ce service ne fait qu'appeler Firestore normalement.
class AdminService {
  AdminService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // --- Vidéos ---

  /// Les 30 dernières vidéos publiées, toutes confondues (pas de filtre par scope).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentVideos() {
    return _db.collection('videos').orderBy('createdAt', descending: true).limit(30).snapshots();
  }

  Future<void> deleteVideo(String videoId) {
    return _db.collection('videos').doc(videoId).delete();
  }

  // --- Utilisateurs ---

  /// Les 50 derniers comptes créés.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() {
    return _db.collection('users').orderBy('createdAt', descending: true).limit(50).snapshots();
  }

  Future<void> setBanned(String uid, bool isBanned) {
    return _db.collection('users').doc(uid).update({'isBanned': isBanned});
  }

  // --- Fiches Business ---

  /// Les 30 dernières fiches Business créées.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchBusinesses() {
    return _db.collection('businesses').orderBy('createdAt', descending: true).limit(30).snapshots();
  }

  Future<void> deleteBusiness(String businessId) {
    return _db.collection('businesses').doc(businessId).delete();
  }
}