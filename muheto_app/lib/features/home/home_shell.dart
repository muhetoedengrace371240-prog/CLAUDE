import 'package:flutter/material.dart';

import '../analytics/analytics_screen.dart';
import '../business/business_screen.dart';
import '../feed/feed_screen.dart';
import '../gold/gold_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MUHETO')), 
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FeatureCard(title: 'Flux', subtitle: 'Vidéo et contenus', destination: const FeedScreen()),
          _FeatureCard(title: 'Business', subtitle: 'Annuaire local', destination: const BusinessScreen()),
          _FeatureCard(title: 'Gold', subtitle: 'Offres premium', destination: const GoldScreen()),
          _FeatureCard(title: 'Notifications', subtitle: 'Centre d’alertes', destination: const NotificationsScreen()),
          _FeatureCard(title: 'Recherche', subtitle: 'Profils et contenus', destination: const SearchScreen()),
          _FeatureCard(title: 'Analytics', subtitle: 'Statistiques', destination: const AnalyticsScreen()),
          _FeatureCard(title: 'Profil', subtitle: 'Informations du compte', destination: const ProfileScreen()),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.subtitle, required this.destination});

  final String title;
  final String subtitle;
  final Widget destination;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination)),
      ),
    );
  }
}
