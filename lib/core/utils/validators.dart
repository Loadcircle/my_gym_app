import '../constants/app_constants.dart';

/// Clase de utilidades para validacion de formularios.
/// Todos los mensajes estan en espanol.
abstract class Validators {
  /// Expresion regular para validar formato de email.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Valida que el email tenga formato correcto.
  /// Retorna null si es valido, mensaje de error si no.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }

    final trimmedValue = value.trim();

    if (!_emailRegex.hasMatch(trimmedValue)) {
      return 'Ingresa un email valido';
    }

    return null;
  }

  /// Valida que la contrasena cumpla requisitos minimos.
  /// Retorna null si es valida, mensaje de error si no.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contrasena es requerida';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'La contrasena debe tener al menos ${AppConstants.minPasswordLength} caracteres';
    }

    return null;
  }

  /// Valida que la contrasena de confirmacion coincida.
  /// Retorna null si coincide, mensaje de error si no.
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contrasena';
    }

    if (value != password) {
      return 'Las contrasenas no coinciden';
    }

    return null;
  }

  /// Valida que el nombre no este vacio.
  /// Retorna null si es valido, mensaje de error si no.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }

    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    return null;
  }

  /// Valida que el campo no este vacio.
  /// Retorna null si es valido, mensaje de error si no.
  static String? validateRequired(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    return null;
  }

  /// Valida un peso de ejercicio.
  /// Retorna null si es valido, mensaje de error si no.
  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El peso es requerido';
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Ingresa un numero valido';
    }

    if (weight < AppConstants.minWeight) {
      return 'El peso no puede ser negativo';
    }

    if (weight > AppConstants.maxWeight) {
      return 'El peso maximo es ${AppConstants.maxWeight} kg';
    }

    return null;
  }

  /// Valida numero de series.
  /// Retorna null si es valido, mensaje de error si no.
  static String? validateSets(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Series es opcional
    }

    final sets = int.tryParse(value);
    if (sets == null) {
      return 'Ingresa un numero entero';
    }

    if (sets < 1) {
      return 'Minimo 1 serie';
    }

    if (sets > AppConstants.maxSets) {
      return 'Maximo ${AppConstants.maxSets} series';
    }

    return null;
  }

  /// Valida numero de repeticiones.
  /// Retorna null si es valido, mensaje de error si no.
  static String? validateReps(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Reps es opcional
    }

    final reps = int.tryParse(value);
    if (reps == null) {
      return 'Ingresa un numero entero';
    }

    if (reps < 1) {
      return 'Minimo 1 repeticion';
    }

    if (reps > AppConstants.maxReps) {
      return 'Maximo ${AppConstants.maxReps} repeticiones';
    }

    return null;
  }
}
