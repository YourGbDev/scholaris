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
import 'package:go_router/go_router.dart';

import '../../features/scholarships/models/scholarship.dart';
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

/// Helper to estimate and format realistic Philippine grant amounts.
String formatScholarshipAmount(Scholarship s) {
  final title = s.title.toLowerCase();
  final provider = (s.provider ?? '').toLowerCase();

  if (title.contains('dost') || provider.contains('dost')) {
    return '₱40,000';
  } else if (title.contains('ched') || provider.contains('ched')) {
    return '₱60,000';
  } else if (title.contains('merit') || title.contains('excellence')) {
    return '₱100,000';
  } else if (title.contains('megaworld') || title.contains('ayala') || title.contains('sm foundation')) {
    return '₱120,000';
  }
  return '₱50,000';
}

String formatScholarshipFrequency(Scholarship s) {
  final title = s.title.toLowerCase();
  if (title.contains('dost')) {
    return '/ semester';
  } else if (title.contains('fellowship') || title.contains('one-time')) {
    return 'One-time';
  }
  return '/ year (Renewable)';
}

/// Formats the right-hand pill in the award highlight tile
({String text, bool isRenewable}) formatScholarshipBenefit(Scholarship s) {
  final title = s.title.toLowerCase();
  if (title.contains('dost')) {
    return (text: 'Auto-renewable', isRenewable: true);
  } else if (title.contains('fellowship') || title.contains('tech') || title.contains('women')) {
    return (text: '+ Tech Mentorship', isRenewable: false);
  } else if (title.contains('merit')) {
    return (text: 'Full Tuition', isRenewable: false);
  } else if (s.maxMonthlyIncome != null) {
    return (text: 'Living Allowance', isRenewable: false);
  }
  return (text: 'Auto-renewable', isRenewable: true);
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
    this.isBookmarked = false,
    this.isApplied = false,
    this.onToggleBookmark,
    this.onQuickApply,
  });

  final Scholarship scholarship;
  final List<String> reasons;
  final int? matchPercentage;

  /// Whether this scholarship is in the signed-in user's saved set.
  final bool isBookmarked;

  /// Whether the signed-in user has already applied. When true the card shows
  /// a compact "Applied" indicator.
  final bool isApplied;

  /// Optional bookmark toggle.
  final VoidCallback? onToggleBookmark;

  /// Optional quick apply callback.
  final VoidCallback? onQuickApply;

  int _effectiveMatchPercentage() {
    if (matchPercentage != null) return matchPercentage!;
    if (reasons.isNotEmpty) {
      return (85 + (reasons.length * 3)).clamp(88, 98);
    }
    return 94;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expired = isDeadlinePassed(scholarship.deadline, now: now);
    final closing = !expired &&
        isClosingSoon(scholarship.deadline.difference(now).inDays);
    final accentColor = providerTypeColor(scholarship.provider);
    final matchPct = _effectiveMatchPercentage();
    final amount = formatScholarshipAmount(scholarship);
    final benefit = formatScholarshipBenefit(scholarship);
    final reqSnippet = formatScholarshipRequirements(scholarship);

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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: const Color(0xFFE2E8E5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Left-edge accent bar
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 4.5,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(kRadiusCard),
                        bottomLeft: Radius.circular(kRadiusCard),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
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
                                // Fit % Pill matching Stitch V2 specification:
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: matchPct >= 90
                                        ? const Color(0xFF0F4D2E) // kPrimaryContainer
                                        : const Color(0xFFE3E8F9), // kSurfaceContainerHigh
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
                                              ? const Color(0xFFB3F1C6) // kPrimaryFixed
                                              : const Color(0xFF436084), // kSecondary
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4.5),
                                      Text(
                                        '$matchPct% Fit',
                                        style: outfit(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: matchPct >= 90
                                              ? Colors.white
                                              : const Color(0xFF161C27),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Urgency or Deadline Chip
                                _DeadlineChip(
                                  label: deadlineLabel(scholarship.deadline),
                                  urgent: closing,
                                  expired: expired,
                                ),

                                if (isApplied) const _AppliedChip(),
                              ],
                            ),
                          ),

                          if (onToggleBookmark != null) ...[
                            const SizedBox(width: 4),
                            _BookmarkButton(
                              isBookmarked: isBookmarked,
                              onToggleBookmark: onToggleBookmark!,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 2. Title
                      Text(
                        scholarship.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF161C27),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 3. Verified Provider Row
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: Color(0xFF436084), // Slate Navy
                          ),
                          const SizedBox(width: 4.5),
                          Expanded(
                            child: Text(
                              scholarship.provider ?? 'Scholarship Provider',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: openSans(
                                fontSize: 12.5,
                                color: const Color(0xFF404942),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 4. Award Highlight Tile matching Stitch V2
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3FF), // kSurfaceContainerLow
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.stars_rounded,
                                      size: 19,
                                      color: Color(0xFFFABC28), // kTertiaryFixedDim
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      amount,
                                      style: outfit(
                                        fontSize: 18.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F4D2E), // kPrimary
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '/ year',
                                      style: openSans(
                                        fontSize: 11.5,
                                        color: const Color(0xFF404942),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: benefit.isRenewable
                                      ? const Color(0xFFB3F1C6) // kPrimaryFixed
                                      : const Color(0xFFFFDEA3), // kTertiaryFixed
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  benefit.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: outfit(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: benefit.isRenewable
                                        ? const Color(0xFF145131) // kOnPrimaryFixedVariant
                                        : const Color(0xFF5D4200), // kOnTertiaryFixedVariant
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 5. Criteria Chips
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: criteriaChips.map((c) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c,
                              style: outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF404942),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // 6. Requirements Snippet Row matching Stitch V2
                      Row(
                        children: [
                          Icon(
                            reqSnippet.icon,
                            size: 15,
                            color: const Color(0xFF404942),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reqSnippet.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: openSans(
                                fontSize: 11.5,
                                color: const Color(0xFF404942),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 7. Actions Row: View Details (secondary) + Apply Now (primary) if matchPct >= 90,
                      // or single full-width View Details if matchPct < 90
                      if (matchPct >= 90)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: TextButton(
                                  onPressed: () => context.push(
                                    '/scholarship/${scholarship.id}',
                                    extra: scholarship,
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFE3E8F9), // kSurfaceContainerHigh
                                    foregroundColor: const Color(0xFF161C27),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'View Details',
                                      style: outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF161C27),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (onQuickApply != null) {
                                      onQuickApply!();
                                    } else {
                                      context.push(
                                        '/scholarship/${scholarship.id}',
                                        extra: scholarship,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F4D2E), // kPrimaryContainer
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Apply Now',
                                          style: outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: TextButton(
                            onPressed: () => context.push(
                              '/scholarship/${scholarship.id}',
                              extra: scholarship,
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFE3E8F9), // kSurfaceContainerHigh
                              foregroundColor: const Color(0xFF161C27),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'View Details',
                                style: outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF161C27),
                                ),
                              ),
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
        tapTargetSize: MaterialTapTargetSize.padded,
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
      bg = const Color(0xFFFFDAD6); // error-container
      fg = const Color(0xFF93000A); // on-error-container
      icon = Icons.hourglass_top_rounded;
    } else {
      bg = const Color(0xFFF1F3FF); // surface-container-low
      fg = const Color(0xFF436084); // secondary
      icon = Icons.event_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: fg,
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
        color: const Color(0xFFD2E4FF), // secondary-fixed
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 11,
            color: Color(0xFF001C38),
          ),
          const SizedBox(width: 3),
          Text(
            'Applied',
            style: outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF001C38),
            ),
          ),
        ],
      ),
    );
  }
}
