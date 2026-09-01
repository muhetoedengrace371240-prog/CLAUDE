import '../../core/localization/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/business_model.dart';
import '../../services/business_service.dart';
import 'business_form_screen.dart';
import '../analytics/business_analytics_screen.dart';

/// Fiche détaillée d'un commerce local : bannière, logo, description,
/// adresse, appel direct, horaires d'ouverture, site web / réseaux sociaux.
class BusinessDetailScreen extends StatefulWidget {
  const BusinessDetailScreen({super.key, required this.businessId});

  final String businessId;

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  final _businessService = BusinessService();

  // Empêche de recompter une vue à chaque rebuild du StreamBuilder (ex:
  // quand un like ou un changement mineur déclenche un nouveau snapshot).
  bool _viewCounted = false;

  Future<void> _launch(BuildContext context, Uri uri) async {
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir ce lien.")),
      );
    }
  }

  void _registerViewOnce() {
    if (_viewCounted) return;
    _viewCounted = true;
    _businessService.registerBusinessView(widget.businessId);
  }

  @override
  Widget build(BuildContext context) {
    final businessId = widget.businessId;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: StreamBuilder<BusinessModel?>(
        stream: _businessService.watchBusiness(businessId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          final business = snapshot.data;
          if (business == null) {
            return Scaffold(
              backgroundColor: AppColors.black,
              appBar: AppBar(leading: BackButton(onPressed: () => Navigator.of(context).pop())),
              body: const Center(
                child: Text(AppLocalizations.of(context).t('business.notFound'), style: const TextStyle(color: Colors.white70)),
              ),
            );
          }

          // Vue comptée une seule fois par ouverture d'écran, dès que la
          // fiche a fini de charger — pas à chaque frame de build.
          WidgetsBinding.instance.addPostFrameCallback((_) => _registerViewOnce());

          final isOpen = business.isOpenNow;
          final isOwner = business.ownerId == FirebaseAuth.instance.currentUser?.uid;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.black,
                expandedHeight: 190,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                actions: [
                  if (isOwner) ...[
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: _RoundIconButton(
                        icon: Icons.insights_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BusinessAnalyticsScreen(businessId: businessId),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: _RoundIconButton(
                        icon: Icons.edit_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BusinessFormScreen(existingBusiness: business),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: business.bannerUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: business.bannerUrl, fit: BoxFit.cover)
                      : const ColoredBox(color: AppColors.surface),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -36),
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.gold, width: 2.5),
                                color: AppColors.black,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: ClipOval(
                                child: business.logoUrl.isNotEmpty
                                    ? CachedNetworkImage(imageUrl: business.logoUrl, fit: BoxFit.cover)
                                    : const ColoredBox(
                                        color: AppColors.surfaceElevated,
                                        child: Icon(Icons.storefront_rounded, color: AppColors.gold, size: 30),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          business.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      if (business.isVerified) ...[
                                        const SizedBox(width: 5),
                                        const Icon(Icons.verified, color: AppColors.gold, size: 18),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    business.category,
                                    style: const TextStyle(
                                      color: AppColors.goldLight,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (isOpen != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isOpen ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          isOpen ? 'Ouvert maintenant' : 'Fermé actuellement',
                                          style: TextStyle(
                                            color: isOpen ? AppColors.success : AppColors.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (business.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          business.description,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 22),
                      ],

                      // --- Actions rapides : Appeler / WhatsApp / Site web ---
                      Row(
                        children: [
                          if (business.phoneNumber.isNotEmpty)
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.call_rounded,
                                label: 'Appeler',
                                onTap: () {
                                  _businessService.registerCallClick(businessId);
                                  _launch(context, Uri(scheme: 'tel', path: business.phoneNumber));
                                },
                              ),
                            ),
                          if (business.whatsappNumber.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.chat_bubble_rounded,
                                label: 'WhatsApp',
                                onTap: () {
                                  _businessService.registerWhatsappClick(businessId);
                                  _launch(
                                    context,
                                    Uri.parse('https://wa.me/${business.whatsappNumber.replaceAll('+', '')}'),
                                  );
                                },
                              ),
                            ),
                          ],
                          if (business.websiteUrl.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.language_rounded,
                                label: 'Site web',
                                onTap: () {
                                  _businessService.registerWebsiteClick(businessId);
                                  _launch(context, Uri.parse(business.websiteUrl));
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 26),

                      // --- Adresse ---
                      if (business.address.isNotEmpty) ...[
                        const _SectionTitle('Adresse'),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppColors.gold, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${business.address}\n${business.city}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                      ],

                      // --- Horaires d'ouverture ---
                      if (business.openingHours.isNotEmpty) ...[
                        const _SectionTitle("Horaires d'ouverture"),
                        const SizedBox(height: 10),
                        ...kWeekDaysFr.map((day) {
                          final hours = business.openingHours[day] ?? 'Fermé';
                          final isToday = kWeekDaysFr[DateTime.now().weekday - 1] == day;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      color: isToday ? AppColors.gold : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Text(
                                  hours,
                                  style: TextStyle(
                                    color: isToday ? Colors.white : AppColors.textMuted,
                                    fontSize: 13,
                                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 26),
                      ],

                      // --- Réseaux sociaux ---
                      if (business.instagramUrl.isNotEmpty || business.facebookUrl.isNotEmpty) ...[
                        const _SectionTitle('Réseaux sociaux'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (business.instagramUrl.isNotEmpty)
                              _RoundIconButton(
                                icon: Icons.camera_alt_rounded,
                                onTap: () => _launch(context, Uri.parse(business.instagramUrl)),
                              ),
                            if (business.facebookUrl.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              _RoundIconButton(
                                icon: Icons.facebook_rounded,
                                onTap: () => _launch(context, Uri.parse(business.facebookUrl)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceElevated),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.gold, size: 20),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
