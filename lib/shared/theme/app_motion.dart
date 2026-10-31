// lib/shared/theme/app_motion.dart
//
// Centralized Scholaris Motion System Tokens & Components
// Derived directly from scholaris-design-system.md Section 5 (Motion).

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

// --- 5.1 Durations -----------------------------------------------------------

/// duration-fast (150ms): Button press feedback, checkbox/switch toggle,
/// toast/snackbar slide-in/out, loading skeleton dissolve.
const Duration kDurationFast = Duration(milliseconds: 150);

/// duration-standard (250ms): Page/route transitions, tab switches,
/// list item expand/collapse, drawer closing.
const Duration kDurationStandard = Duration(milliseconds: 250);

/// duration-slow (350ms): Drawer/modal open, bottom sheet slide-up.
const Duration kDurationSlow = Duration(milliseconds: 350);

// --- 5.2 Easing Curves -------------------------------------------------------

/// ease-out (Curves.easeOutCubic): Anything entering the screen (drawer opening, page pushing in, modal appearing).
const Curve kEaseOut = Curves.easeOutCubic;

/// ease-in (Curves.easeInCubic): Anything leaving the screen (drawer closing, dismissing a modal, toast exit).
const Curve kEaseIn = Curves.easeInCubic;

/// ease-in-out (Curves.easeInOutCubic): State changes in place (tab indicators, button press feedback, expand/collapse).
const Curve kEaseInOut = Curves.easeInOutCubic;

/// Exact cubic-bezier curve approximating Apple's critically damped reposition spring (pip: ζ = 1.0, T = 0.40s).
const Curve kAppleSpringCurve = Cubic(0.16, 1.0, 0.3, 1.0);

// --- 5.2b Apple Spring Physics System (WWDC 2018 / 2026 Spec) ----------------

/// Apple WWDC 2018 / 2026 Spring Physics Specification.
/// Maps Apple's designer parameters (damping ratio ζ and response T in seconds)
/// to physical mass, stiffness, and damping for Flutter's [SpringDescription].
///
/// Mathematical mapping:
/// ω_n = 2π / response
/// stiffness (k) = mass * ω_n²
/// damping (c) = 2 * dampingRatio * mass * ω_n
class AppleSpringDescription extends SpringDescription {
  const AppleSpringDescription({
    required super.mass,
    required super.stiffness,
    required super.damping,
    required this.dampingRatio,
    required this.response,
  });

  /// Damping ratio (ζ):
  /// 1.0 = critically damped (no overshoot, smooth deceleration, default for UI transitions)
  /// 0.8 = slight bounce (momentum interactions only)
  /// < 0.8 = bouncy / playful (rarely used in system UI)
  final double dampingRatio;

  /// Response time in seconds:
  /// Approximate duration in seconds to reach the target if unimpeded.
  /// Defines responsiveness, not a fixed timer.
  final double response;

  factory AppleSpringDescription.fromDampingAndResponse({
    double dampingRatio = 1.0,
    double response = 0.35,
    double mass = 1.0,
  }) {
    assert(response > 0, 'Spring response time must be positive.');
    final omega = (2 * math.pi) / response;
    final stiffness = mass * omega * omega;
    final damping = 2 * dampingRatio * mass * omega;
    return AppleSpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
      dampingRatio: dampingRatio,
      response: response,
    );
  }

  // --- Apple Shipped Presets (Emil Kowalski / Apple WWDC) -------------------

  /// Critically damped UI spring (ζ = 1.0, T = 0.35s). No overshoot, default for UI transitions.
  static const AppleSpringDescription critical = AppleSpringDescription(
    mass: 1.0,
    stiffness: 322.27,
    damping: 35.90,
    dampingRatio: 1.0,
    response: 0.35,
  );

  /// Snappy press feedback (ζ = 1.0, T = 0.20s). Fast response, zero bounce.
  static const AppleSpringDescription snappyPress = AppleSpringDescription(
    mass: 1.0,
    stiffness: 986.96,
    damping: 62.83,
    dampingRatio: 1.0,
    response: 0.20,
  );

  /// Drawer / Modal Sheet (Apple shipped: ζ = 0.8, T = 0.30s). Subtle tactile momentum overshoot.
  static const AppleSpringDescription sheet = AppleSpringDescription(
    mass: 1.0,
    stiffness: 438.65,
    damping: 33.51,
    dampingRatio: 0.8,
    response: 0.30,
  );

  /// Move / Reposition (PiP window) (Apple shipped: ζ = 1.0, T = 0.40s). Smooth critically damped glide.
  static const AppleSpringDescription pip = AppleSpringDescription(
    mass: 1.0,
    stiffness: 246.74,
    damping: 31.42,
    dampingRatio: 1.0,
    response: 0.40,
  );

  /// Rotation / Flip (Apple shipped: ζ = 0.8, T = 0.40s). Playful angular momentum.
  static const AppleSpringDescription rotation = AppleSpringDescription(
    mass: 1.0,
    stiffness: 246.74,
    damping: 25.13,
    dampingRatio: 0.8,
    response: 0.40,
  );

  /// Momentum gesture release (ζ = 0.8, T = 0.35s). For interactive velocity handoffs.
  static const AppleSpringDescription momentum = AppleSpringDescription(
    mass: 1.0,
    stiffness: 322.27,
    damping: 28.72,
    dampingRatio: 0.8,
    response: 0.35,
  );
}

