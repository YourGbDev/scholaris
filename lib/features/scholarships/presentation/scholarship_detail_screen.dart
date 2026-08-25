// lib/features/scholarships/presentation/scholarship_detail_screen.dart
//
// Full scholarship details. Receives the scholarship via route extra when
// possible (from a card), otherwise falls back to loading it by id.
// The bookmark toggle in the app bar keeps the Saved tab in sync.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/utils/constants.dart';
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
      body: _buildBody(context),
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

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context) {
    final daysLeft = scholarship.deadline.difference(DateTime.now()).inDays;
    final closing = isClosingSoon(daysLeft);

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
        const SizedBox(height: 24),
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
                  closing ? 'Closing soon — ${deadlineLabel(scholarship.deadline)}' : deadlineLabel(scholarship.deadline),
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
