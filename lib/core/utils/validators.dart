import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../constants/app_constants.dart';

/// Clase de utilidades para validacion de formularios.
/// Usa AppLocalizations para mensajes internacionalizados.
abstract class Validators {
  /// Expresion regular para validar formato de email.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Valida que el email tenga formato correcto.
  static String? validateEmail(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return l10n.validationEmailRequired;
    }

    final trimmedValue = value.trim();

    if (!_emailRegex.hasMatch(trimmedValue)) {
      return l10n.validationEmailInvalid;
    }

    return null;
  }

  /// Valida que la contrasena cumpla requisitos minimos.
  static String? validatePassword(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.validationPasswordRequired;
    }

    if (value.length < AppConstants.minPasswordLength) {
      return l10n.validationPasswordMinLength(AppConstants.minPasswordLength);
    }

    return null;
  }

  /// Valida que la contrasena de confirmacion coincida.
  static String? validateConfirmPassword(String? value, String? password, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.validationConfirmPassword;
    }

    if (value != password) {
      return l10n.validationPasswordsDoNotMatch;
    }

    return null;
  }

  /// Valida que el nombre no este vacio.
  static String? validateName(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return l10n.validationNameRequired;
    }

    if (value.trim().length < 2) {
      return l10n.validationNameMinLength;
    }

    return null;
  }

  /// Valida que el campo no este vacio.
  static String? validateRequired(String? value, BuildContext context, {String fieldName = ''}) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      if (fieldName.isNotEmpty) {
        return l10n.validationFieldRequired(fieldName);
      }
      return l10n.validationFieldRequired(fieldName);
    }

    return null;
  }

  /// Valida un peso de ejercicio.
  static String? validateWeight(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return l10n.validationWeightRequired;
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return l10n.validationEnterValidNumber;
    }

    if (weight < AppConstants.minWeight) {
      return l10n.validationWeightNegative;
    }

    if (weight > AppConstants.maxWeight) {
      return l10n.validationWeightMax(AppConstants.maxWeight.toString());
    }

    return null;
  }

  /// Valida numero de series.
  static String? validateSets(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return null; // Series es opcional
    }

    final sets = int.tryParse(value);
    if (sets == null) {
      return l10n.validationEnterInteger;
    }

    if (sets < 1) {
      return l10n.validationMinSets;
    }

    if (sets > AppConstants.maxSets) {
      return l10n.validationMaxSets(AppConstants.maxSets);
    }

    return null;
  }

  /// Valida numero de repeticiones.
  static String? validateReps(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return null; // Reps es opcional
    }

    final reps = int.tryParse(value);
    if (reps == null) {
      return l10n.validationEnterInteger;
    }

    if (reps < 1) {
      return l10n.validationMinReps;
    }

    if (reps > AppConstants.maxReps) {
      return l10n.validationMaxReps(AppConstants.maxReps);
    }

    return null;
  }
}
