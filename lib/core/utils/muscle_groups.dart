import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Utilidad centralizada para grupos musculares.
/// Evita duplicación de listas y funciones de color en múltiples archivos.
abstract class MuscleGroups {
  /// Lista de grupos musculares sin "Todos" (claves internas en español).
  static const List<String> all = [
    'Pecho',
    'Espalda',
    'Piernas',
    'Hombros',
    'Brazos',
    'Core',
  ];

  /// Lista de grupos musculares con "Todos" al inicio.
  static const List<String> withAll = [
    'Todos',
    ...all,
  ];

  static const Map<String, String> _translationsEn = {
    'Todos': 'All',
    'Pecho': 'Chest',
    'Espalda': 'Back',
    'Piernas': 'Legs',
    'Hombros': 'Shoulders',
    'Brazos': 'Arms',
    'Core': 'Core',
  };

  static const Map<String, String> _translationsPt = {
    'Todos': 'Todos',
    'Pecho': 'Peito',
    'Espalda': 'Costas',
    'Piernas': 'Pernas',
    'Hombros': 'Ombros',
    'Brazos': 'Bracos',
    'Core': 'Core',
  };

  /// Obtiene el nombre localizado de un grupo muscular.
  /// Las claves internas se mantienen en español para compatibilidad con BD/Firestore.
  static String getLocalizedName(String muscleGroup, String languageCode) {
    switch (languageCode) {
      case 'en':
        return _translationsEn[muscleGroup] ?? muscleGroup;
      case 'pt':
        return _translationsPt[muscleGroup] ?? muscleGroup;
      default:
        return muscleGroup;
    }
  }

  /// Obtiene el color asociado a un grupo muscular.
  static Color getColor(String muscleGroup) {
    switch (muscleGroup) {
      case 'Pecho':
        return AppColors.muscleChest;
      case 'Espalda':
        return AppColors.muscleBack;
      case 'Piernas':
        return AppColors.muscleLegs;
      case 'Hombros':
        return AppColors.muscleShoulders;
      case 'Brazos':
        return AppColors.muscleArms;
      case 'Core':
        return AppColors.muscleCore;
      default:
        return AppColors.primary;
    }
  }
}
