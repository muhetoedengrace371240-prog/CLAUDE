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
  /// pour l'utilisateur, dans la langue passée en paramètre par l'écran
  /// appelant (ex: loc.t('errors.wrongPassword')).
  String friendlyErrorMessage(Object error, String Function(String) t) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return t('errors.userNotFound');
        case 'wrong-password':
        case 'invalid-credential':
          return t('errors.wrongPassword');
        case 'email-already-in-use':
          return t('errors.emailInUse');
        case 'invalid-email':
          return t('errors.invalidEmail');
        case 'weak-password':
          return t('errors.weakPassword');
        case 'network-request-failed':
          return t('errors.networkError');
        case 'too-many-requests':
          return t('errors.tooManyRequests');
        default:
          return t('errors.generic');
      }
    }
    if (error is StateError) return error.message;
    return t('errors.generic');
  }
}
