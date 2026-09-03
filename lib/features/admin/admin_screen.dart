import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/admin_service.dart';

/// Écran de modération réservé aux comptes `isAdmin: true`.
/// Pour l'instant : liste des dernières vidéos, avec suppression.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _adminService = AdminService();

  Future<void> _confirmAndDeleteVideo(String videoId, String caption) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette vidéo ?'),
        content: Text(caption.isEmpty ? 'Vidéo sans légende' : caption),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _adminService.deleteVideo(videoId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vidéo supprimée.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(title: const Text('Modération')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _adminService.watchRecentVideos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur : ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('Aucune vidéo pour le moment.', style: TextStyle(color: Colors.white54)),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final caption = data['caption'] as String? ?? '';
              final username = data['username'] as String? ?? 'inconnu';

              return ListTile(
                title: Text(
                  caption.isEmpty ? '(sans légende)' : caption,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('@$username', style: const TextStyle(color: Colors.white54)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmAndDeleteVideo(doc.id, caption),
                ),
              );
            },
          );
        },
      ),
    );
  }
}