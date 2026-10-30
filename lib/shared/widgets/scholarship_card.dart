// lib/shared/widgets/scholarship_card.dart
//
// The standard Scholaris scholarship card rebuilt to 100% Stitch V2 specification
// (`scholaris_student_dashboard/code.html` and `scholaris_discover_filters/code.html`).
//
// Card anatomy:
// 1. Top row: Match % badge (e.g. "98% Match" with star) + Urgency countdown pill
//    (e.g. "5 days left" with hourglass) + Bookmark button
// 2. Title in Outfit bold
// 3. Verified provider row with verified_user emblem
// 4. Bold grant amount in ₱ with frequency/renewal subtitle
// 5. Criteria chips (degree, need-based, year level, etc.)
// 6. Quick Apply primary CTA button

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
  final text = s.coverage.trim().isNotEmpty ? s.coverage : 'Tuition + Allowance';
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
  final VoidCallback? onToggleBookmark;

  /// Optional quick apply callback.
  final VoidCallback? onQuickApply;
  final GlobalKey? viewDetailsKey;

  int _effectiveMatchPercentage() {
    if (matchPercentage != null) return matchPercentage!;
    return placeholderMatchPercentage(reasons.length);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expired = isDeadlinePassed(scholarship.deadline, now: now);
    final closing = !expired &&
        isClosingSoon(scholarship.deadline.difference(now).inDays);
    final readiness = evaluateApplicationReadiness(
      profile: studentProfile, scholarship: scholarship, referenceNow: now,
    );
    // Placeholder score only; replace with a real scoring model when available.
    final rawMatchPct = _effectiveMatchPercentage();
    final matchPct = readiness.state == ApplicationReadinessState.notEligible && rawMatchPct > 69
        ? 69 : rawMatchPct;
    final amount = formatScholarshipAmount(scholarship);
    final benefit = formatScholarshipBenefit(scholarship);
    final requirements = formatScholarshipRequirements(scholarship);
    final canShowApply = matchPct >= 90 && !isApplied && readiness.canApply;

    // Collect criteria chips
    final criteriaChips = <String>[];
    if (scholarship.requiredCourses != null && scholarship.requiredCourses!.isNotEmpty) {
      criteriaChips.addAll(scholarship.requiredCourses!.take(2));
    } else {
      criteriaChips.add('All Majors');
    }
    if (scholarship.minGpa > 0) {
      criteriaChips.add('GPA ${scholarship.minGpa.toStringAsFixed(1)}+');
    }
    if (scholarship.maxMonthlyIncome != null) {
      criteriaChips.add('Need-Based');
    } else {
      criteriaChips.add('Merit-Based');
    }
    if (scholarship.requiredYearLevels != null && scholarship.requiredYearLevels!.isNotEmpty) {
      criteriaChips.add('College');
    }

    return Semantics(
      button: true,
      label: 'View ${scholarship.title}',
      child: PressableScale(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => context.push(
              '/scholarship/${scholarship.id}',
              extra: scholarship,
            ),
            child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0x0A161C27), width: .5),
              boxShadow: const [BoxShadow(color: Color(0x050F172A), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                                // Fit leads the metadata hierarchy; Applied remains a quiet confirmation.
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: matchPct >= 90
                                        ? const Color(0xFFCBEDD5) // Clear match emphasis
                                        : const Color(0xFFF0F2F0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: matchPct >= 90
                                              ? kPrimary
                                              : const Color(0xFF436084), // kSecondary
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4.5),
                                      Flexible(child: Text(
                                        '$matchPct% Fit',
                                        style: outfit(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: matchPct >= 90
                                              ? kPrimary
                                              : const Color(0xFF404942),
                                        ),
                                      )),
                                    ],
                                  ),
                                ),

                                // Keep the application status with its deadline when badges wrap.
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _DeadlineChip(
                                      label: deadlineLabel(scholarship.deadline),
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
                      const SizedBox(height: 10),

                      // Keep the award beside the title only when both can breathe.
                      LayoutBuilder(builder: (context, constraints) {
                        final sideBySide = constraints.maxWidth >= 420 &&
                            MediaQuery.textScalerOf(context).scale(12) <= 14;
                        final heading = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(scholarship.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: outfit(fontSize: 16, fontWeight: FontWeight.w700,
                                color: const Color(0xFF161C27), letterSpacing: -0.25, height: 1.25)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.account_balance_outlined, size: 15, color: providerTypeColor(scholarship.provider)),
                              const SizedBox(width: 5),
                              Expanded(child: Text(scholarship.provider ?? 'Scholarship Provider',
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: openSans(fontSize: 14, height: 1.4, color: const Color(0xFF4E5C53), fontWeight: FontWeight.w600))),
                            ]),
                          ],
                        );
                        final amountText = Text(amount, style: outfit(fontSize: 18, fontWeight: FontWeight.w700,
                          color: kPrimary, letterSpacing: -0.4));
                        final frequencyText = Text(scholarship.formattedFrequency, style: openSans(fontSize: 12.5,
                          color: const Color(0xFF4E5C53), fontWeight: FontWeight.w600));
                        final award = sideBySide
                            ? Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min,
                                children: [amountText, frequencyText])
                            : Wrap(spacing: 6, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center,
                                children: [const Icon(Icons.school_outlined, size: 17, color: Color(0xFF657168)), amountText, frequencyText]);
                        if (sideBySide) {
                          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: heading),
                            const SizedBox(width: 14),
                            Flexible(child: award),
                          ]);
                        }
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          heading,
                          const SizedBox(height: 10),
                          award,
                        ]);
                      }),
                      const SizedBox(height: 10),
                      Wrap(spacing: 5, runSpacing: 5, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: kScholarshipTagBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(benefit.text, style: outfit(fontSize: 11, fontWeight: FontWeight.w600,
                            color: kScholarshipTagForeground)),
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
                              style: outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kScholarshipTagForeground,
                              ),
                            ),
                          );
                        }),
                      ]),
                      const SizedBox(height: 8),

                      Row(children: [
                        Icon(requirements.icon, size: 15, color: const Color(0xFF404942)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(requirements.text, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: openSans(fontSize: 13, height: 1.45, fontWeight: FontWeight.w600, color: const Color(0xFF4E5C53)))),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: PressableScale(
                          child: SizedBox(key: viewDetailsKey, height: 44, child: TextButton(
                            onPressed: () => context.push(
                              '/scholarship/${scholarship.id}',
                              extra: scholarship,
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF4F6F8),
                              foregroundColor: const Color(0xFF161C27),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'View Details',
                              style: outfit(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          )),
                        )),
                        if (canShowApply) ...[
                          const SizedBox(width: 8),
                          Expanded(child: PressableScale(child: SizedBox(height: 44, child: ElevatedButton(
                            onPressed: onQuickApply ?? () => context.push('/scholarship/${scholarship.id}?apply=1', extra: scholarship),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F4D2E), foregroundColor: Colors.white,
                              elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: FittedBox(child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('Apply Now', style: outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 15),
                            ])),
                          )))),
                        ],
                      ]),
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
  final VoidCallback onToggleBookmark;

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton>
    with SingleTickerProviderStateMixin {
  bool _locallyBookmarked = false;
  bool _animating = false;
  late final AnimationController _burstController;
  late final Animation<double> _burstScale;
  late final Animation<Color?> _burstColor;

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _burstScale = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 1),
      ],
    ).animate(CurvedAnimation(parent: _burstController, curve: Curves.elasticOut));
    _burstColor = ColorTween(begin: kPrimary, end: kAccent).animate(_burstController);
  }

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _BookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBookmarked != oldWidget.isBookmarked) {
      _locallyBookmarked = widget.isBookmarked;
      if (!_animating && !_burstController.isAnimating) {
        _burstController.reset();
      }
    }
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    final willBookmark = !(widget.isBookmarked || _locallyBookmarked);

    if (willBookmark) {
      setState(() {
        _locallyBookmarked = true;
        _animating = true;
      });
      _burstController.forward(from: 0);
    } else {
      setState(() {
        _locallyBookmarked = false;
      });
    }

    try {
      widget.onToggleBookmark();
    } on Exception {
      setState(() {
        _locallyBookmarked = !willBookmark;
      });
      if (willBookmark) {
        _animating = false;
        _burstController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFilled = widget.isBookmarked || _locallyBookmarked;
    final showBurst = _animating && _burstController.isAnimating && showFilled;

    Widget icon;
    if (showBurst) {
      icon = ScaleTransition(
        scale: _burstScale,
        child: AnimatedBuilder(
          animation: _burstColor,
          builder: (context, child) {
            return Icon(
              Icons.bookmark_rounded,
              size: 20,
              color: _burstColor.value ?? kAccent,
            );
          },
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
      bg = const Color(0xFFF4F6F8);
      fg = const Color(0xFF436084);
      icon = Icons.event_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: urgent ? const Color(0x33FF6F59) : const Color(0x0A161C27), width: 0.75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 3.5),
          Flexible(child: Text(
            label,
            style: outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          )),
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
        border: Border.all(color: const Color(0x0A161C27), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: kPrimary,
          ),
          const SizedBox(width: 3),
          Flexible(child: Text(
            'Applied',
            style: outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF345B40),
            ),
          )),
        ],
      ),
    );
  }
}
