import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../services/profile_service.dart';
import 'camera_capture_screen.dart';
import 'publish_document_screen.dart';
import 'publish_photo_screen.dart';
import 'publish_screen.dart';
import 'publish_text_screen.dart';

/// Écran ouvert en plein écran quand l'utilisateur tape sur "+" dans la
/// navbar. Propose 4 types de publication : Vidéo, Photo, Document, Texte.
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _picker = ImagePicker();
  final _profileService = ProfileService();
  bool _isPicking = false;
  bool _isCheckingGoldStatus = false;

  Future<void> _openVideoOptions() async {
    final loc = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.gold),
              title: Text(loc.t('create.camera'), style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.gold),
              title: Text(loc.t('create.gallery'), style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCamera() async {
    setState(() => _isCheckingGoldStatus = true);
    int maxDuration = kDefaultMaxRecordingSeconds;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final user = await _profileService.getUserOnce(uid);
        if (user?.isGoldActive == true) maxDuration = kGoldMaxRecordingSeconds;
      }
    } finally {
      if (mounted) setState(() => _isCheckingGoldStatus = false);
    }

    if (!mounted) return;
    final file = await Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder: (_) => CameraCaptureScreen(maxDurationSeconds: maxDuration),
        fullscreenDialog: true,
      ),
    );
    if (file != null) _goToPublishVideo(file);
  }

  Future<void> _openGallery() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final XFile? picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      if (picked != null) _goToPublishVideo(File(picked.path));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickPhotos() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        _goToPublishPhoto(picked.map((x) => File(x.path)).toList());
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickDocument() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles();
      final path = result?.files.single.path;
      if (result != null && path != null) {
        _goToPublishDocument(File(path), result.files.single.name);
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _goToPublishVideo(File file) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublishScreen(videoFile: file)),
    );
  }

  void _goToPublishPhoto(List<File> files) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublishPhotoScreen(photoFiles: files)),
    );
  }

  void _goToPublishDocument(File file, String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublishDocumentScreen(documentFile: file, documentName: name),
      ),
    );
  }

  void _goToPublishText() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PublishTextScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isBusy = _isPicking || _isCheckingGoldStatus;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(loc.t('nav.create')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.black, size: 38),
              ),
              const SizedBox(height: 20),
              Text(
                loc.t('create.subtitle'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.t('create.hint'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 28),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _CreateOptionTile(
                    icon: Icons.videocam_rounded,
                    label: loc.t('create.video'),
                    isLoading: _isCheckingGoldStatus,
                    onTap: isBusy ? null : _openVideoOptions,
                  ),
                  _CreateOptionTile(
                    icon: Icons.photo_library_rounded,
                    label: loc.t('create.photo'),
                    isLoading: _isPicking,
                    onTap: isBusy ? null : _pickPhotos,
                  ),
                  _CreateOptionTile(
                    icon: Icons.insert_drive_file_rounded,
                    label: loc.t('create.document'),
                    isLoading: _isPicking,
                    onTap: isBusy ? null : _pickDocument,
                  ),
                  _CreateOptionTile(
                    icon: Icons.text_fields_rounded,
                    label: loc.t('create.text'),
                    isLoading: false,
                    onTap: isBusy ? null : _goToPublishText,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateOptionTile extends StatelessWidget {
  const _CreateOptionTile({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceElevated),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.gold),
                  )
                : Icon(icon, color: AppColors.gold, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}