import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/job_offer_model.dart';
import '../../services/job_offer_service.dart';
import 'job_offer_detail_screen.dart';
import 'job_offer_form_screen.dart';
import 'widgets/job_offer_card.dart';
import 'widgets/option_chip.dart';

/// Onglet "Emplois" : liste des offres, avec un filtre "Toutes / Mes offres".
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _service = JobOfferService();
  bool _showMine = false;

  void _openForm() {
    final loc = AppLocalizations.of(context);
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('jobs.loginRequired'))),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JobOfferFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: Text(loc.t('nav.jobs').toUpperCase()),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                OptionChip(
                  label: loc.t('jobs.all'),
                  selected: !_showMine,
                  onTap: () => setState(() => _showMine = false),
                ),
                const SizedBox(width: 8),
                OptionChip(
                  label: loc.t('jobs.mine'),
                  selected: _showMine,
                  onTap: () => setState(() => _showMine = true),
                ),
              ],
            ),
          ),
          Expanded(child: _buildList(loc, uid)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.black,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          loc.t('jobs.publish'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildList(AppLocalizations loc, String? uid) {
    if (_showMine && uid == null) {
      return _Message(
        icon: Icons.lock_outline_rounded,
        title: loc.t('jobs.loginRequired'),
      );
    }

    final stream =
        _showMine ? _service.watchMyOffers(uid!) : _service.watchOffers();

    return StreamBuilder<List<JobOfferModel>>(
      stream: stream,
      builder: (context, snapshot) {
        // L'erreur est AFFICHÉE : une requête refusée ne doit jamais passer
        // pour une liste vide.
        if (snapshot.hasError) {
          return _Message(
            icon: Icons.error_outline_rounded,
            title: loc.t('jobs.loadError'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.gold));
        }

        final offers = snapshot.data ?? const <JobOfferModel>[];
        if (offers.isEmpty) {
          return _Message(
            icon: Icons.work_outline_rounded,
            title: _showMine ? loc.t('jobs.emptyMine') : loc.t('jobs.empty'),
            subtitle: _showMine ? null : loc.t('jobs.emptyHint'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 6, bottom: 96),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return JobOfferCard(
              offer: offer,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JobOfferDetailScreen(offerId: offer.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 44),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
