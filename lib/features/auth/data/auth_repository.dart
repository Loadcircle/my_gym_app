import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/utils/logger.dart';
import 'models/user_model.dart';

/// Provider del repositorio de autenticacion.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

/// Excepcion personalizada para errores de autenticacion.
/// Contiene mensajes amigables en espanol.
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Repositorio que encapsula la logica de autenticacion con Firebase Auth.
/// Proporciona mensajes de error amigables en espanol.
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  static const _tag = 'AuthRepository';

  AuthRepository(this._firebaseAuth);

  /// Stream del estado de autenticacion.
  /// Emite el usuario actual cuando cambia el estado de auth.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Obtiene el usuario actualmente autenticado.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Indica si hay un usuario autenticado.
  bool get isAuthenticated => currentUser != null;

  /// Obtiene el UserModel del usuario actual, si existe.
  UserModel? get currentUserModel {
    final user = currentUser;
    if (user == null) return null;
    return UserModel.fromFirebaseUser(user);
  }

  /// Inicia sesion con email y contrasena.
  /// Retorna el UserModel del usuario autenticado.
  /// Lanza [AuthException] si hay error.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Intentando login con email: $email', tag: _tag);

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw AuthException('No se pudo obtener la informacion del usuario');
      }

      AppLogger.info('Login exitoso para: ${user.email}', tag: _tag);
      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      AppLogger.warning('Error de Firebase Auth: ${e.code}', tag: _tag);
      throw _mapFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      AppLogger.warning('Error de Firebase: ${e.code}', tag: _tag);
      throw _mapFirebaseException(e);
    } catch (e) {
      AppLogger.error('Error inesperado en login', tag: _tag, error: e);
      throw AuthException('Ocurrio un error inesperado. Intenta de nuevo.');
    }
  }

  /// Registra un nuevo usuario con email y contrasena.
  /// Opcionalmente establece el nombre del usuario.
  /// Retorna el UserModel del usuario creado.
  /// Lanza [AuthException] si hay error.
  Future<UserModel> createUserWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      AppLogger.info('Creando cuenta para: $email', tag: _tag);

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw AuthException('No se pudo crear la cuenta');
      }

      // Actualizar nombre si se proporciono
      if (displayName != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
        // Recargar para obtener datos actualizados
        await user.reload();
      }

      final updatedUser = _firebaseAuth.currentUser;
      AppLogger.info('Cuenta creada exitosamente: ${user.email}', tag: _tag);

      return UserModel.fromFirebaseUser(updatedUser ?? user);
    } on FirebaseAuthException catch (e) {
      AppLogger.warning('Error de Firebase Auth al crear cuenta: ${e.code}', tag: _tag);
      throw _mapFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      AppLogger.warning('Error de Firebase al crear cuenta: ${e.code}', tag: _tag);
      throw _mapFirebaseException(e);
    } catch (e) {
      AppLogger.error('Error inesperado creando cuenta (${e.runtimeType}): $e', tag: _tag, error: e);
      throw AuthException('Ocurrio un error inesperado. Intenta de nuevo.');
    }
  }

  /// Cierra la sesion del usuario actual.
  /// Lanza [AuthException] si hay error.
  Future<void> signOut() async {
    try {
      AppLogger.info('Cerrando sesion', tag: _tag);
      await _firebaseAuth.signOut();
      // Tambien cerrar sesion de Google si estaba activa
      await GoogleSignIn().signOut();
      AppLogger.info('Sesion cerrada exitosamente', tag: _tag);
    } catch (e) {
      AppLogger.error('Error cerrando sesion', tag: _tag, error: e);
      throw AuthException('No se pudo cerrar la sesion. Intenta de nuevo.');
    }
  }

  /// Inicia sesion con Google.
  /// Si el usuario no existe, se crea automaticamente.
  /// Retorna null si el usuario cancela el flujo.
  /// Lanza [AuthException] si hay error.
  Future<UserModel?> signInWithGoogle() async {
    try {
      AppLogger.info('Iniciando flujo de Google Sign-In', tag: _tag);

      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Iniciar flujo de seleccion de cuenta de Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // El usuario cancelo el flujo
      if (googleUser == null) {
        AppLogger.info('Usuario cancelo Google Sign-In', tag: _tag);
        return null;
      }

      // Obtener credenciales de autenticacion
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crear credencial para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Autenticar con Firebase usando las credenciales de Google
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        throw AuthException('No se pudo obtener la informacion del usuario');
      }

      AppLogger.info('Google Sign-In exitoso para: ${user.email}', tag: _tag);
      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      AppLogger.warning('Error de Firebase Auth en Google Sign-In: ${e.code}',
          tag: _tag);
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      // Verificar si es un error de cancelacion de Google Sign-In
      if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('canceled')) {
        AppLogger.info('Usuario cancelo Google Sign-In', tag: _tag);
        return null;
      }

      AppLogger.error('Error inesperado en Google Sign-In', tag: _tag, error: e);
      throw AuthException(
          'Ocurrio un error al iniciar sesion con Google. Intenta de nuevo.');
    }
  }

  /// Envia un email para restablecer la contrasena.
  /// Lanza [AuthException] si hay error.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      AppLogger.info('Enviando email de recuperacion a: $email', tag: _tag);

      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());

      AppLogger.info('Email de recuperacion enviado', tag: _tag);
    } on FirebaseAuthException catch (e) {
      AppLogger.warning('Error enviando email de recuperacion: ${e.code}', tag: _tag);
      throw _mapFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      AppLogger.warning('Error de Firebase enviando email: ${e.code}', tag: _tag);
      throw _mapFirebaseException(e);
    } catch (e) {
      AppLogger.error('Error inesperado enviando email (${e.runtimeType}): $e', tag: _tag, error: e);
      throw AuthException('No se pudo enviar el email. Intenta de nuevo.');
    }
  }

  /// Actualiza el perfil del usuario actual.
  /// Lanza [AuthException] si hay error.
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw AuthException('No hay usuario autenticado');
      }

      AppLogger.info('Actualizando perfil', tag: _tag);

      if (displayName != null) {
        await user.updateDisplayName(displayName.trim());
      }

      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      await user.reload();
      final updatedUser = _firebaseAuth.currentUser;

      AppLogger.info('Perfil actualizado', tag: _tag);
      return UserModel.fromFirebaseUser(updatedUser ?? user);
    } catch (e) {
      AppLogger.error('Error actualizando perfil', tag: _tag, error: e);
      throw AuthException('No se pudo actualizar el perfil. Intenta de nuevo.');
    }
  }

  /// Mapea FirebaseException generica a AuthException.
  AuthException _mapFirebaseException(FirebaseException e) {
    // Intentar mapear usando el código si está disponible
    final code = e.code;
    switch (code) {
      case 'user-not-found':
        return AuthException('No existe una cuenta con este email', code: code);
      case 'wrong-password':
        return AuthException('Contrasena incorrecta', code: code);
      case 'invalid-credential':
        return AuthException('Email o contrasena incorrectos', code: code);
      case 'user-disabled':
        return AuthException('Esta cuenta ha sido deshabilitada', code: code);
      case 'too-many-requests':
        return AuthException('Demasiados intentos fallidos. Intenta mas tarde', code: code);
      case 'email-already-in-use':
        return AuthException('Ya existe una cuenta con este email', code: code);
      case 'weak-password':
        return AuthException('La contrasena es muy debil. Usa al menos 6 caracteres', code: code);
      case 'invalid-email':
        return AuthException('El formato del email no es valido', code: code);
      case 'network-request-failed':
        return AuthException('Error de conexion. Verifica tu internet', code: code);
      default:
        AppLogger.warning('Codigo de FirebaseException no mapeado: $code', tag: _tag);
        return AuthException(e.message ?? 'Ocurrio un error. Intenta de nuevo', code: code);
    }
  }

  /// Mapea las excepciones de FirebaseAuth a mensajes amigables en espanol.
  AuthException _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      // Errores de login
      case 'user-not-found':
        return AuthException(
          'No existe una cuenta con este email',
          code: e.code,
        );
      case 'wrong-password':
        return AuthException(
          'Contrasena incorrecta',
          code: e.code,
        );
      case 'invalid-credential':
        return AuthException(
          'Email o contrasena incorrectos',
          code: e.code,
        );
      case 'user-disabled':
        return AuthException(
          'Esta cuenta ha sido deshabilitada',
          code: e.code,
        );
      case 'too-many-requests':
        return AuthException(
          'Demasiados intentos fallidos. Intenta mas tarde',
          code: e.code,
        );

      // Errores de registro
      case 'email-already-in-use':
        return AuthException(
          'Ya existe una cuenta con este email',
          code: e.code,
        );
      case 'weak-password':
        return AuthException(
          'La contrasena es muy debil. Usa al menos 6 caracteres',
          code: e.code,
        );

      // Errores generales
      case 'invalid-email':
        return AuthException(
          'El formato del email no es valido',
          code: e.code,
        );
      case 'network-request-failed':
        return AuthException(
          'Error de conexion. Verifica tu internet',
          code: e.code,
        );
      case 'operation-not-allowed':
        return AuthException(
          'Este metodo de autenticacion no esta habilitado',
          code: e.code,
        );

      // Errores de Google Sign-In / Account Linking
      case 'account-exists-with-different-credential':
        return AuthException(
          'Ya existe una cuenta con este email usando otro metodo de inicio de sesion. '
          'Intenta iniciar sesion con email y contrasena.',
          code: e.code,
        );

      // Error por defecto
      default:
        AppLogger.warning('Codigo de error no mapeado: ${e.code}', tag: _tag);
        return AuthException(
          'Ocurrio un error. Intenta de nuevo',
          code: e.code,
        );
    }
  }
}
