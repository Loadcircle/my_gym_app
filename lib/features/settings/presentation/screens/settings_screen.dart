import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/language_picker_sheet.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../exercises/providers/custom_exercises_provider.dart';
import '../../../exercises/providers/weight_records_provider.dart';
import '../../../profile/providers/user_profile_provider.dart';
import '../../../routines/providers/routines_provider.dart';
import '../../../routines/providers/routine_completion_status_provider.dart';
import '../../../notifications/providers/notification_providers.dart';

/// Pantalla de configuración de la cuenta.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSendingResetEmail = false;
  bool _isDeletingAccount = false;

  String _currentLanguageName(WidgetRef ref, AppLocalizations l10n) {
    final locale = ref.watch(localeNotifierProvider);
    switch (locale.languageCode) {
      case 'es':
        return l10n.spanish;
      case 'pt':
        return l10n.portuguese;
      default:
        return l10n.english;
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final l10n = AppLocalizations.of(context);
    final authState = ref.read(authStateProvider);
    final email = authState.user?.email;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.couldNotGetEmail),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dl10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(dl10n.changePasswordTitle),
          content: Text(dl10n.changePasswordMessage(email)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dl10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(dl10n.send),
            ),
          ],
        );
      },
    );

    if (shouldSend == true && mounted) {
      setState(() => _isSendingResetEmail = true);
      try {
        await ref.read(authStateProvider.notifier).resetPassword(email: email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.emailSentTo(email)),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorSendingEmail(e.toString())),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSendingResetEmail = false);
        }
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dl10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(dl10n.signOutTitle),
          content: Text(dl10n.signOutConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dl10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: Text(dl10n.signOut),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      try {
        await ref.read(notificationSchedulerProvider).cancelAll();
        await ref.read(authStateProvider.notifier).signOut();
        if (mounted) {
          context.go(RouteNames.login);
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorSigningOut(e.toString())),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteAccountFlow() async {
    // Modal 1: Informacion
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dl10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(dl10n.deleteAccountTitle),
          content: Text(dl10n.deleteAccountMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dl10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(dl10n.continueAction),
            ),
          ],
        );
      },
    );

    if (shouldContinue != true || !mounted) return;

    // Modal 2: Confirmacion fuerte
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dl10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(dl10n.deleteAccountFinalTitle),
          content: Text(dl10n.deleteAccountFinalMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dl10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: Text(dl10n.deleteDefinitely),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    // Ejecutar eliminacion
    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeletingAccount = true);

    try {
      await ref.read(notificationSchedulerProvider).cancelAll();
      final database = ref.read(appDatabaseProvider);
      await ref.read(authStateProvider.notifier).deleteAccount(database);

      // Invalidar providers para limpiar datos en memoria
      ref.invalidate(customExercisesProvider);
      ref.invalidate(routinesProvider);
      ref.invalidate(allHistoryProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(routineCompletionsProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        context.go(RouteNames.login);
        // Mostrar toast despues de navegar
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.accountDeleted),
                backgroundColor: AppColors.success,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() => _isDeletingAccount = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneric(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);
    final email = authState.user?.email ?? '';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(l10n.settings),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              // Seccion Cuenta
              _SectionHeader(title: l10n.account),
              const SizedBox(height: 8),

              // Email (solo lectura)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  title: Text(l10n.email),
                  subtitle: Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Cambiar contrasena
              Card(
                child: ListTile(
                  leading: _isSendingResetEmail
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  title: Text(l10n.changePassword),
                  subtitle: Text(l10n.changePasswordSubtitle),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                  onTap: _isSendingResetEmail ? null : _showChangePasswordDialog,
                ),
              ),

              const SizedBox(height: 24),

              // Seccion Idioma
              _SectionHeader(title: l10n.language),
              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.language, color: AppColors.textSecondary),
                  title: Text(l10n.language),
                  subtitle: Text(_currentLanguageName(ref, l10n)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                  onTap: () => showLanguagePickerSheet(context),
                ),
              ),

              const SizedBox(height: 24),

              // Seccion Notificaciones
              _SectionHeader(title: l10n.notifications),
              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                  title: Text(l10n.notifications),
                  subtitle: Text(l10n.notificationsSubtitle),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                  onTap: () => context.push(RouteNames.notificationSettings),
                ),
              ),

              const SizedBox(height: 24),

              // Seccion Sesion
              _SectionHeader(title: l10n.session),
              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: Text(
                    l10n.signOut,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                  onTap: _showLogoutDialog,
                ),
              ),

              const SizedBox(height: 24),

              // Seccion Legal
              _SectionHeader(title: l10n.legal),
              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondary),
                      title: Text(l10n.privacyPolicy),
                      trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textHint),
                      onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.textSecondary),
                      title: Text(l10n.termsAndConditions),
                      trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textHint),
                      onTap: () => _launchUrl(AppConstants.termsAndConditionsUrl),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Seccion Zona de peligro
              _SectionHeader(title: l10n.dangerZone),
              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppColors.error),
                  title: Text(
                    l10n.deleteAccount,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                  subtitle: Text(l10n.deleteAccountSubtitle),
                  onTap: _showDeleteAccountFlow,
                ),
              ),

              const SizedBox(height: 24),

              // Seccion Acerca de
              _SectionHeader(title: l10n.about),
              const SizedBox(height: 8),

              SafeArea(child:  _AppInfoCard()),
            ],
          ),
        ),
        // Loading overlay
        if (_isDeletingAccount)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    l10n.deletingAccount,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Header de sección.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
/// Card con información de la app.
class _AppInfoCard extends StatelessWidget {
  const _AppInfoCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;

        final appName = info?.appName ?? 'GymVault';
        final version = info?.version ?? '...';
        final buildNumber = info?.buildNumber ?? '';
        final buildSuffix = buildNumber.isNotEmpty ? ' ($buildNumber)' : '';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),

                // Nombre
                Text(
                  appName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),

                // Versión
                Text(
                  l10n.versionInfo(version, buildSuffix),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),

                // Descripción corta
                Text(
                  l10n.appDescription,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),

                const SizedBox(height: 16),

                // Footer legal mínimo
                Text(
                  l10n.copyright,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
