import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/profile_service.dart';
import '../auth/welcome_screen.dart';
import '../gold/gold_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'language_selector_sheet.dart';
import 'terms_screen.dart';

/// Écran Paramètres complet, accessible depuis le menu du Profil :
/// gestion du compte (édition profil, MUHETO Gold), langue, conditions
/// d'utilisation, et zone sensible (déconnexion / suppression de compte).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profileService = ProfileService();
  final _authService = AuthService();
  bool _isNavigatingToProfile = false;

  static const _languageLabelKeys = {
    'rn': 'lang.rn',
    'fr': 'lang.fr',
    'en': 'lang.en',
    'sw': 'lang.sw',
  };

  Future<void> _openEditProfile(AppLocalizations loc) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _isNavigatingToProfile) return;

    setState(() => _isNavigatingToProfile = true);
    try {
      final user = await _profileService.getUserOnce(uid);
      if (!mounted || user == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
      );
    } finally {
      if (mounted) setState(() => _isNavigatingToProfile = false);
    }
  }

  Future<void> _confirmLogout(AppLocalizations loc) async {
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

    if (confirmed == true && mounted) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await NotificationService().clearDeviceToken(uid);
      }
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _confirmDeleteAccount(AppLocalizations loc) async {
    final passwordController = TextEditingController();
    String? errorMessage;
    bool isDeleting = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> handleConfirm() async {
            if (passwordController.text.isEmpty) {
              setDialogState(() => errorMessage = loc.t('settings.reauthRequired'));
              return;
            }
            setDialogState(() {
              isDeleting = true;
              errorMessage = null;
            });
            try {
              await _authService.deleteAccount(password: passwordController.text);
              if (context.mounted) Navigator.of(context).pop(true);
            } catch (e) {
              setDialogState(() {
                isDeleting = false;
                errorMessage = loc.t('settings.deleteAccountFailed');
              });
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              loc.t('settings.deleteAccountConfirmTitle'),
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('settings.deleteAccountConfirmMessage'),
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: loc.t('settings.deleteAccountPasswordHint'),
                    isDense: true,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12.5)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.of(context).pop(false),
                child: Text(loc.t('common.cancel'), style: const TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: isDeleting ? null : handleConfirm,
                child: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                      )
                    : Text(
                        loc.t('settings.deleteAccountButton'),
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          );
        },
      ),
    );

    passwordController.dispose();

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('settings.deleteAccountSuccess'))),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
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
          _SectionHeader(loc.t('settings.account')),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: loc.t('settings.editProfile'),
            onTap: _isNavigatingToProfile ? null : () => _openEditProfile(loc),
            trailing: _isNavigatingToProfile
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  )
                : null,
          ),
          _SettingsTile(
            icon: Icons.workspace_premium_rounded,
            title: loc.t('settings.gold'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GoldScreen()),
            ),
          ),
          const Divider(color: AppColors.surfaceElevated, height: 32, indent: 20, endIndent: 20),

          _SectionHeader(loc.t('settings.general')),
          _SettingsTile(
            icon: Icons.language_rounded,
            title: loc.t('settings.language'),
            subtitle: currentLanguageLabel,
            onTap: () => showLanguageSelectorSheet(context),
          ),
          const Divider(color: AppColors.surfaceElevated, height: 32, indent: 20, endIndent: 20),

          _SettingsTile(
            icon: Icons.description_outlined,
            title: loc.t('settings.terms'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
          const Divider(color: AppColors.surfaceElevated, height: 32, indent: 20, endIndent: 20),

          _SettingsTile(
            icon: Icons.logout_rounded,
            title: loc.t('profile.logout'),
            titleColor: AppColors.error,
            onTap: () => _confirmLogout(loc),
          ),
          const SizedBox(height: 8),
          _SectionHeader(loc.t('settings.dangerZone')),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            title: loc.t('settings.deleteAccount'),
            titleColor: AppColors.error,
            onTap: () => _confirmDeleteAccount(loc),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
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
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: titleColor ?? AppColors.gold),
      title: Text(title, style: TextStyle(color: titleColor ?? Colors.white, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: Colors.white54, fontSize: 12.5))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
    );
  }
}
