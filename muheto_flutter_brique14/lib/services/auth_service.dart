import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

/// Centralise toute la logique Firebase Auth + la création du document
/// Firestore `users/{uid}` associé, pour que chaque compte ait toujours
/// un profil exploitable dès l'inscription.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  User? get currentUser => _auth.currentUser;

  /// Flux de l'état de connexion — utilisé par le Splash / routeur racine
  /// pour rediriger automatiquement vers le Feed ou vers l'écran Welcome.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  /// Crée le compte Firebase Auth PUIS le document `users/{uid}` associé.
  /// Vérifie au préalable que le pseudonyme n'est pas déjà pris.
  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();

    if (await _isUsernameTaken(normalizedUsername)) {
      throw StateError('Ce pseudonyme est déjà utilisé, choisis-en un autre.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    await credential.user!.updateDisplayName(normalizedUsername);

    final newUser = UserModel(
      uid: uid,
      username: normalizedUsername,
      displayName: username.trim(),
      avatarUrl: '',
      bio: '',
      isVerified: false,
      isBusinessAccount: false,
      isGoldMember: false,
      goldExpirationDate: null,
      followersCount: 0,
      followingCount: 0,
      likesCount: 0,
      country: 'BI',
      language: 'fr',
    );

    await _db.collection('users').doc(uid).set(newUser.toFirestore());
  }

  Future<bool> _isUsernameTaken(String username) async {
    final snap = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  /// Supprime définitivement le compte : ré-authentifie d'abord
  /// l'utilisateur avec son mot de passe (Firebase exige une session
  /// "récente" pour les opérations sensibles comme la suppression de
  /// compte — sans ça, `user.delete()` échoue avec `requires-recent-login`
  /// si la dernière connexion date de plus de quelques minutes).
  ///
  /// ⚠️ Ne supprime QUE le document `users/{uid}` et le compte Firebase
  /// Auth lui-même. Les vidéos, commentaires, messages et fiches Business
  /// de l'utilisateur restent en base (orphelins, `userId` pointant vers
  /// un compte qui n'existe plus plutôt que d'être supprimés en cascade).
  /// Un nettoyage en cascade complet nécessite une Cloud Function dédiée
  /// (voir SETTINGS_README.md) — le faire depuis le client serait lent,
  /// risqué en cas d'interruption, et nécessiterait des règles Firestore
  /// bien plus permissives que souhaitable.
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw StateError('Aucun utilisateur connecté.');
    }

    final credential = EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(credential);

    final uid = user.uid;
    await _db.collection('users').doc(uid).delete();
    await user.delete();
  }

  /// Transforme les codes d'erreur Firebase en messages compréhensibles
  /// pour l'utilisateur, en français.
  String friendlyErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Aucun compte ne correspond à cette adresse email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email ou mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Un compte existe déjà avec cette adresse email.';
        case 'invalid-email':
          return 'Adresse email invalide.';
        case 'weak-password':
          return 'Mot de passe trop faible (6 caractères minimum).';
        case 'network-request-failed':
          return 'Problème de connexion. Vérifie ton réseau.';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessaie dans quelques instants.';
        case 'requires-recent-login':
          return 'Reconnecte-toi puis réessaie cette action sensible.';
        default:
          return 'Une erreur est survenue. Réessaie.';
      }
    }
    if (error is StateError) return error.message;
    return 'Une erreur est survenue. Réessaie.';
  }
}
