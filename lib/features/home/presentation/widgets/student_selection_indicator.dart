import 'dart:math' as math;

import 'package:flutter/material.dart';

const kStudentSelectionDuration = Duration(milliseconds: 380);

/// One retained lens with a leading edge and a lagging trailing edge.
class StudentSelectionIndicator extends StatefulWidget {
  const StudentSelectionIndicator({
    super.key,
    required this.index,
    required this.duration,
  });

  final int index;
  final Duration duration;

  @override
  State<StudentSelectionIndicator> createState() => _IndicatorState();
}

class _IndicatorState extends State<StudentSelectionIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  late double _fromLeft = widget.index.toDouble();
  late double _fromRight = widget.index + 1.0;
  late double _toLeft = _fromLeft;
  late double _toRight = _fromRight;
  double _fromBulge = 0;
  double get _bulge =>
      _fromBulge * (1 - _clock.value) +
      (1 - _fromBulge) * math.sin(math.pi * _clock.value);
  double get _left => _edge(_fromLeft, _toLeft, leading: _toLeft < _fromLeft);
  double get _right =>
      _edge(_fromRight, _toRight, leading: _toRight > _fromRight);
  double _edge(double from, double to, {required bool leading}) {
    final curve = leading
        ? const Interval(0, .75, curve: Curves.easeOutCubic)
        : const Interval(.15, 1, curve: Curves.easeOutBack);
    return from + (to - from) * curve.transform(_clock.value);
  }

  @override
  void didUpdateWidget(StudentSelectionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      // Capture both presented edges and height before redirecting mid-flight.
      final left = _left;
      final right = _right;
      final bulge = _bulge;
      _fromLeft = left;
      _fromRight = right;
      _fromBulge = bulge;
      _toLeft = widget.index.toDouble();
      _toRight = widget.index + 1.0;
      _clock.duration = widget.duration;
      if (widget.duration == Duration.zero) {
        _clock.stop();
        _clock.value = 1;
      } else {
        _clock.forward(from: 0);
      }
    } else if (widget.duration == Duration.zero) {
      _clock.stop();
      _clock.value = 1;
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    builder: (context, _) => LayoutBuilder(
      builder: (context, bounds) {
        final cell = bounds.maxWidth / 4;
        final left = _left * cell + 4;
        final right = _right * cell - 4;
        final bulge = 12 * _bulge;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: left,
              top: 4 - bulge / 2,
              width: math.max(0, right - left),
              height: bounds.maxHeight - 8 + bulge,
              child: DecoratedBox(
                key: const ValueKey('student-nav-moving-indicator'),
                decoration: BoxDecoration(
                  color: const Color(0x1C1E4D2B),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
