import 'package:drift/drift.dart';

/// Tabla de ejercicios personalizados creados por usuarios.
/// Permite a los usuarios crear sus propios ejercicios con posibilidad
/// de proponer que se agreguen al catalogo global.
class CustomExercises extends Table {
  /// ID del documento (local o Firestore)
  TextColumn get id => text()();

  /// ID del usuario que creo el ejercicio
  TextColumn get userId => text()();

  /// Nombre del ejercicio
  TextColumn get name => text()();

  /// Grupo muscular (Pecho, Espalda, Piernas, etc.)
  TextColumn get muscleGroup => text()();

  /// Notas adicionales del usuario
  TextColumn get notes => text().nullable()();

  /// URL de la imagen en Firebase Storage
  TextColumn get imageUrl => text().nullable()();

  /// Estado de propuesta para el catalogo global
  /// Valores: 'none', 'pending', 'approved', 'rejected'
  TextColumn get proposalStatus =>
      text().withDefault(const Constant('none'))();

  /// ID del ejercicio global al que fue vinculado (si fue aprobado)
  TextColumn get linkedGlobalExerciseId => text().nullable()();

  /// Fecha de creacion
  DateTimeColumn get createdAt => dateTime()();

  /// Fecha de ultima actualizacion
  DateTimeColumn get updatedAt => dateTime()();

  /// Indica si el registro esta sincronizado con Firestore
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Fecha de ultima sincronizacion
  DateTimeColumn get lastSynced => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
