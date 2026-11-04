// lib/shared/widgets/scholarship_card.dart
//
// The standard Scholaris scholarship card rebuilt to 100% Stitch V2 specification
// (`scholaris_student_dashboard/code.html` and `scholaris_discover_filters/code.html`).
//
// Card anatomy:
// 1. Top row: profile readiness label + deadline/status metadata
//    (e.g. "5 days left" with hourglass) + Bookmark button
// 2. Title in bundled semantic semibold
// 3. Verified provider row with verified_user emblem
// 4. Bold grant amount in ₱ with frequency/renewal subtitle
// 5. Criteria chips (degree, need-based, year level, etc.)
// 6. Quick Apply primary CTA button

import 'package:scholaris/shared/theme/app_typography.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/scholarships/models/scholarship.dart';
import '../../features/profile/models/student_profile.dart';
import '../../features/scholarships/services/application_readiness.dart';
import '../../features/scholarships/services/match_reasons.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Maps a scholarship provider string to a brand palette accent color:
/// - University / College / Academic -> Bridge Green (kPrimary)
/// - NGO / Foundation / Association / Alliance -> Coral Connect (kCoralConnect)
/// - Private / Corporate / Bank -> Golden Opportunity (kAccent)
/// - Government Agency / Public Sector (default) -> Navy Trust (kNavyTrust)
Color providerTypeColor(String? provider) {
  if (provider == null || provider.trim().isEmpty) {
    return kNavyTrust;
  }
  final p = provider.toLowerCase();

  if (p.contains('university') ||
      p.contains('college') ||
      p.contains('state u') ||
      p.contains('academic') ||
      p.contains('institute of tech') ||
      p.contains('school')) {
    return kPrimary;
  }

  if (p.contains('foundation') ||
      p.contains('ngo') ||
      p.contains('alliance') ||
      p.contains('association') ||
      p.contains('trust') ||
      p.contains('advocacy') ||
      p.contains('society')) {
    return kCoralConnect;
  }

  if (p.contains('corporation') ||
      p.contains('corp') ||
      p.contains('bank') ||
      p.contains('company') ||
      p.contains('inc') ||
      p.contains('private') ||
      p.contains('technologies') ||
      p.contains('holdings')) {
    return kAccent;
  }

  return kNavyTrust;
}

/// Helper to format canonical Philippine grant amounts from scholarship model.
String formatScholarshipAmount(Scholarship s) {
  return s.formattedAmount;
}

String formatScholarshipFrequency(Scholarship s) {
  return s.formattedFrequency;
}

/// Formats the right-hand pill in the award highlight tile from canonical coverage & frequency
({String text, bool isRenewable}) formatScholarshipBenefit(Scholarship s) {
  final isRenewable = s.frequency == 'annual' || s.frequency == 'per_semester';
  final text = s.coverage.trim().isNotEmpty
      ? s.coverage
      : 'Tuition + Allowance';
  return (text: text, isRenewable: isRenewable);
}

/// Helper to format requirement snippet matching Stitch V2 Discover cards:
/// `1 Essay (500 words) • 1 Letter of Rec • Transcript`
({IconData icon, String text}) formatScholarshipRequirements(Scholarship s) {
  final title = s.title.toLowerCase();
  final provider = (s.provider ?? '').toLowerCase();

  if (title.contains('dost') || provider.contains('dost')) {
    return (
      icon: Icons.science_outlined,
      text: 'STEM Exam Qualifier • Form 137 • Cert of Good Moral',
    );
  } else if (title.contains('ched') || provider.contains('ched')) {
    return (
      icon: Icons.description_outlined,
      text: '1 Essay (500 words) • 1 Letter of Rec • Transcript',
    );
  } else if (s.maxMonthlyIncome != null) {
    return (
      icon: Icons.assignment_turned_in_outlined,
      text: 'ITR / Indigency Certificate • Certificate of Grades',
    );
  } else if (s.minGpa >= 3.0) {
    return (
      icon: Icons.description_outlined,
      text: 'Academic Transcript • 2 Letters of Rec • Essay',
    );
  }
  return (
    icon: Icons.description_outlined,
    text: '1 Essay (500 words) • 1 Letter of Rec • Transcript',
  );
}

