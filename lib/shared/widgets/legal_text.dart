import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Widget que muestra el texto legal con enlaces a términos y privacidad.
/// Usado en las pantallas de login y registro.
class LegalText extends StatelessWidget {
  const LegalText({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        );
    final linkStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        );

    return Text.rich(
      TextSpan(
        text: 'Al continuar, aceptas los ',
        style: textStyle,
        children: [
          TextSpan(
            text: 'Términos y Condiciones',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(AppConstants.termsAndConditionsUrl),
          ),
          TextSpan(
            text: ' y la ',
            style: textStyle,
          ),
          TextSpan(
            text: 'Política de Privacidad',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(AppConstants.privacyPolicyUrl),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
