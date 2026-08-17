import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/business_model.dart';
import '../../services/business_service.dart';
import 'business_detail_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('BUSINESS LOCAL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {
              // TODO: brancher BusinessService.searchBusinesses() sur une barre de recherche dédiée.
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
        onPressed: () {
          // TODO: écran "Créer ma page Business" (réservé aux comptes Business).
        },
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.black,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Ma page', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, color: AppColors.textMuted, size: 44),
            SizedBox(height: 14),
            Text(
              'Aucun commerce dans cette catégorie pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Reviens bientôt, de nouveaux partenaires locaux arrivent chaque semaine.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
