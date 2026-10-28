import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/diploma_level.dart';
import '../../models/field_of_study.dart';
import '../../services/job_offer_service.dart';
import 'widgets/option_chip.dart';

/// Formulaire de publication d'une offre d'emploi. Diplôme et domaines sont
/// facultatifs : sans eux, l'offre s'affiche à tout le monde.
class JobOfferFormScreen extends StatefulWidget {
  const JobOfferFormScreen({super.key});

  @override
  State<JobOfferFormScreen> createState() => _JobOfferFormScreenState();
}

class _JobOfferFormScreenState extends State<JobOfferFormScreen> {
  final _service = JobOfferService();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _diplomaOtherController = TextEditingController();

  DiplomaLevel? _diploma;
  final Set<FieldOfStudy> _fields = {};
  bool _isPublishing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _whatsappController.dispose();
    _diplomaOtherController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final loc = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final requiredControllers = [
      _titleController,
      _companyController,
      _cityController,
      _descriptionController,
    ];
    final missingRequired =
        requiredControllers.any((c) => c.text.trim().isEmpty);
    final missingOther = _diploma == DiplomaLevel.other &&
        _diplomaOtherController.text.trim().isEmpty;

    if (missingRequired || missingOther) {
      setState(() => _errorMessage = loc.t('jobs.requiredField'));
      return;
    }

    setState(() {
      _isPublishing = true;
      _errorMessage = null;
    });

    try {
      await _service.publishOffer(
        title: _titleController.text,
        company: _companyController.text,
        city: _cityController.text,
        description: _descriptionController.text,
        contactWhatsapp: _whatsappController.text,
        minDiploma: _diploma,
        minDiplomaOther: _diplomaOtherController.text,
        fields: _fields.toList(),
      );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(loc.t('jobs.published'))));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPublishing = false;
        _errorMessage = loc.t('jobs.publishFailed');
      });
    }
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    int maxLength = 80,
    TextInputType? keyboardType,
    bool showCounter = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          counterText: showCounter ? null : '',
          counterStyle: const TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _isPublishing ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(loc.t('jobs.formTitle')),
      ),
      body: AbsorbPointer(
        absorbing: _isPublishing,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('jobs.scamWarning'),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12.5, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.t('jobs.lifetimeHint'),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _field(_titleController, loc.t('jobs.fieldTitle')),
            _field(_companyController, loc.t('jobs.fieldCompany')),
            _field(_cityController, loc.t('jobs.fieldCity'), maxLength: 60),
            _field(
              _descriptionController,
              loc.t('jobs.fieldDescription'),
              maxLines: 6,
              maxLength: 1500,
              showCounter: true,
            ),
            _field(
              _whatsappController,
              loc.t('jobs.fieldWhatsapp'),
              maxLength: 20,
              keyboardType: TextInputType.phone,
            ),
            _label(loc.t('jobs.fieldDiploma')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OptionChip(
                  label: loc.t('jobs.noDiploma'),
                  selected: _diploma == null,
                  onTap: () => setState(() => _diploma = null),
                ),
                ...DiplomaLevel.values.map(
                  (level) => OptionChip(
                    label: loc.t(diplomaLevelKey(level)),
                    selected: _diploma == level,
                    onTap: () => setState(() => _diploma = level),
                  ),
                ),
              ],
            ),
            if (_diploma == DiplomaLevel.other) ...[
              const SizedBox(height: 12),
              _field(_diplomaOtherController, loc.t('jobs.fieldDiplomaOther')),
            ],
            _label(loc.t('jobs.fieldFields')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FieldOfStudy.values
                  .map(
                    (field) => OptionChip(
                      label: loc.t(fieldOfStudyKey(field)),
                      selected: _fields.contains(field),
                      onTap: () => setState(() {
                        if (!_fields.remove(field)) {
                          _fields.add(field);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 26),
            ElevatedButton(
              onPressed: _isPublishing ? null : _publish,
              child: _isPublishing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.black,
                      ),
                    )
                  : Text(loc.t('jobs.publish')),
            ),
          ],
        ),
      ),
    );
  }
}
