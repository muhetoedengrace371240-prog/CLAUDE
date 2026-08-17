import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/business_model.dart';

/// Carte d'un commerce dans la liste Business Locale : logo, nom, badge
/// vérifié/sponsorisé, catégorie, adresse courte, statut ouvert/fermé.
class BusinessCard extends StatelessWidget {
  const BusinessCard({super.key, required this.business, required this.onTap});

  final BusinessModel business;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOpen = business.isOpenNow;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: business.isSponsored ? AppColors.gold.withValues(alpha: 0.5) : AppColors.surfaceElevated,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 1.6),
              ),
              child: ClipOval(
                child: business.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: business.logoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const _LogoFallback(),
                      )
                    : const _LogoFallback(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          business.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (business.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: AppColors.gold, size: 15),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    business.category,
                    style: const TextStyle(color: AppColors.goldLight, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 13),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          business.address.isNotEmpty ? business.address : business.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (business.isSponsored)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SPONSORISÉ',
                      style: TextStyle(color: AppColors.black, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
                if (isOpen != null) ...[
                  const SizedBox(height: 6),
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
                      const SizedBox(width: 4),
                      Text(
                        isOpen ? 'Ouvert' : 'Fermé',
                        style: TextStyle(
                          color: isOpen ? AppColors.success : AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceElevated,
      child: Icon(Icons.storefront_rounded, color: AppColors.gold),
    );
  }
}
