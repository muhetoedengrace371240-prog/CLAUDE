import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/field_of_study.dart';
import '../../models/job_offer_model.dart';
import '../../services/chat_service.dart';
import '../../services/job_offer_service.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/job_offer_card.dart';

/// Détail d'une offre : description, exigences, publicateur, et actions
/// (postuler par la messagerie, WhatsApp, ou fermer/supprimer si c'est la
/// sienne).
class JobOfferDetailScreen extends StatelessWidget {
  const JobOfferDetailScreen({super.key, required this.offerId});

  final String offerId;

  Future<void> _apply(BuildContext context, JobOfferModel offer) async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (FirebaseAuth.instance.currentUser == null) {
      messenger
          .showSnackBar(SnackBar(content: Text(loc.t('chat.loginRequired'))));
      return;
    }

    try {
      final chatId = await ChatService().getOrCreateChat(offer.ownerId);
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserId: offer.ownerId,
            otherUsername: offer.ownerUsername,
            otherAvatarUrl: '',
          ),
        ),
      );
    } catch (_) {
      messenger
          .showSnackBar(SnackBar(content: Text(loc.t('jobs.openChatFailed'))));
    }
  }

  Future<void> _openWhatsapp(BuildContext context, String number) async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');

    var opened = false;
    try {
      if (digits.isNotEmpty) {
        opened = await launchUrl(
          Uri.parse('https://wa.me/$digits'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger
          .showSnackBar(SnackBar(content: Text(loc.t('business.openFailed'))));
    }
  }

  Future<bool> _confirm(
      BuildContext context, String message, String confirmLabel) async {
    final loc = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel,
                style: const TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _close(BuildContext context, JobOfferModel offer) async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await _confirm(
        context, loc.t('jobs.closeConfirm'), loc.t('jobs.close'));
    if (!confirmed) {
      return;
    }
    try {
      await JobOfferService().closeOffer(offer.id);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.t('errors.generic'))));
    }
  }

  Future<void> _delete(BuildContext context, JobOfferModel offer) async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await _confirm(
        context, loc.t('jobs.deleteConfirm'), loc.t('common.delete'));
    if (!confirmed) {
      return;
    }
    try {
      await JobOfferService().deleteOffer(offer.id);
      navigator.pop();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.t('errors.generic'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(),
      body: StreamBuilder<JobOfferModel?>(
        stream: JobOfferService().watchOffer(offerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                loc.t('jobs.loadError'),
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          }

          final offer = snapshot.data;
          if (offer == null) {
            return Center(
              child: Text(
                loc.t('jobs.notFound'),
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final isOwner = currentUid != null && currentUid == offer.ownerId;
          final canApply = !isOwner && offer.isVisible;

          String? status;
          if (!offer.isActive) {
            status = loc.t('jobs.statusClosed');
          } else if (offer.isExpired) {
            status = loc.t('jobs.statusExpired');
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                offer.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${offer.company} · ${offer.city}',
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (status != null) ...[
                const SizedBox(height: 8),
                Text(status,
                    style:
                        const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              if (offer.ownerUsername.isNotEmpty) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => ProfileScreen(uid: offer.ownerId)),
                  ),
                  child: Text(
                    '${loc.t('jobs.postedBy')} @${offer.ownerUsername}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.gold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.t('jobs.scamWarning'),
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              _Section(
                title: loc.t('jobs.description'),
                child: Text(
                  offer.description,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14, height: 1.45),
                ),
              ),
              _Section(
                title: loc.t('jobs.requiredDiploma'),
                child: Text(
                  jobDiplomaLabel(loc, offer),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              _Section(
                title: loc.t('jobs.fieldsTitle'),
                child: offer.fields.isEmpty
                    ? Text(
                        loc.t('jobs.allFields'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: offer.fields
                            .map((field) =>
                                _Tag(label: loc.t(fieldOfStudyKey(field))))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 28),
              if (canApply)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _apply(context, offer),
                    child: Text(loc.t('jobs.apply')),
                  ),
                ),
              if (canApply && offer.contactWhatsapp.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _openWhatsapp(context, offer.contactWhatsapp),
                    icon: const Icon(Icons.chat_bubble_rounded),
                    label: Text(loc.t('business.whatsapp')),
                  ),
                ),
              ],
              if (isOwner) ...[
                if (offer.isActive)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _close(context, offer),
                      child: Text(loc.t('jobs.close')),
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _delete(context, offer),
                    child: Text(
                      loc.t('jobs.deleteOffer'),
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceElevated),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
    );
  }
}
