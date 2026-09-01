import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/timeago_locale.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/chat_model.dart';
import '../../gold/widgets/gold_badge.dart';

/// Une ligne de la liste des conversations : avatar, pseudo, aperçu du
/// dernier message (préfixé "Toi : " si c'est l'utilisateur connecté qui
/// l'a envoyé), horodatage relatif, et pastille dorée si non lu.
class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUid,
    required this.onTap,
  });

  final ChatModel chat;
  final String currentUid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isUnread = chat.unreadCount > 0;
    final isMineLastMessage = chat.lastMessageSenderId == currentUid;
    final preview = chat.lastMessage.isEmpty
        ? loc.t('chat.startConversation')
        : '${isMineLastMessage ? loc.t('chat.you') : ''}${chat.lastMessage}';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: isUnread ? AppColors.gold : Colors.transparent, width: 1.6),
        ),
        child: ClipOval(
          child: chat.otherAvatarUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: chat.otherAvatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: AppColors.surface,
                    child: Icon(Icons.person, color: AppColors.gold),
                  ),
                )
              : const ColoredBox(
                  color: AppColors.surface,
                  child: Icon(Icons.person, color: AppColors.gold),
                ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              '@${chat.otherUsername}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          if (chat.otherIsGoldMember) ...[
            const SizedBox(width: 4),
            const GoldBadge(size: 14),
          ],
        ],
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isUnread ? Colors.white70 : AppColors.textMuted,
          fontSize: 13,
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chat.lastMessageAt != null)
            Text(
              timeago.format(chat.lastMessageAt!, locale: timeagoLocaleFor(loc.locale.languageCode), allowFromNow: true),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          const SizedBox(height: 6),
          if (isUnread)
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
              child: Text(
                chat.unreadCount > 9 ? '9+' : '${chat.unreadCount}',
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
