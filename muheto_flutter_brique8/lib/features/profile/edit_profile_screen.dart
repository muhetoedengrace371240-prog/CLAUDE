import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';

/// Écran d'édition du profil connecté : photo d'avatar, pseudonyme,
/// biographie. Enregistre directement dans Firestore `users/{uid}` et,
/// si une nouvelle photo est choisie, dans Firebase Storage
/// (`avatars/{uid}.jpg`).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _picker = ImagePicker();

  late final _usernameController = TextEditingController(text: widget.user.username);
  late final _bioController = TextEditingController(text: widget.user.bio);

  File? _pickedAvatar;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedAvatar = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final newUsername = _usernameController.text.trim().toLowerCase();

      if (newUsername != widget.user.username) {
        final taken = await _profileService.isUsernameTaken(newUsername, excludingUid: uid);
        if (taken) {
          setState(() {
            _errorMessage = 'Ce pseudonyme est déjà utilisé.';
            _isSaving = false;
          });
          return;
        }
      }

      String? avatarUrl;
      if (_pickedAvatar != null) {
        final ref = FirebaseStorage.instance.ref('avatars/$uid.jpg');
        await ref.putFile(_pickedAvatar!, SettableMetadata(contentType: 'image/jpeg'));
        avatarUrl = await ref.getDownloadURL();
      }

      await _profileService.updateProfile(
        uid: uid,
        username: newUsername,
        bio: _bioController.text.trim(),
        avatarUrl: avatarUrl,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'La mise à jour a échoué. Réessaie.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  )
                : const Text(
                    'Enregistrer',
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _isSaving ? null : _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.gold, width: 2.5),
                          ),
                          child: ClipOval(child: _buildAvatarPreview()),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              gradient: AppColors.goldGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, color: AppColors.black, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Pseudonyme',
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.gold),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Au moins 3 caractères.';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value.trim())) {
                      return 'Lettres, chiffres, points et underscores uniquement.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  maxLength: 120,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Biographie',
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    alignLabelWithHint: true,
                    hintText: 'Créateur de contenu | Burundi 🇧🇮',
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPreview() {
    if (_pickedAvatar != null) {
      return Image.file(_pickedAvatar!, fit: BoxFit.cover);
    }
    if (widget.user.avatarUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.user.avatarUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const ColoredBox(
          color: AppColors.surface,
          child: Icon(Icons.person, color: AppColors.gold, size: 42),
        ),
      );
    }
    return const ColoredBox(
      color: AppColors.surface,
      child: Icon(Icons.person, color: AppColors.gold, size: 42),
    );
  }
}
