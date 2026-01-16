import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/models/user_model.dart';

part 'auth_state.freezed.dart';

/// Estados posibles de la autenticacion.
enum AuthStatus {
  /// Estado inicial, no se ha verificado aun.
  initial,

  /// Verificando estado de autenticacion.
  loading,

  /// Usuario autenticado.
  authenticated,

  /// Usuario no autenticado.
  unauthenticated,

  /// Error de autenticacion.
  error,
}

/// Estado de autenticacion de la aplicacion.
@freezed
class AuthState with _$AuthState {
  const AuthState._();

  const factory AuthState({
    /// Estado actual de la autenticacion.
    @Default(AuthStatus.initial) AuthStatus status,

    /// Usuario autenticado, si existe.
    UserModel? user,

    /// Mensaje de error, si hay.
    String? errorMessage,

    /// Indica si se esta procesando una accion (login, registro, etc).
    @Default(false) bool isLoading,
  }) = _AuthState;

  /// Estado inicial.
  factory AuthState.initial() => const AuthState();

  /// Estado de carga.
  factory AuthState.loading() => const AuthState(
        status: AuthStatus.loading,
        isLoading: true,
      );

  /// Estado autenticado con usuario.
  factory AuthState.authenticated(UserModel user) => AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

  /// Estado no autenticado.
  factory AuthState.unauthenticated() => const AuthState(
        status: AuthStatus.unauthenticated,
      );

  /// Estado de error.
  factory AuthState.error(String message) => AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );

  /// Indica si el usuario esta autenticado.
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  /// Indica si el estado es inicial o cargando.
  bool get isInitialOrLoading =>
      status == AuthStatus.initial || status == AuthStatus.loading;

  /// Indica si hay un error.
  bool get hasError => status == AuthStatus.error && errorMessage != null;
}
