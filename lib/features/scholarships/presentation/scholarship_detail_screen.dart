// lib/features/scholarships/presentation/scholarship_detail_screen.dart
//
// Full scholarship details. Receives the scholarship via route extra when
// possible (from a card), otherwise falls back to loading it by id.
// The bookmark toggle in the app bar keeps the Saved tab in sync. When the
// signed-in student's profile makes this scholarship an actual match, a
// "Why this matches you" section restates the reasons they saw on the card.
// The Apply action is gated by the pure application-readiness evaluation:
// only an eligible student with an active, open scholarship gets an enabled
// Apply button, and confirming the dialog is what sends the write through the
// existing applications provider; once applied, the button is replaced by an
// "Application submitted" banner.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/services/application_readiness.dart';
import 'package:scholaris/features/scholarships/services/match_reasons.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/utils/constants.dart';
import 'package:scholaris/shared/widgets/primary_button.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

class ScholarshipDetailScreen extends ConsumerStatefulWidget {
  const ScholarshipDetailScreen({
    super.key,
    required this.scholarshipId,
    this.initial,
  });

  final String scholarshipId;
  final Scholarship? initial;

  @override
  ConsumerState<ScholarshipDetailScreen> createState() =>
      _ScholarshipDetailScreenState();
}

class _ScholarshipDetailScreenState
    extends ConsumerState<ScholarshipDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final bookmarkIds = bookmarksAsync.valueOrNull ?? const <String>{};
    final saved = bookmarkIds.contains(widget.scholarshipId);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Scholarship'),
        actions: [
          IconButton(
            tooltip: saved ? 'Remove from saved' : 'Save this scholarship',
            onPressed: saved
                ? _unbookmark
                : _bookmark,
            icon: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: saved ? kAccent : kPrimary,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ResponsiveContainer(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final initial = widget.initial;
    if (initial != null) return _DetailContent(scholarship: initial);

    return ref.watch(scholarshipByIdProvider(widget.scholarshipId)).when(
          loading: () => const LoadingView(),
          error: (_, _) => ErrorView(
            message: 'We could not load this scholarship.',
            onRetry: () =>
                ref.invalidate(scholarshipByIdProvider(widget.scholarshipId)),
          ),
          data: (scholarship) => scholarship == null
              ? const EmptyView(
                  icon: Icons.search_off_rounded,
                  title: 'Scholarship not found',
                  message: 'This scholarship may no longer be active.',
                )
              : _DetailContent(scholarship: scholarship),
        );
  }

  Future<void> _bookmark() async {
    final notifier = ref.read(bookmarksProvider.notifier);
    try {
      await notifier.toggle(widget.scholarshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to your list.')),
        );
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
    }
  }

  Future<void> _unbookmark() async {
    final notifier = ref.read(bookmarksProvider.notifier);
    try {
      await notifier.toggle(widget.scholarshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from your list.')),
        );
      }
    } on Exception {
      // Ignore transient failures on removal.
    }
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final expired = isDeadlinePassed(scholarship.deadline, now: now);
    // Expired deadlines must never be labelled "Closing soon" (the old
    // `days <= 14` check also fired for negative day counts).
    final closing = !expired &&
        isClosingSoon(scholarship.deadline.difference(now).inDays);
    final daysLeft = scholarship.deadline.difference(now).inDays;
    final reasons = _matchReasons(ref);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Text(
          scholarship.name,
          style: poppins(fontSize: 24, fontWeight: FontWeight.w700, color: kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          scholarship.provider ?? 'Scholarship provider',
          style: openSans(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        _AmountCard(scholarship: scholarship, closing: closing, daysLeft: daysLeft),
        const SizedBox(height: 16),
        _ApplySection(scholarship: scholarship),
        const SizedBox(height: 24),
        if (reasons.isNotEmpty) ...[
          _SectionLabel('Why this matches you'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: reasons.map((r) => _ReasonPill(label: r)).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (scholarship.description != null) ...[
          _SectionLabel('About'),
          const SizedBox(height: 8),
          Text(
            scholarship.description!,
            style: openSans(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
        ],
        _SectionLabel('Eligibility'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _EligibilityChip(icon: Icons.workspace_premium_outlined, label: 'Min GPA ${scholarship.minGpa.toStringAsFixed(2)}'),
            _EligibilityChip(
              icon: Icons.school_outlined,
              label: 'Year ${_yearLevelsLabel(scholarship.yearLevels)}',
            ),
            _EligibilityChip(
              icon: Icons.menu_book_outlined,
              label: scholarship.eligibleCourses.isEmpty
                  ? 'All courses'
                  : 'Selected courses',
            ),
            _EligibilityChip(
              icon: Icons.location_on_outlined,
              label: scholarship.regionsEligible.isEmpty
                  ? 'All regions'
                  : '${scholarship.regionsEligible.length} region(s)',
            ),
            _EligibilityChip(
              icon: Icons.account_balance_wallet_outlined,
              label: _incomeBracketLabel(scholarship.maxIncomeBracket),
            ),
            if (scholarship.isPwdPriority)
              _EligibilityChip(icon: Icons.accessible_rounded, label: 'PWD priority'),
            if (scholarship.isWorkingStudentPriority)
              _EligibilityChip(icon: Icons.work_outline_rounded, label: 'Working students'),
          ],
        ),
        if (scholarship.tags.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionLabel('Tags'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scholarship.tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kPrimarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(t, style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  /// Returns the "why this matches you" reasons only when the signed-in
  /// student's profile is genuinely ready (eligible per the readiness
  /// evaluation, which derives its verdict from the MatchingEngine's own
  /// criteria code), so the detail screen never implies a match the engine
  /// would not produce. Non-eligible students instead get the Apply section's
  /// "Why you can't apply" explanation.
  List<String> _matchReasons(WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final readiness = evaluateApplicationReadiness(
      profile: profile,
      scholarship: scholarship,
      referenceNow: DateTime.now(),
    );
    if (readiness.state != ApplicationReadinessState.eligible) {
      return const [];
    }
    return matchReasonsFor(profile!, scholarship);
  }

  String _yearLevelsLabel(List<int> levels) {
    if (levels.length == 5) return '1–5';
    if (levels.length == 1) return '${levels.first} only';
    return levels.map((l) => '$l').join(', ');
  }

  String _incomeBracketLabel(String bracket) {
    switch (bracket) {
      case 'low':
        return 'Income under ₱25k';
      case 'mid':
        return 'Income up to ₱70k';
      case 'high':
        return 'All income levels';
      default:
        return 'All income levels';
    }
  }
}

class _ApplySection extends ConsumerStatefulWidget {
  const _ApplySection({required this.scholarship});

  final Scholarship scholarship;

  @override
  ConsumerState<_ApplySection> createState() => _ApplySectionState();
}

class _ApplySectionState extends ConsumerState<_ApplySection> {
  /// True while an apply request is in flight, so the button renders a spinner
  /// and cannot be double-submitted.
  bool _isApplying = false;

  /// Pre-apply confirmation, following the withdrawal-confirmation convention.
  /// Confirming is what allows the application write to proceed; cancelling
  /// leaves the applications provider and repository untouched.
  Future<bool> _confirmApply() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apply to this scholarship?'),
        content: Text(
          'Confirming will create and submit your application for '
          '"${widget.scholarship.name}" in Scholaris. You can track it under '
          'My Applications.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('apply-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('apply-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// Confirmed apply path for an eligible, open scholarship.
  Future<void> _apply() async {
    if (_isApplying) return;
    final confirmed = await _confirmApply();
    if (!confirmed || !mounted) return;
    await _submit();
  }

  /// Signed-out path: preserves the existing sign-in-first behavior — no
  /// confirmation dialog, the submit attempt surfaces the sign-in requirement.
  Future<void> _applySignedOut() async {
    if (_isApplying) return;
    await _submit();
  }

  /// The only application write path: the existing applicationsProvider →
  /// ApplicationRepository chain. Readiness gating never bypasses it and the
  /// repository's duplicate/auth guards stay authoritative.
  Future<void> _submit() async {
    setState(() => _isApplying = true);
    try {
      await ref.read(applicationsProvider.notifier).apply(widget.scholarship.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted!')),
      );
    } on ApplicationNotAuthenticatedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to apply.')),
      );
    } on ApplicationDuplicateException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already applied to this scholarship.'),
        ),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit your application. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever the signed-in user's applications change so the applied
    // state is reflected as soon as the provider lands it.
    ref.watch(applicationsProvider);
    final applied =
        ref.read(applicationsProvider.notifier).hasApplied(widget.scholarship.id);

    if (applied) return const _AppliedBanner();

    final userId = ref.watch(currentUserIdProvider);
    final profileAsync =
        userId == null ? null : ref.watch(currentProfileProvider);
    // While the profile is still loading its readiness cannot be judged
    // honestly — hold the action until it lands instead of flashing a
    // misleading state.
    if (profileAsync != null && profileAsync.isLoading) {
      return const SizedBox.shrink();
    }
    final profile = profileAsync?.valueOrNull;
    final readiness = evaluateApplicationReadiness(
      profile: profile,
      scholarship: widget.scholarship,
      referenceNow: DateTime.now(),
    );

    switch (readiness.state) {
      case ApplicationReadinessState.eligible:
        return _applyButton(onPressed: _apply);

      case ApplicationReadinessState.closed:
        return const _ReadinessNotice(
          icon: Icons.event_busy_rounded,
          title: 'Applications closed',
          message:
              'The deadline for this scholarship has passed. You can no longer apply.',
        );

      case ApplicationReadinessState.inactive:
        return const _ReadinessNotice(
          icon: Icons.pause_circle_outline_rounded,
          title: 'Not accepting applications',
          message:
              'This scholarship is currently inactive. Explore other scholarships instead.',
        );

      case ApplicationReadinessState.notEligible:
        return _ReadinessNotice(
          icon: Icons.info_outline_rounded,
          title: "Why you can't apply",
          message:
              'Based on your profile, the requirements below are not met:',
          reasons: readiness.reasons,
        );

      case ApplicationReadinessState.profileIncomplete:
        if (userId == null) {
          // Signed out: preserve the existing safety flow — the Apply action
          // stays available and the sign-in requirement is surfaced on tap.
          return _applyButton(onPressed: _applySignedOut);
        }
        // Reuse the existing profile-setup route; no new navigation surface.
        return _ReadinessNotice(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Finish your profile to apply',
          message:
              'Your profile is incomplete, so we cannot check your eligibility yet.',
          actionLabel: 'Update profile',
          onAction: () => context.go('/profile-setup/personal'),
        );
    }
  }

  Widget _applyButton({required VoidCallback? onPressed}) {
    return Semantics(
      button: true,
      label: 'Apply to this scholarship',
      child: PrimaryButton(
        label: _isApplying ? 'Applying...' : 'Apply now',
        icon: Icons.send_rounded,
        loading: _isApplying,
        onPressed: _isApplying ? null : onPressed,
      ),
    );
  }
}

class _AppliedBanner extends StatelessWidget {
  const _AppliedBanner();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Application submitted',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kPrimarySoft,
          borderRadius: BorderRadius.circular(kRadiusInput),
          border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, size: 22, color: kPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application submitted',
                    style: poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You applied to this scholarship.',
                    style: openSans(fontSize: 13, color: Colors.black54),
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

/// The Apply section's unavailable/readiness state: explains why the Apply
/// action is not offered (closed, inactive, not eligible, profile incomplete)
/// without pretending a missing profile is an eligibility verdict.
class _ReadinessNotice extends StatelessWidget {
  const _ReadinessNotice({
    required this.icon,
    required this.title,
    required this.message,
    this.reasons = const [],
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Deterministic missing-criterion explanations (non-eligible state only).
  final List<String> reasons;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimarySoft,
        borderRadius: BorderRadius.circular(kRadiusInput),
        border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: kPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: openSans(fontSize: 13, color: Colors.black54),
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reasons.map((r) => _ReadinessReason(label: r)).toList(),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.edit_outlined),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single missing-criterion pill. Unlike the match-reason check pills, these
/// use a neutral marker — they explain a blocker, not a match.
class _ReadinessReason extends StatelessWidget {
  const _ReadinessReason({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove_circle_outline, size: 15, color: kPrimary),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonPill extends StatelessWidget {
  const _ReasonPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: kPrimarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 15, color: kPrimary),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
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

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.scholarship,
    required this.closing,
    required this.daysLeft,
  });

  final Scholarship scholarship;
  final bool closing;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, Color(0xFF1A6B42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Up to',
            style: GoogleFonts.openSans(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            formatPeso(scholarship.amount),
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _coverageLabel(scholarship.coverageType),
            style: GoogleFonts.openSans(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: closing ? kAccent : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 16,
                  color: closing ? const Color(0xFF8A5B00) : Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  closing
                      ? 'Closing soon — ${deadlineLabel(scholarship.deadline)}'
                      : deadlineLabel(scholarship.deadline),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: closing ? const Color(0xFF8A5B00) : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${scholarship.slotsAvailable ?? 'Unlimited'} slot(s) available',
            style: GoogleFonts.openSans(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String _coverageLabel(String? coverageType) {
    switch (coverageType) {
      case 'full':
        return 'Full coverage including tuition';
      case 'partial':
        return 'Partial coverage';
      case 'stipend':
        return 'Monthly stipend';
      default:
        return 'Scholarship award';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: poppins(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}

class _EligibilityChip extends StatelessWidget {
  const _EligibilityChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.openSans(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
