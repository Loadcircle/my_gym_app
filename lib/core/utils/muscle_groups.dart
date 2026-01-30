import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Utilidad centralizada para grupos musculares.
/// Evita duplicación de listas y funciones de color en múltiples archivos.
abstract class MuscleGroups {
  /// Lista de grupos musculares sin "Todos".
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
