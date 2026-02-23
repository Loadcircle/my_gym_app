import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/onboarding/tour_provider.dart';
import '../../features/profile/providers/user_profile_provider.dart';
import '../../l10n/app_localizations.dart';

/// Drawer lateral de la aplicacion.
/// Muestra el perfil del usuario y opciones de navegacion.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);
    final profileAsync = ref.watch(userProfileStreamProvider);

    final user = authState.user;
    final profile = profileAsync.valueOrNull;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // Header con info del usuario
          _DrawerHeader(
            displayName: profile?.fullName.isNotEmpty == true
                ? profile!.fullName
                : user?.displayName ?? l10n.user,
            email: user?.email ?? '',
          ),

          // Items de navegacion
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.person_outline,
                  label: l10n.myProfile,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(RouteNames.profile);
                  },
                ),
                _DrawerItem(
                  icon: Icons.insights_outlined,
                  label: l10n.generalProgress,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(RouteNames.progress);
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: l10n.configuration,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(RouteNames.settings);
                  },
                ),
                const Divider(color: AppColors.border, height: 32),
                _DrawerItem(
                  icon: Icons.help_outline,
                  label: l10n.featureTour,
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(tourNotifierProvider.notifier).resetAllTours();
                    ref.read(triggerExercisesTourProvider.notifier).state = true;
                  },
                ),
                _DrawerItem(
                  icon: Icons.logout,
                  label: l10n.signOut,
                  textColor: AppColors.error,
                  iconColor: AppColors.error,
                  onTap: () => _showLogoutDialog(context, ref),
                ),
              ],
            ),
          ),

          // Version de la app
          const _AppVersionFooter(),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.signOutTitle),
          content: Text(l10n.signOutConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: Text(l10n.signOut),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      Navigator.of(context).pop(); // Cerrar drawer
      try {
        await ref.read(authStateProvider.notifier).signOut();
        if (context.mounted) {
          context.go(RouteNames.login);
        }
      } catch (e) {
        if (context.mounted) {
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
}

/// Header del drawer con avatar y datos del usuario.
class _DrawerHeader extends StatelessWidget {
  final String displayName;
  final String email;

  const _DrawerHeader({
    required this.displayName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar placeholder
          InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () {
              Navigator.of(context).pop(); // cerrar drawer
              context.push(RouteNames.profile);
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Center(
                child: Text(
                  _getInitials(displayName),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nombre
          Text(
            displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

/// Item del drawer.
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor ?? AppColors.textPrimary,
            ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}

/// Footer con la version de la app.
class _AppVersionFooter extends StatelessWidget {
  const _AppVersionFooter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '...';
        final buildNumber = snapshot.data?.buildNumber ?? '';

        return Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'v$version${buildNumber.isNotEmpty ? '+$buildNumber' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        );
      },
    );
  }
}
