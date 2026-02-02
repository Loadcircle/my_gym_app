import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/logger.dart';

/// Entry point comun para todos los flavors.
/// Recibe el entorno como parametro desde main_dev.dart o main_prod.dart.
void mainCommon(Environment env) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar el entorno
  AppConfig.setEnvironment(env);

  // Configurar orientacion (solo portrait para uso en gym)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar Firebase
  await _initializeFirebase();

  runApp(
    const ProviderScope(
      child: MyGymApp(),
    ),
  );
}

/// Inicializa Firebase y configura Crashlytics.
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();

    if(AppConfig.environment.name == 'dev'){
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
    } else {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
      );
    }

    final app = Firebase.app();

    AppLogger.info('Firebase inicializado correctamente', tag: 'Main');
    AppLogger.info('Entorno: ${AppConfig.environment.name}', tag: 'Main');

    
    // ✅ Debug de a qué Firebase apunta este flavor
    AppLogger.info('Firebase appName: ${app.name}', tag: 'Firebase');
    AppLogger.info('Firebase projectId: ${app.options.projectId}', tag: 'Firebase');
    AppLogger.info('Firebase storageBucket: ${app.options.storageBucket}', tag: 'Firebase');

  
    // Configurar Crashlytics
    if (AppConfig.enableCrashlytics) {
      // Capturar errores de Flutter framework
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Capturar errores de Dart (async, isolates, etc.)
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      AppLogger.info('Crashlytics habilitado (Flutter + Dart errors)', tag: 'Main');
    } else {
      // En dev, solo imprimir errores
      FlutterError.onError = (details) {
        AppLogger.error(
          'Flutter Error: ${details.exception}',
          tag: 'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      // Capturar errores Dart en dev también para logging
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.error(
          'Dart Error: $error',
          tag: 'DartError',
          error: error,
          stackTrace: stack,
        );
        return true;
      };
    }
  } catch (e, stackTrace) {
    AppLogger.error(
      'Error inicializando Firebase',
      tag: 'Main',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

/// Widget principal de la aplicacion.
class MyGymApp extends ConsumerWidget {
  const MyGymApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: AppConfig.isDev,

      // Theme
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // Router
      routerConfig: router,
    );
  }
}
