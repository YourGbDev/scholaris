// lib/shared/widgets/entrance.dart
//
// Shared entrance-motion toolkit for Scholaris screens.
//
// Scholaris uses one restrained "staggered fade + rise" entrance everywhere:
// items appear in reading order, fading in while easing up a short distance.
// The choreography is intentionally calm — no bounce, no elastic curves — and
// it always resolves: once the entrance finishes, the UI is fully static.
//
// Two pieces are provided:
//   [EntranceMotion]  — timing tokens + the interval assigned to each item.
//   [EntranceMotionMixin] — a State mixin that owns the single entrance
//       controller, resolves Flutter's reduced-motion accessibility setting
//       (MediaQueryData.disableAnimations), and builds the per-item
//       transitions.
//
// Reduced motion is honored at the timing layer: when the platform requests
// reduced animations the controller jumps to its final value, so every item
// renders in its settled state on the first frame. Functional behavior
// (navigation, validation, callbacks) is never gated on the animation.

import 'package:flutter/material.dart';

/// Entrance-timing tokens shared by every Scholaris screen.
abstract final class EntranceMotion {
  /// Total duration of the entrance choreography.
  static const int totalMs = 1500;

  /// How long a single item takes to settle.
  static const int itemMs = 420;

  /// Delay between consecutive items.
  static const int staggerMs = 100;

  /// Idle beat before the first item starts.
  static const int initialDelayMs = 60;

  /// The single easing curve used by the entrance.
  static const Curve curve = Curves.easeOutCubic;

  /// Total controller duration.
  static Duration get total => const Duration(milliseconds: totalMs);

  /// When item [index] finishes settling (used to gate delayed affordances
  /// such as intro CTA activation).
  static Duration settledAt(int index) =>
      Duration(milliseconds: initialDelayMs + index * staggerMs + itemMs);

  /// The [Interval] of item [index] within [total].
  static Interval intervalFor(int index) {
    final begin = initialDelayMs + index * staggerMs;
    final end = begin + itemMs;
    return Interval(
      begin / totalMs,
      (end > totalMs ? totalMs : end) / totalMs,
      curve: curve,
    );
  }
}

/// State mixin that drives a screen's staggered entrance.
///
/// Hosts must mix in [TickerProviderStateMixin] (before this mixin) so the
/// entrance controller has a ticker; screens that layer additional
/// controllers on top keep working because [TickerProviderStateMixin]
/// supports multiple tickers. The mixin owns [entranceController] and
/// disposes it in [dispose]; if the host also overrides [dispose], it must
/// call `super.dispose()` so the controller is released.
mixin EntranceMotionMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  late final AnimationController entranceController = AnimationController(
    vsync: this,
    duration: EntranceMotion.total,
  );

  // Null until the first didChangeDependencies so the initial read always
  // differs from the platform value: the very first frame must either start
  // the entrance (default) or jump to the settled state (reduced motion).
  bool? _reducedMotion;

  /// Whether the platform requested reduced animations. Resolved in
  /// [didChangeDependencies]; safe to read from [build] and event handlers.
  bool get reducedMotion => _reducedMotion ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce == _reducedMotion) return;
    _reducedMotion = reduce;
    if (reduce) {
      // Jump to the settled state: content is immediately visible and fully
      // interactive, and the controller never ticks.
      entranceController.value = 1.0;
    } else {
      // Resumes from the current value, so toggling reduced motion off
      // mid-entrance simply continues the choreography.
      entranceController.forward();
    }
  }

  @override
  void dispose() {
    entranceController.dispose();
    super.dispose();
  }

  /// The curved progress of item [index] over [entranceController].
  Animation<double> entranceFor(int index) => CurvedAnimation(
    parent: entranceController,
    curve: EntranceMotion.intervalFor(index),
  );

  /// Wraps [child] in the standard entrance transitions for item [index]:
  /// fade in, rise by [offset] (fractional), and optionally scale up from
  /// [scaleFrom].
  Widget entranceItem({
    required int index,
    required Widget child,
    Offset offset = const Offset(0, 0.18),
    double scaleFrom = 1.0,
  }) {
    final animation = entranceFor(index);
    Widget result = FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: offset,
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
    if (scaleFrom != 1.0) {
      result = ScaleTransition(
        scale: Tween<double>(begin: scaleFrom, end: 1.0).animate(animation),
        child: result,
      );
    }
    return result;
  }
}

/// A self-contained staggered entrance for a list of children.
///
/// Use this on screens that only need the standard choreography; screens with
/// bespoke motion should use [EntranceMotionMixin] instead. A single
/// controller drives all children — child *i* settles over
/// `EntranceMotion.intervalFor(i)` — so adding an item simply extends the
/// cascade without re-tuning any widget.
///
/// Reduced motion: when the platform requests reduced animations the widget
/// renders every child in its final state on the first frame.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.children,
    this.offset = const Offset(0, 0.18),
    this.scaleFrom = 1.0,
  });

  final List<Widget> children;

  /// Fractional rise applied to every child.
  final Offset offset;

  /// Optional subtle scale-up start value (1.0 disables scaling).
  final double scaleFrom;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: EntranceMotion.total,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _controller.value = 1.0;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _entranceItem(index: i, child: widget.children[i]),
      ],
    );
  }

  Widget _entranceItem({required int index, required Widget child}) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: EntranceMotion.intervalFor(index),
    );
    Widget result = FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.offset,
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
    if (widget.scaleFrom != 1.0) {
      result = ScaleTransition(
        scale: Tween<double>(
          begin: widget.scaleFrom,
          end: 1.0,
        ).animate(animation),
        child: result,
      );
    }
    return result;
  }
}
