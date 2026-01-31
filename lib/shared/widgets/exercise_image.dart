import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';

/// Widget para mostrar imagen de ejercicio desde Firebase Storage.
/// Usa cache local para mejor rendimiento y funcionamiento offline.
/// Optimizado con constraints de memoria para listas.
class ExerciseImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  /// Tamaño máximo en memoria para el cache. Default 300 para imágenes grandes, 120 para listas.
  final int? memCacheSize;

  const ExerciseImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.memCacheSize,
  });

  /// Constructor optimizado para listas (menor uso de memoria).
  const ExerciseImage.list({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  }) : memCacheSize = 120;

  /// Constructor para imágenes de detalle (mayor calidad).
  const ExerciseImage.detail({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  }) : memCacheSize = 400;

  @override
  Widget build(BuildContext context) {
    // Calcular el tamaño de cache basado en el widget o usar el default
    final cacheSize = memCacheSize ??
        (width != null && width! <= 100 ? 120 : 300);

    final content = imageUrl != null && imageUrl!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl!,
            width: width,
            height: height,
            fit: fit,
            memCacheHeight: cacheSize,
            memCacheWidth: cacheSize,
            filterQuality: FilterQuality.medium,
            placeholder: (context, url) =>
                placeholder ?? _buildDefaultPlaceholder(),
            errorWidget: (context, url, error) =>
                errorWidget ?? _buildDefaultError(),
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 200),
          )
        : (placeholder ?? _buildDefaultPlaceholder());

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceVariant,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceVariant,
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

/// Widget para mostrar imagen de ejercicio con placeholder de icono.
class ExerciseImageWithFallback extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final BorderRadius? borderRadius;

  const ExerciseImageWithFallback({
    super.key,
    this.imageUrl,
    this.size = 60,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ExerciseImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      placeholder: _buildIconPlaceholder(),
      errorWidget: _buildIconPlaceholder(),
    );
  }

  Widget _buildIconPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.fitness_center,
        size: size * 0.4,
        color: AppColors.primary,
      ),
    );
  }
}
