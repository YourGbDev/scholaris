// lib/shared/widgets/scholarship_card.dart
//
// The standard Scholaris scholarship card. Used by the personalized matches
// list and the full catalog. The card leads with the value (amount) and
// deadline urgency, surfaces match-reason chips under a "Why this matches you"
// header on matched cards, and offers a quick bookmark toggle.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Government agencies: CHED, DOST, TESDA, Department, Commission, Ministry,
  // City Government, Council, National, Regional, BARMM, etc.
  return kNavyTrust;
}

class ScholarshipCard extends StatelessWidget {
  const ScholarshipCard({
    super.key,
    required this.scholarship,
    this.reasons = const [],
    this.isBookmarked = false,
    this.isApplied = false,
    this.onToggleBookmark,
  });

  final Scholarship scholarship;
  final List<String> reasons;

  /// Whether this scholarship is in the signed-in user's saved set.
  final bool isBookmarked;

  /// Whether the signed-in user has already applied. When true the card shows
  /// a compact "Applied" indicator. Optional — existing cards are unchanged.
  final bool isApplied;

  /// Optional bookmark toggle. When null the card renders without a bookmark
  /// button (e.g. embed contexts that handle saving elsewhere).
  final VoidCallback? onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expired = isDeadlinePassed(scholarship.deadline, now: now);
    // Expired deadlines must never be styled as urgent: the old `days <= 14`
    // check also fired for negative day counts, labelling closed scholarships
    // "closing soon".
    final closing = !expired &&
        isClosingSoon(scholarship.deadline.difference(now).inDays);
    final accentColor = providerTypeColor(scholarship.provider);

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
              borderRadius: BorderRadius.circular(kRadiusCard),
              // Shared neutral warm shadow (kCardShadow) — the one shadow
              // language across all Scholaris elevated surfaces.
              boxShadow: const [
                BoxShadow(
                  color: kCardShadow,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
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
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              scholarship.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: poppins(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _DeadlineChip(
                            label: deadlineLabel(scholarship.deadline),
                            urgent: closing,
                            expired: expired,
                          ),
                          if (isApplied) ...[
                            const SizedBox(width: 4),
                            const _AppliedChip(),
                          ],
                          if (onToggleBookmark != null) ...[
                            const SizedBox(width: 4),
                            _BookmarkButton(
                              isBookmarked: isBookmarked,
                              onToggleBookmark: onToggleBookmark!,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scholarship.provider ?? 'Scholarship provider',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: openSans(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      if (scholarship.slots != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${scholarship.slots} slots available',
                              style: openSans(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (reasons.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Why this matches you',
                          style: poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: reasons
                              .map((r) => _ReasonChip(label: r))
                              .toList(),
                        ),
                      ],
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
        color: showFilled ? kAccent : kPrimary,
      );
    }

    return IconButton(
      tooltip: showFilled ? 'Remove from saved' : 'Save this scholarship',
      onPressed: _handleTap,
      icon: icon,
      padding: const EdgeInsets.all(10),
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
    this.expired = false,
  });

  final String label;
  final bool urgent;

  /// An expired deadline renders neutral (never urgent): its label is
  /// "Closed" and it must not read as an active deadline.
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final background = expired
        ? const Color(0xFFECECE6)
        : urgent
            ? const Color(0xFFFFF3D6)
            : const Color(0xFFE8F2EC);
    final foreground = expired
        ? Colors.black54
        : urgent
            ? const Color(0xFF8A5B00)
            : kPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class _AppliedChip extends StatelessWidget {
  const _AppliedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: kMatchGoldSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kMatchGoldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 13, color: kAccent),
          const SizedBox(width: 3),
          Text(
            'Applied',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kMatchGoldText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kMatchGoldSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kMatchGoldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 14, color: kAccent),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kMatchGoldText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
