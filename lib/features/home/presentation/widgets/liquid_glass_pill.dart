import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'student_glass_refraction.dart';

/// Rim optics sample the backdrop; navigation content stays outside the filter.
class LiquidGlassPill extends StatelessWidget {
  const LiquidGlassPill({
    super.key,
    required this.child,
    this.tintOpacity = .44,
    this.coreBlur = 6.5,
  });

  final Widget child;
  final double tintOpacity;
  final double coreBlur;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: StudentGlassRefraction(
        enabled: true,
        radius: 999,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xA6FFFFFF), width: .8),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                top: 10,
                bottom: 10,
                left: 10,
                right: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: coreBlur,
                      sigmaY: coreBlur,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipPath(
                  clipper: const _GlassRimClipper(),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 11),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: tintOpacity),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

class _GlassRimClipper extends CustomClipper<Path> {
  const _GlassRimClipper();

  @override
  Path getClip(Size size) {
    final outer = Offset.zero & size;
    final inset = size.shortestSide < 20 ? size.shortestSide / 2 : 10.0;
    return Path.combine(
      PathOperation.difference,
      Path()
        ..addRRect(RRect.fromRectAndRadius(outer, const Radius.circular(999))),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          outer.deflate(inset),
          const Radius.circular(999),
        ),
      ),
    );
  }

  @override
  bool shouldReclip(_GlassRimClipper oldClipper) => false;
}
