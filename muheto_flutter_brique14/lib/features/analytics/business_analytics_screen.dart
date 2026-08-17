import '../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

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
    final businessService = BusinessService();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(title: Text(AppLocalizations.of(context).t('analytics.businessTitle'))),
      body: StreamBuilder<BusinessModel?>(
        stream: businessService.watchBusiness(businessId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          final business = snapshot.data;
          if (business == null) {
            return const Center(
              child: Text(AppLocalizations.of(context).t('business.notFound'), style: const TextStyle(color: Colors.white70)),
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
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Vue d\'ensemble de l\'engagement sur ta fiche.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    icon: Icons.visibility_rounded,
                    value: StatCard.formatCount(business.viewsCount),
                    label: 'Vues de la fiche',
                  ),
                  StatCard(
                    icon: Icons.touch_app_rounded,
                    value: StatCard.formatCount(totalClicks),
                    label: 'Clics au total',
                  ),
                  StatCard(
                    icon: Icons.call_rounded,
                    value: StatCard.formatCount(business.callClicksCount),
                    label: 'Clics "Appeler"',
                  ),
                  StatCard(
                    icon: Icons.chat_bubble_rounded,
                    value: StatCard.formatCount(business.whatsappClicksCount),
                    label: 'Clics WhatsApp',
                  ),
                  StatCard(
                    icon: Icons.language_rounded,
                    value: StatCard.formatCount(business.websiteClicksCount),
                    label: 'Clics site web',
                  ),
                  StatCard(
                    icon: Icons.percent_rounded,
                    value: business.viewsCount == 0
                        ? '—'
                        : '${((totalClicks / business.viewsCount) * 100).toStringAsFixed(0)}%',
                    label: 'Taux de clic',
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Répartition des clics',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              SimpleBarChart(
                points: [
                  BarChartPoint(label: 'Appel', value: business.callClicksCount),
                  BarChartPoint(label: 'WhatsApp', value: business.whatsappClicksCount),
                  BarChartPoint(label: 'Site web', value: business.websiteClicksCount),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
