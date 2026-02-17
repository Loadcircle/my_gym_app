import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/progress_calculation_service.dart';
import '../../../core/services/sync_service.dart' show appDatabaseProvider;
import '../../auth/providers/auth_provider.dart';

/// Provider del servicio de cálculo de progreso.
final progressCalculationServiceProvider =
    Provider<ProgressCalculationService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProgressCalculationService(db);
});

/// Provider del rango de tiempo seleccionado.
final progressTimeRangeProvider =
    StateProvider<ProgressTimeRange>((ref) => ProgressTimeRange.days30);

/// Provider del resumen hero.
final heroSummaryProvider = FutureProvider<HeroSummaryData>((ref) async {
  final user = ref.watch(currentUserProvider);
  final timeRange = ref.watch(progressTimeRangeProvider);
  final service = ref.watch(progressCalculationServiceProvider);

  if (user == null) {
    return const HeroSummaryData(
      workoutDays: 0,
      totalVolume: 0,
      dominantMuscleGroup: '',
      bestProgressPercentage: 0,
    );
  }

  return service.calculateHeroSummary(user.uid, timeRange);
});

/// Provider de distribución muscular.
final muscleDistributionProvider =
    FutureProvider<MuscleDistributionData>((ref) async {
  final user = ref.watch(currentUserProvider);
  final timeRange = ref.watch(progressTimeRangeProvider);
  final service = ref.watch(progressCalculationServiceProvider);

  if (user == null) {
    return const MuscleDistributionData(
      distribution: [],
      topMuscles: [],
      forgottenMuscles: [],
    );
  }

  return service.calculateMuscleDistribution(user.uid, timeRange);
});
