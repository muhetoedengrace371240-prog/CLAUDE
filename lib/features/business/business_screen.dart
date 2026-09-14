import 'package:muheto_app/features/search/widgets/search_tab_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/business_model.dart';
import '../../services/business_service.dart';
import 'business_detail_screen.dart';
import 'business_form_screen.dart';
import '../search/search_screen.dart';
import 'widgets/business_card.dart';
import 'widgets/chip_filter_row.dart';

/// Écran "Business Local" : liste premium Noir & Or des commerces
/// partenaires, filtrable par catégorie, avec les fiches sponsorisées mises
/// en avant en tête de liste.
class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  final _businessService = BusinessService();
  String? _selectedCategory;
  bool _isOpeningForm = false;

  Future<void> _handleMyPageTap() async {
    final loc = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('business.loginRequired'))),
      );
      return;
    }

    setState(() => _isOpeningForm = true);
    try {
      final existing = await _businessService.getMyBusiness(uid);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BusinessFormScreen(existingBusiness: existing)),
      );
    } finally {
      if (mounted) setState(() => _isOpeningForm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: Text(loc.t('business.title').toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SearchScreen(initialTab: SearchResultTab.business),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          ChipFilterRow(
            categories: kBusinessCategories,
            selected: _selectedCategory,
            onSelected: (category) => setState(() => _selectedCategory = category),
            labelBuilder: (category) => loc.t(businessCategoryKey(category)),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<BusinessModel>>(
              stream: _businessService.watchBusinesses(category: _selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                }

                final businesses = snapshot.data ?? const [];
                if (businesses.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: businesses.length,
                  itemBuilder: (context, index) {
                    final business = businesses[index];
                    return BusinessCard(
                      business: business,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BusinessDetailScreen(businessId: business.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isOpeningForm ? null : _handleMyPageTap,
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.black,
        icon: _isOpeningForm
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.black),
              )
            : const Icon(Icons.add_business_rounded),
        label: Text(loc.t('business.myPage'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined, color: AppColors.textMuted, size: 44),
            const SizedBox(height: 14),
            Text(
              loc.t('business.emptyCategory'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              loc.t('business.emptyCategoryHint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}