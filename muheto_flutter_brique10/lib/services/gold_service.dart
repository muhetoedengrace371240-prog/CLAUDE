import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

/// Gère l'activation, le statut et l'expiration de l'abonnement MUHETO Gold.
///
/// ⚠️ IMPORTANT — portée de cette brique : aucune passerelle de paiement
/// réelle (Mobile Money, carte bancaire, Stripe...) n'est intégrée ici.
/// `startFreeTrial()` et `activateSubscription()` écrivent directement le
/// statut Gold dans Firestore, ce qui est correct pour du développement/démo
/// mais NE DOIT PAS rester tel quel en production : n'importe quel
/// utilisateur pourrait sinon s'auto-attribuer le statut Gold en appelant
/// ces méthodes sans jamais payer. Avant mise en production, remplace ces
/// deux méthodes par un appel à une Cloud Function qui vérifie une
/// confirmation de paiement (webhook du fournisseur) avant d'écrire
/// `isGoldMember`/`goldExpirationDate` — voir GOLD_README.md.
class GoldService {
  GoldService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  /// Flux temps réel du statut Gold d'un utilisateur — pratique pour animer
  /// un badge qui doit se mettre à jour sans recharger l'écran.
  Stream<UserModel?> watchGoldStatus(String uid) {
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
        );
  }

  /// Démarre l'essai gratuit de 7 jours affiché sur l'écran d'offre
  /// ("Essayer 7 jours gratuits"). Idempotent au sens où un utilisateur qui
  /// est déjà Gold verra juste sa date repoussée — à restreindre à un usage
  /// unique par utilisateur côté Cloud Function en production.
  Future<void> startFreeTrial(String uid) {
    final expiration = DateTime.now().add(const Duration(days: 7));
    return _users.doc(uid).update({
      'isGoldMember': true,
      'goldExpirationDate': Timestamp.fromDate(expiration),
    });
  }

  /// Active un abonnement payant (mensuel, 30 jours) — à appeler UNIQUEMENT
  /// après confirmation de paiement réelle en production (voir avertissement
  /// en tête de fichier). Prolonge à partir de la date d'expiration actuelle
  /// si l'utilisateur est déjà Gold et pas encore expiré, sinon à partir
  /// d'aujourd'hui.
  Future<void> activateSubscription(String uid, {Duration duration = const Duration(days: 30)}) async {
    final doc = await _users.doc(uid).get();
    final current = doc.data();
    final currentExpiration = (current?['goldExpirationDate'] as Timestamp?)?.toDate();

    final baseDate = (currentExpiration != null && currentExpiration.isAfter(DateTime.now()))
        ? currentExpiration
        : DateTime.now();

    await _users.doc(uid).update({
      'isGoldMember': true,
      'goldExpirationDate': Timestamp.fromDate(baseDate.add(duration)),
    });
  }

  /// Résilie l'abonnement immédiatement (coupe l'accès Gold sans attendre
  /// la date d'expiration).
  Future<void> cancelSubscription(String uid) {
    return _users.doc(uid).update({'isGoldMember': false});
  }
}
