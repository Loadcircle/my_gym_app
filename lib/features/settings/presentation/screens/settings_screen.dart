import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/providers/auth_provider.dart';

/// Pantalla de configuración de la cuenta.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSendingResetEmail = false;

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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final email = authState.user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configuracion'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // Sección Cuenta
          _SectionHeader(title: 'Cuenta'),
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

          // Cambiar contraseña
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

          // Sección Sesión
          _SectionHeader(title: 'Sesion'),
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

          // Sección Acerca de
          _SectionHeader(title: 'Acerca de'),
          const SizedBox(height: 8),

          _AppInfoCard(),
        ],
      ),
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
        final version = info?.version ?? '...';
        final buildNumber = info?.buildNumber ?? '';
        final appName = info?.appName ?? 'My Gym App';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Logo/Icono de la app
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // Nombre de la app
                Text(
                  appName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),

                // Versión
                Text(
                  'Version $version${buildNumber.isNotEmpty ? ' ($buildNumber)' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
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
