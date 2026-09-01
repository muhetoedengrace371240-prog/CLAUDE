import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';
import 'widgets/chat_list_tile.dart';

/// Écran "Boîte de réception" : notifications d'activité + liste des
/// conversations, branchée en temps réel sur Firestore.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).t('chat.inbox')),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: AppLocalizations.of(context).t('chat.activity')),
              Tab(text: AppLocalizations.of(context).t('chat.messages')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ActivityEmptyState(),
            _ChatListView(),
          ],
        ),
      ),
    );
  }
}

class _ActivityEmptyState extends StatelessWidget {
  const _ActivityEmptyState();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded, color: AppColors.gold, size: 48),
            const SizedBox(height: 14),
            Text(
              loc.t('chat.noActivity'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              loc.t('chat.noActivitySub'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatListView extends StatelessWidget {
  const _ChatListView();

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).t('chat.loginToView'),
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return StreamBuilder<List<ChatModel>>(
      stream: chatService.watchUserChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }

        final chats = snapshot.data ?? const [];
        if (chats.isEmpty) {
          final loc = AppLocalizations.of(context);
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.gold, size: 48),
                  const SizedBox(height: 14),
                  Text(
                    loc.t('chat.noMessages'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.t('chat.noConversationsSub'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(
            color: AppColors.surfaceElevated,
            height: 1,
            indent: 82,
          ),
          itemBuilder: (context, index) {
            final chat = chats[index];
            return ChatListTile(
              chat: chat,
              currentUid: currentUid,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chat.id,
                      otherUserId: chat.otherUserId,
                      otherUsername: chat.otherUsername,
                      otherAvatarUrl: chat.otherAvatarUrl,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
