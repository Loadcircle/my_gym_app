import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/providers/app_config_provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import 'exercise_video_player.dart';

/// Widget que reproduce video desde Firebase Storage.
/// Acepta un path relativo y lo resuelve a URL usando getDownloadURL().
/// Si recibe una URL completa, la usa directamente.
class StorageVideoPlayer extends ConsumerWidget {
  final String? path;
  final double? height;
  final bool autoPlay;
  final bool showControls;
  final bool allowFullscreen;

  const StorageVideoPlayer({
    super.key,
    this.path,
    this.height = 200,
    this.autoPlay = false,
    this.showControls = true,
    this.allowFullscreen = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si no hay path, mostrar placeholder
    if (path == null || path!.isEmpty) {
      return _buildPlaceholder();
    }

    // Si ya es una URL completa, usar directamente
    if (StorageService.isFullUrl(path)) {
      return ExerciseVideoPlayer(
        videoUrl: path,
        height: height,
        autoPlay: autoPlay,
        showControls: showControls,
        allowFullscreen: allowFullscreen,
      );
    }

    // Resolver path a URL
    final urlAsync = ref.watch(videoUrlProvider(path!));

    return urlAsync.when(
      loading: () => _buildLoading(),
      error: (_, __) => _buildError(),
      data: (url) {
        if (url == null) {
          return _buildError();
        }
        return ExerciseVideoPlayer(
          videoUrl: url,
          height: height,
          autoPlay: autoPlay,
          showControls: showControls,
          allowFullscreen: allowFullscreen,
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 8),
            Text(
              'Video del ejercicio',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            SizedBox(height: 8),
            Text(
              'Error al cargar video',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
