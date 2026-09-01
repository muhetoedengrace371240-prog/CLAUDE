import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../models/business_model.dart';
import '../../services/business_service.dart';
import 'business_detail_screen.dart';
import 'widgets/business_category_picker.dart';
import 'widgets/opening_hours_editor.dart';

/// Écran de création OU d'édition d'une fiche Business.
///
/// - [existingBusiness] == null  → mode création (nouvelle fiche).
/// - [existingBusiness] != null  → mode édition (les champs sont
///   pré-remplis ; seul le propriétaire peut arriver sur cet écran en
///   édition, la vérification étant faite en amont par l'appelant et,
///   en dernier rempart, par les règles Firestore).
class BusinessFormScreen extends StatefulWidget {
  const BusinessFormScreen({super.key, this.existingBusiness});

  final BusinessModel? existingBusiness;

  bool get isEditing => existingBusiness != null;

  @override
  State<BusinessFormScreen> createState() => _BusinessFormScreenState();
}

class _BusinessFormScreenState extends State<BusinessFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessService = BusinessService();
  final _picker = ImagePicker();

  late final _nameController = TextEditingController(text: widget.existingBusiness?.name ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.existingBusiness?.description ?? '');
  late final _phoneController = TextEditingController(text: widget.existingBusiness?.phoneNumber ?? '');
  late final _whatsappController =
      TextEditingController(text: widget.existingBusiness?.whatsappNumber ?? '');
  late final _addressController = TextEditingController(text: widget.existingBusiness?.address ?? '');
  late final _cityController =
      TextEditingController(text: widget.existingBusiness?.city ?? 'Bujumbura');
  late final _websiteController = TextEditingController(text: widget.existingBusiness?.websiteUrl ?? '');
  late final _instagramController =
      TextEditingController(text: widget.existingBusiness?.instagramUrl ?? '');
  late final _facebookController =
      TextEditingController(text: widget.existingBusiness?.facebookUrl ?? '');

  String? _selectedCategory;
  Map<String, String> _openingHours = {};

  File? _pickedLogo;
  File? _pickedBanner;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.existingBusiness?.category;
    _openingHours = Map<String, String>.from(widget.existingBusiness?.openingHours ?? const {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (picked != null) setState(() => _pickedLogo = File(picked.path));
  }

  Future<void> _pickBanner() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 85);
    if (picked != null) setState(() => _pickedBanner = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Choisis une catégorie pour ton commerce.');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final businessId = widget.existingBusiness?.id ?? _businessService.newBusinessId();

      String logoUrl = widget.existingBusiness?.logoUrl ?? '';
      if (_pickedLogo != null) {
        final ref = FirebaseStorage.instance.ref('business_logos/$businessId.jpg');
        await ref.putFile(_pickedLogo!, SettableMetadata(contentType: 'image/jpeg'));
        logoUrl = await ref.getDownloadURL();
      }

      String bannerUrl = widget.existingBusiness?.bannerUrl ?? '';
      if (_pickedBanner != null) {
        final ref = FirebaseStorage.instance.ref('business_banners/$businessId.jpg');
        await ref.putFile(_pickedBanner!, SettableMetadata(contentType: 'image/jpeg'));
        bannerUrl = await ref.getDownloadURL();
      }

      final business = BusinessModel(
        id: businessId,
        ownerId: uid,
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
        logoUrl: logoUrl,
        bannerUrl: bannerUrl,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        instagramUrl: _instagramController.text.trim(),
        facebookUrl: _facebookController.text.trim(),
        openingHours: _openingHours,
        // Ces deux champs restent volontairement hors de portée de ce
        // formulaire : voir la note dans BUSINESS_README.md sur le passage
        // à une Cloud Function pour les gérer de façon plus robuste.
        isVerified: widget.existingBusiness?.isVerified ?? false,
        isSponsored: widget.existingBusiness?.isSponsored ?? false,
        createdAt: widget.existingBusiness?.createdAt,
      );

      if (widget.isEditing) {
        await _businessService.updateBusiness(businessId, business.toFirestore());
      } else {
        await _businessService.createBusinessWithId(businessId, business);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BusinessDetailScreen(businessId: businessId)),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'Fiche mise à jour !' : 'Ta page Business est en ligne !'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = "L'enregistrement a échoué. Vérifie ta connexion et réessaie.");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier ma page' : 'Créer ma page Business'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  )
                : const Text('Enregistrer', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Bannière ---
                GestureDetector(
                  onTap: _pickBanner,
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceElevated),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildBannerPreview(),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              gradient: AppColors.goldGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: AppColors.black, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Logo ---
                Row(
                  children: [
                    GestureDetector(
                      onTap: _pickLogo,
                      child: Stack(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.gold, width: 2),
                            ),
                            child: ClipOval(child: _buildLogoPreview()),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                gradient: AppColors.goldGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_rounded, color: AppColors.black, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Ajoute un logo et une bannière pour donner confiance à tes clients.',
                        style: TextStyle(color: Colors.white54, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _FieldLabel('Nom du commerce'),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Ex : Chez Kaze Restaurant'),
                  validator: (value) =>
                      (value == null || value.trim().length < 2) ? 'Nom requis.' : null,
                ),
                const SizedBox(height: 18),

                const _FieldLabel('Catégorie'),
                const SizedBox(height: 8),
                BusinessCategoryPicker(
                  selected: _selectedCategory,
                  onSelected: (category) => setState(() => _selectedCategory = category),
                ),
                const SizedBox(height: 18),

                const _FieldLabel('Description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 300,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Décris ton commerce, tes spécialités...'),
                ),
                const SizedBox(height: 8),

                const _FieldLabel('Téléphone'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '+257 79 123 456',
                    prefixIcon: Icon(Icons.call_outlined, color: AppColors.gold),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Numéro requis.' : null,
                ),
                const SizedBox(height: 18),

                const _FieldLabel('WhatsApp (optionnel)'),
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '+257 79 123 456',
                    prefixIcon: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.gold),
                  ),
                ),
                const SizedBox(height: 18),

                const _FieldLabel('Adresse'),
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Avenue, quartier...',
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.gold),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Adresse requise.' : null,
                ),
                const SizedBox(height: 18),

                const _FieldLabel('Ville'),
                TextFormField(
                  controller: _cityController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Bujumbura'),
                ),
                const SizedBox(height: 18),

                const _FieldLabel('Site web (optionnel)'),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.language_rounded, color: AppColors.gold),
                  ),
                ),
                const SizedBox(height: 18),

                const _FieldLabel('Instagram (optionnel)'),
                TextFormField(
                  controller: _instagramController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'https://instagram.com/...'),
                ),
                const SizedBox(height: 18),

                const _FieldLabel('Facebook (optionnel)'),
                TextFormField(
                  controller: _facebookController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'https://facebook.com/...'),
                ),
                const SizedBox(height: 24),

                const _FieldLabel("Horaires d'ouverture"),
                const SizedBox(height: 8),
                OpeningHoursEditor(
                  initialHours: _openingHours,
                  onChanged: (hours) => _openingHours = hours,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.black),
                        )
                      : Text(widget.isEditing ? 'Enregistrer les modifications' : 'Publier ma page'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerPreview() {
    if (_pickedBanner != null) return Image.file(_pickedBanner!, fit: BoxFit.cover);
    final url = widget.existingBusiness?.bannerUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
    }
    return const Center(
      child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 32),
    );
  }

  Widget _buildLogoPreview() {
    if (_pickedLogo != null) return Image.file(_pickedLogo!, fit: BoxFit.cover);
    final url = widget.existingBusiness?.logoUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
    }
    return const ColoredBox(
      color: AppColors.surfaceElevated,
      child: Icon(Icons.storefront_rounded, color: AppColors.gold, size: 28),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
