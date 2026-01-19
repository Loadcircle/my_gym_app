import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_config_model.dart';

/// Repositorio para obtener configuracion de la app desde Firestore.
class AppConfigRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'app_config';
  static const String _mediaDoc = 'media';

  AppConfigRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obtiene la configuracion de media (imagenes/videos por defecto).
  Future<MediaConfigModel> getMediaConfig() async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(_mediaDoc).get();

      if (!doc.exists) {
        return const MediaConfigModel();
      }

      return MediaConfigModel.fromFirestore(doc);
    } catch (e) {
      // En caso de error, retorna config vacia (usara fallbacks)
      return const MediaConfigModel();
    }
  }

  /// Obtiene toda la configuracion de la app.
  Future<AppConfigModel> getAppConfig() async {
    final media = await getMediaConfig();
    return AppConfigModel(media: media);
  }

  /// Stream para escuchar cambios en la configuracion de media.
  Stream<MediaConfigModel> watchMediaConfig() {
    return _firestore
        .collection(_collection)
        .doc(_mediaDoc)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return const MediaConfigModel();
      return MediaConfigModel.fromFirestore(doc);
    });
  }
}
