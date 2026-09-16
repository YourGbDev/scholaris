// lib/features/onboarding/presentation/onboarding_screen.dart
//
// First-launch onboarding for Scholaris: three high-fidelity slides matching
// the Stitch design specifications (academic momentum, Philippine context,
// verified grant ecosystem).
//
// Shows exactly once — completing, skipping or choosing "Log in" persists the
// `onboarding_seen` flag via [onboardingSeenProvider].

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'package:scholaris/features/onboarding/controllers/onboarding_controller.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';

bool get _isWidgetTestBinding =>
    WidgetsBinding.instance.runtimeType.toString().contains('Test');

class _SlideSpec {
  const _SlideSpec({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.badgeKicker,
    required this.badgeIcon,
    required this.extraFeature,
  });

  final String asset;
  final String title;
  final String subtitle;
  final String badgeKicker;
  final IconData badgeIcon;
  final String extraFeature;
}

const List<_SlideSpec> _kSlides = [
  _SlideSpec(
    asset: 'assets/animations/onboarding_slide1.json',
    title: 'Find Your Scholarship',
    subtitle: 'Hundreds of opportunities matched to your profile',
    badgeKicker: 'SIMULAN ANG PANGARAP',
    badgeIcon: Icons.auto_awesome,
    extraFeature: '₱480M+ Active Funds',
  ),
  _SlideSpec(
    asset: 'assets/animations/onboarding_slide2_hero.json',
    title: 'Smart Matching',
    subtitle:
        'We find the best fit based on your grades, course, and financial need',
    badgeKicker: 'SMART CRITERIA MATCHING',
    badgeIcon: Icons.track_changes,
    extraFeature: '98% Algorithmic Match',
  ),
  _SlideSpec(
    asset: 'assets/animations/onboarding_slide3.json',
    title: 'Apply with Ease',
    subtitle: 'Track your applications and never miss a deadline',
    badgeKicker: 'RADICAL TRANSPARENCY',
    badgeIcon: Icons.verified_user_outlined,
    extraFeature: 'Live Audit Trail',
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
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: SizedBox(
                height: 36,
                child: Row(
                  children: [
                    const Expanded(
                      child: ScholarisLogo(fontSize: 18, badgeSize: 28, iconSize: 16),
                    ),
                    if (_page == 2)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '3 of 3',
                          style: poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _kSlides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final spec = _kSlides[index];
                  final isLast = index == _kSlides.length - 1;
                  return _SlideFadeRise(
                    child: _OnboardingSlide(
                      spec: spec,
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
          ],
        ),
      ),
    );
  }
}

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
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation),
        child: widget.child,
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.spec,
    required this.index,
    required this.isLast,
    required this.onSkip,
    required this.onNext,
    required this.onFinish,
    required this.onLogin,
  });

  final _SlideSpec spec;
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
        final illustrationArea = math.min(height * 0.40, 260.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration Hero Canvas
                    Container(
                      height: illustrationArea,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8E5)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Lottie.asset(
                              spec.asset,
                              fit: BoxFit.contain,
                              animate:
                                  !(MediaQuery.maybeOf(context)?.disableAnimations ??
                                      false) &&
                                  !_isWidgetTestBinding,
                            ),
                          ),
                          // Feature Pill Tag on Artwork
                          Positioned(
                            bottom: 8,
                            left: 16,
                            right: 16,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x10000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(spec.badgeIcon, size: 13, color: kPrimary),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        spec.extraFeature,
                                        style: poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF161C27),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Kicker Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB3F1C6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        spec.badgeKicker,
                        style: poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF145131),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      spec.title,
                      textAlign: TextAlign.center,
                      style: poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        spec.subtitle,
                        textAlign: TextAlign.center,
                        style: openSans(
                          fontSize: 14,
                          color: const Color(0xFF404942),
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Stepper Dots
                    _Dots(count: _kSlides.length, active: index),
                  ],
                ),
              ),
              // Bottom Controls
              _BottomControls(
                isLast: isLast,
                onSkip: onSkip,
                onNext: onNext,
                onFinish: onFinish,
                onLogin: onLogin,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

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
              color: i == active ? kPrimary : const Color(0xFFDDE2F3),
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
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: kNavyTrust,
              textStyle: poppins(fontSize: 15, fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Skip'),
          ),
          Semantics(
            button: true,
            label: 'Next',
            child: SizedBox(
              width: 58,
              height: 58,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  elevation: 2,
                ),
                child: const Icon(Icons.arrow_forward_rounded, size: 24),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Get Started',
              style: poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onLogin,
          child: Text(
            'Already have an account? Log in',
            style: poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kNavyTrust,
            ),
          ),
        ),
      ],
    );
  }
}
