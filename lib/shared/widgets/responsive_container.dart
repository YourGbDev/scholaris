// lib/shared/widgets/responsive_container.dart
//
// Keeps Scholaris content comfortably readable on tablet and desktop widths
// without turning the app into a desktop dashboard. On phones the child fills
// the screen; on wider viewports it is centered and capped at a reading width.
// The mobile experience remains the source of truth.

import 'package:flutter/material.dart';

/// Max content width used across the app's scrollable screens.
const double kContentMaxWidth = 640;

class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
