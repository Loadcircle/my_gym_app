import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Dimensiones del tooltip de tour.
const double kTourTooltipWidth = 290.0;
const double kTourTooltipHeight = 200.0;

/// Tooltip personalizado para los pasos del tour.
/// Recibe el [controller] y el [skipLabel] como parámetros explícitos
/// porque el container se renderiza en un Overlay sin acceso al
/// InheritedWidget de ShowCaseWidget ni a AppLocalizations.
class TourTooltip extends StatelessWidget {
  final String title;
  final String description;
  final String skipLabel;
  final ShowCaseWidgetState controller;

  const TourTooltip({
    super.key,
    required this.title,
    required this.description,
    required this.skipLabel,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.next(),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: kTourTooltipWidth,
          maxHeight: kTourTooltipHeight,
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra acento naranja
            Container(
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            // Título
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            // Descripción
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // Footer: Skip + flecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón skip — GestureDetector propio para absorber el tap
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.dismiss(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    child: Text(
                      skipLabel,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Flecha "continuar"
                const Text(
                  '›',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper para crear un [Showcase.withWidget] con el tooltip estilizado de la app.
///
/// Usa un [Builder] para capturar el controller de [ShowCaseWidget] y el texto
/// de "Omitir" desde el árbol de widgets (donde sí existen los InheritedWidgets),
/// y los pasa como parámetros explícitos a [TourTooltip].
Widget tourShowcase({
  required GlobalKey showcaseKey,
  required String title,
  required String description,
  required Widget child,
  double height = kTourTooltipHeight,
  double width = kTourTooltipWidth,
}) {
  return Builder(
    builder: (context) {
      final controller = ShowCaseWidget.of(context);
      final skipLabel = AppLocalizations.of(context).featureTourSkip;
      return Showcase.withWidget(
        key: showcaseKey,
        height: height,
        width: width,
        targetBorderRadius: BorderRadius.circular(10),
        overlayOpacity: 0.72,
        container: TourTooltip(
          title: title,
          description: description,
          skipLabel: skipLabel,
          controller: controller,
        ),
        child: child,
      );
    },
  );
}
