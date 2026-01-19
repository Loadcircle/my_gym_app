import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'app_config_model.freezed.dart';
part 'app_config_model.g.dart';

/// Configuracion de media (imagenes y videos por defecto).
@freezed
class MediaConfigModel with _$MediaConfigModel {
  const factory MediaConfigModel({
    @Default('') String defaultImagePath,
    @Default('') String defaultVideoPath,
  }) = _MediaConfigModel;

  factory MediaConfigModel.fromJson(Map<String, dynamic> json) =>
      _$MediaConfigModelFromJson(json);

  factory MediaConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const MediaConfigModel();
    return MediaConfigModel.fromJson(data);
  }
}

/// Configuracion general de la app.
/// Agrupa todas las configuraciones de Firestore.
@freezed
class AppConfigModel with _$AppConfigModel {
  const factory AppConfigModel({
    @Default(MediaConfigModel()) MediaConfigModel media,
  }) = _AppConfigModel;

  factory AppConfigModel.fromJson(Map<String, dynamic> json) =>
      _$AppConfigModelFromJson(json);
}
