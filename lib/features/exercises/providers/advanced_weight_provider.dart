import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/set_entry_model.dart';

const _uuid = Uuid();

/// Estado del formulario de registro avanzado.
class AdvancedWeightState {
  final List<SetEntryModel> setEntries;
  final bool isSaving;

  const AdvancedWeightState({
    this.setEntries = const [],
    this.isSaving = false,
  });

  AdvancedWeightState copyWith({
    List<SetEntryModel>? setEntries,
    bool? isSaving,
  }) {
    return AdvancedWeightState(
      setEntries: setEntries ?? this.setEntries,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  /// Peso maximo entre todas las series.
  double get summaryWeight {
    if (setEntries.isEmpty) return 0;
    return setEntries.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
  }

  /// Total de series.
  int get summarySets => setEntries.length;

  /// Max reps entre series con peso maximo.
  int get summaryReps {
    if (setEntries.isEmpty) return 0;
    final maxW = summaryWeight;
    return setEntries
        .where((e) => e.weight == maxW)
        .map((e) => e.reps)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Indica si hay al menos una serie valida (peso > 0, reps >= 1).
  bool get isValid {
    return setEntries.isNotEmpty &&
        setEntries.every((e) => e.weight > 0 && e.reps >= 1);
  }
}

/// Notifier para el formulario avanzado de registro de peso.
class AdvancedWeightNotifier extends StateNotifier<AdvancedWeightState> {
  AdvancedWeightNotifier({double? prefillWeight, int? prefillReps})
      : super(AdvancedWeightState(
          setEntries: [
            SetEntryModel(
              id: _uuid.v4(),
              setNumber: 1,
              weight: prefillWeight ?? 0,
              reps: prefillReps ?? 10,
            ),
          ],
        ));

  /// Re-inicializa con datos (usado si se cargan datos async).
  void reinitialize({double? prefillWeight, int? prefillReps}) {
    if (state.setEntries.length == 1 && state.setEntries.first.weight == 0) {
      // Solo reinicializar si tenemos el set por defecto sin peso
      state = AdvancedWeightState(
        setEntries: [
          SetEntryModel(
            id: state.setEntries.first.id,
            setNumber: 1,
            weight: prefillWeight ?? 0,
            reps: prefillReps ?? 10,
          ),
        ],
      );
    }
  }

  /// Agrega una nueva serie.
  void addSet({double weight = 0, int reps = 10}) {
    final newEntry = SetEntryModel(
      id: _uuid.v4(),
      setNumber: state.setEntries.length + 1,
      weight: weight,
      reps: reps,
    );
    state = state.copyWith(
      setEntries: [...state.setEntries, newEntry],
    );
  }

  /// Actualiza peso y/o reps de una serie.
  void updateSet(String setId, {double? weight, int? reps}) {
    final updated = state.setEntries.map((e) {
      if (e.id == setId) {
        return e.copyWith(
          weight: weight ?? e.weight,
          reps: reps ?? e.reps,
        );
      }
      return e;
    }).toList();
    state = state.copyWith(setEntries: updated);
  }

  /// Elimina una serie y renumera las restantes.
  void deleteSet(String setId) {
    final filtered = state.setEntries.where((e) => e.id != setId).toList();
    final renumbered = filtered.asMap().entries.map((entry) {
      return entry.value.copyWith(setNumber: entry.key + 1);
    }).toList();
    state = state.copyWith(setEntries: renumbered);
  }

  /// Duplica la ultima serie.
  void duplicateLastSet() {
    if (state.setEntries.isEmpty) return;
    final last = state.setEntries.last;
    addSet(weight: last.weight, reps: 0);
  }

  /// Marca como guardando.
  void setSaving(bool saving) {
    state = state.copyWith(isSaving: saving);
  }

  /// Reinicia el estado.
  void clear() {
    state = const AdvancedWeightState();
  }
}

/// Provider del notifier para registro avanzado (keyed by exerciseId).
final advancedWeightProvider = StateNotifierProvider
    .family<AdvancedWeightNotifier, AdvancedWeightState, String>(
  (ref, exerciseId) => AdvancedWeightNotifier(),
);
