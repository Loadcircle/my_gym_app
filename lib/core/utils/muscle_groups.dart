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

  /// Primary muscles por grupo muscular.
  static const Map<String, List<String>> primaryMuscles = {
    'Pecho': ['chest_pectoralis_major', 'chest_pectoralis_minor'],
    'Espalda': ['back_latissimus', 'back_trapezius', 'back_rhomboids', 'back_erector_spinae'],
    'Piernas': ['legs_quadriceps', 'legs_hamstrings', 'legs_glutes', 'legs_calves', 'legs_adductors'],
    'Hombros': ['shoulders_anterior_deltoid', 'shoulders_lateral_deltoid', 'shoulders_posterior_deltoid'],
    'Brazos': ['arms_biceps', 'arms_triceps', 'arms_forearms'],
    'Core': ['core_rectus_abdominis', 'core_obliques', 'core_transverse_abdominis'],
  };

  /// Infiere el tipo de movimiento a partir del grupo muscular.
  static String inferMovementType(String muscleGroup) {
    switch (muscleGroup) {
      case 'Pecho':
      case 'Hombros':
        return 'push';
      case 'Espalda':
      case 'Brazos':
        return 'pull';
      case 'Piernas':
        return 'legs';
      case 'Core':
        return 'core';
      default:
        return '';
    }
  }

  /// Infiere el primary muscle a partir del grupo muscular (retorna el primero).
  static String inferPrimaryMuscle(String muscleGroup) {
    final muscles = primaryMuscles[muscleGroup];
    return muscles != null && muscles.isNotEmpty ? muscles.first : '';
  }

  /// Obtiene el grupo muscular padre de un primary muscle.
  static String getMuscleGroupForPrimary(String primaryMuscle) {
    for (final entry in primaryMuscles.entries) {
      if (entry.value.contains(primaryMuscle)) {
        return entry.key;
      }
    }
    return '';
  }

  /// Traducciones de primary muscles.
  static const Map<String, Map<String, String>> _primaryMuscleTranslations = {
    'chest_pectoralis_major': {'es': 'Pectoral mayor', 'en': 'Pectoralis major', 'pt': 'Peitoral maior'},
    'chest_pectoralis_minor': {'es': 'Pectoral menor', 'en': 'Pectoralis minor', 'pt': 'Peitoral menor'},
    'back_latissimus': {'es': 'Dorsal ancho', 'en': 'Latissimus dorsi', 'pt': 'Grande dorsal'},
    'back_trapezius': {'es': 'Trapecio', 'en': 'Trapezius', 'pt': 'Trapezio'},
    'back_rhomboids': {'es': 'Romboides', 'en': 'Rhomboids', 'pt': 'Romboides'},
    'back_erector_spinae': {'es': 'Erector espinal', 'en': 'Erector spinae', 'pt': 'Eretor da espinha'},
    'legs_quadriceps': {'es': 'Cuadriceps', 'en': 'Quadriceps', 'pt': 'Quadriceps'},
    'legs_hamstrings': {'es': 'Isquiotibiales', 'en': 'Hamstrings', 'pt': 'Isquiotibiais'},
    'legs_glutes': {'es': 'Gluteos', 'en': 'Glutes', 'pt': 'Gluteos'},
    'legs_calves': {'es': 'Pantorrillas', 'en': 'Calves', 'pt': 'Panturrilhas'},
    'legs_adductors': {'es': 'Aductores', 'en': 'Adductors', 'pt': 'Adutores'},
    'shoulders_anterior_deltoid': {'es': 'Deltoides anterior', 'en': 'Anterior deltoid', 'pt': 'Deltoide anterior'},
    'shoulders_lateral_deltoid': {'es': 'Deltoides lateral', 'en': 'Lateral deltoid', 'pt': 'Deltoide lateral'},
    'shoulders_posterior_deltoid': {'es': 'Deltoides posterior', 'en': 'Posterior deltoid', 'pt': 'Deltoide posterior'},
    'arms_biceps': {'es': 'Biceps', 'en': 'Biceps', 'pt': 'Biceps'},
    'arms_triceps': {'es': 'Triceps', 'en': 'Triceps', 'pt': 'Triceps'},
    'arms_forearms': {'es': 'Antebrazos', 'en': 'Forearms', 'pt': 'Antebracos'},
    'core_rectus_abdominis': {'es': 'Recto abdominal', 'en': 'Rectus abdominis', 'pt': 'Reto abdominal'},
    'core_obliques': {'es': 'Oblicuos', 'en': 'Obliques', 'pt': 'Obliquos'},
    'core_transverse_abdominis': {'es': 'Transverso abdominal', 'en': 'Transverse abdominis', 'pt': 'Transverso abdominal'},
  };

  /// Obtiene el nombre localizado de un primary muscle.
  static String getLocalizedPrimaryMuscle(String primaryMuscle, String languageCode) {
    final translations = _primaryMuscleTranslations[primaryMuscle];
    if (translations == null) return primaryMuscle;
    return translations[languageCode] ?? translations['es'] ?? primaryMuscle;
  }

  /// Obtiene el color de un primary muscle (usa el color del muscleGroup padre).
  static Color getPrimaryMuscleColor(String primaryMuscle) {
    final group = getMuscleGroupForPrimary(primaryMuscle);
    return group.isNotEmpty ? getColor(group) : AppColors.primary;
  }
}
