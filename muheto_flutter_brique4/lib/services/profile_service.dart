import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../models/video_model.dart';

/// Centralise tous les accès Firestore liés à un profil : infos utilisateur,
/// vidéos publiées, et relation d'abonnement (follow / unfollow).
///
/// Structure Firestore additionnelle utilisée par ce service :
///   users/{uid}/followers/{followerUid}  → { createdAt }
///   users/{uid}/following/{targetUid}    → { createdAt }
///
/// Index composite requis (Firestore Console → Indexes) :
///   videos: userId ASC, createdAt DESC
class ProfileService {
  ProfileService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _videos => _db.collection('videos');

  String? get currentUid => _auth.currentUser?.uid;

  /// Flux temps réel des informations d'un utilisateur (avatar, bio,
  /// compteurs abonnés/abonnements, badge vérifié...).
  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
        );
  }

  /// Flux temps réel des vidéos publiées par un utilisateur, les plus
  /// récentes en premier — alimente la grille 3 colonnes du profil.
  Stream<List<VideoModel>> watchUserVideos(String uid) {
    return _videos
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(VideoModel.fromFirestore).toList());
  }

  /// Vérifie si l'utilisateur connecté suit déjà [targetUid].
  Stream<bool> watchIsFollowing(String targetUid) {
    final uid = currentUid;
    if (uid == null) return Stream.value(false);

    return _users
        .doc(targetUid)
        .collection('followers')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Bascule l'abonnement de l'utilisateur connecté envers [targetUid].
  /// Met à jour de façon atomique :
  ///  - users/{targetUid}/followers/{uid} + followersCount du profil ciblé
  ///  - users/{uid}/following/{targetUid} + followingCount du profil courant
  Future<bool> toggleFollow(String targetUid) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Tu dois être connecté pour suivre un créateur.');
    }
    if (uid == targetUid) {
      throw StateError('Tu ne peux pas te suivre toi-même.');
    }

    final targetRef = _users.doc(targetUid);
    final currentRef = _users.doc(uid);
    final followerRef = targetRef.collection('followers').doc(uid);
    final followingRef = currentRef.collection('following').doc(targetUid);

    return _db.runTransaction<bool>((tx) async {
      final followerSnap = await tx.get(followerRef);
      final alreadyFollowing = followerSnap.exists;

      if (alreadyFollowing) {
        tx.delete(followerRef);
        tx.delete(followingRef);
        tx.update(targetRef, {'followersCount': FieldValue.increment(-1)});
        tx.update(currentRef, {'followingCount': FieldValue.increment(-1)});
        return false;
      } else {
        tx.set(followerRef, {'userId': uid, 'createdAt': FieldValue.serverTimestamp()});
        tx.set(followingRef, {'userId': targetUid, 'createdAt': FieldValue.serverTimestamp()});
        tx.update(targetRef, {'followersCount': FieldValue.increment(1)});
        tx.update(currentRef, {'followingCount': FieldValue.increment(1)});
        return true;
      }
    });
  }

  /// Met à jour les infos éditables du profil connecté.
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (data.isEmpty) return;
    await _users.doc(uid).update(data);
  }
}
