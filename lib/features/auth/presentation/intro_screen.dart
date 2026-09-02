// lib/features/auth/presentation/intro_screen.dart
//
// First-run intro: a short, self-running preview of what Scholaris does —
// student → matching → scholarship opportunities — followed by a single
// call-to-action into login.
//
// The branding entrance is staged rather than staggered: the logo is the only
// element on screen for its own beat, then it is held alone, then the
// wordmark enters, held, then the tagline, held — the three brand elements
// never resolve as one block. Only after that branding block settles does the
// story copy and the "matching" preview enter.
//
// The "matching" moment is a restrained native-Flutter timeline: profile
// skeleton rows resolve, one by one, into example scholarship cards with
// match percentages while a status line narrates the three stages. The
// timeline is gated to start only after the entrance has fully settled, so
// branding and matching never overlap. Each card settles over its own short
// window (no drifting), status changes fade + rise through an AnimatedSwitcher,
// and the Get-started CTA is choreographed to fade in only after the final
// card has settled — the reward at the end of the sequence. It uses only
// FadeTransition / SlideTransition / AnimatedSwitcher driven by Interval
// curves over the shared entrance controller plus one timeline controller — no
// assets, no third-party animation packages.
//
// Reduced motion: when the platform requests reduced animations both the
// entrance and the matching timeline jump to their settled state, so every
// card is visible and the CTA is enabled on the first frame.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';
import 'package:scholaris/shared/widgets/scholaris_logo_badge.dart';

/// Total duration of the intro's staged entrance (logo → wordmark → tagline →
/// story → matching preview). Longer than the default so each branding element
/// gets an isolated moment before the next enters.
const int kIntroEntranceTotalMs = 1900;

/// Total duration of the matching timeline (independent of the entrance).
const int _matchingTimelineMs = 4200;

/// How long a single opportunity card takes to settle once it begins
/// resolving. Fixed per card so each reveal lands decisively.
const int _cardRevealMs = 520;

/// Timeline points (ms) at which each opportunity card begins resolving.
const List<int> _revealAtMs = [700, 1700, 2700];

/// When the Get-started CTA starts to fade in — after the final card has
/// settled and the summary status is on screen.
const int _ctaFadeInMs = 3100;

/// How long the CTA reveal lasts.
const int _ctaFadeMs = 450;

// Branding choreography (ms into [kIntroEntranceTotalMs]). Each element
// settles, is held alone, then the next begins — the three brand elements
// never enter as one block.
const int _logoBeginMs = 60;
const int _logoEndMs = 360;
const int _wordmarkBeginMs = 560;
const int _wordmarkEndMs = 860;
const int _taglineBeginMs = 1060;
const int _taglineEndMs = 1360;
const int _storyBeginMs = 1420;
const int _storyEndMs = 1660;
const int _previewBeginMs = 1660;
const int _previewEndMs = 1900;

