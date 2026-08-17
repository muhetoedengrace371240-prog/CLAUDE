import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/search_keywords.dart';
import '../models/user_model.dart';
import '../models/video_model.dart';

/// Service de recherche globale (Brique 12) : utilisateurs et vidéos.
/// La recherche de commerces reste dans `BusinessService.searchBusinesses`
/// (déjà écrite en Brique 7, corrigée en Brique 12 pour utiliser un champ
/// normalisé `nameLower`) — `SearchScreen` combine les trois selon l'onglet
/// actif.
///
/// ⚠️ Il s'agit d'une recherche par PRÉFIXE / MOTS-CLÉS, PAS d'une vraie
/// recherche plein-texte (Firestore n'en propose pas nativement) : pas de
/// tolérance aux fautes de frappe, pas de classement par pertinence
/// au-delà de l'ordre de tri choisi. C'est un choix pragmatique pour rester
/// 100% Firestore sans service tiers. Pour une recherche plus avancée à
/// plus grande échelle (tolérance aux fautes, pertinence, recherche
/// combinée multi-champs), la marche à suivre standard est d'indexer les
/// données dans Algolia ou Typesense en parallèle de Firestore.
class SearchService {
  SearchService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Recherche des utilisateurs par préfixe de pseudonyme. Les pseudos sont
  /// stockés normalisés en minuscules depuis la Brique 5 (`AuthService`),
  /// donc la comparaison Firestore (sensible à la casse) fonctionne
  /// correctement tant qu'on lowercase aussi la requête ici.
  Stream<List<UserModel>> searchUsers(String query) {
    final normalized = query.trim().toLowerCase().replaceFirst('@', '');
    if (normalized.isEmpty) return Stream.value(const []);

    return _db
        .collection('users')
        .orderBy('username')
        .startAt([normalized])
        .endAt(['$normalized\uf8ff'])
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  /// Recherche des vidéos :
  /// - si la requête commence par `#`, correspondance exacte sur un hashtag
  ///   (`arrayContains`) — les hashtags sont stockés en minuscules depuis
  ///   la Brique 3 (voir `UploadService`).
  /// - sinon, correspondance sur `searchKeywords` (`arrayContainsAny`), le
  ///   tableau de mots-clés dénormalisé à la publication à partir de la
  ///   légende + des hashtags (voir `core/utils/search_keywords.dart`) —
  ///   permet une recherche multi-mots sans dépendre d'un service tiers.
  ///
  /// ⚠️ Seules les vidéos publiées APRÈS la Brique 12 possèdent le champ
  /// `searchKeywords` (calculé par `UploadService` à l'écriture). Les
  /// vidéos publiées avant ne remonteront pas dans cette recherche tant
  /// qu'un script de backfill ne leur aura pas ajouté ce champ
  /// rétroactivement (voir `SEARCH_README.md`).
  Stream<List<VideoModel>> searchVideos(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Stream.value(const []);

    if (trimmed.startsWith('#')) {
      final tag = trimmed.toLowerCase();
      return _db
          .collection('videos')
          .where('hashtags', arrayContains: tag)
          .limit(20)
          .snapshots()
          .map((snap) => _sortByCreatedAtDesc(snap.docs.map(VideoModel.fromFirestore).toList()));
    }

    final keywords = parseSearchQuery(trimmed);
    if (keywords.isEmpty) return Stream.value(const []);

    return _db
        .collection('videos')
        .where('searchKeywords', arrayContainsAny: keywords)
        .limit(20)
        .snapshots()
        .map((snap) => _sortByCreatedAtDesc(snap.docs.map(VideoModel.fromFirestore).toList()));
  }

  /// `arrayContains`/`arrayContainsAny` ne peuvent pas être combinés à un
  /// `orderBy` sur un champ différent sans index composite dédié — on trie
  /// donc côté client par date décroissante, ce qui reste tout à fait
  /// raisonnable pour un lot de résultats limité à 20.
  List<VideoModel> _sortByCreatedAtDesc(List<VideoModel> videos) {
    videos.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) return 0;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return videos;
  }
}
