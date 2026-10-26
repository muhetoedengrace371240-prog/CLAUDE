import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/business_model.dart';
import '../../services/business_service.dart';
import 'widgets/simple_bar_chart.dart';
import 'widgets/stat_card.dart';

/// Dashboard Analytics de la fiche Business : vues de la fiche et clics sur
/// les boutons d'action (Appeler / WhatsApp / Site web), tous incrémentés
/// en temps réel par `BusinessService` (voir `BusinessDetailScreen`).
class BusinessAnalyticsScreen extends StatelessWidget {
  const BusinessAnalyticsScreen({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final businessService = BusinessService();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(title: Text(loc.t('analytics.title'))),
      body: StreamBuilder<BusinessModel?>(
        stream: businessService.watchBusiness(businessId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          }

          final business = snapshot.data;
          if (business == null) {
            return Center(
              child: Text(
                loc.t('analytics.notFound'),
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final totalClicks = business.callClicksCount +
              business.websiteClicksCount +
              business.whatsappClicksCount;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                business.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                loc.t('analytics.overview'),
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 18),
              // Hauteur fixe (mainAxisExtent) plutôt qu'un rapport
              // largeur/hauteur : le contenu d'une tuile a une hauteur
              // constante, quelle que soit la largeur de l'écran.
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 148,
                ),
                children: [
                  StatCard(
                    icon: Icons.visibility_rounded,
                    value: StatCard.formatCount(business.viewsCount),
                    label: loc.t('analytics.views'),
                  ),
                  StatCard(
                    icon: Icons.touch_app_rounded,
                    value: StatCard.formatCount(totalClicks),
                    label: loc.t('analytics.totalClicks'),
                  ),
                  StatCard(
                    icon: Icons.call_rounded,
                    value: StatCard.formatCount(business.callClicksCount),
                    label: loc.t('analytics.callClicks'),
                  ),
                  StatCard(
                    icon: Icons.chat_bubble_rounded,
                    value: StatCard.formatCount(business.whatsappClicksCount),
                    label: loc.t('analytics.whatsappClicks'),
                  ),
                  StatCard(
                    icon: Icons.language_rounded,
                    value: StatCard.formatCount(business.websiteClicksCount),
                    label: loc.t('analytics.websiteClicks'),
                  ),
                  StatCard(
                    icon: Icons.percent_rounded,
                    value: business.viewsCount == 0
                        ? '—'
                        : '${((totalClicks / business.viewsCount) * 100).toStringAsFixed(0)}%',
                    label: loc.t('analytics.clickRate'),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                loc.t('analytics.clickBreakdown'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              SimpleBarChart(
                points: [
                  BarChartPoint(
                      label: loc.t('business.call'),
                      value: business.callClicksCount),
                  BarChartPoint(
                      label: loc.t('business.whatsapp'),
                      value: business.whatsappClicksCount),
                  BarChartPoint(
                      label: loc.t('business.website'),
                      value: business.websiteClicksCount),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
