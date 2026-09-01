import 'package:cloud_firestore/cloud_firestore.dart';

/// Catégories de commerces disponibles sur la Page Business Locale.
const kBusinessCategories = [
  'Restaurant',
  'Boutique',
  'Beauté & Bien-être',
  'Santé',
  'Éducation',
  'Technologie',
  'Hôtellerie',
  'Artisanat',
  'Services',
  'Autre',
];

/// Jours de la semaine en français, dans l'ordre utilisé pour les horaires
/// (index 0 = Lundi, comme `DateTime.weekday` où 1 = Monday).
const kWeekDaysFr = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

/// Représente un document de la collection Firestore `businesses`.
///
/// Structure Firestore recommandée :
/// businesses/{businessId}
///   - ownerId: string (référence vers users/{uid}, le compte Business propriétaire)
///   - name, category, description: string
///   - logoUrl, bannerUrl: string (Firebase Storage)
///   - address, city: string
///   - phoneNumber: string (format international recommandé, ex: "+25779123456")
///   - whatsappNumber: string (optionnel, souvent identique à phoneNumber)
///   - websiteUrl, instagramUrl, facebookUrl: string (optionnels)
///   - openingHours: map<jour, "08:00-18:00" | "Fermé">
///   - isVerified: bool (badge doré vérifié)
///   - isSponsored: bool (mis en avant en tête de liste — correspond à
///     "Publicité locale ciblée" de l'offre MUHETO Business)
///   - createdAt: Timestamp
class BusinessModel {
  const BusinessModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.description,
    required this.logoUrl,
    required this.bannerUrl,
    required this.address,
    required this.city,
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.websiteUrl,
    required this.instagramUrl,
    required this.facebookUrl,
    required this.openingHours,
    required this.isVerified,
    required this.isSponsored,
    required this.createdAt,
    this.viewsCount = 0,
    this.callClicksCount = 0,
    this.websiteClicksCount = 0,
    this.whatsappClicksCount = 0,
  });

  final String id;
  final String ownerId;
  final String name;
  final String category;
  final String description;
  final String logoUrl;
  final String bannerUrl;
  final String address;
  final String city;
  final String phoneNumber;
  final String whatsappNumber;
  final String websiteUrl;
  final String instagramUrl;
  final String facebookUrl;
  final Map<String, String> openingHours;
  final bool isVerified;
  final bool isSponsored;
  final DateTime? createdAt;

  /// Compteurs analytics (Brique 13) — incrémentés automatiquement par
  /// `BusinessService` lors des interactions réelles sur la fiche.
  final int viewsCount;
  final int callClicksCount;
  final int websiteClicksCount;
  final int whatsappClicksCount;

  factory BusinessModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawHours = Map<String, dynamic>.from(data['openingHours'] as Map? ?? const {});

    return BusinessModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Autre',
      description: data['description'] as String? ?? '',
      logoUrl: data['logoUrl'] as String? ?? '',
      bannerUrl: data['bannerUrl'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? 'Bujumbura',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      whatsappNumber: data['whatsappNumber'] as String? ?? '',
      websiteUrl: data['websiteUrl'] as String? ?? '',
      instagramUrl: data['instagramUrl'] as String? ?? '',
      facebookUrl: data['facebookUrl'] as String? ?? '',
      openingHours: rawHours.map((key, value) => MapEntry(key, value as String? ?? 'Fermé')),
      isVerified: data['isVerified'] as bool? ?? false,
      isSponsored: data['isSponsored'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      viewsCount: (data['viewsCount'] as num?)?.toInt() ?? 0,
      callClicksCount: (data['callClicksCount'] as num?)?.toInt() ?? 0,
      websiteClicksCount: (data['websiteClicksCount'] as num?)?.toInt() ?? 0,
      whatsappClicksCount: (data['whatsappClicksCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      // Champ normalisé dédié à la recherche par préfixe (Brique 12) :
      // Firestore compare les chaînes par ordre d'octets, donc une requête
      // startAt/endAt sur `name` échouerait si la casse ne correspond pas
      // exactement à ce que l'utilisateur tape. `nameLower` élimine ce
      // problème une bonne fois pour toutes.
      'nameLower': name.toLowerCase(),
      'category': category,
      'description': description,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'address': address,
      'city': city,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
      'websiteUrl': websiteUrl,
      'instagramUrl': instagramUrl,
      'facebookUrl': facebookUrl,
      'openingHours': openingHours,
      'isVerified': isVerified,
      'isSponsored': isSponsored,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Calcule si le commerce est ouvert à l'instant présent, en se basant
  /// sur `openingHours` du jour courant (format "HH:mm-HH:mm" ou "Fermé").
  /// Retourne `null` si l'horaire du jour est absent ou mal formaté
  /// (auquel cas l'UI n'affiche simplement pas de badge).
  bool? get isOpenNow {
    final today = kWeekDaysFr[DateTime.now().weekday - 1];
    final todayHours = openingHours[today];
    if (todayHours == null || todayHours.toLowerCase() == 'fermé') return false;

    final parts = todayHours.split('-');
    if (parts.length != 2) return null;

    final start = _parseMinutes(parts[0].trim());
    final end = _parseMinutes(parts[1].trim());
    if (start == null || end == null) return null;

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= start && nowMinutes <= end;
  }

  static int? _parseMinutes(String hhmm) {
    final segments = hhmm.split(':');
    if (segments.length != 2) return null;
    final hours = int.tryParse(segments[0]);
    final minutes = int.tryParse(segments[1]);
    if (hours == null || minutes == null) return null;
    return hours * 60 + minutes;
  }
}
