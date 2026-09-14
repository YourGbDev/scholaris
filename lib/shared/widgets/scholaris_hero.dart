// lib/shared/widgets/scholaris_hero.dart
//
// The Scholaris hero surface — the first visual anchor of the Discover tab.
// Uses the brand green gradient with soft painted background blobs, Poppins
// greeting, Open Sans subtitle and a restrained gold accent.
//
// On wide viewports the trailing slot renders the Scholaris student
// illustration — the "Student discovering opportunity" artwork. Callers may
// still override [trailing] with custom content without changing the layout.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Source artwork for the Scholaris hero student illustration (4:3 landscape,
/// transparent background).
const String kHeroStudentIllustrationAsset =
    'assets/images/scholaris_hero_student.png';

/// Minimum inner width before the hero shows the trailing illustration slot
/// beside the text. Below this the hero renders text-only so it stays compact
/// and readable on phones.
const double _kHeroIllustrationBreakpoint = 480;

/// Width of the trailing illustration slot on wide viewports.
const double _kHeroIllustrationWidth = 190;

/// Height of the trailing illustration slot on wide viewports.
const double _kHeroIllustrationHeight = 150;

class ScholarisHero extends StatelessWidget {
  const ScholarisHero({
    super.key,
    required this.greeting,
    this.subtitle,
    this.trailing,
  });

  /// The headline greeting (e.g. "Good to see you, Maria").
  final String greeting;

  /// Optional supporting line rendered under the greeting.
  final String? subtitle;

  /// Optional illustration placed in the trailing slot on wide viewports.
  /// When null the Scholaris student illustration is shown by default.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final hero = Container(
      decoration: BoxDecoration(
        gradient: kHeroSurface,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _HeroBackdropPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= _kHeroIllustrationBreakpoint;
                final textContent = _HeroText(
                  greeting: greeting,
                  subtitle: subtitle,
                );

                if (!wide) return textContent;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: textContent),
                    const SizedBox(width: kSpaceMd),
                    SizedBox(
                      width: _kHeroIllustrationWidth,
                      height: _kHeroIllustrationHeight,
                      child: trailing ?? const _HeroStudentIllustration(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );

    // Marks the hero region as a semantic header while keeping the greeting
    // and subtitle as independently-readable text nodes.
    return Semantics(header: true, child: hero);
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText({required this.greeting, this.subtitle});

  final String greeting;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: kAccent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                greeting,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: openSans(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

/// The Scholaris hero student illustration — "Student discovering
/// opportunity". A 4:3 landscape PNG with transparent background that
/// integrates with the hero's painted surface.
class _HeroStudentIllustration extends StatelessWidget {
  const _HeroStudentIllustration();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Illustration of a student discovering scholarship opportunities',
      child: Image.asset(
        kHeroStudentIllustrationAsset,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        // Decorative: the greeting carries the meaningful hero content.
        excludeFromSemantics: true,
      ),
    );
  }
}

/// Paints the soft layered background blobs behind the hero content.
///
/// Three restrained radial washes — a white highlight, a faint gold warm spot
/// and a deeper green tint — sit beneath the text. The shapes are deliberately
/// subtle: no particles, no glow, no glass.
class _HeroBackdropPainter extends CustomPainter {
  const _HeroBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Large soft white wash high on the right — lifts the composition.
    _paintBlob(
      canvas,
      size,
      center: Offset(size.width * 0.88, size.height * 0.12),
      radius: size.width * 0.45,
      gradient: const RadialGradient(
        colors: [Color(0x1AFFFFFF), Colors.transparent],
        radius: 0.9,
      ),
    );

    // Faint gold warm spot low on the left — a restrained accent.
    _paintBlob(
      canvas,
      size,
      center: Offset(size.width * 0.12, size.height * 0.88),
      radius: size.width * 0.32,
      gradient: const RadialGradient(
        colors: [Color(0x0FF1B41E), Colors.transparent],
        radius: 0.9,
      ),
    );

    // Subtle deeper-green tint mid-right for depth.
    _paintBlob(
      canvas,
      size,
      center: Offset(size.width * 0.55, size.height * 0.55),
      radius: size.width * 0.3,
      gradient: const RadialGradient(
        colors: [Color(0x141A6B42), Colors.transparent],
        radius: 0.9,
      ),
    );
  }

  void _paintBlob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required RadialGradient gradient,
  }) {
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _HeroBackdropPainter oldDelegate) => false;
}
