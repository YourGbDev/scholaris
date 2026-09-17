// lib/shared/widgets/radial_matching_gauge.dart
//
// Circular / radial Matching Power progress gauge matching Stitch V2 specification
// (`scholaris_student_dashboard/code.html`).
// Features a background circular track, smooth progress arc in Golden Opportunity
// (kTertiaryFixedDim / #FABC28), and centered percentage + "Active" status label.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RadialMatchingGauge extends StatelessWidget {
  const RadialMatchingGauge({
    super.key,
    required this.percentage,
    this.status = 'Active',
    this.size = 80.0,
    this.strokeWidth = 7.0,
    this.trackColor,
    this.progressColor,
    this.textColor = Colors.white,
    this.subtextColor,
  });

  /// The match score from 0 to 100.
  final int percentage;

  /// Status badge beneath the percentage (defaults to 'Active').
  final String status;

  /// Outer dimension (width/height) of the gauge.
  final double size;

  /// Thickness of the ring stroke.
  final double strokeWidth;

  /// Background ring color (defaults to 20% white).
  final Color? trackColor;

  /// Progress arc color (defaults to kTertiaryFixedDim #FABC28).
  final Color? progressColor;

  /// Color of the main percentage text.
  final Color textColor;

  /// Color of the subtitle/status text.
  final Color? subtextColor;

  @override
  Widget build(BuildContext context) {
    final effectiveTrackColor =
        trackColor ?? Colors.white.withValues(alpha: 0.20);
    final effectiveProgressColor = progressColor ?? kTertiaryFixedDim;
    final effectiveSubtextColor =
        subtextColor ?? Colors.white.withValues(alpha: 0.75);

    final ratio = (percentage.clamp(0, 100)) / 100.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RadialGaugePainter(
              progress: ratio,
              strokeWidth: strokeWidth,
              trackColor: effectiveTrackColor,
              progressColor: effectiveProgressColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$percentage%',
                style: outfit(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                status.toUpperCase(),
                style: outfit(
                  fontSize: size * 0.11,
                  fontWeight: FontWeight.w700,
                  color: effectiveSubtextColor,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  const _RadialGaugePainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc starting from top (-pi / 2)
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
