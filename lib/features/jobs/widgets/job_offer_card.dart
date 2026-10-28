import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/diploma_level.dart';
import '../../../models/job_offer_model.dart';

/// Libellé affiché du diplôme minimum d'une offre : le texte libre si le
/// niveau est "autre" et précisé, sinon la traduction du niveau, sinon
/// "aucune exigence".
String jobDiplomaLabel(AppLocalizations loc, JobOfferModel offer) {
  final level = offer.minDiploma;
  if (level == null) {
    return loc.t('jobs.noDiplomaRequired');
  }
  if (level == DiplomaLevel.other && offer.minDiplomaOther.isNotEmpty) {
    return offer.minDiplomaOther;
  }
  return loc.t(diplomaLevelKey(level));
}

/// Carte d'une offre dans la liste.
class JobOfferCard extends StatelessWidget {
  const JobOfferCard({super.key, required this.offer, required this.onTap});

  final JobOfferModel offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    String? status;
    if (!offer.isActive) {
      status = loc.t('jobs.statusClosed');
    } else if (offer.isExpired) {
      status = loc.t('jobs.statusExpired');
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceElevated),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    offer.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${offer.company} · ${offer.city}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (offer.minDiploma != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.school_outlined,
                      color: AppColors.textMuted, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      jobDiplomaLabel(loc, offer),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ],
            if (offer.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                offer.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
