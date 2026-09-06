// lib/features/auth/presentation/graduation_ceremony.dart
//
// Day 19: the Scholaris opening ceremony — a full-bleed Lottie graduation
// moment played exactly once as the app's first-run experience. The host route
// owns navigation: this widget only reports completion through [onCompleted]
// once the animation has reached its end state (or when reduced motion or an
// asset failure makes playback impossible).
//
// Lifecycle rules honoured here:
//   * the Lottie plays a single time when its composition finishes loading;
//   * [onCompleted] fires exactly once, never synchronously from an animation
//     status notification — it is always deferred to a post-frame callback;
//   * when MediaQuery.disableAnimations is set the ceremony does NOT play and
//     completion is reported immediately;
//   * when the asset cannot load, completion is reported and nothing is shown
//     in its place (no fallback animation, no spinner);
//   * the controller is disposed with the state and a disposed widget never
//     invokes [onCompleted].

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:scholaris/shared/theme/app_theme.dart';

/// The bundled graduation ceremony Lottie asset (portrait composition).
const String kCeremonyAsset = 'assets/animations/scholaris_ceremony.json';

/// Natural duration of the ceremony asset (510 frames @ 60fps ≈ 8.5s). Used to
/// keep playback and tests in sync with the animation's real timing.
const int kCeremonyDurationMs = 8500;

/// A self-contained, one-shot Lottie graduation ceremony.
class GraduationCeremony extends StatefulWidget {
  const GraduationCeremony({
    super.key,
    this.assetPath = kCeremonyAsset,
    required this.onCompleted,
  });

  /// Lottie asset to load. Overridable for tests.
  final String assetPath;

  /// Called exactly once when the ceremony reaches its end state: playback
  /// finished, reduced motion skipped playback, or the asset failed to load.
  /// Deferred to a post-frame callback so it is never delivered from inside a
  /// controller status notification.
  final VoidCallback onCompleted;

  @override
  State<GraduationCeremony> createState() => _GraduationCeremonyState();
}

class _GraduationCeremonyState extends State<GraduationCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _reduced = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce == _reduced) return;
    _reduced = reduce;
    // Reduced motion: the ceremony never plays; jump straight to completion so
    // the host route moves on without any animation.
    if (reduce) _complete();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _complete();
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    // Deliver completion from a clean post-frame context — never synchronously
    // from a status notification, a build-phase dependency change, or an asset
    // error callback — so the host can safely navigate / rebuild. A widget
    // disposed before this frame runs simply drops the callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kBackground,
      child: Lottie.asset(
        widget.assetPath,
        controller: _controller,
        animate: false,
        repeat: false,
        // The asset is a portrait composition (~400×800); contain keeps the
        // shapes from being distorted on unusual aspect ratios while still
        // filling the portrait viewport the ceremony is designed for.
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        onLoaded: (composition) {
          if (!mounted) return;
          _controller.duration = composition.duration;
          if (!_reduced && !_completed) _controller.forward();
        },
        errorBuilder: (context, error, stackTrace) {
          // The asset is missing or corrupt: never block the flow, never show
          // a substitute. Report completion so the host route moves on.
          _complete();
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
