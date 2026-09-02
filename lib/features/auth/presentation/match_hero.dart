// lib/features/auth/presentation/match_hero.dart
//
// Day 18: a small self-contained Lottie "match hero" for the intro screen.
// Owns its own AnimationController, plays the bundled Lottie once when [start]
// flips true, reports completion via [onCompleted], honours reduced motion
// (no playback — settles immediately into a meaningful end state), and
// degrades to a simple native fallback if the asset cannot load.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:scholaris/shared/theme/app_theme.dart';

/// The bundled Lottie hero asset.
const String kMatchHeroAsset = 'assets/animations/scholaris_match_hero.json';

/// Natural duration of the hero asset (240 frames @ 60fps). Used to keep
/// playback and tests in sync with the real animation's timing.
const int kMatchHeroDurationMs = 4000;

/// A self-contained Lottie hero that plays once and reports completion.
class MatchHero extends StatefulWidget {
  const MatchHero({
    super.key,
    required this.start,
    required this.onCompleted,
    this.assetPath = kMatchHeroAsset,
    this.width = 220,
    this.height = 220,
  });

  /// When true the hero begins its animation (or settles immediately under
  /// reduced motion). The host controls this so playback starts only after the
  /// entrance has settled.
  final bool start;

  /// Called (microtask-deferred) once the hero reaches its end state.
  final VoidCallback onCompleted;

  /// Lottie asset to load. Overridable for tests.
  final String assetPath;

  final double width;
  final double height;

  @override
  State<MatchHero> createState() => _MatchHeroState();
}

class _MatchHeroState extends State<MatchHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduced = false;
  bool _compositionReady = false;
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
    if (reduce != _reduced) {
      _reduced = reduce;
      if (reduce) _settle();
    }
  }

  @override
  void didUpdateWidget(MatchHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.start && !oldWidget.start) {
      if (_reduced) {
        _settle();
      } else {
        _play();
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _complete();
  }

  void _settle() {
    _complete();
  }

  void _play() {
    if (_completed || !_compositionReady) return;
    _controller.forward();
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    // Deliver completion from a clean post-frame context (never synchronously
    // from inside a controller status notification), so the host can safely
    // start its own matching ticker. The host still microtask-defers the
    // actual forward() (see IntroScreen._onHeroCompleted).
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
    if (_reduced) return _buildFallback();
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Lottie.asset(
        widget.assetPath,
        controller: _controller,
        animate: false,
        repeat: false,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
          _compositionReady = true;
          if (widget.start && !_completed) _controller.forward();
        },
        errorBuilder: (context, error, stackTrace) {
          _complete();
          return _buildFallback();
        },
      ),
    );
  }

  /// Native static fallback shown when the Lottie cannot load or reduced
  /// motion is active: a graduation cap inside a soft circle with a gold
  /// check badge — the "matched" settled state.
  Widget _buildFallback() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 132,
              height: 132,
              decoration: const BoxDecoration(
                color: kPrimarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 56,
                color: kPrimary,
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: kAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 24, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
