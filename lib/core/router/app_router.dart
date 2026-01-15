import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'route_names.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/exercises/presentation/screens/exercises_screen.dart';
import '../../features/exercises/presentation/screens/exercise_detail_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';

/// Provider del router principal de la aplicacion.
/// Usa go_router para navegacion declarativa.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
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

      // Main App Routes
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
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.location,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.exercises),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
