import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/google_sign_in_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

/// Pantalla de registro.
/// Permite al usuario crear una cuenta con email y contrasena.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Limpiar errores previos
    ref.read(authStateProvider.notifier).clearError();

    try {
      await ref.read(authStateProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (mounted) {
        context.go(RouteNames.exercises);
      }
    } catch (e) {
      // Mostrar error en UI
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // Limpiar errores previos
    ref.read(authStateProvider.notifier).clearError();

    try {
      final success = await ref.read(authStateProvider.notifier).signInWithGoogle();

      // Si el usuario cancelo, no hacemos nada
      if (!success) return;

      if (mounted) {
        context.go(RouteNames.exercises);
      }
    } catch (e) {
      // El error ya se maneja en el provider y se muestra via el listener
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Escuchar errores para mostrar snackbar
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        _showErrorSnackBar(next.errorMessage!);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: authState.isLoading ? null : () => context.go(RouteNames.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Crear Cuenta',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Registrate para empezar',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Name field
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  enabled: !authState.isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Tu nombre',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !authState.isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'tu@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  enabled: !authState.isLoading,
                  decoration: InputDecoration(
                    labelText: 'Contrasena',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  enabled: !authState.isLoading,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contrasena',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  onFieldSubmitted: (_) => _handleRegister(),
                ),
                const SizedBox(height: 32),

                // Register button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleRegister,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Text('Registrarse'),
                ),
                const SizedBox(height: 24),

                // Divisor "o continua con"
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.textSecondary)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'o continua con',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 24),

                // Boton de Google
                GoogleSignInButton(
                  onPressed: authState.isLoading ? null : _handleGoogleSignIn,
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: 16),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ya tienes cuenta? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () => context.go(RouteNames.login),
                      child: const Text('Inicia Sesion'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
