import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A single retained capsule. Its center redirects from its presented position;
/// a small transient stretch conveys travel without an overshooting endpoint.
class StudentSelectionIndicator extends ImplicitlyAnimatedWidget {
  const StudentSelectionIndicator({
    super.key,
    required this.index,
    required super.duration,
  }) : super(curve: Curves.easeOutCubic);

  final int index;

  @override
  AnimatedWidgetBaseState<StudentSelectionIndicator> createState() =>
      _IndicatorState();
}

class _IndicatorState
    extends AnimatedWidgetBaseState<StudentSelectionIndicator> {
  Tween<double>? _position;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _position = visitor(
      _position,
      widget.index.toDouble(),
      (value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final cell = bounds.maxWidth / 4;
      final center = (_position!.evaluate(animation) + .5) * cell;
      final distance = (_position!.end! - _position!.begin!).abs();
      final wave = math.sin(math.pi * controller.value);
      final stretch = wave * math.min(22.0, distance * cell * .3);
      final width = cell - 8 + stretch;
      final left = center - width / 2;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: left,
            top: 8 - 14 * wave,
            width: width,
            height: bounds.maxHeight - 16 + 28 * wave,
            child: DecoratedBox(
              key: const ValueKey('student-nav-moving-indicator'),
              decoration: BoxDecoration(
                // Keep the selection neutral so the green icon and label carry
                // the accent, while the backdrop still shows through the pill.
                color: const Color(0x1F555B57),
                border: Border.all(color: const Color(0x12FFFFFF), width: .5),
                borderRadius: BorderRadius.circular(21),
              ),
            ),
          ),
        ],
      );
    },
  );
}
