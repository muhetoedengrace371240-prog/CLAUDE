import 'package:cloud_firestore/cloud_firestore.dart';

import 'diploma_level.dart';
import 'field_of_study.dart';

/// Durée de vie d'une offre : passé ce délai, elle n'est plus affichée.
const kJobOfferLifetime = Duration(days: 30);

/// Représente un document de la collection Firestore `jobOffers`.
///
/// Structure Firestore :
/// jobOffers/{offerId}
///   - ownerId: string (uid du publicateur)
///   - ownerUsername: string (dénormalisé, évite une lecture par offre)
///   - title, company, city, description: string
///   - contactWhatsapp: string (optionnel)
///   - minDiploma: string | null (valeur de DiplomaLevel, absent = aucune exigence)
///   - minDiplomaOther: string (texte libre, utilisé seulement si minDiploma == other)
///   - fields: array<string> (valeurs de FieldOfStudy, vide = tous domaines)
///   - isActive: bool (le publicateur peut fermer son offre)
///   - createdAt, expiresAt: Timestamp
class JobOfferModel {
  const JobOfferModel({
    required this.id,
    required this.ownerId,
    required this.ownerUsername,
    required this.title,
    required this.company,
    required this.city,
    required this.description,
    this.contactWhatsapp = '',
    this.minDiploma,
    this.minDiplomaOther = '',
    this.fields = const [],
    this.isActive = true,
    this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String ownerId;
  final String ownerUsername;
  final String title;
  final String company;
  final String city;
  final String description;
  final String contactWhatsapp;
  final DiplomaLevel? minDiploma;
  final String minDiplomaOther;
  final List<FieldOfStudy> fields;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  factory JobOfferModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawFields = List<String>.from(data['fields'] as List? ?? const []);

    return JobOfferModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      ownerUsername: data['ownerUsername'] as String? ?? '',
      title: data['title'] as String? ?? '',
      company: data['company'] as String? ?? '',
      city: data['city'] as String? ?? '',
      description: data['description'] as String? ?? '',
      contactWhatsapp: data['contactWhatsapp'] as String? ?? '',
      minDiploma: diplomaLevelFromString(data['minDiploma'] as String?),
      minDiplomaOther: data['minDiplomaOther'] as String? ?? '',
      fields: rawFields
          .map(fieldOfStudyFromString)
          .whereType<FieldOfStudy>()
          .toList(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'ownerUsername': ownerUsername,
      'title': title,
      'company': company,
      'city': city,
      'description': description,
      'contactWhatsapp': contactWhatsapp,
      'minDiploma': minDiploma?.name,
      'minDiplomaOther': minDiplomaOther,
      'fields': fields.map((f) => f.name).toList(),
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  /// Offre expirée : à ne plus afficher.
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Offre à afficher dans la liste : ouverte et non expirée.
  bool get isVisible => isActive && !isExpired;

  /// Le diplôme de l'utilisateur suffit-il ? Si l'offre n'exige rien, si
  /// l'utilisateur n'a pas renseigné son diplôme (champ optionnel), ou si
  /// l'un des deux niveaux est "autre" (non comparable), on ne filtre pas :
  /// l'offre reste visible.
  bool isOpenToDiploma(DiplomaLevel? userDiploma) {
    final required = minDiploma;
    if (required == null || userDiploma == null) return true;
    if (!required.isComparable || !userDiploma.isComparable) return true;
    return userDiploma.index >= required.index;
  }

  /// Le domaine de l'utilisateur correspond-il ? Même principe : sans
  /// information d'un côté ou de l'autre, on ne filtre pas.
  bool isInField(FieldOfStudy? userField) {
    if (fields.isEmpty || userField == null) return true;
    return fields.contains(userField);
  }
}