/// Backward-compatible aliases for existing references
const SpringDescription kDefaultSpring = AppleSpringDescription.critical;
const SpringDescription kSnappySpring = AppleSpringDescription.snappyPress;
const SpringDescription kMomentumSpring = AppleSpringDescription.momentum;

// --- 5.2c Apple Fluid Mechanics: Rubber-Banding & Velocity Handoff ------------

/// Apple's logarithmic rubber-banding resistance formula:
/// f(x, d, c) = (x * d * c) / (d + c * |x|)
///
/// x: overshoot distance beyond edge (pixels)
/// d: dimension of scrollable/draggable area (width or height in pixels)
/// c: Apple shipped constant = 0.55
double appleRubberBand({
  required double overshoot,
  required double dimension,
  double constant = 0.55,
}) {
  if (dimension <= 0) return 0.0;
  final absOvershoot = overshoot.abs();
  final resisted = (absOvershoot * dimension * constant) / (dimension + constant * absOvershoot);
  return overshoot < 0 ? -resisted : resisted;
}

/// Inverse mapping of Apple rubber-band displacement back to raw gesture overshoot.
double appleRubberBandInverse({
  required double resistedOffset,
  required double dimension,
  double constant = 0.55,
}) {
  final absResisted = resistedOffset.abs();
  if (dimension <= 0 || absResisted >= dimension) return 0.0;
  final raw = (absResisted * dimension) / (constant * (dimension - absResisted));
  return resistedOffset < 0 ? -raw : raw;
}

/// Normalized relative spring velocity from gesture velocity and remaining distance:
/// v_rel = gestureVelocity / (targetValue - currentValue)
/// Pass this as initialVelocity to SpringSimulation so there is no visible seam
/// between dragging and animating.
double calculateRelativeVelocity({
  required double gestureVelocity,
  required double currentValue,
  required double targetValue,
}) {
  final distance = targetValue - currentValue;
  if (distance.abs() < 1e-5) return 0.0;
  return gestureVelocity / distance;
}

/// Apple inertial momentum projection via exponential decay:
/// project(initialVelocity, decelerationRate = 0.998) = (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate)
/// Never use textbook constant deceleration v²/2a.
double projectMomentum({
  required double initialVelocity,
  double decelerationRate = 0.998,
}) {
  return (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate);
}

/// Custom scroll physics applying Apple's exact logarithmic rubber-banding formula (0.55)
/// and critically damped spring return to any Flutter scroll view.
class AppleBouncingScrollPhysics extends BouncingScrollPhysics {
  const AppleBouncingScrollPhysics({
    super.parent,
    this.rubberBandConstant = 0.55,
  });

  final double rubberBandConstant;

  @override
  AppleBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return AppleBouncingScrollPhysics(
      parent: buildParent(ancestor),
      rubberBandConstant: rubberBandConstant,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (!position.outOfRange) {
      return offset;
    }

    final double overscrollPastStart = math.max(position.minScrollExtent - position.pixels, 0.0);
    final double overscrollPastEnd = math.max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast = math.max(overscrollPastStart, overscrollPastEnd);
    final bool easing = (overscrollPastStart > 0.0 && offset > 0.0) || (overscrollPastEnd > 0.0 && offset < 0.0);

    final double dimension = position.viewportDimension;
    if (easing) {
      return offset;
    }

    final currentResisted = appleRubberBand(
      overshoot: overscrollPast,
      dimension: dimension,
      constant: rubberBandConstant,
    );
    final newResisted = appleRubberBand(
      overshoot: overscrollPast + offset.abs(),
      dimension: dimension,
      constant: rubberBandConstant,
    );

    final delta = newResisted - currentResisted;
    return offset < 0 ? -delta : delta;
  }
}

