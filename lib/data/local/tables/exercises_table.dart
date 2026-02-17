import 'package:drift/drift.dart';

/// Tabla de ejercicios para cache local.
/// Espejo de la coleccion 'exercises' de Firestore.
class Exercises extends Table {
  /// ID del documento en Firestore (clave primaria)
  TextColumn get id => text()();

  /// Nombre del ejercicio
  TextColumn get name => text()();

  /// Grupo muscular (Pecho, Espalda, Piernas, etc.)
  TextColumn get muscleGroup => text()();

  /// Descripcion del ejercicio
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Instrucciones paso a paso (separadas por \n)
  TextColumn get instructions => text().withDefault(const Constant(''))();

  /// URL de la imagen en Firebase Storage
  TextColumn get imageUrl => text().nullable()();

  /// URL del video en Firebase Storage
  TextColumn get videoUrl => text().nullable()();

  /// Keywords de búsqueda (separados por coma)
  TextColumn get keywords => text().withDefault(const Constant(''))();

  /// Nombre del ejercicio en inglés
  TextColumn get nameEn => text().withDefault(const Constant(''))();

  /// Nombre del ejercicio en portugués
  TextColumn get namePt => text().withDefault(const Constant(''))();

  /// Tipo de movimiento: 'push', 'pull', 'legs', 'core'
  TextColumn get movementType => text().withDefault(const Constant(''))();

  /// Músculo principal (e.g. 'chest_pectoralis_major')
  TextColumn get primaryMuscle => text().withDefault(const Constant(''))();

  /// Músculos secundarios como JSON array string
  TextColumn get secondaryMuscles => text().nullable()();

  /// Orden dentro del grupo muscular
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Fecha de ultima sincronizacion con Firestore
  DateTimeColumn get lastSynced => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
