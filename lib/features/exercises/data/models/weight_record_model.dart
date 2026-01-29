import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'record_mode.dart';
import 'set_entry_model.dart';

part 'weight_record_model.freezed.dart';
part 'weight_record_model.g.dart';

/// Modelo de registro de peso.
/// Representa un registro de peso para un ejercicio especifico.
/// En modo quick: weight/reps/sets son valores directos.
/// En modo advanced: weight/reps/sets son resumen calculado, setEntries tiene el detalle.
@freezed
class WeightRecordModel with _$WeightRecordModel {
  const factory WeightRecordModel({
    required String id,
    required String exerciseId,
    required String userId,
    required double weight,
    @Default(1) int reps,
    @Default(1) int sets,
    String? notes,
    required DateTime date,
    @Default(RecordMode.quick) RecordMode mode,
    @Default([]) List<SetEntryModel> setEntries,
  }) = _WeightRecordModel;

  factory WeightRecordModel.fromJson(Map<String, dynamic> json) =>
      _$WeightRecordModelFromJson(json);

  /// Crea un WeightRecordModel desde un documento de Firestore.
  factory WeightRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final mode = RecordMode.fromString(data['mode'] as String?);

    List<SetEntryModel> setEntries = [];
    if (mode == RecordMode.advanced && data['setEntries'] != null) {
      final entriesList = data['setEntries'] as List<dynamic>;
      setEntries = entriesList
          .map((e) => SetEntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return WeightRecordModel(
      id: doc.id,
      exerciseId: data['exerciseId'] as String,
      userId: data['userId'] as String,
      weight: (data['weight'] as num).toDouble(),
      reps: data['reps'] as int? ?? 1,
      sets: data['sets'] as int? ?? 1,
      notes: data['notes'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      mode: mode,
      setEntries: setEntries,
    );
  }

  const WeightRecordModel._();

  /// Convierte a Map para guardar en Firestore.
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'exerciseId': exerciseId,
      'userId': userId,
      'weight': weight,
      'reps': reps,
      'sets': sets,
      'notes': notes,
      'date': Timestamp.fromDate(date),
      'mode': mode.name,
    };

    if (mode == RecordMode.advanced && setEntries.isNotEmpty) {
      map['setEntries'] = setEntries.map((e) => e.toJson()).toList();
    }

    return map;
  }
}
