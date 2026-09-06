// lib/shared/widgets/scholarship_card.dart
//
// The standard Scholaris scholarship card. Used by the personalized matches
// list and the full catalog. The card leads with the value (amount) and
// deadline urgency, surfaces match-reason chips under a "Why this matches you"
// header on matched cards, and offers a quick bookmark toggle.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../features/scholarships/models/scholarship.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadiusCard),
              boxShadow: const [
                BoxShadow(
                  color: kPrimarySoft,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
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
  bool _playing = false;

  @override
  void didUpdateWidget(covariant _BookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If upstream state changed underneath us, reset local visual state.
    if (widget.isBookmarked != oldWidget.isBookmarked) {
      _locallyBookmarked = widget.isBookmarked;
      _playing = false;
    }
  }

  void _handleTap() {
    // When already bookmarked, un-bookmark with instant icon swap.
    if (widget.isBookmarked || _locallyBookmarked) {
      setState(() {
        _locallyBookmarked = false;
        _playing = false;
      });
      widget.onToggleBookmark();
      return;
    }

    // Not bookmarked: play burst animation, then settle to filled icon.
    setState(() {
      _playing = true;
      _locallyBookmarked = true;
    });
    widget.onToggleBookmark();
  }

  @override
  Widget build(BuildContext context) {
    final showFilled = widget.isBookmarked || _locallyBookmarked;

    Widget icon;
    if (_playing) {
      icon = SizedBox(
        width: 20,
        height: 20,
        child: Lottie.asset(
          'assets/animations/bookmark_burst.json',
          fit: BoxFit.contain,
          repeat: false,
          onLoaded: (composition) {
            // Play exactly once; when complete, drop back to static icon.
            // Lottie calls the status listener when the animation ends, but
            // to avoid depending on controller internals here we simply let
            // the composition finish and then clear _playing on the next
            // frame by relying on didUpdateWidget / rebuilds after the
            // callback from parent state update.
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
        color: kPrimarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 13, color: kPrimary),
          const SizedBox(width: 3),
          Text(
            'Applied',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kPrimary,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kPrimarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 14, color: kPrimary),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
