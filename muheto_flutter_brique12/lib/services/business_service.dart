import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/business_model.dart';

/// Centralise les accès Firestore à la collection `businesses`.
///
/// Architecture : l'id du document est généré à l'avance via
/// [newBusinessId] (même pattern que `UploadService` pour les vidéos),
/// PAS l'uid du propriétaire directement — un compte pourra ainsi gérer
/// plusieurs fiches dans une future évolution sans migration de données.
/// En V1, `getMyBusiness` fait respecter la règle "une seule fiche par
/// utilisateur" au niveau applicatif (voir BUSINESS_FORM_README.md).
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

  /// Recherche par préfixe sur le nom, insensible à la casse grâce au champ
  /// dénormalisé `nameLower` (voir [_withNameLower]) — utilisée par la
  /// Brique 12 (Recherche globale). Pour une recherche plus fine
  /// (substring n'importe où dans le texte, tolérance aux fautes de frappe,
  /// pertinence/ranking), envisager Algolia ou Typesense en complément.
  Stream<List<BusinessModel>> searchBusinesses(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return watchBusinesses();

    return _businesses
        .orderBy('nameLower')
        .startAt([normalized])
        .endAt(['$normalized\uf8ff'])
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map(BusinessModel.fromFirestore).toList());
  }

  /// Lit une fiche business par id.
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
    return _businesses.doc(id).set(_withNameLower(business.toFirestore()));
  }

  /// Met à jour une fiche existante. Ajoute automatiquement `nameLower` si
  /// le nom fait partie de la mise à jour, pour que la recherche reste
  /// cohérente après une modification du nom du commerce.
  Future<void> updateBusiness(String businessId, Map<String, dynamic> data) {
    return _businesses.doc(businessId).update(_withNameLower(data));
  }

  /// Injecte/rafraîchit le champ dénormalisé `nameLower` (recherche
  /// insensible à la casse) à partir de `name`, sans dupliquer cette
  /// logique à chaque appelant.
  Map<String, dynamic> _withNameLower(Map<String, dynamic> data) {
    final name = data['name'] as String?;
    if (name != null) {
      data['nameLower'] = name.trim().toLowerCase();
    }
    return data;
  }

  /// Vérifie que [uid] est bien le propriétaire de [businessId] avant
  /// d'autoriser une modification côté UI (en plus des règles Firestore
  /// qui appliquent la même contrainte côté serveur, en dernier rempart).
  Future<bool> isOwner(String businessId, String uid) async {
    final doc = await _businesses.doc(businessId).get();
    return doc.data()?['ownerId'] == uid;
  }
}
