import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
          title: const Text('BOÎTE DE RÉCEPTION'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'Activité'),
              Tab(text: 'Messages'),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, color: AppColors.gold, size: 48),
            SizedBox(height: 14),
            Text(
              'Aucune activité pour le moment',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Les likes, commentaires et nouveaux abonnés apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
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
      return const Center(
        child: Text('Connecte-toi pour voir tes messages.', style: TextStyle(color: Colors.white70)),
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, color: AppColors.gold, size: 48),
                  SizedBox(height: 14),
                  Text(
                    'Aucun message pour le moment',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ouvre le profil d\'un créateur et tape sur l\'icône message pour démarrer une conversation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
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
