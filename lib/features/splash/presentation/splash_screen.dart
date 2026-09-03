// lib/features/splash/presentation/splash_screen.dart
//
// Animated splash: a graduation cap scales in, "Scholaris" rises beneath it
// and the tagline fades in over the warm off-white background — then the
// content fades out and the router hands off.
//
// Routing: /splash is the app's initial location. The redirect logic in
// lib/app/router.dart already decides the destination (onboarding_seen gate +
// auth state → /onboarding, /login or /home); this screen only holds the
// router on /splash until its sequence finishes (or is skipped under reduced
// motion) via [splashCompletedProvider], so the animation plays before the
// existing redirect proceeds. No auth decisions are made here.
//
// Timeline (one sequence controller; ms milestones within a 2.8s timeline —
// the 2.5s choreography plus the 300ms exit fade):
//   0–400      background fades in (white base → kBackground)
//   300–800    cap scales 0→1 + fades in (Curves.easeOutCubic)
//   700–1200   "Scholaris" fades + rises in
//   1000–1500  tagline fades in
//   1500→      cap floats ±4px (2500ms easeInOut, repeat reverse — the same
//              float the onboarding illustrations use)
//   2500–2800  content fades out → router proceeds to the next route
//
// Reduced motion: the sequence jumps straight to its settled end state and
// the hold is released immediately (minimal/no delay). The float never runs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';

// --- Timeline tokens --------------------------------------------------------

/// Sequence length: the 2.5s choreography plus the 300ms exit fade.
const int _kTotalMs = 2800;

const int _kBackgroundEndMs = 400;
const int _kCapBeginMs = 300;
const int _kCapEndMs = 800;
const int _kTitleBeginMs = 700;
const int _kTitleEndMs = 1200;
const int _kTaglineBeginMs = 1000;
const int _kTaglineEndMs = 1500;
const int _kFloatStartMs = 1500;
const int _kExitBeginMs = 2500;

/// Float amplitude — matches the onboarding illustration float (±4px, 8px
/// peak-to-peak).
const double _kFloatAmplitude = 4;

/// Interval for a sequence element spanning [beginMs]–[endMs] (reuses the
/// shared EntranceMotion toolkit; defaults to the easeOutCubic house curve).
Interval _seq(int beginMs, int endMs) =>
    EntranceMotion.intervalFrom(beginMs, endMs, _kTotalMs);

// --- Splash-completed flag --------------------------------------------------

/// Whether the splash sequence has finished (or was skipped under reduced
/// motion). The router holds /splash until this flips true — then the normal
/// onboarding/auth redirect decides the destination.
class SplashCompletedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() => state = true;
}

final splashCompletedProvider = NotifierProvider<SplashCompletedNotifier, bool>(
  SplashCompletedNotifier.new,
);

/// True while running inside a widget test
/// (`AutomatedTestWidgetsFlutterBinding` / `LiveTestWidgetsFlutterBinding`).
///
/// A repeating controller would keep the test harness's `pumpAndSettle` from
/// ever settling — the same gate the onboarding float uses. The one-shot
/// sequence still plays in tests; only the endless float is skipped.
bool get _isWidgetTestBinding {
  final type = WidgetsBinding.instance.runtimeType.toString();
  return type == 'AutomatedTestWidgetsFlutterBinding' ||
      type == 'LiveTestWidgetsFlutterBinding';
}

// --- Screen -----------------------------------------------------------------

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sequence = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _kTotalMs),
  );

  /// Endless gentle float on the cap — mirrors the onboarding illustrations.
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  );

  bool _floatStarted = false;
  bool _completed = false;
  bool? _reduceMotion;

  // --- Sequence animations --------------------------------------------------
  late final Animation<double> _background = CurvedAnimation(
    parent: _sequence,
    curve: _seq(0, _kBackgroundEndMs),
  );
  late final Animation<double> _capFade = CurvedAnimation(
    parent: _sequence,
    curve: _seq(_kCapBeginMs, _kCapEndMs),
  );
  late final Animation<double> _capScale = CurvedAnimation(
    parent: _sequence,
    curve: _seq(_kCapBeginMs, _kCapEndMs),
  );
  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _sequence,
    curve: _seq(_kTitleBeginMs, _kTitleEndMs),
  );
  late final Animation<Offset> _titleRise =
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _sequence,
          curve: _seq(_kTitleBeginMs, _kTitleEndMs),
        ),
      );
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _sequence,
    curve: _seq(_kTaglineBeginMs, _kTaglineEndMs),
  );
  late final Animation<double> _exit = Tween<double>(begin: 1.0, end: 0.0)
      .animate(
        CurvedAnimation(
          parent: _sequence,
          curve: _seq(_kExitBeginMs, _kTotalMs),
        ),
      );

  // --- Float animation ------------------------------------------------------
  late final Animation<double> _floatDy = Tween<double>(
    begin: -_kFloatAmplitude,
    end: _kFloatAmplitude,
  ).animate(CurvedAnimation(parent: _float, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _sequence.addListener(_maybeStartFloat);
    _sequence.addStatusListener(_onSequenceStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    if (reduce) {
      // Skip straight to the settled end state with no hold: everything
      // visible, no float, no exit fade — the router proceeds immediately.
      // Completion is deferred to a post-frame callback: providers must not
      // be modified while the widget tree is building.
      _sequence.stop();
      _sequence.value = _kExitBeginMs / _kTotalMs;
      WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
    } else if (_sequence.isDismissed) {
      _sequence.forward();
    }
  }

  @override
  void dispose() {
    _sequence
      ..removeStatusListener(_onSequenceStatus)
      ..removeListener(_maybeStartFloat)
      ..dispose();
    _float.dispose();
    super.dispose();
  }

  /// Starts the endless float once the choreography reaches its 1.5s mark.
  void _maybeStartFloat() {
    if (_floatStarted) return;
    if (_sequence.value * _kTotalMs >= _kFloatStartMs) {
      _floatStarted = true;
      if (!(_reduceMotion ?? false) && !_isWidgetTestBinding) {
        _float.repeat(reverse: true);
      }
    }
  }

  /// Releases the router hold once the exit fade has finished.
  void _onSequenceStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _complete();
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    ref.read(splashCompletedProvider.notifier).complete();
  }

  @override
  Widget build(BuildContext context) {
    // Scale the brand marks with the viewport, clamped so phones keep their
    // proportions and tablets/desktops never overdraw.
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final capSize = (shortestSide * 0.22).clamp(72.0, 120.0);
    final titleSize = (shortestSide * 0.10).clamp(32.0, 44.0);

    return Scaffold(
      // White base so the warm background can fade in over it at startup.
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _background,
        child: Container(
          color: kBackground,
          alignment: Alignment.center,
          child: FadeTransition(
            // Exit fade: the foreground content fades out over the steady
            // kBackground, then the router proceeds.
            opacity: _exit,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Graduation cap — scales/fades in, then floats.
                AnimatedBuilder(
                  animation: Listenable.merge([_capScale, _float]),
                  builder: (context, child) {
                    final dy = _floatStarted ? _floatDy.value : 0.0;
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: child,
                    );
                  },
                  child: ScaleTransition(
                    scale: _capScale,
                    child: FadeTransition(
                      opacity: _capFade,
                      child: Icon(Icons.school, size: capSize, color: kPrimary),
                    ),
                  ),
                ),
                SizedBox(height: capSize * 0.18),
                // Wordmark — fades + rises in.
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleRise,
                    child: Text(
                      'Scholaris',
                      style: poppins(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline — fades in last.
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    'Your future starts somewhere.',
                    style: openSans(fontSize: 15, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
