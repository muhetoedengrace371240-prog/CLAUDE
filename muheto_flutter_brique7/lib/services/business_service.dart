import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/business_model.dart';

/// Centralise les accès Firestore à la collection `businesses`.
///
/// Index composite requis (Firestore Console → Indexes) si tu combines le
/// filtre par catégorie avec le tri :
///   businesses: category ASC, isSponsored DESC, createdAt DESC
class BusinessService {
  BusinessService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _businesses => _db.collection('businesses');

  /// Flux temps réel des commerces, triés avec les partenaires sponsorisés
  /// en tête de liste, puis du plus récent au plus ancien.
  /// Filtre par [category] si fourni (`null` = toutes catégories).
  Stream<List<BusinessModel>> watchBusinesses({String? category}) {
    Query<Map<String, dynamic>> query = _businesses
        .orderBy('isSponsored', descending: true)
        .orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map(BusinessModel.fromFirestore).toList(),
        );
  }

  /// Recherche simple par nom (préfixe), insensible à la casse si le champ
  /// `name` est stocké normalisé côté écriture — sinon utile pour un
  /// préfixe exact. Pour une recherche plus fine, envisager Algolia/Typesense.
  Stream<List<BusinessModel>> searchBusinesses(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return watchBusinesses();

    return _businesses
        .orderBy('name')
        .startAt([normalized])
        .endAt(['$normalized\uf8ff'])
        .snapshots()
        .map((snap) => snap.docs.map(BusinessModel.fromFirestore).toList());
  }

  Stream<BusinessModel?> watchBusiness(String businessId) {
    return _businesses.doc(businessId).snapshots().map(
          (doc) => doc.exists ? BusinessModel.fromFirestore(doc) : null,
        );
  }

  /// Crée une nouvelle fiche Business (à utiliser depuis le futur écran
  /// "Créer ma page Business", réservé aux comptes Business).
  Future<String> createBusiness(BusinessModel business) async {
    final docRef = await _businesses.add(business.toFirestore());
    return docRef.id;
  }

  Future<void> updateBusiness(String businessId, Map<String, dynamic> data) {
    return _businesses.doc(businessId).update(data);
  }
}