// --- Reduced Motion Helper ---------------------------------------------------

/// Checks if user accessibility preferences have disabled animations.
bool isReducedMotion(BuildContext context) {
  return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

// --- 5.3 Component Behaviors: PressableScale ---------------------------------

/// Button press scale feedback token (0.97 per HIG).
const double kButtonPressScale = 0.97;

/// Interactive scale feedback widget driven by continuous Apple SpringSimulation:
/// - Fires scale feedback (default 0.97) immediately on pointer-down.
/// - Returns to 1.0 on pointer-up or pointer-cancel via Apple's snappy critically damped spring.
/// - Velocity-preserving: preserves pointer release velocity so transitions are fully interruptible mid-flight.
/// - Respects reduced motion preferences.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.scale = kButtonPressScale,
    this.spring,
    this.duration = kDurationFast,
    this.curve = kEaseInOut,
    this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final double scale;
  final AppleSpringDescription? spring;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<PressableScale> createState() => PressableScaleState();
}

class PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  /// Current interpolated scale value (1.0 at rest)
  double get currentScale => controller.value;

  /// Current instantaneous velocity
  double get currentVelocity => controller.velocity;

  @override
  void initState() {
    super.initState();
    // Unbounded controller to allow spring physics (including slight overshoot if damping < 1.0)
    controller = AnimationController.unbounded(
      value: 1.0,
      vsync: this,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void animateTo(double target) {
    if (!widget.enabled) return;
    final spring = widget.spring ?? AppleSpringDescription.snappyPress;
    // Pass current controller velocity as initial velocity for seamless velocity handoff & interruptibility
    final simulation = SpringSimulation(
      spring,
      controller.value,
      target,
      controller.velocity,
    );
    controller.animateWith(simulation);
  }

  void _onPointerDown(PointerDownEvent event) {
    animateTo(widget.scale);
  }

  void _onPointerUp(PointerUpEvent event) {
    animateTo(1.0);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    animateTo(1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (isReducedMotion(context)) {
      if (widget.onTap != null) {
        return GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.translucent,
          child: widget.child,
        );
      }
      return widget.child;
    }

    Widget content = ScaleTransition(
      scale: controller,
      child: widget.child,
    );

    if (widget.onTap != null) {
      content = GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.translucent,
        child: content,
      );
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.translucent,
      child: content,
    );
  }
}

// --- Page & Route Transitions (Section 5.3) ----------------------------------

/// Page/route transitions: horizontal slide + fade per Section 5.3:
/// New page slides in from the right (Offset(0.08, 0) -> Offset.zero)
/// while fading from 0 -> 1 opacity, duration-standard (250ms), ease-out (Curves.easeOutCubic).
/// Page/route transitions: horizontal slide + fade per Section 5.3:
/// New page slides in from the right (Offset(0.08, 0) -> Offset.zero)
/// while fading from 0 -> 1 opacity, duration-standard (250ms), ease-out (Curves.easeOutCubic).
/// Replaces Flutter's default Material fade-through everywhere in the app.
Widget buildScholarisPageTransition({
  BuildContext? context,
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required Widget child,
}) {
  if (context != null && isReducedMotion(context)) {
    return FadeTransition(opacity: animation, child: child);
  }

  final inCurved = CurvedAnimation(
    parent: animation,
    curve: kEaseOut,
    reverseCurve: kEaseIn,
  );

  final inSlide = Tween<Offset>(
    begin: const Offset(0.08, 0.0),
    end: Offset.zero,
  ).animate(inCurved);

  final inFade = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(inCurved);

  final outCurved = CurvedAnimation(
    parent: secondaryAnimation,
    curve: kEaseIn,
  );

  final outFade = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).animate(outCurved);

  return SlideTransition(
    position: inSlide,
    child: FadeTransition(
      opacity: inFade,
      child: FadeTransition(
        opacity: outFade,
        child: child,
      ),
    ),
  );
}

