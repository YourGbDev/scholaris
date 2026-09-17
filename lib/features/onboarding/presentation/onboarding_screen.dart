// lib/features/onboarding/presentation/onboarding_screen.dart
//
// First-launch onboarding for Scholaris V2: three high-fidelity slides matching
// the Stitch design specifications (academic momentum, Philippine context,
// verified grant ecosystem):
//
// 1. "Find Your Scholarship" — Verified Grants Ecosystem Canvas & ₱480M+ metric.
// 2. "Get Matched, Not Just Listed." — Precision Matching Canvas & Algorithmic Matrix.
// 3. "Track Every Step" — End-to-End Audit Trail Canvas & Live Sync Milestones.
//
// Shows exactly once — completing, skipping or choosing "Log In" persists the
// `onboarding_seen` flag via [onboardingSeenProvider].

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/onboarding/controllers/onboarding_controller.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';

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
    if (_page >= 2) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _goBack() {
    if (_page <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: ResponsiveContainer(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Flexible(
                              child: ScholarisLogo(
                                compact: true,
                                fontSize: 18,
                                badgeSize: 28,
                                iconSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFABC28),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_page < 2)
                        TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF436084),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF436084),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFDDE2F3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'STEP ',
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF436084),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '3 of 3',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F4D2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Page View
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _page = index),
                  children: [
                    _SlideFadeRise(
                      child: _Slide1Ecosystem(
                        onNext: _goNext,
                        onLogin: _finish,
                      ),
                    ),
                    _SlideFadeRise(
                      child: _Slide2Matching(
                        onBack: _goBack,
                        onNext: _goNext,
                      ),
                    ),
                    _SlideFadeRise(
                      child: _Slide3AuditTrail(
                        onFinish: _finish,
                        onLogin: _finish,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 1: Find Your Scholarship (Ecosystem Canvas)
// ---------------------------------------------------------------------------
class _Slide1Ecosystem extends StatelessWidget {
  const _Slide1Ecosystem({required this.onNext, required this.onLogin});

  final VoidCallback onNext;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final heroHeight = math.min(math.max(height * 0.36, 180.0), 260.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // Graphic Hero: Ecosystem Canvas
                      SizedBox(
                        height: heroHeight,
                        width: double.infinity,
                        child: const _EcosystemHeroCanvas(),
                      ),
                      const SizedBox(height: 12),
                      // Regional Inspiration Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB3F1C6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: Color(0xFF145131),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'SIMULAN ANG PANGARAP',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF145131),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Headline
                      Text(
                        'Find Your Scholarship',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00351C),
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Narrative
                      Text(
                        'Discover thousands of verified grants and endowments tailored specifically to your academic background, region, and financial need.',
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: const Color(0xFF404942),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Metric Bento
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDDE2F3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDEA3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.payments_rounded,
                                size: 19,
                                color: Color(0xFF3C2A00),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₱480M+ Active Funds',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF161C27),
                                    ),
                                  ),
                                  Text(
                                    'Across Luzon, Visayas & Mindanao',
                                    style: GoogleFonts.openSans(
                                      fontSize: 11,
                                      color: const Color(0xFF436084),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Dots & Actions
              const _OnboardingDots(active: 0),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4D2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              TextButton(
                onPressed: onLogin,
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.openSans(
                      fontSize: 12.5,
                      color: const Color(0xFF436084),
                    ),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign In',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F4D2E),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 2: Smart Criteria Matching (Precision Matrix)
// ---------------------------------------------------------------------------
class _Slide2Matching extends StatelessWidget {
  const _Slide2Matching({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final heroHeight = math.min(math.max(height * 0.36, 180.0), 260.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // Graphic Hero: Precision Matrix Canvas
                      SizedBox(
                        height: heroHeight,
                        width: double.infinity,
                        child: const _PrecisionMatchingCanvas(),
                      ),
                      const SizedBox(height: 12),
                      // Kicker
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD2E4FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.track_changes_rounded,
                              size: 13,
                              color: Color(0xFF2B486B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'SMART CRITERIA MATCHING',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2B486B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Headline
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF161C27),
                            letterSpacing: -0.5,
                            height: 1.15,
                          ),
                          children: const [
                            TextSpan(text: 'Get Matched,\n'),
                            TextSpan(
                              text: 'Not Just Listed.',
                              style: TextStyle(color: Color(0xFF0F4D2E)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Narrative
                      Text(
                        'Say goodbye to endless scrolling through dead ends. Scholaris cross-examines your academic standing, LGU jurisdiction, and financial bracket to highlight funds you actually qualify for.',
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: const Color(0xFF404942),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Trust Features
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8E5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            _FeatureCheckRow(
                              text: 'Zero guesswork algorithmic accuracy',
                            ),
                            SizedBox(height: 5),
                            _FeatureCheckRow(
                              text:
                                  'Pre-filtered by GWA cutoff & Barangay indigency',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Dots & Action Buttons
              const _OnboardingDots(active: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 17),
                      label: Text(
                        'Back',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF436084),
                        side: const BorderSide(color: Color(0xFFC0C9C0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4D2E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 3: Radical Transparency (Audit Trail Canvas)
// ---------------------------------------------------------------------------
class _Slide3AuditTrail extends StatelessWidget {
  const _Slide3AuditTrail({required this.onFinish, required this.onLogin});

  final VoidCallback onFinish;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final heroHeight = math.min(math.max(height * 0.38, 190.0), 280.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // Graphic Hero: Audit Trail Canvas
                      SizedBox(
                        height: heroHeight,
                        width: double.infinity,
                        child: const _AuditTrailCanvas(),
                      ),
                      const SizedBox(height: 12),
                      // Kicker
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB3F1C6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🚀', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              'RADICAL TRANSPARENCY',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF145131),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Headline
                      Text(
                        'Track Every Step',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF161C27),
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Narrative
                      Text(
                        'Follow your application from draft to submission to final decision with real-time status updates, deadline alerts, and verified digital receipts.',
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: const Color(0xFF404942),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Reassurance Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDDE2F3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 17,
                              color: Color(0xFF0F4D2E),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: GoogleFonts.openSans(
                                    fontSize: 11,
                                    color: const Color(0xFF404942),
                                  ),
                                  children: [
                                    const TextSpan(
                                      text:
                                          'Never miss an announcement or deadline again ',
                                    ),
                                    TextSpan(
                                      text: '• 100% Free for Students',
                                      style: GoogleFonts.openSans(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F4D2E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Dots & Final Actions
              const _OnboardingDots(active: 2),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4D2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              TextButton(
                onPressed: onLogin,
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.openSans(
                      fontSize: 12.5,
                      color: const Color(0xFF436084),
                    ),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Log In',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF161C27),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Graphic Canvas 1: Ecosystem Hero Canvas
// ---------------------------------------------------------------------------
class _EcosystemHeroCanvas extends StatelessWidget {
  const _EcosystemHeroCanvas();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E5)),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        children: [
          // Ambient Glows
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD2E4FF).withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB3F1C6).withValues(alpha: 0.4),
              ),
            ),
          ),
          // Sun Ray Geometric Lines
          CustomPaint(
            size: const Size(200, 200),
            painter: _SunRayPainter(),
          ),
          // Center Core Glassmorphic Shield
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F4D2E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFFB3F1C6),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E8F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4.5,
                        height: 4.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F4D2E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        'VERIFIED GRANTS',
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00351C),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Badge 1: DOST-SEI STEM
          const Positioned(
            top: 8,
            left: 8,
            child: _EcosystemBadge(
              icon: Icons.biotech_rounded,
              iconBg: Color(0xFFD2E4FF),
              iconColor: Color(0xFF001C38),
              title: 'DOST-SEI',
              subtitle: 'Priority STEM',
            ),
          ),
          // Badge 2: CHED UniFAST
          const Positioned(
            bottom: 8,
            left: 8,
            child: _EcosystemBadge(
              icon: Icons.verified_rounded,
              iconBg: Color(0xFFB3F1C6),
              iconColor: Color(0xFF002110),
              title: 'CHED UniFAST',
              subtitle: 'Tertiary Subsidy',
            ),
          ),
          // Badge 3: LGU Academic Grant
          const Positioned(
            top: 8,
            right: 8,
            child: _EcosystemBadge(
              icon: Icons.location_city_rounded,
              iconBg: Color(0xFFFFDEA3),
              iconColor: Color(0xFF3C2A00),
              title: 'LGU Honors',
              subtitle: 'City & Provincial',
            ),
          ),
          // Badge 4: Private Foundations
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDDE2F3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.foundation_rounded,
                      size: 11,
                      color: Color(0xFF436084),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Private Endowments',
                    style: GoogleFonts.outfit(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF404942),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EcosystemBadge extends StatelessWidget {
  const _EcosystemBadge({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 11, color: iconColor),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF161C27),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.openSans(
                  fontSize: 8,
                  color: const Color(0xFF436084),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SunRayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFABC28).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 36, paint);
    canvas.drawCircle(center, 65, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Graphic Canvas 2: Precision Matching Visual Matrix
// ---------------------------------------------------------------------------
class _PrecisionMatchingCanvas extends StatelessWidget {
  const _PrecisionMatchingCanvas();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E5)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orbit rings
          CustomPaint(
            size: const Size(220, 220),
            painter: _DashedOrbitPainter(),
          ),
          // Center Matching Priority Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular Gauge
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(52, 52),
                        painter: _CircularGaugePainter(percentage: 0.98),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F4D2E),
                              ),
                              children: [
                                const TextSpan(text: '98'),
                                TextSpan(
                                  text: '%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFF1B41E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'MATCH',
                            style: GoogleFonts.outfit(
                              fontSize: 6.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF436084),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 9.5,
                        color: Color(0xFF0F4D2E),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'DOST-SEI Merit',
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F4D2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Metadata Badges
          const Positioned(
            top: 7,
            left: 7,
            child: _MatrixBadge(
              dotColor: Color(0xFF0F4D2E),
              text: 'GWA 1.45',
            ),
          ),
          const Positioned(
            top: 7,
            right: 7,
            child: _MatrixBadge(
              icon: Icons.school_rounded,
              iconColor: Color(0xFF0F4D2E),
              text: 'UP Diliman / SUC',
            ),
          ),
          const Positioned(
            bottom: 7,
            left: 7,
            child: _MatrixBadge(
              icon: Icons.verified_user_rounded,
              iconColor: Color(0xFF436084),
              text: 'ITR Verified',
            ),
          ),
          const Positioned(
            bottom: 7,
            right: 7,
            child: _MatrixBadge(
              dotColor: Color(0xFFF1B41E),
              text: 'BS STEM Priority',
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixBadge extends StatelessWidget {
  const _MatrixBadge({
    this.dotColor,
    this.icon,
    this.iconColor,
    required this.text,
  });

  final Color? dotColor;
  final IconData? icon;
  final Color? iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 3.5),
          ] else if (icon != null) ...[
            Icon(icon, size: 10, color: iconColor),
            const SizedBox(width: 3.5),
          ],
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF161C27),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  _CircularGaugePainter({required this.percentage});

  final double percentage;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 4.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Active Arc
    final activePaint = Paint()
      ..color = const Color(0xFF0F4D2E)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}

class _DashedOrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F4D2E).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 44, paint);
    canvas.drawCircle(center, 74, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Graphic Canvas 3: Audit Trail Canvas
// ---------------------------------------------------------------------------
class _AuditTrailCanvas extends StatelessWidget {
  const _AuditTrailCanvas();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 14,
                      color: Color(0xFF0F4D2E),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'End-to-End Audit Trail',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF161C27),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4.5,
                      height: 4.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F4D2E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      'Live sync',
                      style: GoogleFonts.outfit(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF404942),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Steps
          Expanded(
            child: Stack(
              children: [
                // Connecting line
                Positioned(
                  left: 9,
                  top: 9,
                  bottom: 12,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F4D2E),
                          Color(0xFF436084),
                          Color(0xFFF1B41E),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _AuditStepRow(
                      icon: Icons.check,
                      iconBg: Color(0xFF0F4D2E),
                      iconColor: Colors.white,
                      step: '1. Draft & Verified',
                      chip: 'TCG / BIR 2316',
                      subtitle: 'Biometric ID & credential hash verified',
                      badge: 'PASSED',
                      badgeBg: Color(0xFFF1F3FF),
                      badgeColor: Color(0xFF404942),
                    ),
                    _AuditStepRow(
                      icon: Icons.lock_rounded,
                      iconBg: Color(0xFF436084),
                      iconColor: Colors.white,
                      step: '2. Timestamped',
                      chip: 'SHA-256',
                      subtitle: 'Immutable digital vault receipt sealed',
                      badge: 'SEALED',
                      badgeBg: Color(0xFFD2E4FF),
                      badgeColor: Color(0xFF001C38),
                    ),
                    _AuditStepRow(
                      isCurrent: true,
                      step: '3. Committee Review',
                      subtitle: 'Deliberation batch in progress',
                      badge: '4d left',
                      badgeBg: Color(0xFFFFDAD6),
                      badgeColor: Color(0xFF93000A),
                    ),
                    _AuditStepRow(
                      icon: Icons.stars_rounded,
                      iconBg: Color(0xFFDDE2F3),
                      iconColor: Color(0xFFF1B41E),
                      step: '4. Direct Grant Payout',
                      chip: 'PHP 60,000',
                      subtitle: 'Automated release via LandBank / DBP',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditStepRow extends StatelessWidget {
  const _AuditStepRow({
    this.icon,
    this.iconBg,
    this.iconColor,
    this.isCurrent = false,
    required this.step,
    this.chip,
    required this.subtitle,
    this.badge,
    this.badgeBg,
    this.badgeColor,
  });

  final IconData? icon;
  final Color? iconBg;
  final Color? iconColor;
  final bool isCurrent;
  final String step;
  final String? chip;
  final String subtitle;
  final String? badge;
  final Color? badgeBg;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Node
        if (isCurrent)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0F4D2E), width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F4D2E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          )
        else
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: iconBg ?? const Color(0xFFDDE2F3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 11, color: iconColor ?? const Color(0xFF436084)),
          ),
        const SizedBox(width: 6),
        // Step details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      step,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF161C27),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (chip != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3.5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB3F1C6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        chip!,
                        style: GoogleFonts.outfit(
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF145131),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                subtitle,
                style: GoogleFonts.openSans(
                  fontSize: 8.5,
                  color: const Color(0xFF404942),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
            decoration: BoxDecoration(
              color: badgeBg ?? const Color(0xFFE3E8F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge!,
              style: GoogleFonts.outfit(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: badgeColor ?? const Color(0xFF161C27),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
class _FeatureCheckRow extends StatelessWidget {
  const _FeatureCheckRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 15,
          color: Color(0xFF0F4D2E),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.openSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF161C27),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: i == active ? 26 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == active
                  ? const Color(0xFF0F4D2E)
                  : const Color(0xFFDDE2F3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
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
