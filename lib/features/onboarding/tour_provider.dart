import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/notification_constants.dart';
import '../../data/local/daos/user_preferences_dao.dart';
import '../exercises/providers/user_preferences_provider.dart';

/// Estado del tour — flags de si ya fue visto.
class TourState {
  final bool hasSeenExercisesTour;
  final bool hasSeenDetailTour;

  const TourState({
    this.hasSeenExercisesTour = false,
    this.hasSeenDetailTour = false,
  });

  TourState copyWith({bool? hasSeenExercisesTour, bool? hasSeenDetailTour}) {
    return TourState(
      hasSeenExercisesTour: hasSeenExercisesTour ?? this.hasSeenExercisesTour,
      hasSeenDetailTour: hasSeenDetailTour ?? this.hasSeenDetailTour,
    );
  }
}

class TourNotifier extends StateNotifier<TourState> {
  final UserPreferencesDao _dao;

  TourNotifier(this._dao) : super(const TourState()) {
    _loadInitialValues();
  }

  Future<void> _loadInitialValues() async {
    final seenExercises =
        await _dao.getBool(kHasSeenExercisesTour, defaultValue: false);
    final seenDetail =
        await _dao.getBool(kHasSeenDetailTour, defaultValue: false);
    if (mounted) {
      state = TourState(
        hasSeenExercisesTour: seenExercises,
        hasSeenDetailTour: seenDetail,
      );
    }
  }

  Future<bool> hasSeenExercisesTour() async {
    return _dao.getBool(kHasSeenExercisesTour, defaultValue: false);
  }

  Future<bool> hasSeenDetailTour() async {
    return _dao.getBool(kHasSeenDetailTour, defaultValue: false);
  }

  Future<void> markExercisesTourSeen() async {
    await _dao.setBool(kHasSeenExercisesTour, true);
    if (mounted) {
      state = state.copyWith(hasSeenExercisesTour: true);
    }
  }

  Future<void> markDetailTourSeen() async {
    await _dao.setBool(kHasSeenDetailTour, true);
    if (mounted) {
      state = state.copyWith(hasSeenDetailTour: true);
    }
  }

  Future<void> resetAllTours() async {
    await _dao.setBool(kHasSeenExercisesTour, false);
    await _dao.setBool(kHasSeenDetailTour, false);
    if (mounted) {
      state = const TourState(
        hasSeenExercisesTour: false,
        hasSeenDetailTour: false,
      );
    }
  }
}

final tourNotifierProvider = StateNotifierProvider<TourNotifier, TourState>(
  (ref) {
    final dao = ref.watch(userPreferencesDaoProvider);
    return TourNotifier(dao);
  },
);

/// Provider para disparar manualmente el tour de ejercicios desde el drawer.
final triggerExercisesTourProvider = StateProvider<bool>((ref) => false);