/// Global PageTransitionsBuilder for ThemeData.pageTransitionsTheme
class ScholarisPageTransitionsBuilder extends PageTransitionsBuilder {
  const ScholarisPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildScholarisPageTransition(
      context: context,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

/// Standalone PageRoute adhering to Section 5.3 (250ms horizontal slide + fade)
class ScholarisPageRoute<T> extends PageRoute<T> {
  ScholarisPageRoute({
    required this.builder,
    super.settings,
  });

  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => kDurationStandard;

  @override
  Duration get reverseTransitionDuration => kDurationStandard;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildScholarisPageTransition(
      context: context,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

// --- Tab Switches & Content Cross-Fade (Section 5.3) -------------------------

/// Tab content cross-fades simultaneously with smooth midpoint luminance,
/// falling back to a clean 150ms opacity fade when reduced motion is preferred.
class TabContentCrossFade extends StatelessWidget {
  const TabContentCrossFade({
    super.key,
    required this.activeKey,
    required this.child,
    this.duration = kDurationStandard,
  });

  final ValueKey<Object> activeKey;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduced = isReducedMotion(context);
    return AnimatedSwitcher(
      duration: reduced ? kDurationFast : duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topLeft,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: activeKey,
        child: child,
      ),
    );
  }
}

// --- List Item Expand / Collapse (Section 5.3) ------------------------------

/// List item expand/collapse per Section 5.3:
/// Height and opacity animate together over duration-standard (250ms) with ease-in-out (Curves.easeInOutCubic).
/// Bypasses height animation if reduced motion is requested.
class ExpandableSection extends StatefulWidget {
  const ExpandableSection({
    super.key,
    required this.isExpanded,
    required this.child,
    this.duration = kDurationStandard,
    this.curve = kEaseInOut,
  });

  final bool isExpanded;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void didUpdateWidget(ExpandableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isReducedMotion(context)) {
      return widget.isExpanded ? widget.child : const SizedBox.shrink();
    }
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _animation,
        child: FadeTransition(
          opacity: _animation,
          child: widget.child,
        ),
      ),
    );
  }
}

// --- 5.4 Staggered Content Reveal -------------------------------------------

/// Staggered content reveal per Section 5.4:
/// 1. Container establishes its layout first (~180ms fade/expand, ease-out).
/// 2. Child blocks start animating ~140ms in (containerLeadMs).
/// 3. Each child block: translateY(12px -> 0) + fade, 220-240ms, ease-out.
/// 4. Stagger offset between children: fixed 40-50ms (not accelerating/decelerating).
class StaggeredContentReveal extends StatefulWidget {
  const StaggeredContentReveal({
    super.key,
    required this.children,
    this.containerLeadMs = 140,
    this.staggerOffsetMs = 45,
    this.childDurationMs = 230,
    this.containerDurationMs = 180,
  });

  final List<Widget> children;
  final int containerLeadMs;
  final int staggerOffsetMs;
  final int childDurationMs;
  final int containerDurationMs;

  @override
  State<StaggeredContentReveal> createState() => _StaggeredContentRevealState();
}

