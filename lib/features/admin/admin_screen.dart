import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/admin_service.dart';

/// Écran de modération réservé aux comptes `isAdmin: true`.
/// 3 onglets : Vidéos, Utilisateurs, Business.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final _adminService = AdminService();
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _confirm(String title, String message, {String confirmLabel = 'Confirmer'}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Modération'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Vidéos'),
            Tab(text: 'Utilisateurs'),
            Tab(text: 'Business'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVideosTab(),
          _buildUsersTab(),
          _buildBusinessesTab(),
        ],
      ),
    );
  }

  // --- Onglet Vidéos ---

  Widget _buildVideosTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _adminService.watchRecentVideos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Aucune vidéo pour le moment.', style: TextStyle(color: Colors.white54)));
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
                onPressed: () async {
                  final ok = await _confirm(
                    'Supprimer cette vidéo ?',
                    caption.isEmpty ? 'Vidéo sans légende' : caption,
                    confirmLabel: 'Supprimer',
                  );
                  if (ok) {
                    await _adminService.deleteVideo(doc.id);
                    _showSnack('Vidéo supprimée.');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- Onglet Utilisateurs ---

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _adminService.watchUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Aucun utilisateur.', style: TextStyle(color: Colors.white54)));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final username = data['username'] as String? ?? 'inconnu';
            final isBanned = data['isBanned'] as bool? ?? false;
            final isAdmin = data['isAdmin'] as bool? ?? false;

            return ListTile(
              title: Text('@$username', style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                isAdmin ? 'Administrateur' : (isBanned ? 'Banni' : 'Actif'),
                style: TextStyle(color: isBanned ? Colors.redAccent : Colors.white54),
              ),
              trailing: isAdmin
                  ? const Icon(Icons.shield_moon_rounded, color: AppColors.gold)
                  : TextButton(
                      onPressed: () async {
                        final action = isBanned ? 'débannir' : 'bannir';
                        final ok = await _confirm(
                          isBanned ? 'Débannir @$username ?' : 'Bannir @$username ?',
                          isBanned
                              ? 'Ce compte pourra de nouveau utiliser MUHETO normalement.'
                              : 'Ce compte ne pourra plus utiliser MUHETO tant qu\'il n\'est pas débanni.',
                          confirmLabel: action[0].toUpperCase() + action.substring(1),
                        );
                        if (ok) {
                          await _adminService.setBanned(doc.id, !isBanned);
                          _showSnack(isBanned ? 'Compte débanni.' : 'Compte banni.');
                        }
                      },
                      child: Text(
                        isBanned ? 'Débannir' : 'Bannir',
                        style: TextStyle(color: isBanned ? AppColors.gold : Colors.redAccent),
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  // --- Onglet Business ---

  Widget _buildBusinessesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _adminService.watchBusinesses(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Aucune fiche Business.', style: TextStyle(color: Colors.white54)));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final name = data['name'] as String? ?? 'Sans nom';
            final category = data['category'] as String? ?? '';

            return ListTile(
              title: Text(name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(category, style: const TextStyle(color: Colors.white54)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () async {
                  final ok = await _confirm(
                    'Supprimer cette fiche ?',
                    name,
                    confirmLabel: 'Supprimer',
                  );
                  if (ok) {
                    await _adminService.deleteBusiness(doc.id);
                    _showSnack('Fiche Business supprimée.');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}