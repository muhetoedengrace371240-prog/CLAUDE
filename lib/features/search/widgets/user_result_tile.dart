import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../gold/widgets/gold_badge.dart';

/// Ligne de résultat "Utilisateurs / Créateurs" dans la recherche globale.
class UserResultTile extends StatelessWidget {
  const UserResultTile({super.key, required this.user, required this.onTap});

  final UserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold, width: 1.4),
        ),
        child: ClipOval(
          child: user.avatarUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: user.avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const _AvatarFallback(),
                )
              : const _AvatarFallback(),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              '@${user.username}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
          ),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: AppColors.gold, size: 14),
          ],
          if (user.isGoldActive) ...[
            const SizedBox(width: 4),
            const GoldBadge(size: 13),
          ],
        ],
      ),
      subtitle: user.bio.isNotEmpty
          ? Text(
              user.bio,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12.5),
            )
          : Text(
              '${user.followersCount} abonnés',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceElevated,
      child: Icon(Icons.person, color: AppColors.gold, size: 22),
    );
  }
}
