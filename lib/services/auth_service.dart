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
      isAdmin: false,
      isBanned: false,
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
    /// Supprime le compte de l'utilisateur connecté après ré-authentification
  /// par mot de passe. Supprime le document Firestore `users/{uid}` puis
  /// le compte Firebase Auth.
  ///
  /// ⚠️ Ne supprime PAS en cascade les vidéos, commentaires, chats ou la
  /// fiche Business — une vraie conformité RGPD nécessiterait une Cloud
  /// Function `onDelete` côté serveur (voir la brique de suivi correspondante).
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw StateError('Aucun utilisateur connecté.');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    await _db.collection('users').doc(user.uid).delete();
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
        default:
          return 'Une erreur est survenue. Réessaie.';
      }
    }
    if (error is StateError) return error.message;
    return 'Une erreur est survenue. Réessaie.';
  }
}
