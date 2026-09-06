// lib/features/auth/presentation/empty_stage.dart
//
// Day 19: the empty graduation stage shown behind the login form.
//
// The ceremony is over; the graduate, faculty, diploma, cap and audience are
// gone. What remains is the warm cream auditorium — the stage is still there,
// and the next person standing on it could be the user.
//
// Rendered with native Flutter only (Container + CustomPaint), no images, no
// animation. It is deliberately quiet so the login form stays the focus:
//   * warm cream environment (kBackground)
//   * a soft, slightly darker warm-neutral stage platform
//   * an extremely subtle warm gold radial glow (~0.03-level)
//   * a barely-there cream curtain suggestion at the left/right edges

import 'package:flutter/material.dart';

import 'package:scholaris/shared/theme/app_theme.dart';

/// Slightly darker warm neutral for the stage platform.
const Color _stagePlatform = Color(0xFFEFECE4);

/// The front lip of the platform (a touch darker for a little depth).
const Color _stageLip = Color(0xFFE7E3D8);

/// Warm neutral used for the faint curtain edges.
const Color _curtainTone = Color(0xFFEDE9DE);

/// Key on the root container so tests can target the stage reliably.
const Key kEmptyStageKey = Key('empty-stage');

/// The empty graduation auditorium behind the login form.
class EmptyStage extends StatelessWidget {
  const EmptyStage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: kEmptyStageKey,
      color: kBackground,
      child: CustomPaint(
        painter: const _StagePainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _StagePainter extends CustomPainter {
  const _StagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // --- Warm lighting: a gold-tinted radial glow, extremely subtle --------
    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.32),
        radius: 1.1,
        colors: [
          kAccent.withValues(alpha: 0.06),
          kAccent.withValues(alpha: 0.03),
          kAccent.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    // --- Stage platform: a flat, soft perspective ellipse ------------------
    final platformCenter = Offset(size.width * 0.5, size.height * 0.72);
    final platformW = size.width * 0.92;
    final platformH = size.height * 0.18;

    // Very faint warm shadow beneath the platform for grounding.
    final shadow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x143D3527),
          const Color(0x003D3527),
        ],
      ).createShader(Rect.fromCenter(
        center: platformCenter.translate(0, size.height * 0.015),
        width: platformW,
        height: platformH,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: platformCenter.translate(0, size.height * 0.015),
        width: platformW,
        height: platformH,
      ),
      shadow,
    );

    canvas.drawOval(
      Rect.fromCenter(center: platformCenter, width: platformW, height: platformH),
      Paint()..color = _stagePlatform,
    );

    // Front lip: a slightly smaller ellipse just below for gentle depth.
    canvas.drawOval(
      Rect.fromCenter(
        center: platformCenter.translate(0, size.height * 0.02),
        width: platformW * 0.96,
        height: platformH * 0.55,
      ),
      Paint()..color = _stageLip,
    );

    // --- Curtain suggestion: barely-there cream edges ----------------------
    final curtain = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _curtainTone.withValues(alpha: 0.9),
          _curtainTone.withValues(alpha: 0.0),
          _curtainTone.withValues(alpha: 0.0),
          _curtainTone.withValues(alpha: 0.9),
        ],
        stops: const [0.0, 0.07, 0.93, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, curtain);
  }

  @override
  bool shouldRepaint(covariant _StagePainter oldDelegate) => false;
}
