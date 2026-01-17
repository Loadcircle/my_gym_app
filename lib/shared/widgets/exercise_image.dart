import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';

/// Widget para mostrar imagen de ejercicio desde Firebase Storage.
/// Usa cache local para mejor rendimiento y funcionamiento offline.
class ExerciseImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ExerciseImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final content = imageUrl != null && imageUrl!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl!,
            width: width,
            height: height,
            fit: fit,
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
