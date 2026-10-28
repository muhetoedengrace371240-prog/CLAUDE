import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/diploma_level.dart';
import '../models/field_of_study.dart';
import '../models/job_offer_model.dart';

/// Centralise les accès Firestore à la collection `jobOffers`.
///
/// ⚠️ Choix volontaire : AUCUNE requête ne combine un filtre et un tri.
/// Combiner `where` et `orderBy` sur des champs différents exige un index
/// composite à créer dans la console Firebase ; sans lui, la requête échoue
/// et l'écran affiche une liste vide sans erreur visible (c'est ce qui est
/// arrivé à la grille du profil). On trie donc par date côté Firestore avec
/// un seul `orderBy`, et on filtre (offres fermées, expirées) côté
/// application.
class JobOfferService {
  JobOfferService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _offers =>
      _db.collection('jobOffers');

  /// Nombre d'offres lues d'un coup. Les offres fermées ou expirées sont
  /// retirées APRÈS cette lecture : la liste affichée peut donc contenir
  /// moins de [_pageSize] offres.
  static const int _pageSize = 50;

  /// Offres à afficher dans la liste : les plus récentes en premier,
  /// sans les offres fermées ni expirées.
  Stream<List<JobOfferModel>> watchOffers() {
    return _offers
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(JobOfferModel.fromFirestore)
              .where((offer) => offer.isVisible)
              .toList(),
        );
  }

  /// Offres publiées par [uid], y compris fermées ou expirées (pour que le
  /// publicateur puisse les gérer). Tri par date côté application.
  Stream<List<JobOfferModel>> watchMyOffers(String uid) {
    return _offers.where('ownerId', isEqualTo: uid).snapshots().map((snap) {
      final offers = snap.docs.map(JobOfferModel.fromFirestore).toList();
      offers.sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) {
          return 0;
        }
        if (aDate == null) {
          return -1; // date serveur pas encore reçue : en premier
        }
        if (bDate == null) {
          return 1;
        }
        return bDate.compareTo(aDate);
      });
      return offers;
    });
  }

  /// Lit une offre par id (écran de détail).
  Stream<JobOfferModel?> watchOffer(String offerId) {
    return _offers.doc(offerId).snapshots().map(
          (doc) => doc.exists ? JobOfferModel.fromFirestore(doc) : null,
        );
  }

  /// Publie une offre et retourne son id. L'offre expire après
  /// [kJobOfferLifetime]. Le nom du publicateur est copié dans l'offre pour
  /// éviter une lecture supplémentaire à chaque affichage.
  /// [minDiplomaOther] n'est enregistré que si [minDiploma] vaut `other`.
  Future<String> publishOffer({
    required String title,
    required String company,
    required String city,
    required String description,
    String contactWhatsapp = '',
    DiplomaLevel? minDiploma,
    String minDiplomaOther = '',
    List<FieldOfStudy> fields = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Tu dois être connecté pour publier une offre.');
    }

    final uid = user.uid;
    final offerId = _offers.doc().id;

    final userDoc = await _db.collection('users').doc(uid).get();
    final username =
        userDoc.data()?['username'] as String? ?? user.displayName ?? '';

    final offer = JobOfferModel(
      id: offerId,
      ownerId: uid,
      ownerUsername: username,
      title: title.trim(),
      company: company.trim(),
      city: city.trim(),
      description: description.trim(),
      contactWhatsapp: contactWhatsapp.trim(),
      minDiploma: minDiploma,
      minDiplomaOther:
          minDiploma == DiplomaLevel.other ? minDiplomaOther.trim() : '',
      fields: fields,
      isActive: true,
      createdAt: null, // laisse Firestore poser un horodatage serveur fiable
      expiresAt: DateTime.now().add(kJobOfferLifetime),
    );

    await _offers.doc(offerId).set(offer.toFirestore());
    return offerId;
  }

  /// Ferme une offre : elle disparaît de la liste mais reste visible de son
  /// publicateur.
  Future<void> closeOffer(String offerId) {
    return _offers.doc(offerId).update({'isActive': false});
  }

  /// Supprime définitivement une offre.
  Future<void> deleteOffer(String offerId) {
    return _offers.doc(offerId).delete();
  }
}
