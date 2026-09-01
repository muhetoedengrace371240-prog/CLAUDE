import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Écran "Boîte de réception" : notifications + messages privés.
/// La liste sera branchée sur Firestore (collection `conversations`)
/// dans la brique Messagerie.
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
            _InboxEmptyState(),
            _InboxEmptyState(),
          ],
        ),
      ),
    );
  }
}

class _InboxEmptyState extends StatelessWidget {
  const _InboxEmptyState();

  @override
  Widget build(BuildContext context) {
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
              'Tes notifications et conversations privées apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
