import 'package:flutter/material.dart';
import 'package:scholaris/shared/theme/app_motion.dart';

/// One visit clock for a retained tab. Replaying never remounts page content.
class StudentTabEntrance extends StatefulWidget {
  const StudentTabEntrance({
    super.key,
    required this.active,
    required this.child,
    this.visit = 0,
  });
  final bool active;
  final int visit;
  final Widget child;
  @override
  State<StudentTabEntrance> createState() => _StudentTabEntranceState();
}

class _StudentTabEntranceState extends State<StudentTabEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );
  bool get _immediate =>
      isReducedMotion(context) || MediaQuery.accessibleNavigationOf(context);
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (widget.active && !_immediate) _animation.forward(from: 0);
    }
    if (_immediate) {
      _animation.stop();
      _animation.value = 1;
    }
  }

  @override
  void didUpdateWidget(StudentTabEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) {
      _animation.stop();
    } else if (!oldWidget.active || widget.visit != oldWidget.visit) {
      if (_immediate) {
        _animation.stop();
        _animation.value = 1;
      } else {
        _animation.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _StudentVisitClock(animation: _animation, child: widget.child);
}

// The scope itself does not notify on ticks: only reveal layers rebuild, not
// the page's providers, lists or retained children.
class _StudentVisitClock extends InheritedWidget {
  const _StudentVisitClock({required this.animation, required super.child});
  final Animation<double> animation;
  @override
  bool updateShouldNotify(_StudentVisitClock oldWidget) =>
      animation != oldWidget.animation;
}

/// Fade and gently lift a section. Equal order means the same row/phase; long lists
/// cap their delay so scrolling never waits for a lengthy entrance sequence.
class StudentTabReveal extends StatelessWidget {
  const StudentTabReveal({
    super.key,
    required this.order,
    required this.child,
    this.structural = false,
    this.immediate = false,
  }) : assert(order >= 0);
  final int order;
  final Widget child;
  final bool structural;
  final bool immediate;

  @override
  Widget build(BuildContext context) {
    final clock = context
        .dependOnInheritedWidgetOfExactType<_StudentVisitClock>();
    if (clock == null) return child;
    final showImmediately =
        immediate ||
        isReducedMotion(context) ||
        MediaQuery.accessibleNavigationOf(context);
    // The app bar is immediate; headings/heroes lead the lower card rows.
    final isStructure = structural || order == 0;
    final rowCurve = switch (order) {
      <= 1 => const Interval(.22, .65, curve: Curves.easeOutCubic),
      2 => const Interval(.36, .82, curve: Curves.easeOutCubic),
      _ => const Interval(.48, 1, curve: Curves.easeOutCubic),
    };
    final fade = showImmediately
        ? const AlwaysStoppedAnimation<double>(1)
        : isStructure
        ? CurveTween(curve: const Interval(.08, .40,
            curve: Curves.easeOutCubic)).animate(clock.animation)
        : CurveTween(
            curve: rowCurve,
          ).animate(clock.animation);
    return AnimatedBuilder(
      animation: fade,
      child: child,
      builder: (context, child) {
        final hidden = fade.value == 0;
        return ExcludeFocus(
          excluding: hidden,
          child: ExcludeSemantics(
            excluding: hidden,
            child: IgnorePointer(
              ignoring: hidden,
              child: Transform.translate(
                offset: Offset(0, (showImmediately ? 0 : isStructure ? 6 : 8) * (1 - fade.value)),
                child: FadeTransition(opacity: fade, child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}
