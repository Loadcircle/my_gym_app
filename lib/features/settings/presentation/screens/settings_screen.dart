import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../exercises/providers/custom_exercises_provider.dart';
import '../../../exercises/providers/weight_records_provider.dart';
import '../../../profile/providers/user_profile_provider.dart';
import '../../../routines/providers/routines_provider.dart';
import '../../../routines/providers/routine_completion_status_provider.dart';

/// Pantalla de configuración de la cuenta.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSendingResetEmail = false;
  bool _isDeletingAccount = false;

  Future<void> _showChangePasswordDialog() async {
    final authState = ref.read(authStateProvider);
    final email = authState.user?.email;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener el email de la cuenta'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contrasena'),
        content: Text(
          'Se enviara un enlace para cambiar tu contrasena a:\n\n$email',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (shouldSend == true && mounted) {
      setState(() => _isSendingResetEmail = true);
      try {
        await ref.read(authStateProvider.notifier).resetPassword(email: email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email enviado a $email'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar email: $e'),
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
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesion'),
        content: const Text('¿Estas seguro que deseas cerrar sesion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Cerrar Sesion'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await ref.read(authStateProvider.notifier).signOut();
        if (mounted) {
          context.go(RouteNames.login);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesion: $e'),
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
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Al eliminar la cuenta, se eliminan todos los datos personales '
          'y de entrenamiento asociados.\n\n'
          'Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (shouldContinue != true || !mounted) return;

    // Modal 2: Confirmacion fuerte
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cuenta definitivamente?'),
        content: const Text(
          'Se eliminaran todos tus ejercicios, rutinas, '
          'registros de peso y datos personales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    // Ejecutar eliminacion
    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeletingAccount = true);

    try {
      final database = ref.read(appDatabaseProvider);
      await ref.read(authStateProvider.notifier).deleteAccount(database);

      // Invalidar providers para limpiar datos en memoria
      ref.invalidate(customExercisesProvider);
      ref.invalidate(routinesProvider);
      ref.invalidate(allHistoryProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(routineCompletionsProvider);

      if (mounted) {
        context.go(RouteNames.login);
        // Mostrar toast despues de navegar
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cuenta eliminada'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final email = authState.user?.email ?? '';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Configuracion'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              // Seccion Cuenta
              const _SectionHeader(title: 'Cuenta'),
              const SizedBox(height: 8),

              // Email (solo lectura)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  title: const Text('Email'),
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
                  title: const Text('Cambiar contrasena'),
                  subtitle: const Text('Se enviara un email con instrucciones'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                  onTap: _isSendingResetEmail ? null : _showChangePasswordDialog,
                ),
              ),

              const SizedBox(height: 24),

              // Seccion Sesion
              const _SectionHeader(title: 'Sesion'),
              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: Text(
                    'Cerrar sesion',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                  onTap: _showLogoutDialog,
                ),
              ),

              const SizedBox(height: 24),

              // Seccion Legal
              const _SectionHeader(title: 'Legal'),
              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondary),
                      title: const Text('Politica de privacidad'),
                      trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textHint),
                      onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.textSecondary),
                      title: const Text('Terminos y condiciones'),
                      trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textHint),
                      onTap: () => _launchUrl(AppConstants.termsAndConditionsUrl),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Seccion Zona de peligro
              const _SectionHeader(title: 'Zona de peligro'),
              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppColors.error),
                  title: Text(
                    'Eliminar cuenta',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                  subtitle: const Text('Elimina permanentemente tu cuenta y datos'),
                  onTap: _showDeleteAccountFlow,
                ),
              ),

              const SizedBox(height: 24),

              // Seccion Acerca de
              const _SectionHeader(title: 'Acerca de'),
              const SizedBox(height: 8),

              SafeArea(child:  _AppInfoCard()),
            ],
          ),
        ),
        // Loading overlay
        if (_isDeletingAccount)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Eliminando cuenta...',
                    style: TextStyle(color: Colors.white),
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
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;

        final appName = info?.appName ?? 'GymVault';
        final version = info?.version ?? '...';
        final buildNumber = info?.buildNumber ?? '';

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
                    'assets/images/logo.png',
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
                  'Versión $version${buildNumber.isNotEmpty ? ' ($buildNumber)' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),

                // Descripción corta
                Text(
                  'Registra tus entrenamientos, ejercicios y progreso en el gimnasio.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),

                const SizedBox(height: 16),

                // Footer legal mínimo
                Text(
                  '© 2026 GymVault',
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