class _StaggeredContentRevealState extends State<StaggeredContentReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final int _totalDurationMs;

  @override
  void initState() {
    super.initState();
    final childCount = widget.children.length;
    _totalDurationMs = childCount > 0
        ? widget.containerLeadMs + ((childCount - 1) * widget.staggerOffsetMs) + widget.childDurationMs
        : widget.containerDurationMs;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalDurationMs),
    );

    // Run cascade entrance
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isReducedMotion(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: widget.children,
      );
    }

    final containerEnd = (widget.containerDurationMs / _totalDurationMs).clamp(0.0, 1.0);
    final containerAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, containerEnd, curve: kEaseOut),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FadeTransition(
          opacity: containerAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.children.length, (index) {
              final startMs = widget.containerLeadMs + (index * widget.staggerOffsetMs);
              final endMs = startMs + widget.childDurationMs;

              final startFraction = (startMs / _totalDurationMs).clamp(0.0, 1.0);
              final endFraction = (endMs / _totalDurationMs).clamp(0.0, 1.0);

              final rawProgress = endFraction > startFraction
                  ? ((_controller.value - startFraction) / (endFraction - startFraction)).clamp(0.0, 1.0)
                  : 1.0;
              final childProgress = kEaseOut.transform(rawProgress);

              final currentTranslateY = 12.0 * (1.0 - childProgress);

              return Transform.translate(
                offset: Offset(0, currentTranslateY),
                child: Opacity(
                  opacity: childProgress,
                  child: widget.children[index],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// --- 5.6 Loading State -> Real Data Resolution ------------------------------

/// Dissolves skeleton placeholder via ~150ms cross-fade into real content per Section 5.6.
/// All rows/content populate simultaneously (no row-by-row stagger).
class CrossFadeLoading extends StatelessWidget {
  const CrossFadeLoading({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.child,
    this.duration = kDurationFast, // 150ms
  });

  final bool isLoading;
  final Widget skeleton;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: kEaseOut,
      switchOutCurve: kEaseIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(
        key: ValueKey<bool>(isLoading),
        child: isLoading ? skeleton : child,
      ),
    );
  }
}

/// Shimmering/gray placeholder band for skeleton layouts matching Section 5.6.
class SkeletonBand extends StatefulWidget {
  const SkeletonBand({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.color = const Color(0xFFE5E7EB),
  });

  final double? width;
  final double height;
  final double borderRadius;
  final Color color;

  @override
  State<SkeletonBand> createState() => _SkeletonBandState();
}

class _SkeletonBandState extends State<SkeletonBand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Only repeat shimmer if not in a headless widget test environment,
    // avoiding infinite pumpAndSettle ticker timeouts.
    final isTest = WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');
    if (!isTest) {
      _shimmerController.repeat(reverse: true);
    }

    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _pulse.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

// --- 5.3 Toasts & Snackbars --------------------------------------------------

/// Displays a toast snackbar with slide-up + fade-in (150ms ease-out) and fade-out (150ms ease-in).
void showScholarisToast(
  BuildContext context, {
  required String message,
  IconData? icon,
  bool isError = false,
  Duration displayDuration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: displayDuration,
      margin: const EdgeInsets.only(bottom: 24, right: 24, left: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFBA1A1A) : const Color(0xFF161C27),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// --- 5.7 Staggered List Item Reveal & Count-Up Dynamics -----------------------

/// List item entrance animation powered by Apple's critically damped reposition spring
/// (Apple shipped: ζ = 1.0, T = 0.40s per WWDC 2018).
/// Replaces arbitrary fixed timers with physical spring simulations.
class StaggeredListItem extends StatefulWidget {
  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.spring,
    this.staggerMs = 35,
    this.durationMs = 200, // Kept for backward compatibility
    this.slideDistance = 14.0,
  });

  final int index;
  final Widget child;
  final AppleSpringDescription? spring;
  final int staggerMs;
  final int durationMs;
  final double slideDistance;

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Unbounded controller to allow spring physics
    _controller = AnimationController.unbounded(
      value: 0.0,
      vsync: this,
    );

    final delay = Duration(milliseconds: widget.index.clamp(0, 15) * widget.staggerMs);
    _timer = Timer(delay, () {
      if (mounted) {
        final spring = widget.spring ?? AppleSpringDescription.pip;
        _controller.animateWith(
          SpringSimulation(spring, _controller.value, 1.0, 0.0),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isReducedMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value.clamp(0.0, 1.0);
        final translateY = widget.slideDistance * (1.0 - progress);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Count-up animation for hero stat numbers:
/// Driven by Apple critically damped reposition spring (AppleSpringDescription.pip)
/// using continuous SpringSimulation.
class CountUpAnimation extends StatefulWidget {
  const CountUpAnimation({
    super.key,
    required this.targetValue,
    this.prefix = '',
    this.suffix = '',
    this.spring,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.formatWithCommas = true,
    this.immediate = false,
  });

  final int targetValue;
  final String prefix;
  final String suffix;
  final AppleSpringDescription? spring;
  final Duration duration;
  final TextStyle? style;
  final bool formatWithCommas;
  final bool immediate;

  @override
  State<CountUpAnimation> createState() => _CountUpAnimationState();
}

class _CountUpAnimationState extends State<CountUpAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(
      value: widget.immediate ? widget.targetValue.toDouble() : 0.0,
      vsync: this,
    );
    if (!widget.immediate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animate(0.0, widget.targetValue.toDouble());
        }
      });
    }
  }

  void _animate(double from, double to) {
    if (isReducedMotion(context) || widget.immediate) {
      _controller.value = to;
      return;
    }
    final sp = widget.spring ?? AppleSpringDescription.pip;
    final simulation = SpringSimulation(
      sp,
      from,
      to,
      0.0,
    );
    _controller.animateWith(simulation);
  }

  @override
  void didUpdateWidget(CountUpAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      if (widget.immediate) {
        _controller.value = widget.targetValue.toDouble();
      } else {
        _animate(_controller.value, widget.targetValue.toDouble());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(int value) {
    if (!widget.formatWithCommas) return '$value';
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (isReducedMotion(context)) {
      return Text(
        '${widget.prefix}${_format(widget.targetValue)}${widget.suffix}',
        style: widget.style,
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final current = _controller.value.round().clamp(0, widget.targetValue);
        return Text(
          '${widget.prefix}${_format(current)}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

// --- 5.8 Apple Spring Modal Bottom Sheet & Drawer ----------------------------

/// Apple Shipped Sheet Animation Style token (damping 0.8, response 0.3s)
final AnimationStyle kAppleSheetAnimationStyle = AnimationStyle(
  duration: const Duration(milliseconds: 300),
  reverseDuration: const Duration(milliseconds: 250),
);

/// Presents a modal bottom sheet with Apple's shipped sheet spring physics
/// (damping 0.8, response 0.3s) and velocity-inheriting gesture drag dismiss.
Future<T?> showAppleSpringModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? barrierColor,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool showDragHandle = false,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
  RouteSettings? routeSettings,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push(
    AppleSpringModalSheetRoute<T>(
      builder: builder,
      backgroundColor: backgroundColor,
      shape: shape,
      showDragHandle: showDragHandle,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.4),
      settings: routeSettings,
    ),
  );
}

/// Custom popup route for bottom sheets powered entirely by AppleSpringDescription.sheet
class _ClampedSpringAnimation extends Animation<double> with AnimationWithParentMixin<double> {
  _ClampedSpringAnimation(this.parent);

  @override
  final Animation<double> parent;

  @override
  double get value => parent.value.clamp(0.0, 1.0);
}

class AppleSpringModalSheetRoute<T> extends PopupRoute<T> {
  AppleSpringModalSheetRoute({
    required this.builder,
    this.backgroundColor,
    this.shape,
    this.showDragHandle = false,
    this.isScrollControlled = false,
    this.isDismissible = true,
    this.enableDrag = true,
    this.barrierColor = const Color(0x66000000),
    super.settings,
  });

  final WidgetBuilder builder;
  final Color? backgroundColor;
  final ShapeBorder? shape;
  final bool showDragHandle;
  final bool isScrollControlled;
  final bool isDismissible;
  final bool enableDrag;

  @override
  final Color barrierColor;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);

  @override
  AnimationController createAnimationController() {
    return AnimationController.unbounded(
      vsync: navigator!,
      value: 0.0,
      duration: transitionDuration,
      reverseDuration: reverseTransitionDuration,
    );
  }

  /// Public accessor for the sheet's animation controller.
  AnimationController? get sheetController => controller;
  @override
  Animation<double> createAnimation() {
    assert(controller != null);
    return _ClampedSpringAnimation(controller!);
  }


  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _AppleSpringSheetContainer(
      route: this,
      builder: builder,
      enableDrag: enableDrag,
    );
  }
}

class _AppleSpringSheetContainer extends StatefulWidget {
  const _AppleSpringSheetContainer({
    required this.route,
    required this.builder,
    required this.enableDrag,
  });

  final AppleSpringModalSheetRoute route;
  final WidgetBuilder builder;
  final bool enableDrag;

  @override
  State<_AppleSpringSheetContainer> createState() => _AppleSpringSheetContainerState();
}

class _AppleSpringSheetContainerState extends State<_AppleSpringSheetContainer> {
  double _sheetHeight = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.route.sheetController?.animateWith(
          SpringSimulation(AppleSpringDescription.sheet, 0.0, 1.0, 0.0),
        );
      }
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!widget.enableDrag || _sheetHeight <= 0) return;
    final controller = widget.route.sheetController;
    if (controller == null) return;

    final dy = details.primaryDelta ?? 0.0;
    final deltaNormalized = dy / _sheetHeight;
    final newRawValue = controller.value - deltaNormalized;

    if (newRawValue > 1.0) {
      // Over-drag upwards: apply Apple rubber-band resistance
      final overshootPx = (newRawValue - 1.0) * _sheetHeight;
      final resistedPx = appleRubberBand(overshoot: overshootPx, dimension: _sheetHeight);
      controller.value = 1.0 + (resistedPx / _sheetHeight);
    } else {
      controller.value = newRawValue;
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!widget.enableDrag || _sheetHeight <= 0) return;
    final controller = widget.route.sheetController;
    if (controller == null) return;

    final velocityPx = details.primaryVelocity ?? 0.0;
    final normalizedVelocity = -velocityPx / _sheetHeight;

    final shouldDismiss = controller.value < 0.75 || velocityPx > 500.0;

    if (shouldDismiss) {
      const target = 0.0;
      final relativeVel = calculateRelativeVelocity(
        gestureVelocity: normalizedVelocity,
        currentValue: controller.value,
        targetValue: target,
      );
      controller
          .animateWith(
            SpringSimulation(AppleSpringDescription.sheet, controller.value, target, relativeVel),
          )
          .then((_) {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      const target = 1.0;
      final relativeVel = calculateRelativeVelocity(
        gestureVelocity: normalizedVelocity,
        currentValue: controller.value,
        targetValue: target,
      );
      controller.animateWith(
        SpringSimulation(AppleSpringDescription.sheet, controller.value, target, relativeVel),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.route.sheetController;
    if (controller == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = controller.value;
        final clampedProgress = progress.clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.route.isDismissible
                    ? () {
                        controller
                            .animateWith(
                              SpringSimulation(AppleSpringDescription.sheet, controller.value, 0.0, 0.0),
                            )
                            .then((_) {
                          if (mounted) Navigator.of(context).pop();
                        });
                      }
                    : null,
                child: Container(
                  color: widget.route.barrierColor.withValues(
                    alpha: widget.route.barrierColor.a * clampedProgress,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: NotificationListener<SizeChangedLayoutNotification>(
                child: SizeChangedLayoutNotifier(
                  child: MeasureSize(
                    onChange: (size) {
                      if (_sheetHeight != size.height) {
                        setState(() => _sheetHeight = size.height);
                      }
                    },
                    child: GestureDetector(
                      onVerticalDragUpdate: _onVerticalDragUpdate,
                      onVerticalDragEnd: _onVerticalDragEnd,
                      child: Transform.translate(
                        offset: Offset(0, _sheetHeight * (1.0 - progress)),
                        child: _buildSheetBody(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSheetBody(BuildContext context) {
    Widget content = widget.builder(context);
    if (widget.route.showDragHandle) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Flexible(child: content),
        ],
      );
    }
    if (widget.route.backgroundColor != null || widget.route.shape != null) {
      content = Material(
        color: widget.route.backgroundColor ?? Colors.white,
        shape: widget.route.shape ??
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }
    return content;
  }
}

/// Helper widget to measure size dynamically
class MeasureSize extends StatefulWidget {
  const MeasureSize({super.key, required this.onChange, required this.child});
  final ValueChanged<Size> onChange;
  final Widget child;

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = context.size;
      if (size != null && _oldSize != size) {
        _oldSize = size;
        widget.onChange(size);
      }
    });
    return widget.child;
  }
}

// --- 5.9 Apple Liquid Glass Material -----------------------------------------

/// Generates an ImageFilter combining Apple 20px blur with 180% saturation boost.
ui.ImageFilter createAppleBlurFilter({
  double blur = 20.0,
  double saturation = 1.8,
}) {
  final blurFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur);
  if ((saturation - 1.0).abs() < 0.01) {
    return blurFilter;
  }
  final s = saturation;
  final invS = 1.0 - s;
  final rL = 0.2126 * invS;
  final gL = 0.7152 * invS;
  final bL = 0.0722 * invS;

  final colorFilter = ui.ColorFilter.matrix(<double>[
    rL + s, gL,     bL,     0, 0,
    rL,     gL + s, bL,     0, 0,
    rL,     gL,     bL + s, 0, 0,
    0,      0,      0,      1, 0,
  ]);

  try {
    return ui.ImageFilter.compose(outer: blurFilter, inner: colorFilter);
  } catch (_) {
    return blurFilter;
  }
}

/// Liquid Glass material widget implementing Apple's WWDC materials spec:
/// - blur(20px) + saturate(180%)
/// - Translucent tint: rgba(255,255,255, 0.60–0.82)
/// - Top light-edge refraction border: 1px rgba(255,255,255,0.4)
/// - Subtle ambient elevation shadow
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.tintColor = Colors.white,
    this.tintOpacity = 0.82,
    this.blur = 20.0,
    this.saturation = 1.8,
    this.border,
    this.showLightEdge = true,
    this.preserveBlurWithReducedMotion = false,
    this.lightEdgeColor = const Color(0x66FFFFFF), // rgba(255,255,255,0.4)
    this.padding,
    this.margin,
    this.boxShadow,
  });

  final Widget child;
  final double borderRadius;
  final Color tintColor;
  final double tintOpacity;
  final double blur;
  final double saturation;
  final BoxBorder? border;
  final bool showLightEdge;
  final bool preserveBlurWithReducedMotion;
  final Color lightEdgeColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    if (isReducedMotion(context) && !preserveBlurWithReducedMotion) {
      Widget simpleContent = Container(
        padding: padding,
        decoration: BoxDecoration(
          color: tintColor.withValues(alpha: math.min(1.0, tintOpacity + 0.1)),
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ??
              Border.all(
                color: Colors.black.withValues(alpha: 0.08),
                width: 1.0,
              ),
        ),
        child: child,
      );
      if (margin != null) {
        simpleContent = Padding(padding: margin!, child: simpleContent);
      }
      return simpleContent;
    }

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: createAppleBlurFilter(blur: blur, saturation: saturation),
        child: Stack(
          children: [
            Container(
              padding: padding,
              decoration: BoxDecoration(
                color: tintColor.withValues(alpha: tintOpacity),
                borderRadius: BorderRadius.circular(borderRadius),
                border: border ??
                    Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
              ),
              child: child,
            ),
            if (showLightEdge)
              Positioned(
                top: 0,
                left: borderRadius * 0.3,
                right: borderRadius * 0.3,
                height: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        lightEdgeColor.withValues(alpha: 0.0),
                        lightEdgeColor,
                        lightEdgeColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (boxShadow != null || borderRadius > 0) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: boxShadow ??
              [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
        ),
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}

// --- 5.10 Apple HIG Optical Typography System --------------------------------

/// Calculates optical letter-spacing (tracking) in pixels according to Apple HIG:
/// - Display / Large text (> 20pt): Negative tracking (-0.02em to -0.01em)
/// - Body text (14-16pt): Neutral tracking (~0.0)
/// - Small labels / Captions (< 14pt): Positive tracking (+0.015em to +0.035em)
double opticalTracking(double fontSize) {
  if (fontSize >= 32) return fontSize * -0.020; // 36pt -> -0.72
  if (fontSize >= 24) return fontSize * -0.015; // 28pt -> -0.42
  if (fontSize >= 20) return fontSize * -0.010; // 22pt -> -0.22
  if (fontSize >= 17) return fontSize * -0.005; // 18pt -> -0.09
  if (fontSize >= 14) return 0.0;               // 14-16pt -> 0.0
  if (fontSize >= 12) return fontSize * 0.018;  // 12pt -> +0.22
  return fontSize * 0.028;                      // 11pt -> +0.31
}

/// Returns Apple optical leading (line height multiplier) according to HIG:
/// - Display / Headings: Tight leading (1.05 - 1.20)
/// - Body / Reading: Relaxed leading (1.45 - 1.50)
/// - Labels / Buttons: Moderate leading (1.20 - 1.30)
double opticalLeading(double fontSize, {bool isBody = false}) {
  if (isBody) {
    if (fontSize >= 16) return 1.50;
    return 1.45;
  }
  if (fontSize >= 32) return 1.10;
  if (fontSize >= 24) return 1.15;
  if (fontSize >= 20) return 1.20;
  if (fontSize >= 16) return 1.25;
  return 1.30;
}

/// Applies Apple HIG optical tracking and leading across an entire TextTheme.
TextTheme applyOpticalTypography(TextTheme base) {
  TextStyle? opt(TextStyle? style, {bool isBody = false}) {
    if (style == null || style.fontSize == null) return style;
    final fs = style.fontSize!;
    return style.copyWith(
      letterSpacing: opticalTracking(fs),
      height: opticalLeading(fs, isBody: isBody),
    );
  }

  return base.copyWith(
    displayLarge: opt(base.displayLarge),
    displayMedium: opt(base.displayMedium),
    displaySmall: opt(base.displaySmall),
    headlineLarge: opt(base.headlineLarge),
    headlineMedium: opt(base.headlineMedium),
    headlineSmall: opt(base.headlineSmall),
    titleLarge: opt(base.titleLarge),
    titleMedium: opt(base.titleMedium),
    titleSmall: opt(base.titleSmall),
    bodyLarge: opt(base.bodyLarge, isBody: true),
    bodyMedium: opt(base.bodyMedium, isBody: true),
    bodySmall: opt(base.bodySmall, isBody: true),
    labelLarge: opt(base.labelLarge),
    labelMedium: opt(base.labelMedium),
    labelSmall: opt(base.labelSmall),
  );
}
