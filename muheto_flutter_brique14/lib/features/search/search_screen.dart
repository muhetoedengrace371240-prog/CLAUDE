import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/business_model.dart';
import '../../models/user_model.dart';
import '../../models/video_model.dart';
import '../../services/business_service.dart';
import '../../services/search_service.dart';
import '../business/business_detail_screen.dart';
import '../business/widgets/business_card.dart';
import '../profile/profile_screen.dart';
import '../profile/single_video_screen.dart';
import '../profile/widgets/video_grid_tile.dart';
import 'widgets/search_tab_selector.dart';
import 'widgets/user_result_tile.dart';

/// Écran de recherche globale : utilisateurs/créateurs, vidéos, et pages
/// Business — un seul champ de recherche, un filtre par catégorie pour
/// choisir quelle collection interroger.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialTab = SearchResultTab.users});

  /// Onglet ouvert par défaut — pratique pour arriver directement sur
  /// "Business" depuis l'icône de recherche de `BusinessScreen`.
  final SearchResultTab initialTab;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchService = SearchService();
  final _businessService = BusinessService();
  final _controller = TextEditingController();

  late SearchResultTab _selectedTab = widget.initialTab;

  // Le debounce évite de lancer une requête Firestore à chaque frappe —
  // on attend que l'utilisateur arrête de taper pendant 350ms.
  Timer? _debounceTimer;
  String _debouncedQuery = '';

  @override
  void initState() {
    super.initState();
    // Focus automatique dès l'ouverture de l'écran — l'utilisateur arrive
    // ici pour taper immédiatement, pas pour regarder un écran vide.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  final _focusNode = FocusNode();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          onChanged: _onQueryChanged,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).t('search.hint'),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold, size: 20),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                    onPressed: () {
                      _controller.clear();
                      _onQueryChanged('');
                    },
                  )
                : null,
            isDense: true,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchTabSelector(
              selected: _selectedTab,
              onSelected: (tab) => setState(() => _selectedTab = tab),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_debouncedQuery.isEmpty) {
      return const _SearchPrompt();
    }

    switch (_selectedTab) {
      case SearchResultTab.users:
        return _UserResults(query: _debouncedQuery, searchService: _searchService);
      case SearchResultTab.videos:
        return _VideoResults(query: _debouncedQuery, searchService: _searchService);
      case SearchResultTab.business:
        return _BusinessResults(query: _debouncedQuery, businessService: _businessService);
    }
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.travel_explore_rounded, color: AppColors.textMuted, size: 42),
            SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).t('search.prompt'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 38),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserResults extends StatelessWidget {
  const _UserResults({required this.query, required this.searchService});

  final String query;
  final SearchService searchService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: searchService.searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }
        final users = snapshot.data ?? const [];
        if (users.isEmpty) {
          return _EmptyResult(
            message: AppLocalizations.of(context).t('search.noUsers', {'query': query}),
          );
        }
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return UserResultTile(
              user: user,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProfileScreen(uid: user.uid)),
              ),
            );
          },
        );
      },
    );
  }
}

class _VideoResults extends StatelessWidget {
  const _VideoResults({required this.query, required this.searchService});

  final String query;
  final SearchService searchService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VideoModel>>(
      stream: searchService.searchVideos(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }
        final videos = snapshot.data ?? const [];
        if (videos.isEmpty) {
          return _EmptyResult(
            message: AppLocalizations.of(context).t('search.noVideos', {'query': query}),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          itemCount: videos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            final video = videos[index];
            return VideoGridTile(
              video: video,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SingleVideoScreen(video: video)),
              ),
            );
          },
        );
      },
    );
  }
}

class _BusinessResults extends StatelessWidget {
  const _BusinessResults({required this.query, required this.businessService});

  final String query;
  final BusinessService businessService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusinessModel>>(
      stream: businessService.searchBusinesses(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }
        final businesses = snapshot.data ?? const [];
        if (businesses.isEmpty) {
          return _EmptyResult(
            message: AppLocalizations.of(context).t('search.noBusiness', {'query': query}),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: businesses.length,
          itemBuilder: (context, index) {
            final business = businesses[index];
            return BusinessCard(
              business: business,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BusinessDetailScreen(businessId: business.id)),
              ),
            );
          },
        );
      },
    );
  }
}
