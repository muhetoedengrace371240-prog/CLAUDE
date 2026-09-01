import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/business_model.dart';

/// Une ligne d'édition d'horaire pour un jour donné : champ texte
/// "HH:mm-HH:mm" désactivé et grisé quand le switch "Fermé" est activé.
class OpeningHoursEditor extends StatefulWidget {
  const OpeningHoursEditor({super.key, required this.initialHours, required this.onChanged});

  final Map<String, String> initialHours;
  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<OpeningHoursEditor> createState() => _OpeningHoursEditorState();
}

class _OpeningHoursEditorState extends State<OpeningHoursEditor> {
  late final Map<String, TextEditingController> _controllers = {
    for (final day in kWeekDaysFr)
      day: TextEditingController(
        text: (widget.initialHours[day] ?? '').toLowerCase() == 'fermé'
            ? ''
            : (widget.initialHours[day] ?? '08:00-18:00'),
      ),
  };

  late final Map<String, bool> _isClosed = {
    for (final day in kWeekDaysFr) day: (widget.initialHours[day] ?? '').toLowerCase() == 'fermé',
  };

  void _emitChange() {
    final result = <String, String>{
      for (final day in kWeekDaysFr)
        day: _isClosed[day]! ? 'Fermé' : (_controllers[day]!.text.trim().isEmpty ? 'Fermé' : _controllers[day]!.text.trim()),
    };
    widget.onChanged(result);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: kWeekDaysFr.map((day) {
        final isClosed = _isClosed[day]!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                child: Text(day, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              Expanded(
                child: TextField(
                  controller: _controllers[day],
                  enabled: !isClosed,
                  onChanged: (_) => _emitChange(),
                  style: TextStyle(color: isClosed ? AppColors.textMuted : Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '08:00-18:00',
                    filled: true,
                    fillColor: isClosed ? Colors.transparent : AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Fermé', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                  Switch(
                    value: isClosed,
                    activeColor: AppColors.gold,
                    onChanged: (value) {
                      setState(() => _isClosed[day] = value);
                      _emitChange();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
