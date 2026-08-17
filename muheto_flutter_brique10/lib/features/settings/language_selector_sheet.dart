import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_theme.dart';

const _kLanguageOptions = [
  (code: 'rn', flag: '🇧🇮', labelKey: 'lang.rn'),
  (code: 'fr', flag: '🇫🇷', labelKey: 'lang.fr'),
  (code: 'en', flag: '🇬🇧', labelKey: 'lang.en'),
  (code: 'sw', flag: '🇹🇿', labelKey: 'lang.sw'),
];

/// Affiche le bottom sheet de sélection de langue. À appeler via :
/// ```dart
/// showLanguageSelectorSheet(context);
/// ```
Future<void> showLanguageSelectorSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const LanguageSelectorSheet(),
  );
}

class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final currentCode = localeProvider.locale.languageCode;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              loc.t('settings.chooseLanguage'),
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ..._kLanguageOptions.map((option) {
              final isSelected = option.code == currentCode;
              return GestureDetector(
                onTap: () {
                  context.read<LocaleProvider>().setLocale(Locale(option.code));
                  Navigator.of(context).pop();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.goldGradient : null,
                    color: isSelected ? null : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(option.flag, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loc.t(option.labelKey),
                          style: TextStyle(
                            color: isSelected ? AppColors.black : Colors.white,
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.black, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
