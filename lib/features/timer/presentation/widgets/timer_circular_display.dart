import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Widget de countdown circular usando CustomPaint.
/// Muestra el tiempo restante como arco de progreso sobre fondo oscuro.
class TimerCircularDisplay extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isFinished;
  final bool isPaused;
  final VoidCallback? onTap;

  const TimerCircularDisplay({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.isFinished = false,
    this.isPaused = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0
        ? remainingSeconds / totalSeconds
        : 0.0;

    final timeText = _formatTime(remainingSeconds);

    Color arcColor;
    if (isFinished) {
      arcColor = AppColors.success;
    } else if (isPaused) {
      arcColor = AppColors.warning;
    } else {
      arcColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 200,
        height: 200,
        child: CustomPaint(
          painter: _CircularTimerPainter(
            progress: progress,
            arcColor: arcColor,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: isFinished
                        ? AppColors.success
                        : AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                  child: Text(timeText),
                ),
                if (isPaused && !isFinished)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'PAUSED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color arcColor;

  _CircularTimerPainter({
    required this.progress,
    required this.arcColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const strokeWidth = 8.0;

    // Fondo del arco
    final trackPaint = Paint()
      ..color = AppColors.surfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Arco de progreso
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Empezar desde arriba
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.arcColor != arcColor;
  }
}
