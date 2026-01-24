import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'route_names.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/auth_state.dart';
import '../../features/exercises/presentation/screens/exercises_screen.dart';
import '../../features/exercises/presentation/screens/exercise_detail_screen.dart';
import '../../features/exercises/presentation/screens/add_exercise_screen.dart';
import '../../features/exercises/presentation/screens/custom_exercise_detail_screen.dart';
import '../../features/exercises/presentation/screens/edit_custom_exercise_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';

/// Provider que indica si el estado de auth aun esta inicializando.
/// Usado por el router para saber si debe esperar.
final _isAuthInitializingProvider = Provider<bool>((ref) {
  final status = ref.watch(authStateProvider.select((s) => s.status));
  return status == AuthStatus.initial;
});

/// Provider del router principal de la aplicacion.
/// Usa go_router para navegacion declarativa con proteccion de rutas.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Solo observar autenticacion e inicializacion, NO errores
  // Esto evita que el router se reconstruya cuando hay errores de login
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final isInitializing = ref.watch(_isAuthInitializingProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,

    // Redirect basado en estado de autenticacion
    redirect: (context, state) {
      final currentPath = state.matchedLocation;

      // Rutas de autenticacion
      final authRoutes = [
        RouteNames.login,
        RouteNames.register,
        RouteNames.forgotPassword,
      ];
      final isOnAuthRoute = authRoutes.contains(currentPath);
      final isOnSplash = currentPath == RouteNames.splash;

      // Si estamos cargando el estado inicial, quedarnos en splash
      if (isInitializing && isOnSplash) {
        return null;
      }

      // Si no esta autenticado y no esta en ruta de auth ni splash, ir a login
      if (!isAuthenticated && !isOnAuthRoute && !isOnSplash) {
        return RouteNames.login;
      }

      // Si esta autenticado y esta en ruta de auth o splash, ir a exercises
      if (isAuthenticated && (isOnAuthRoute || isOnSplash)) {
        return RouteNames.exercises;
      }

      // No redirect necesario
      return null;
    },

    routes: [
      // Splash Screen (initial)
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main App Routes (protegidas)
      GoRoute(
        path: RouteNames.exercises,
        name: 'exercises',
        builder: (context, state) => const ExercisesScreen(),
      ),
      GoRoute(
        path: '${RouteNames.exerciseDetail}/:exerciseId',
        name: 'exerciseDetail',
        builder: (context, state) {
          final exerciseId = state.pathParameters['exerciseId'] ?? '';
          return ExerciseDetailScreen(exerciseId: exerciseId);
        },
      ),
      GoRoute(
        path: RouteNames.addExercise,
        name: 'addExercise',
        builder: (context, state) => const AddExerciseScreen(),
      ),
      GoRoute(
        path: '${RouteNames.customExerciseDetail}/:exerciseId',
        name: 'customExerciseDetail',
        builder: (context, state) {
          final exerciseId = state.pathParameters['exerciseId'] ?? '';
          return CustomExerciseDetailScreen(exerciseId: exerciseId);
        },
      ),
      GoRoute(
        path: '${RouteNames.editCustomExercise}/:exerciseId',
        name: 'editCustomExercise',
        builder: (context, state) {
          final exerciseId = state.pathParameters['exerciseId'] ?? '';
          return EditCustomExerciseScreen(exerciseId: exerciseId);
        },
      ),
      GoRoute(
        path: RouteNames.history,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Pagina no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.splash),
              child: const Text('Ir al Inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});
