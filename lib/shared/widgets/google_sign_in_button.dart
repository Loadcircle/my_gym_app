import 'package:flutter/material.dart';

/// Boton de inicio de sesion con Google.
/// Sigue las guias de diseno de Google para branding.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continuar con Google',
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Color(0xFFDEDEDE)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _GoogleLogo(size: 24),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Widget que dibuja el logo oficial de Google usando CustomPainter.
class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

/// Painter que dibuja el logo de Google con los colores oficiales.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;

    // Colores oficiales de Google
    const Color blue = Color(0xFF4285F4);
    const Color green = Color(0xFF34A853);
    const Color yellow = Color(0xFFFBBC05);
    const Color red = Color(0xFFEA4335);

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double centerX = s / 2;
    final double centerY = s / 2;
    final double radius = s / 2;

    // Parte azul (derecha)
    paint.color = blue;
    final Path bluePath = Path()
      ..moveTo(centerX, centerY)
      ..lineTo(s, centerY)
      ..arcToPoint(
        Offset(s * 0.854, s * 0.146),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(bluePath, paint);

    // Parte verde (abajo derecha)
    paint.color = green;
    final Path greenPath = Path()
      ..moveTo(centerX, centerY)
      ..lineTo(s * 0.854, s * 0.854)
      ..arcToPoint(
        Offset(s * 0.146, s * 0.854),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(greenPath, paint);

    // Parte amarilla (abajo izquierda)
    paint.color = yellow;
    final Path yellowPath = Path()
      ..moveTo(centerX, centerY)
      ..lineTo(s * 0.146, s * 0.854)
      ..arcToPoint(
        Offset(0, centerY),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Parte roja (arriba)
    paint.color = red;
    final Path redPath = Path()
      ..moveTo(centerX, centerY)
      ..lineTo(0, centerY)
      ..arcToPoint(
        Offset(s * 0.146, s * 0.146),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(s * 0.854, s * 0.146)
      ..close();
    canvas.drawPath(redPath, paint);

    // Circulo blanco interior
    paint.color = Colors.white;
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.55, paint);

    // "G" azul
    paint.color = blue;
    final Path gPath = Path()
      ..moveTo(s * 0.95, centerY)
      ..lineTo(centerX + 1, centerY)
      ..lineTo(centerX + 1, centerY + s * 0.15)
      ..lineTo(s * 0.85, centerY + s * 0.15)
      ..lineTo(s * 0.85, centerY + s * 0.05)
      ..lineTo(centerX + s * 0.1, centerY + s * 0.05)
      ..arcToPoint(
        Offset(centerX + s * 0.1, centerY - s * 0.25),
        radius: Radius.circular(radius * 0.5),
        clockwise: true,
      )
      ..lineTo(s * 0.75, centerY - s * 0.25)
      ..arcToPoint(
        Offset(s * 0.95, centerY),
        radius: Radius.circular(radius * 0.65),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(gPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