/// Builds an [Interval] over the intro's entrance timeline.
Interval _entranceInterval(int beginMs, int endMs) =>
    EntranceMotion.intervalFrom(beginMs, endMs, kIntroEntranceTotalMs);

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen>
    with
        TickerProviderStateMixin<IntroScreen>,
        EntranceMotionMixin<IntroScreen> {
  /// The intro's entrance is longer than the default because the branding is
  /// staged: logo alone, then wordmark, then tagline, each settling before the
  /// next enters, followed by the story and matching preview.
  @override
  Duration get entranceDuration =>
      const Duration(milliseconds: kIntroEntranceTotalMs);

  /// Drives the matching preview from 0 → 1 over [_matchingTimelineMs].
  late final AnimationController _matching = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _matchingTimelineMs),
  );

  /// Per-card reveal animations, built once over the matching controller.
  /// Each card resolves over its own fixed window ([_cardRevealMs]) so it
  /// settles decisively instead of drifting for the whole gap between reveal
  /// points.
  late final List<CurvedAnimation> _cardAnimations = List.generate(
    _opportunities.length,
    (i) {
      final begin = _revealAtMs[i] / _matchingTimelineMs;
      final end = (_revealAtMs[i] + _cardRevealMs) / _matchingTimelineMs;
      return CurvedAnimation(
        parent: _matching,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );
    },
  );

  /// Fade-in for the CTA, choreographed at the tail of the matching timeline
  /// so it reads as the reward once every card has settled.
  late final CurvedAnimation _ctaAnimation = CurvedAnimation(
    parent: _matching,
    curve: Interval(
      _ctaFadeInMs / _matchingTimelineMs,
      (_ctaFadeInMs + _ctaFadeMs) / _matchingTimelineMs,
      curve: Curves.easeOutCubic,
    ),
  );

  bool _matchingStarted = false;
  bool _entranceReady = false;

  /// True once the CTA reveal has fully resolved, making the button tappable.
  bool _ctaReady = false;

  @override
  void initState() {
    super.initState();
    // Gate the CTA twice: it must not be tappable while the screen is still
    // animating in (_entranceReady) nor before the matching sequence has
    // settled (_ctaReady). With reduced motion both resolve at once (see
    // didChangeDependencies), so the Day 16 CTA lifecycle bug is not repeated.
    entranceController.addListener(_onEntranceTick);
    _ctaAnimation.addListener(_onCtaTick);
  }

  void _onEntranceTick() {
    if (_entranceReady || entranceController.value < 1.0) return;
    setState(() => _entranceReady = true);
    // The matching timeline begins only once the branding entrance has fully
    // settled, so branding and matching never overlap. Reduced motion already
    // jumped the timeline to its end (see didChangeDependencies), so it never
    // forwards.
    //
    // The forward is deferred to a microtask: this listener fires while the
    // entrance controller is still notifying from inside its own tick, and
    // starting a fresh ticker from within that notification is not clock-safe
    // (the new ticker would capture the frame timestamp while the entrance
    // controller is mid-notification). By the time the microtask runs the
    // notification cycle has unwound — still within the same frame — so the
    // matching ticker starts cleanly with the correct start time and the
    // Day 17 sequence is unchanged.
    if (!reducedMotion) {
      Future<void>.microtask(() {
        if (!mounted) return;
        _matching.forward();
      });
    }
  }

  void _onCtaTick() {
    if (_ctaReady || _ctaAnimation.value < 1.0) return;
    setState(() => _ctaReady = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_matchingStarted) return;
    _matchingStarted = true;
    if (reducedMotion) {
      // Skip straight to the end of the matching timeline: every card and the
      // CTA render in their settled state on the first frame.
      _matching.value = 1.0;
      // _onEntranceTick / _onCtaTick fired while the element was still dirty
      // (setState is a no-op there), so resolve both gates post-frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _entranceReady = true;
          _ctaReady = true;
        });
      });
    }
    // Normal motion: the matching timeline is started by _onEntranceTick once
    // the entrance controller reaches 1.0 (the branding block has settled).
  }

  @override
  void dispose() {
    entranceController.removeListener(_onEntranceTick);
    _ctaAnimation.removeListener(_onCtaTick);
    _matching.dispose();
    super.dispose();
  }

  /// The narrated stage of the matching timeline: 0 = reading the profile,
  /// 1–2 = narrowing matches, 3 = finished (all cards revealed).
  int _matchingStage(double value) {
    for (var i = 0; i < _revealAtMs.length; i++) {
      if (value * _matchingTimelineMs < _revealAtMs[i]) return i;
    }
    return _revealAtMs.length;
  }

  static const List<({String name, String award, int percent, IconData icon})>
  _opportunities = [
    (
      name: 'STEM Futures Grant',
      award: '₱50,000 per year',
      percent: 94,
      icon: Icons.emoji_events_outlined,
    ),
    (
      name: 'Luzon Merit Scholarship',
      award: '₱30,000 per year',
      percent: 88,
      icon: Icons.school_outlined,
    ),
    (
      name: 'Future Educators Fund',
      award: '₱25,000 per year',
      percent: 82,
      icon: Icons.menu_book_outlined,
    ),
  ];

  String _statusFor(int stage) => switch (stage) {
    0 => 'Reading your profile…',
    1 => 'Matching your academics…',
    2 => 'Ranking opportunities…',
    _ => '12 scholarships fit you',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. Logo: the sole focus for its own beat -------------
                  // Scale 0.90 → 1.0 with a subtle fade + minimal rise, and
                  // nothing else enters until it has settled and been held.
                  entranceItem(
                    index: 0,
                    scaleFrom: 0.90,
                    offset: const Offset(0, 0.05),
                    interval: _entranceInterval(_logoBeginMs, _logoEndMs),
                    child: const Center(
                      child: ScholarisLogoBadge(heroTag: kScholarisLogoHeroTag),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // --- 2. Wordmark: enters only after the logo is held -----
                  entranceItem(
                    index: 1,
                    offset: const Offset(0, 0.12),
                    interval: _entranceInterval(
                      _wordmarkBeginMs,
                      _wordmarkEndMs,
                    ),
                    child: Text(
                      'Scholaris',
                      textAlign: TextAlign.center,
                      style: poppins(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // --- 3. Tagline: enters only after the wordmark is held --
                  entranceItem(
                    index: 2,
                    offset: const Offset(0, 0.12),
                    interval: _entranceInterval(_taglineBeginMs, _taglineEndMs),
                    child: Text(
                      'Find scholarships that fit you',
                      textAlign: TextAlign.center,
                      style: openSans(fontSize: 15, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // --- 4. Story copy ---------------------------------------
                  entranceItem(
                    index: 3,
                    offset: const Offset(0, 0.10),
                    interval: _entranceInterval(_storyBeginMs, _storyEndMs),
                    child: Text(
                      'Tell us about your studies — we surface the scholarships '
                      'worth your time.',
                      textAlign: TextAlign.center,
                      style: openSans(fontSize: 14, color: Colors.black45),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // --- 5. Matching preview -----------------------------------
                  entranceItem(
                    index: 4,
                    offset: const Offset(0, 0.08),
                    interval: _entranceInterval(_previewBeginMs, _previewEndMs),
                    child: _buildMatchingPreview(),
                  ),
                  const SizedBox(height: 28),
                  // --- 6. CTA + footer (reveal at the tail of the matching
                  //        timeline, not as part of the entrance stagger) -----
                  _buildCta(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The end-of-sequence call to action. Fades + rises in at the tail of the
  /// matching timeline (see [_ctaAnimation]) so it lands as the reward once
  /// every card has settled, instead of sitting disabled on screen the whole
  /// time. Tapping routes to /login; the button is only enabled once both the
  /// screen entrance and the CTA reveal have resolved.
  Widget _buildCta() {
    return FadeTransition(
      opacity: _ctaAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_ctaAnimation),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _entranceReady && _ctaReady
                  ? () => context.go('/login')
                  : null,
              child: Text(
                'Get started',
                style: poppins(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Free for students · No fees to apply',
              textAlign: TextAlign.center,
              style: openSans(fontSize: 12, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingPreview() {
    return AnimatedBuilder(
      animation: _matching,
      builder: (context, _) {
        final value = _matching.value;
        final stage = _matchingStage(value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusLine(stage, value),
            const SizedBox(height: 16),
            for (var i = 0; i < _opportunities.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _cardAnimations[i].value > 0
                    ? _buildReveal(i, _opportunities[i], i == 0)
                    : _buildSkeletonRow(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatusLine(int stage, double value) {
    final matching = stage < _revealAtMs.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (matching)
          Transform.scale(
            scale: 1 + 0.03 * math.sin(value * math.pi * 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: kAccent,
                shape: BoxShape.circle,
              ),
            ),
          )
        else
          const Icon(Icons.check_circle, size: 16, color: kPrimary),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.center,
            children: [?currentChild],
          ),
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: Text(
            _statusFor(stage),
            key: ValueKey<String>(_statusFor(stage)),
            style: poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: matching ? Colors.black54 : kPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReveal(
    int index,
    ({String name, String award, int percent, IconData icon}) opportunity,
    bool topMatch,
  ) {
    final animation = _cardAnimations[index];
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(color: kPrimary.withValues(alpha: 0.08)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0F4D2E),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: kPrimarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(opportunity.icon, size: 22, color: kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.name,
                      style: poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opportunity.award,
                      style: openSans(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: topMatch ? kPrimary : kPrimarySoft,
                  borderRadius: BorderRadius.circular(kRadiusInput),
                ),
                child: Text(
                  '${opportunity.percent}%',
                  style: poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: topMatch ? Colors.white : kPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Placeholder row shown while the timeline is still "searching" — resolves
  /// into a real opportunity card at its reveal point.
  Widget _buildSkeletonRow() {
    return Opacity(
      opacity: 0.55,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kRadiusCard),
          border: Border.all(color: kPrimary.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: kPrimarySoft,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: kPrimarySoft,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: 0.4,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: kPrimarySoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
