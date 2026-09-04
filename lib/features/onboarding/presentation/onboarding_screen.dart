// lib/features/onboarding/presentation/onboarding_screen.dart
//
// First-launch onboarding for Scholaris: three full-screen slides that teach
// the app's value before login. Shows exactly once — completing, skipping or
// choosing "Log in" persists the `onboarding_seen` flag via
// [onboardingSeenProvider], so the router never routes back here.
//
// Layout follows the introduction_animation template from the
// Best-Flutter-UI-Templates pack, restyled with Scholaris tokens:
//   - full-screen warm background (kBackground)
//   - looping Lottie animation in the upper ~45% of the screen
//     (BoxFit.contain; frozen on its first frame for reduced motion)
//   - Poppins title + centered Open Sans subtitle beneath it
//   - page dots (kPrimary active, kPrimarySoft inactive) hugging the copy
//   - bottom row: "Skip" left + circular kPrimary next button right
//     (slides 1–2); full-width "Get Started" CTA + "Log in" link (last)
//   - bottom controls sit in a 24px gutter so nothing touches the edges
//
// The copy cluster is vertically centered above the anchored bottom row, so
// the slide reads balanced instead of top-heavy.
//
// Motion is constrained to the shared EntranceMotion choreography (fade +
// gentle rise on each slide mount), the PageView's natural horizontal swipe,
// and the illustrations' built-in Lottie motion (frozen for reduced motion).
// No bounce, no spring, no shimmer — and no extra float wrapper on top of
// animations that already move.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/features/onboarding/controllers/onboarding_controller.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';

/// A single onboarding slide's copy + illustration asset.
class _SlideSpec {
  const _SlideSpec({
    required this.asset,
    required this.title,
    required this.subtitle,
  });

  final String asset;
  final String title;
  final String subtitle;
}

const List<_SlideSpec> _kSlides = [
  _SlideSpec(
    asset: 'assets/animations/onboarding_slide1.json',
    title: 'Find Your Scholarship',
    subtitle: 'Hundreds of opportunities matched to your profile',
  ),
  _SlideSpec(
    asset: 'assets/animations/selection list clients.json',
    title: 'Smart Matching',
    subtitle:
        'We find the best fit based on your grades, course, and financial need',
  ),
  _SlideSpec(
    asset: 'assets/animations/onboarding_slide3.json',
    title: 'Apply with Ease',
    subtitle: 'Track your applications and never miss a deadline',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Mark onboarding as seen, then hand off to the login funnel. Called from
  /// "Skip", "Get Started" and the "Log in" link — all three mean the user is
  /// done with the intro and it must never show again.
  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (!mounted) return;
    context.go('/login');
  }

  void _goNext() {
    if (_page >= _kSlides.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: _kSlides.length,
          onPageChanged: (index) => setState(() => _page = index),
          itemBuilder: (context, index) {
            final spec = _kSlides[index];
            final isLast = index == _kSlides.length - 1;
            return _SlideFadeRise(
              child: _OnboardingSlide(
                asset: spec.asset,
                title: spec.title,
                subtitle: spec.subtitle,
                index: index,
                isLast: isLast,
                onSkip: _finish,
                onNext: _goNext,
                onFinish: _finish,
                onLogin: _finish,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One restrained EntranceMotion fade + rise per slide mount. The PageView
/// handles the horizontal swipe; this adds the calm settle the shared motion
/// language prescribes. Reduced-motion honors the settled state directly.
class _SlideFadeRise extends StatefulWidget {
  const _SlideFadeRise({required this.child});

  final Widget child;

  @override
  State<_SlideFadeRise> createState() => _SlideFadeRiseState();
}

class _SlideFadeRiseState extends State<_SlideFadeRise>
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
    final animation = CurvedAnimation(
      parent: _controller,
      curve: EntranceMotion.intervalFor(0),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animation),
        child: widget.child,
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.index,
    required this.isLast,
    required this.onSkip,
    required this.onNext,
    required this.onFinish,
    required this.onLogin,
  });

  final String asset;
  final String title;
  final String subtitle;
  final int index;
  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        // Illustration occupies the upper ~45% of the screen, capped so the
        // artwork never crowds the copy on short viewports.
        final illustrationArea = math.min(height * 0.45, 320.0);

        return Column(
          children: [
            // The copy cluster (illustration → title → subtitle → dots) sits
            // vertically centered in the space above the anchored bottom row,
            // so the slide reads balanced instead of top-heavy.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Illustration -------------------------------------------
                  SizedBox(
                    height: illustrationArea,
                    width: double.infinity,
                    child: Padding(
                      // Padding keeps the artwork clear of the screen edges in
                      // every breakpoint; contain letterboxes where the ratio
                      // differs.
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Lottie.asset(
                        asset,
                        fit: BoxFit.contain,
                        // The Lottie files carry their own looping motion, so
                        // there is no float wrapper here — stacking the old
                        // ±4px breathing on top would double-animate. Frozen
                        // on the first frame for reduced-motion users and in
                        // widget tests.
                        animate:
                            !(MediaQuery.maybeOf(context)?.disableAnimations ??
                                false) &&
                            !_isWidgetTestBinding,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // --- Title ----------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // --- Subtitle -------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: openSans(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // --- Page dots ------------------------------------------------
                  _Dots(count: _kSlides.length, active: index),
                ],
              ),
            ),
            // --- Bottom controls: 24px gutters so nothing touches the edges.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _BottomControls(
                isLast: isLast,
                onSkip: onSkip,
                onNext: onNext,
                onFinish: onFinish,
                onLogin: onLogin,
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

/// Page dots — kPrimary pill for the active slide, kPrimarySoft for the rest.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: i == active ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: i == active ? kPrimary : kPrimarySoft,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.isLast,
    required this.onSkip,
    required this.onNext,
    required this.onFinish,
    required this.onLogin,
  });

  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    if (!isLast) {
      // Skip on the left, circular kPrimary next button on the right — one
      // horizontally aligned row (the 24px gutters live on the parent).
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: Colors.black54,
              textStyle: poppins(fontSize: 15, fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Skip'),
          ),
          Semantics(
            button: true,
            label: 'Next',
            child: SizedBox(
              width: 64,
              height: 64,
              child: Material(
                color: kPrimary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onNext,
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Last slide: full-width "Get Started" CTA + log-in link. The parent's
    // 24px gutters keep the button from touching the screen edges.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusInput),
              ),
            ),
            child: Text(
              'Get Started',
              style: poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onLogin,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Already have an account? ',
                  style: openSans(fontSize: 13.5, color: Colors.black54),
                ),
                TextSpan(
                  text: 'Log in',
                  style: poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// True while running inside a widget test
/// (`AutomatedTestWidgetsFlutterBinding` / `LiveTestWidgetsFlutterBinding`).
///
/// The Lottie compositions loop forever; a repeating animation would keep the
/// test harness's `pumpAndSettle` from ever settling — it only stops when no
/// frame is scheduled. Freezing the illustration there keeps the widget tests
/// fast and deterministic; real app runs (debug, profile, release, web)
/// always animate.
bool get _isWidgetTestBinding {
  final type = WidgetsBinding.instance.runtimeType.toString();
  return type == 'AutomatedTestWidgetsFlutterBinding' ||
      type == 'LiveTestWidgetsFlutterBinding';
}
