// lib/features/auth/presentation/intro_screen.dart
//
// First-run intro: a short, self-running preview of what Scholaris does —
// student → matching → scholarship opportunities — followed by a single
// call-to-action into login.
//
// The "matching" moment is a restrained native-Flutter timeline: profile
// skeleton rows resolve, one by one, into example scholarship cards with
// match percentages while a status line narrates the three stages. It uses
// only FadeTransition / SlideTransition driven by Interval curves over one
// controller — no assets, no third-party animation packages.
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

/// Total duration of the matching timeline (independent of the entrance).
const int _matchingTimelineMs = 4200;

/// Timeline points (ms) at which each opportunity card resolves.
const List<int> _revealAtMs = [700, 1700, 2700];

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen>
    with
        TickerProviderStateMixin<IntroScreen>,
        EntranceMotionMixin<IntroScreen> {
  /// Drives the matching preview from 0 → 1 over [_matchingTimelineMs].
  late final AnimationController _matching = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _matchingTimelineMs),
  );

  /// Per-card reveal animations, built once over the matching controller.
  late final List<CurvedAnimation> _cardAnimations = List.generate(
    _opportunities.length,
    (i) {
      final begin = _revealAtMs[i] / _matchingTimelineMs;
      final end = i + 1 < _revealAtMs.length
          ? _revealAtMs[i + 1] / _matchingTimelineMs
          : 1.0;
      return CurvedAnimation(
        parent: _matching,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );
    },
  );

  bool _matchingStarted = false;
  bool _entranceReady = false;

  @override
  void initState() {
    super.initState();
    // Enable the CTA once the entrance has settled so a user cannot tap into
    // a screen that is still animating in. With reduced motion the entrance
    // completes instantly (see EntranceMotionMixin), so this resolves at once.
    entranceController.addListener(_onEntranceTick);
  }

  void _onEntranceTick() {
    if (_entranceReady || entranceController.value < 1.0) return;
    setState(() => _entranceReady = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_matchingStarted) return;
    _matchingStarted = true;
    if (reducedMotion) {
      _matching.value = 1.0;
      // The entrance controller jumped to 1.0 inside didChangeDependencies
      // (see EntranceMotionMixin), where _onEntranceTick's setState is a
      // no-op because the element is still dirty. Resolve the CTA post-frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_entranceReady) setState(() => _entranceReady = true);
      });
    } else {
      _matching.forward();
    }
  }

  @override
  void dispose() {
    entranceController.removeListener(_onEntranceTick);
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
                  entranceItem(
                    index: 0,
                    child: const Center(
                      child: ScholarisLogoBadge(heroTag: kScholarisLogoHeroTag),
                    ),
                  ),
                  const SizedBox(height: 24),
                  entranceItem(
                    index: 1,
                    child: Column(
                      children: [
                        Text(
                          'Scholaris',
                          textAlign: TextAlign.center,
                          style: poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find scholarships that fit you',
                          textAlign: TextAlign.center,
                          style: openSans(fontSize: 15, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  entranceItem(
                    index: 2,
                    child: Text(
                      'Tell us about your studies — we surface the scholarships '
                      'worth your time.',
                      textAlign: TextAlign.center,
                      style: openSans(fontSize: 14, color: Colors.black45),
                    ),
                  ),
                  const SizedBox(height: 28),
                  entranceItem(index: 3, child: _buildMatchingPreview()),
                  const SizedBox(height: 28),
                  entranceItem(
                    index: 4,
                    child: ElevatedButton(
                      onPressed: _entranceReady
                          ? () => context.go('/login')
                          : null,
                      child: Text(
                        'Get started',
                        style: poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  entranceItem(
                    index: 5,
                    child: Text(
                      'Free for students · No fees to apply',
                      textAlign: TextAlign.center,
                      style: openSans(fontSize: 12, color: Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          duration: const Duration(milliseconds: 260),
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
          begin: const Offset(0, 0.12),
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
