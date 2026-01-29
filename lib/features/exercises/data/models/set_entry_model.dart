import 'package:freezed_annotation/freezed_annotation.dart';

part 'set_entry_model.freezed.dart';
part 'set_entry_model.g.dart';

/// Modelo de una serie individual dentro de un registro avanzado.
@freezed
class SetEntryModel with _$SetEntryModel {
  const factory SetEntryModel({
    required String id,
    required int setNumber,
    required double weight,
    required int reps,
  }) = _SetEntryModel;

  factory SetEntryModel.fromJson(Map<String, dynamic> json) =>
      _$SetEntryModelFromJson(json);
}
