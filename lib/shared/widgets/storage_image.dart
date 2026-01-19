import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/providers/app_config_provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import 'exercise_image.dart';

/// Widget que muestra una imagen desde Firebase Storage.
/// Acepta un path relativo y lo resuelve a URL usando getDownloadURL().
/// Si recibe una URL completa, la usa directamente.
class StorageImage extends ConsumerWidget {
  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const StorageImage({
    super.key,
    this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si no hay path, mostrar placeholder
    if (path == null || path!.isEmpty) {
      return _buildPlaceholder();
    }

    // Si ya es una URL completa, usar directamente
    if (StorageService.isFullUrl(path)) {
      return ExerciseImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        placeholder: placeholder ?? _buildPlaceholder(),
        errorWidget: errorWidget ?? _buildError(),
      );
    }

    // Resolver path a URL
    final urlAsync = ref.watch(imageUrlProvider(path!));

    return urlAsync.when(
      loading: () => placeholder ?? _buildPlaceholder(),
      error: (_, __) => errorWidget ?? _buildError(),
      data: (url) {
        if (url == null) {
          return errorWidget ?? _buildError();
        }
        return ExerciseImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: fit,
          borderRadius: borderRadius,
          placeholder: placeholder ?? _buildPlaceholder(),
          errorWidget: errorWidget ?? _buildError(),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(
          Icons.fitness_center,
          size: 48,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Widget simplificado para mostrar imagen de ejercicio con fallback.
class StorageImageWithFallback extends ConsumerWidget {
  final String? path;
  final double size;
  final BorderRadius? borderRadius;

  const StorageImageWithFallback({
    super.key,
    this.path,
    this.size = 60,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    return StorageImage(
      path: path,
      width: size,
      height: size,
      borderRadius: radius,
      placeholder: _buildIconPlaceholder(radius),
      errorWidget: _buildIconPlaceholder(radius),
    );
  }

  Widget _buildIconPlaceholder(BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: radius,
      ),
      child: Icon(
        Icons.fitness_center,
        size: size * 0.4,
        color: AppColors.primary,
      ),
    );
  }
}
