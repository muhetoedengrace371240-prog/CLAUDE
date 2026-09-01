import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/gold_service.dart';

/// Chaque tuple associe une icône à la clé de traduction de son libellé
/// (`gold.benefit.*`), pour garder l'ordre d'affichage fixe tout en restant
/// entièrement traduit dans les 4 langues.
const _kBenefitKeys = [
  ('gold.benefit.badge', Icons.workspace_premium_rounded),
  ('gold.benefit.visibility', Icons.trending_up_rounded),
  ('gold.benefit.business', Icons.storefront_rounded),
  ('gold.benefit.longVideos', Icons.movie_filter_rounded),
  ('gold.benefit.noAds', Icons.block_rounded),
  ('gold.benefit.analytics', Icons.bar_chart_rounded),
  ('gold.benefit.hdDownload', Icons.high_quality_rounded),
  ('gold.benefit.support', Icons.support_agent_rounded),
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

  Future<void> _startTrial(AppLocalizations loc) async {
    final uid = _uid;
    if (uid == null) return;

    setState(() => _isProcessing = true);
    try {
      await _goldService.startFreeTrial(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('gold.trialWelcome')),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('gold.trialFailed'))),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelSubscription(AppLocalizations loc) async {
    final uid = _uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(loc.t('gold.cancelTitle'), style: const TextStyle(color: Colors.white)),
        content: Text(loc.t('gold.cancelMessage'), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.t('common.cancel'), style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              loc.t('gold.cancelConfirm'),
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
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
    final loc = AppLocalizations.of(context);
    final uid = _uid;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(loc.t('gold.title')),
      ),
      body: uid == null
          ? Center(
              child: Text(loc.t('gold.loginRequired'), style: const TextStyle(color: Colors.white70)),
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
                        Center(
                          child: Text(
                            loc.t('gold.title'),
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            loc.t('gold.subtitle'),
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 30),

                        if (isGoldActive) ...[
                          _ActiveStatusCard(
                            expirationDate: user?.goldExpirationDate,
                            onCancel: () => _cancelSubscription(loc),
                            loc: loc,
                          ),
                        ] else ...[
                          ..._kBenefitKeys.map(
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
                                      loc.t(benefit.$1),
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
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  loc.t('gold.price'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loc.t('gold.cancelAnytime'),
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton(
                                  onPressed: _isProcessing ? null : () => _startTrial(loc),
                                  child: _isProcessing
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.black),
                                        )
                                      : Text(loc.t('gold.startTrial')),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: Text(
                              loc.t('gold.paymentNotice'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
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
  const _ActiveStatusCard({required this.expirationDate, required this.onCancel, required this.loc});

  final DateTime? expirationDate;
  final VoidCallback onCancel;
  final AppLocalizations loc;

  /// Le Kirundi ('rn') n'existe pas dans les données de locale CLDR
  /// utilisées par `package:intl` — `DateFormat(..., 'rn')` lèverait une
  /// `LocaleDataException`. On se replie sur le français, langue
  /// administrative courante au Burundi, plutôt que de faire planter
  /// l'app. Le Kiswahili ('sw') est en revanche bien supporté nativement.
  String _dateFormatLocaleFor(String appLanguageCode) {
    switch (appLanguageCode) {
      case 'en':
        return 'en_US';
      case 'sw':
        return 'sw_TZ';
      case 'fr':
      case 'rn':
      default:
        return 'fr_FR';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLocale = _dateFormatLocaleFor(loc.locale.languageCode);
    final formattedDate =
        expirationDate != null ? DateFormat('d MMMM yyyy', dateLocale).format(expirationDate!) : null;

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
          Text(
            loc.t('gold.activeMember'),
            style: const TextStyle(color: AppColors.black, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (formattedDate != null) ...[
            const SizedBox(height: 4),
            Text(
              loc.t('gold.activeUntil').replaceFirst('{date}', formattedDate),
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
            child: Text(loc.t('gold.unsubscribe')),
          ),
        ],
      ),
    );
  }
}