class ScholarshipCard extends StatelessWidget {
  const ScholarshipCard({
    super.key,
    required this.scholarship,
    this.reasons = const [],
    this.matchPercentage,
    this.studentProfile,
    this.isBookmarked = false,
    this.isApplied = false,
    this.onToggleBookmark,
    this.onQuickApply,
    this.viewDetailsKey,
    this.cardGuideKey,
  });

  final Scholarship scholarship;
  final List<String> reasons;
  final int? matchPercentage;
  final StudentProfile? studentProfile;

  /// Whether this scholarship is in the signed-in user's saved set.
  final bool isBookmarked;

  /// Whether the signed-in user has already applied. When true the card shows
  /// a compact "Applied" indicator.
  final bool isApplied;

  /// Optional bookmark toggle.
  final FutureOr<void> Function()? onToggleBookmark;

  /// Optional quick apply callback.
  final VoidCallback? onQuickApply;
  final GlobalKey? viewDetailsKey;
  final GlobalKey? cardGuideKey;

  int _effectiveMatchPercentage() {
    if (matchPercentage != null) return matchPercentage!;
    return placeholderMatchPercentage(reasons.length);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expired = isDeadlinePassed(scholarship.deadline, now: now);
    final closing =
        !expired && isClosingSoon(scholarship.deadline.difference(now).inDays);
    final readiness = evaluateApplicationReadiness(
      profile: studentProfile,
      scholarship: scholarship,
      referenceNow: now,
    );
    // shortcut: legacy demo cutoff only gates quick apply; review it with action eligibility.
    final rawMatchPct = _effectiveMatchPercentage();
    final matchPct =
        readiness.state == ApplicationReadinessState.notEligible &&
            rawMatchPct > 69
        ? 69
        : rawMatchPct;
    final amount = formatScholarshipAmount(scholarship);
    final benefit = formatScholarshipBenefit(scholarship);
    final requirements = formatScholarshipRequirements(scholarship);
    final canShowApply = matchPct >= 90 && !isApplied && readiness.canApply;

    // Curate criteria chips: keep essential qualifications on 1 clean row (anti-slop)
    final criteriaChips = <String>[];
    if (scholarship.requiredCourses != null &&
        scholarship.requiredCourses!.isNotEmpty) {
      criteriaChips.add(scholarship.requiredCourses!.first);
    }
    if (scholarship.minGpa > 0) {
      criteriaChips.add('GPA ${scholarship.minGpa.toStringAsFixed(1)}+');
    }
    if (criteriaChips.isEmpty) {
      if (scholarship.maxMonthlyIncome != null) {
        criteriaChips.add('Need-Based');
      } else {
        criteriaChips.add('Merit-Based');
      }
    }

    return Semantics(
      key: cardGuideKey,
      button: true,
      label: 'View ${scholarship.title}',
      child: PressableScale(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kRadiusCard),
          child: InkWell(
            borderRadius: BorderRadius.circular(kRadiusCard),
            onTap: () => context.push(
              '/scholarship/${scholarship.id}',
              extra: scholarship,
            ),
            child: Container(
              decoration: kSoftCardDecoration,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Top Badges & Bookmark Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    switch (readiness.state) {
                                      ApplicationReadinessState.eligible =>
                                        'Profile match',
                                      ApplicationReadinessState.notEligible =>
                                        'Review criteria',
                                      ApplicationReadinessState
                                          .profileIncomplete =>
                                        'Check eligibility',
                                      ApplicationReadinessState.closed =>
                                        'Review details',
                                      ApplicationReadinessState.inactive =>
                                        'Unavailable',
                                    },
                                    style: AppTypography.style(
                                      AppTextRole.badge,
                                      fontSize: 12,
                                      color: kTextSupporting,
                                      height: 1.4,
                                      letterSpacing: 0,
                                    ),
                                  ),

                                  // Keep the application status with its deadline when badges wrap.
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      _DeadlineChip(
                                        label: deadlineLabel(
                                          scholarship.deadline,
                                        ),
                                        urgent: closing,
                                        expired: expired,
                                      ),
                                      if (isApplied) const _AppliedChip(),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            if (onToggleBookmark != null) ...[
                              const SizedBox(width: 36),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Keep the award beside the title only when both can breathe.
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final sideBySide =
                                constraints.maxWidth >= 420 &&
                                MediaQuery.textScalerOf(context).scale(12) <=
                                    14;
                            final heading = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  scholarship.title,
                                  style: AppTypography.style(
                                    AppTextRole.cardTitle,
                                    fontSize: 15,
                                    height: 1.3,
                                    color: kTextPrimary,
                                    letterSpacing: -.15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_outlined,
                                      size: 15,
                                      color: providerTypeColor(
                                        scholarship.provider,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        scholarship.provider ??
                                            'Scholarship Provider',
                                        style: AppTypography.style(
                                          AppTextRole.label,
                                          fontSize: 13,
                                          height: 1.45,
                                          color: kTextSecondary,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                            final amountText = Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: amount),
                                  TextSpan(
                                    text:
                                        ' ${scholarship.formattedFrequency.replaceFirst('/ ', '/\u00a0')}',
                                    style: AppTypography.style(
                                      AppTextRole.caption,
                                      fontSize: 12,
                                      height: 1.4,
                                      color: kTextSupporting,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                              style: AppTypography.style(
                                AppTextRole.metric,
                                fontSize: 18,
                                height: 1.2,
                                color: kPrimary,
                                letterSpacing: -.3,
                              ),
                            );
                            final award = sideBySide
                                ? amountText
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.school_outlined,
                                        size: 17,
                                        color: Color(0xFF657168),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(child: amountText),
                                    ],
                                  );
                            if (sideBySide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: heading),
                                  const SizedBox(width: 14),
                                  Flexible(child: award),
                                ],
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                heading,
                                const SizedBox(height: 8),
                                award,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: kScholarshipTagBackground,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                benefit.text,
                                style: AppTypography.style(
                                  AppTextRole.badge,
                                  fontSize: 12,
                                  height: 1.3,
                                  color: kScholarshipTagForeground,
                                  letterSpacing: -.1,
                                ),
                              ),
                            ),
                            ...criteriaChips.map((c) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: kScholarshipTagBackground,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  c,
                                  style: AppTypography.style(
                                    AppTextRole.badge,
                                    fontSize: 12,
                                    height: 1.3,
                                    color: kScholarshipTagForeground,
                                    letterSpacing: -.1,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              requirements.icon,
                              size: 14,
                              color: const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                requirements.text,
                                style: AppTypography.style(
                                  AppTextRole.body,
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                  height: 1.4,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final details = PressableScale(
                              child: TextButton(
                                key: viewDetailsKey,
                                onPressed: () => context.push(
                                  '/scholarship/${scholarship.id}',
                                  extra: scholarship,
                                ),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(44, 44),
                                  backgroundColor: const Color(0xFFF4F6F8),
                                  foregroundColor: kTextPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'View Details',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.style(
                                    AppTextRole.button,
                                    fontSize: 13,
                                    height: 1.4,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            );
                            final apply = PressableScale(
                              child: ElevatedButton(
                                onPressed:
                                    onQuickApply ??
                                    () => context.push(
                                      '/scholarship/${scholarship.id}?apply=1',
                                      extra: scholarship,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(44, 44),
                                  backgroundColor: kPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Apply Now',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.style(
                                          AppTextRole.button,
                                          fontSize: 13,
                                          color: Colors.white,
                                          height: 1.4,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 15,
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (!canShowApply) {
                              return SizedBox(
                                width: double.infinity,
                                child: details,
                              );
                            }
                            if (constraints.maxWidth < 260 ||
                                MediaQuery.textScalerOf(context).scale(14) >
                                    18) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  details,
                                  const SizedBox(height: 8),
                                  apply,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: details),
                                const SizedBox(width: 8),
                                Expanded(child: apply),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Keep a full touch target without making the badge row taller.
                  if (onToggleBookmark != null)
                    Positioned(
                      top: 0,
                      right: 8,
                      child: _BookmarkButton(
                        isBookmarked: isBookmarked,
                        onToggleBookmark: onToggleBookmark!,
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
}

class _BookmarkButton extends StatefulWidget {
  const _BookmarkButton({
    required this.isBookmarked,
    required this.onToggleBookmark,
  });

  final bool isBookmarked;
  final FutureOr<void> Function() onToggleBookmark;

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton>
    with SingleTickerProviderStateMixin {
  bool? _pendingBookmark;
  late final AnimationController _burstController;
  late final Animation<double> _burstScale;

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _burstScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 60,
      ),
    ]).animate(_burstController);
  }

  @override
  void didUpdateWidget(covariant _BookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear pending state once the parent confirms the new bookmark status.
    if (_pendingBookmark != null && widget.isBookmarked == _pendingBookmark) {
      setState(() => _pendingBookmark = null);
    }
  }

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_pendingBookmark != null) return;
    HapticFeedback.lightImpact();
    final willBookmark = !widget.isBookmarked;
    setState(() => _pendingBookmark = willBookmark);
    if (willBookmark) {
      _burstController.forward(from: 0);
    } else {
      _burstController.reset();
    }

    try {
      await widget.onToggleBookmark();
      // If widget already reflects the new status, clear pending immediately.
      if (mounted && widget.isBookmarked == willBookmark) {
        setState(() => _pendingBookmark = null);
      }
    } on Exception {
      if (mounted) {
        _burstController.reset();
        setState(() => _pendingBookmark = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update saved scholarships. Please try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFilled = _pendingBookmark ?? widget.isBookmarked;
    final showBurst = _burstController.isAnimating && showFilled;

    Widget icon;
    if (showBurst) {
      icon = ScaleTransition(
        scale: _burstScale,
        child: const Icon(
          Icons.bookmark_rounded,
          size: 20,
          color: kAccent,
        ),
      );
    } else {
      icon = Icon(
        showFilled ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        size: 20,
        color: showFilled ? kAccent : const Color(0xFF436084),
      );
    }

    return IconButton(
      tooltip: showFilled ? 'Remove from saved' : 'Save this scholarship',
      onPressed: _handleTap,
      icon: icon,
      padding: const EdgeInsets.all(8),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        fixedSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _DeadlineChip extends StatelessWidget {
  const _DeadlineChip({
    required this.label,
    required this.urgent,
    required this.expired,
  });

  final String label;
  final bool urgent;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;

    if (expired) {
      bg = const Color(0xFFE2E8E5);
      fg = const Color(0xFF707971);
      icon = Icons.block_rounded;
    } else if (urgent) {
      bg = const Color(0xFFFFF0EE);
      fg = const Color(0xFFC62828);
      icon = Icons.hourglass_top_rounded;
    } else {
      bg = const Color(0xFFEDF1F5);
      fg = const Color(0xFF344E6B);
      icon = Icons.event_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: urgent ? const Color(0xFFE8B9B3) : const Color(0xFFCDD5DF),
          width: 0.75,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 3.5),
          Flexible(
            child: Text(
              label,
              style: AppTypography.style(
                AppTextRole.label,
                fontSize: 12,
                letterSpacing: -.15,
                color: fg,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppliedChip extends StatelessWidget {
  const _AppliedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFD7F0DF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFB9D8C5), width: .75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 14, color: kPrimary),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              'Applied',
              style: AppTypography.style(
                AppTextRole.badge,
                fontSize: 12,
                letterSpacing: -.15,
                color: const Color(0xFF345B40),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
