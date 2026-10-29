import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart' show Ticker;

/// Smooth wheel deltas only; touch, keyboard and scrollbar drags stay native.
class WorkspaceSmoothScroll extends StatefulWidget {
  const WorkspaceSmoothScroll({super.key, required this.child});
  final Widget child;
  @override
  State<WorkspaceSmoothScroll> createState() => _WorkspaceSmoothScrollState();
}

class _WorkspaceSmoothScrollState extends State<WorkspaceSmoothScroll> {
  late final _controller = SmoothWheelScrollController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.reducedMotion = MediaQuery.disableAnimationsOf(context);
    return PrimaryScrollController(
      controller: _controller,
      automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
      child: widget.child,
    );
  }
}

class SmoothWheelScrollController extends ScrollController {
  bool reducedMotion = false;
  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _SmoothWheelPosition(
    physics: physics,
    context: context,
    oldPosition: oldPosition,
    reduced: () => reducedMotion,
  );
}

class _SmoothWheelPosition extends ScrollPositionWithSingleContext {
  _SmoothWheelPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    required this.reduced,
  });
  final bool Function() reduced;
  @override
  void pointerScroll(double delta) {
    if (reduced() || delta == 0) {
      super.pointerScroll(delta);
      return;
    }
    final glide = activity is _WheelGlideActivity
        ? activity! as _WheelGlideActivity
        : null;
    final previous = glide?.target;
    final continuing = previous != null && (previous - pixels) * delta > 0;
    final target = ((continuing ? previous : pixels) + delta)
        .clamp(minScrollExtent, maxScrollExtent)
        .toDouble();
    if (target == pixels) return;
    updateUserScrollDirection(
      delta > 0 ? ScrollDirection.reverse : ScrollDirection.forward,
    );
    if (glide != null) {
      glide.target = target;
    } else {
      beginActivity(_WheelGlideActivity(this, target, context.vsync, reduced));
    }
  }
}

/// Lenis-style exponential damping, integrated with Flutter's scroll lifecycle.
class _WheelGlideActivity extends ScrollActivity {
  _WheelGlideActivity(
    super.delegate,
    this.target,
    TickerProvider vsync,
    this.reduced,
  ) {
    _ticker = vsync.createTicker(_tick)..start();
  }

  double target;
  final bool Function() reduced;
  late final Ticker _ticker;
  Duration _previousTime = Duration.zero;
  double _velocity = 0;
  bool _disposed = false;

  void _tick(Duration elapsed) {
    if (reduced()) {
      delegate.goIdle();
      return;
    }
    final dt =
        (elapsed - _previousTime).inMicroseconds /
        Duration.microsecondsPerSecond;
    _previousTime = elapsed;
    if (dt <= 0) return;
    final position = delegate as ScrollPosition;
    target = target
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    final current = position.pixels;
    // Match Lenis's default damping: lerp 0.1 * 60, independent of frame rate.
    final next = current + (target - current) * (1 - math.exp(-6 * dt));
    final done = (target - next).abs() < .1;
    final value = done ? target : next;
    _velocity = (value - current) / dt;
    final overflow = delegate.setPixels(value);
    if (!_disposed && (done || overflow != 0)) delegate.goIdle();
  }

  @override
  void applyNewDimensions() {
    final position = delegate as ScrollPosition;
    target = target
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (position.outOfRange) delegate.goBallistic(0);
  }

  @override
  void resetActivity() => delegate.goIdle();

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => _velocity;

  @override
  void dispose() {
    _disposed = true;
    _ticker.dispose();
    super.dispose();
  }
}
