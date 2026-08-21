import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../auth/welcome_screen.dart';
import 'language_selector_sheet.dart';

/// Écran Paramètres, accessible depuis le menu du Profil.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _languageLabelKeys = {
    'rn': 'lang.rn',
    'fr': 'lang.fr',
    'en': 'lang.en',
    'sw': 'lang.sw',
  };

  Future<void> _confirmLogout(BuildContext context, AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(loc.t('settings.logoutConfirmTitle'), style: const TextStyle(color: Colors.white)),
        content: Text(loc.t('settings.logoutConfirmMessage'), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.t('common.cancel'), style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              loc.t('profile.logout'),
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await NotificationService().clearDeviceToken(uid);
      }
      await AuthService().signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, AppLocalizations loc) async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(loc.t('settings.deleteAccountConfirmTitle'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.t('settings.deleteAccountConfirmMessage'), style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: loc.t('auth.password'),
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.t('common.cancel'), style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              loc.t('settings.deleteAccount'),
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await AuthService().deleteAccount(password: passwordController.text);
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService().friendlyErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final currentLanguageLabel = loc.t(_languageLabelKeys[localeProvider.locale.languageCode] ?? 'lang.fr');

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(title: Text(loc.t('settings.title'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SettingsTile(
            icon: Icons.language_rounded,
            title: loc.t('settings.language'),
            subtitle: currentLanguageLabel,
            onTap: () => showLanguageSelectorSheet(context),
          ),
          const Divider(color: AppColors.surfaceElevated, height: 32, indent: 20, endIndent: 20),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: loc.t('profile.logout'),
            titleColor: AppColors.error,
            onTap: () => _confirmLogout(context, loc),
          ),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            title: loc.t('settings.deleteAccount'),
            titleColor: AppColors.error,
            onTap: () => _confirmDeleteAccount(context, loc),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: titleColor ?? AppColors.gold),
      title: Text(title, style: TextStyle(color: titleColor ?? Colors.white, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: Colors.white54, fontSize: 12.5))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
    );
  }
}