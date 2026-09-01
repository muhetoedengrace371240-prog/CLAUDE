import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/business_model.dart';

/// Centralise les accès Firestore à la collection `businesses`.
///
/// ⚠️ Depuis la Brique 8 : l'id du document business est TOUJOURS l'uid du
/// compte propriétaire (`businesses/{ownerId}`), et non plus un id généré
/// aléatoirement. Conséquences volontaires :
///  - un compte ne peut avoir qu'une seule page Business (V1) ;
///  - vérifier/mettre à jour "sa" page ne nécessite plus de requête `where`,
///    juste une lecture directe par id — plus rapide et moins coûteux ;
///  - les règles de sécurité Firestore deviennent triviales : il suffit de
///    comparer `request.auth.uid` à l'id du document (voir BUSINESS_README.md).
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

  /// Lit une fiche business par id (id de document = uid du propriétaire).
  Stream<BusinessModel?> watchBusiness(String businessId) {
    return _businesses.doc(businessId).snapshots().map(
          (doc) => doc.exists ? BusinessModel.fromFirestore(doc) : null,
        );
  }

  /// Retourne la fiche Business déjà créée par [uid], s'il en a une.
  /// Utilisé par le bouton "Ma page" pour savoir s'il faut ouvrir le
  /// formulaire en mode création ou en mode édition (une seule fiche par
  /// utilisateur en V1).
  Future<BusinessModel?> getMyBusiness(String uid) async {
    final snap = await _businesses.where('ownerId', isEqualTo: uid).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return BusinessModel.fromFirestore(snap.docs.first);
  }

  /// Génère un id de document à l'avance — utile pour uploader le logo et
  /// la bannière vers Storage avec un chemin cohérent avant même que le
  /// document Firestore existe (même pattern que `UploadService`).
  String newBusinessId() => _businesses.doc().id;

  /// Crée la fiche à l'id pré-généré par [newBusinessId]. Échoue via les
  /// règles de sécurité si `business.ownerId` ne correspond pas à
  /// l'utilisateur connecté (voir `firestore.rules`).
  Future<void> createBusinessWithId(String id, BusinessModel business) {
    return _businesses.doc(id).set(business.toFirestore());
  }

  /// Vérifie que [uid] est bien le propriétaire de [businessId] avant
  /// d'autoriser une modification côté UI (en plus des règles Firestore
  /// qui appliquent la même contrainte côté serveur, en dernier rempart).
  Future<bool> isOwner(String businessId, String uid) async {
    final doc = await _businesses.doc(businessId).get();
    return doc.data()?['ownerId'] == uid;
  }

  /// Alias explicite utilisé par l'écran de création/édition : la page
  /// Business (unique) de l'utilisateur connecté, si elle existe déjà.
  Future<BusinessModel?> getMyBusiness(String uid) async {
    final doc = await _businesses.doc(uid).get();
    return doc.exists ? BusinessModel.fromFirestore(doc) : null;
  }

  /// Crée OU met à jour la page Business de [business.ownerId] en une seule
  /// écriture (l'id du document est toujours `business.ownerId`).
  Future<void> saveBusiness(BusinessModel business) {
    return _businesses.doc(business.ownerId).set(business.toFirestore());
  }
}
