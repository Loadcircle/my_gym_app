import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/logger.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';
import 'auth_state.dart';

/// Provider del estado de autenticacion.
/// Escucha cambios en el estado de auth de Firebase.
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Provider que expone solo si el usuario esta autenticado.
/// Util para guards de navegacion.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAuthenticated;
});

/// Provider que expone el usuario actual.
/// Retorna null si no esta autenticado.
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

/// Provider del stream de cambios de autenticacion.
/// Util para escuchar cambios en tiempo real.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// Notifier que maneja el estado de autenticacion.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<User?>? _authSubscription;
  static const _tag = 'AuthNotifier';

  AuthNotifier(this._repository) : super(AuthState.initial()) {
    _init();
  }

  /// Inicializa el listener del estado de auth.
  void _init() {
    AppLogger.info('Inicializando AuthNotifier', tag: _tag);

    _authSubscription = _repository.authStateChanges.listen(
      (user) {
        AppLogger.info(
          'Cambio en estado de auth: ${user?.email ?? 'sin usuario'}',
          tag: _tag,
        );

        if (user != null) {
          state = AuthState.authenticated(UserModel.fromFirebaseUser(user));
        } else {
          // Solo cambiar a unauthenticated si no estamos en estado de error
          // para no sobrescribir mensajes de error de login/registro fallido
          if (state.status != AuthStatus.error) {
            state = AuthState.unauthenticated();
          }
        }
      },
      onError: (error) {
        AppLogger.error('Error en auth stream', tag: _tag, error: error);
        state = AuthState.error('Error verificando autenticacion');
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Inicia sesion con email y contrasena.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final user = await _repository.signInWithEmail(
        email: email,
        password: password,
      );

      state = AuthState.authenticated(user);
      AppLogger.info('Login exitoso', tag: _tag);
    } on AuthException catch (e) {
      AppLogger.warning('Error en login: ${e.message}', tag: _tag);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        status: AuthStatus.error,
      );
      rethrow;
    } catch (e) {
      AppLogger.error('Error inesperado en login', tag: _tag, error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ocurrio un error inesperado',
        status: AuthStatus.error,
      );
      rethrow;
    }
  }

  /// Registra un nuevo usuario.
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final user = await _repository.createUserWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      state = AuthState.authenticated(user);
      AppLogger.info('Registro exitoso', tag: _tag);
    } on AuthException catch (e) {
      AppLogger.warning('Error en registro: ${e.message}', tag: _tag);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        status: AuthStatus.error,
      );
      rethrow;
    } catch (e) {
      AppLogger.error('Error inesperado en registro', tag: _tag, error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ocurrio un error inesperado',
        status: AuthStatus.error,
      );
      rethrow;
    }
  }

  /// Cierra la sesion del usuario actual.
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.signOut();
      state = AuthState.unauthenticated();
      AppLogger.info('Sesion cerrada', tag: _tag);
    } catch (e) {
      AppLogger.error('Error cerrando sesion', tag: _tag, error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cerrar sesion',
      );
      rethrow;
    }
  }

  /// Envia email para recuperar contrasena.
  Future<void> resetPassword({required String email}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _repository.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
      AppLogger.info('Email de recuperacion enviado', tag: _tag);
    } on AuthException catch (e) {
      AppLogger.warning('Error enviando email de recuperacion: ${e.message}', tag: _tag);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      AppLogger.error('Error inesperado enviando email', tag: _tag, error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ocurrio un error inesperado',
      );
      rethrow;
    }
  }

  /// Inicia sesion con Google.
  /// Retorna true si el login fue exitoso, false si el usuario cancelo.
  Future<bool> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final user = await _repository.signInWithGoogle();

      // El usuario cancelo el flujo
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      state = AuthState.authenticated(user);
      AppLogger.info('Google Sign-In exitoso', tag: _tag);
      return true;
    } on AuthException catch (e) {
      AppLogger.warning('Error en Google Sign-In: ${e.message}', tag: _tag);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        status: AuthStatus.error,
      );
      rethrow;
    } catch (e) {
      AppLogger.error('Error inesperado en Google Sign-In', tag: _tag, error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ocurrio un error inesperado',
        status: AuthStatus.error,
      );
      rethrow;
    }
  }

  /// Limpia el mensaje de error actual.
  /// Tambien resetea el status a unauthenticated si estamos en estado de error.
  void clearError() {
    if (state.errorMessage != null || state.status == AuthStatus.error) {
      state = state.copyWith(
        errorMessage: null,
        status: state.user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      );
    }
  }
}
