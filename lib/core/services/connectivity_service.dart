import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';

/// Servicio para monitorear el estado de conectividad.
class ConnectivityService {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Stream del estado de conectividad.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      // results es ahora List<ConnectivityResult>
      final isConnected = results.isNotEmpty &&
          !results.every((r) => r == ConnectivityResult.none);
      AppLogger.debug(
        'Conectividad cambiada: $results (conectado: $isConnected)',
        tag: 'Connectivity',
      );
      return isConnected;
    });
  }

  /// Verifica si hay conexion actualmente.
  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    // results es ahora List<ConnectivityResult>
    return results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);
  }

  /// Limpia recursos.
  void dispose() {
    _subscription?.cancel();
  }
}

/// Provider del servicio de conectividad.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider del estado de conectividad actual.
final isConnectedProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

/// Provider que indica si esta online (con valor inicial).
final hasConnectionProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(connectivityServiceProvider);
  return service.hasConnection();
});
