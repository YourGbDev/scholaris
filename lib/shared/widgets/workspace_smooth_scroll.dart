
import 'package:flutter/material.dart';

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
  double? _wheelTarget;
  @override
  void pointerScroll(double delta) {
    if (reduced() || delta == 0) {
      _wheelTarget = null;
      super.pointerScroll(delta);
      return;
    }
    final previous = _wheelTarget;
    final continuing =
        isScrollingNotifier.value &&
        previous != null &&
        (previous - pixels) * delta > 0;
    final target = ((continuing ? previous : pixels) + delta)
        .clamp(minScrollExtent, maxScrollExtent)
        .toDouble();
    _wheelTarget = target;
    // Retarget from the current presentation value; reversing never finishes an old trip first.
    animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }
}
