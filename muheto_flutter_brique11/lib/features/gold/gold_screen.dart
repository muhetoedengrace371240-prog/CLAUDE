import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/gold_service.dart';

const _kBenefits = [
  ('Badge premium doré', Icons.workspace_premium_rounded),
  ('Meilleure visibilité dans le Feed', Icons.trending_up_rounded),
  ('Mise en avant de ta page Business', Icons.storefront_rounded),
  ('Vidéos plus longues (10 min)', Icons.movie_filter_rounded),
  ('Aucune publicité', Icons.block_rounded),
  ('Analytics avancées', Icons.bar_chart_rounded),
  ('Téléchargement en HD', Icons.high_quality_rounded),
  ('Support prioritaire', Icons.support_agent_rounded),
];

/// Écran d'offre MUHETO Gold — design ultra-premium Noir & Or, fidèle à la
/// maquette (badge, liste d'avantages, prix, essai gratuit de 7 jours).
class GoldScreen extends StatefulWidget {
  const GoldScreen({super.key});

  @override
  State<GoldScreen> createState() => _GoldScreenState();
}

class _GoldScreenState extends State<GoldScreen> {
  final _goldService = GoldService();
  bool _isProcessing = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _startTrial() async {
    final uid = _uid;
    if (uid == null) return;

    setState(() => _isProcessing = true);
    try {
      await _goldService.startFreeTrial(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bienvenue dans MUHETO Gold ✨ Ton essai de 7 jours est actif.'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'activer l'essai pour le moment. Réessaie.")),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final uid = _uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Résilier MUHETO Gold ?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tu perdras immédiatement le badge doré et tous les avantages Gold.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Résilier', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _goldService.cancelSubscription(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('MUHETO GOLD'),
      ),
      body: uid == null
          ? const Center(
              child: Text('Connecte-toi pour accéder à MUHETO Gold.', style: TextStyle(color: Colors.white70)),
            )
          : StreamBuilder<UserModel?>(
              stream: _goldService.watchGoldStatus(uid),
              builder: (context, snapshot) {
                final user = snapshot.data;
                final isGoldActive = user?.isGoldActive ?? false;

                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1A1500), AppColors.black],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              gradient: AppColors.goldGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Color(0x55D4AF37), blurRadius: 30, spreadRadius: 4),
                              ],
                            ),
                            child: const Icon(Icons.workspace_premium_rounded, color: AppColors.black, size: 50),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Center(
                          child: Text(
                            'MUHETO GOLD',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'Passe à la vitesse supérieure',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 30),

                        if (isGoldActive) ...[
                          _ActiveStatusCard(
                            expirationDate: user?.goldExpirationDate,
                            onCancel: _cancelSubscription,
                          ),
                        ] else ...[
                          ..._kBenefits.map(
                            (benefit) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.surfaceElevated),
                                    ),
                                    child: Icon(benefit.$2, color: AppColors.gold, size: 17),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      benefit.$1,
                                      style: const TextStyle(color: Colors.white, fontSize: 14.5),
                                    ),
                                  ),
                                  const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                            ),
                            child: Column(
                              children: [
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '3.99\$',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' / mois',
                                        style: TextStyle(color: Colors.white54, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Annulable à tout moment',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton(
                                  onPressed: _isProcessing ? null : _startTrial,
                                  child: _isProcessing
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.black),
                                        )
                                      : const Text('Essayer 7 jours gratuits'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Center(
                            child: Text(
                              'Le paiement réel (Mobile Money / carte) sera demandé\nà la fin de la période d\'essai.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ActiveStatusCard extends StatelessWidget {
  const _ActiveStatusCard({required this.expirationDate, required this.onCancel});

  final DateTime? expirationDate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        expirationDate != null ? DateFormat('d MMMM yyyy', 'fr_FR').format(expirationDate!) : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.black, size: 34),
          const SizedBox(height: 10),
          const Text(
            'Tu es membre MUHETO Gold ✨',
            style: TextStyle(color: AppColors.black, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (formattedDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Actif jusqu\'au $formattedDate',
              style: const TextStyle(color: AppColors.black, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.black, width: 1.4),
              foregroundColor: AppColors.black,
            ),
            child: const Text('Résilier l\'abonnement'),
          ),
        ],
      ),
    );
  }
}
