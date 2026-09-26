// lib/features/applications/presentation/applications_screen.dart
//
// "Application Tracker" — the student's dedicated tracking surface rebuilt to 100%
// visual, structural, and literal fidelity against Stitch V2 specifications:
// - `scholaris_application_tracker/code.html`
// - `scholaris_no_applications_yet_tracker_initial_state/code.html`
//
// Features:
// - Top warm context header with "My Applications" eyebrow & "Application Tracker" title
// - Potential Award Metric Card with Bridge Green ambient gradient and active breakdown
// - Status Filter Bar with live per-status counts and horizontal scroll
// - Urgent Deadline Alert Banner when actions are pending before deadline
// - 4 distinct card variants (Under Review with stepper, Approved with celebration & next steps,
//   Draft with checklist & resume CTA, Submitted with verified receipt proof)
// - Bottom Admissions Momentum motivation card linking to Discover
// - Rich Empty State with halo graphic, 3-step educational roadmap, document prep tip,
//   and matched opportunity preview card.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/services/application_filters.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/utils/constants.dart';
import 'package:scholaris/shared/widgets/mascot_pose_view.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import 'application_detail_screen.dart';
import 'application_status_chip.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key, this.embedded = false});

  /// True when this screen is rendered as a Home tab body (no own Scaffold or
  /// AppBar); false when pushed as a standalone screen.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = _buildTrackingBody(context, ref);

    if (embedded) {
      return SafeArea(
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Applications',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Application Tracker',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: kOnSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Track deadlines, submission proofs, and award decisions.',
                            style: GoogleFonts.openSans(
                              fontSize: 12.5,
                              color: kOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: kSurfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        size: 22,
                        color: kPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Applications',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Application Tracker',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kOnSurface,
              ),
            ),
          ],
        ),
      ),
      body: ResponsiveContainer(child: body),
    );
  }

  Widget _buildTrackingBody(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);
    final scholarshipsAsync = ref.watch(scholarshipsProvider);
    final filteredAsync = ref.watch(filteredApplicationsProvider);

    return applicationsAsync.when(
      loading: () => const LoadingView(),
      error: (_, _) => ErrorView(
        message: 'Could not load your applications.',
        onRetry: () => ref.invalidate(applicationsProvider),
      ),
      data: (applications) {
        if (applications.isEmpty) {
          return const _EmptyApplicationsState();
        }

        final counts = ApplicationFilters.statusCounts(applications);
        final status = ref.watch(applicationFilterProvider).status;
        final filtered = filteredAsync.valueOrNull ?? const <Application>[];

        final allScholarships = scholarshipsAsync.valueOrNull ?? const <Scholarship>[];
        final byId = <String, Scholarship>{for (final s in allScholarships) s.id: s};

        // Calculate total potential value: sum of estimated scholarship grant values
        double totalPotential = 0;
        for (final app in applications) {
          final s = byId[app.scholarshipId];
          totalPotential += _scholarshipAmountValue(s);
        }

        // Check for urgent upcoming deadline (within 7 days)
        Application? urgentApp;
        Scholarship? urgentScholarship;
        for (final app in applications) {
          if (app.status == ApplicationStatus.draft ||
              app.status == ApplicationStatus.underReview ||
              app.status == ApplicationStatus.submitted) {
            final s = byId[app.scholarshipId];
            if (s != null) {
              final diff = s.deadline.difference(DateTime.now()).inDays;
              if (diff >= 0 && diff <= 7) {
                urgentApp = app;
                urgentScholarship = s;
                break;
              }
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              _PotentialAwardCard(
                totalPotential: totalPotential,
                applications: applications,
                counts: counts,
              ),
              const SizedBox(height: 10),
              _SummaryBar(applications: applications),
              const SizedBox(height: 10),
              _StatusFilterBar(
                counts: counts,
                selected: status,
                onSelect: (s) =>
                    ref.read(applicationFilterProvider.notifier).select(s),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filtered.isEmpty
                    ? _buildFilteredEmpty(context, ref, status)
                    : scholarshipsAsync.when(
                        loading: () => const LoadingView(),
                        error: (_, _) => ErrorView(
                          message: 'Could not load scholarship details.',
                          onRetry: () => ref.invalidate(scholarshipsProvider),
                        ),
                        data: (_) {
                          return ListView.builder(
                            // ignore: deprecated_member_use
                            cacheExtent: 1500.0,
                            padding: const EdgeInsets.only(bottom: 28),
                            itemCount: filtered.length +
                                (urgentApp != null ? 1 : 0) +
                                1, // +1 for Admissions Momentum
                            itemBuilder: (context, index) {
                              // If urgent banner exists, render it at index 0
                              if (urgentApp != null && urgentScholarship != null) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _UrgentDeadlineBanner(
                                      application: urgentApp,
                                      scholarship: urgentScholarship,
                                    ),
                                  );
                                }
                                index--;
                              }

                              // If reached the end of applications, render Admissions Momentum card
                              if (index == filtered.length) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 8, bottom: 16),
                                  child: _AdmissionsMomentumCard(),
                                );
                              }

                              final app = filtered[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ApplicationCard(
                                  application: app,
                                  scholarship: byId[app.scholarshipId],
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilteredEmpty(
    BuildContext context,
    WidgetRef ref,
    ApplicationStatus? status,
  ) {
    final label = status == null
        ? 'this status'
        : ApplicationStatusUi.of(status).label.toLowerCase();

    return Center(
      child: EmptyView(
        icon: Icons.filter_alt_off_rounded,
        title: 'No $label applications',
        message:
            'You have no applications with this status yet. Tap another '
            'status or show all applications to keep tracking.',
        actionLabel: 'Show all applications',
        onAction: () => ref.read(applicationFilterProvider.notifier).reset(),
      ),
    );
  }
}

/// Potential Award Metric Card with Soft Ambient Gradient matching Stitch design.
class _PotentialAwardCard extends StatelessWidget {
  const _PotentialAwardCard({
    required this.totalPotential,
    required this.applications,
    required this.counts,
  });

  final double totalPotential;
  final List<Application> applications;
  final Map<ApplicationStatus, int> counts;

  String _formatAmount(double amount) {
    final whole = amount.toInt();
    return whole.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = applications
        .where((a) =>
            a.status != ApplicationStatus.rejected &&
            a.status != ApplicationStatus.withdrawn)
        .length;

    final approvedCount = counts[ApplicationStatus.approved] ?? 0;
    final underReviewCount = counts[ApplicationStatus.underReview] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00351C), // Deep Bridge Green Primary
            Color(0xFF0F4D2E), // Primary Container
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F4D2E),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background geometric circle watermark
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.08,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TOTAL POTENTIAL AWARDS',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: const Color(0xFFB3F1C6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            text: '₱${_formatAmount(totalPotential)} ',
                            style: GoogleFonts.outfit(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'applied value',
                                style: GoogleFonts.openSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF98D4AB),
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFABC28), // Golden amber pulse
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$activeCount Active',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$approvedCount Approved • $underReviewCount Under Review',
                style: GoogleFonts.openSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB3F1C6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.applications});

  final List<Application> applications;

  @override
  Widget build(BuildContext context) {
    final total = applications.length;
    final pending = ApplicationFilters.pendingCount(applications);
    final approved = ApplicationFilters.approvedCount(applications);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _SummaryPill(
          key: const ValueKey('application-summary-total'),
          icon: Icons.send_outlined,
          label: '$total Total',
        ),
        _SummaryPill(
          key: const ValueKey('application-summary-pending'),
          icon: Icons.schedule_rounded,
          label: '$pending Pending',
        ),
        _SummaryPill(
          key: const ValueKey('application-summary-approved'),
          icon: Icons.check_circle_outline_rounded,
          label: '$approved Approved',
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: kPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
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

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  final Map<ApplicationStatus, int> counts;
  final ApplicationStatus? selected;
  final ValueChanged<ApplicationStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatusFilterChip(
            key: const ValueKey('application-filter-all'),
            label: 'All',
            count: total,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final status in ApplicationStatus.values) ...[
            const SizedBox(width: 6),
            _StatusFilterChip(
              key: ValueKey('application-filter-${status.dbValue}'),
              label: ApplicationStatusUi.of(status).label,
              count: counts[status] ?? 0,
              selected: selected == status,
              onTap: () => onSelect(status),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFF161C27);
    final background = selected ? kPrimary : const Color(0xFFF1F3FF);
    final border = selected ? kPrimary : const Color(0xFFE2E8E5);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label ($count)',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: border, width: 1.0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label == 'Approved') ...[
                  Icon(
                    Icons.verified_rounded,
                    size: 13,
                    color: selected ? Colors.white : const Color(0xFF0F4D2E),
                  ),
                  const SizedBox(width: 4),
                ] else if (label == 'Under review' && selected) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD2E4FF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  '$label ($count)',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: foreground,
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

/// Urgent Deadline Alert Banner (Stitch lines 38-60)
class _UrgentDeadlineBanner extends StatelessWidget {
  const _UrgentDeadlineBanner({
    required this.application,
    required this.scholarship,
  });

  final Application application;
  final Scholarship scholarship;

  @override
  Widget build(BuildContext context) {
    final daysLeft = scholarship.deadline.difference(DateTime.now()).inDays;
    final timeLabel = daysLeft <= 1 ? 'Due in 24 Hours' : 'Due in $daysLeft Days';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08BA1A1A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFBA1A1A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeLabel.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFBA1A1A),
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      '1 Action Needed',
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF93000A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${scholarship.title} requires completing your application before the deadline.',
                  style: GoogleFonts.openSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF93000A),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ApplicationDetailScreen(
                          applicationId: application.id,
                          initial: application,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        application.status == ApplicationStatus.draft
                            ? 'Resume Draft'
                            : 'View Submission',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFBA1A1A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 14, color: Color(0xFFBA1A1A)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Application Card: Renders 4 distinct Stitch V2 card variants based on status
class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.scholarship,
  });

  final Application application;
  final Scholarship? scholarship;

  @override
  Widget build(BuildContext context) {
    final scholarshipKnown = scholarship != null;
    final isApproved = application.status == ApplicationStatus.approved ||
        application.status == ApplicationStatus.awarded;
    final isDraft = application.status == ApplicationStatus.draft;

    final formattedAmount = _grantValue(scholarship);

    return Semantics(
      button: true,
      label: scholarshipKnown
          ? 'Open application for ${scholarship!.title}'
          : 'Open application',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openApplicationDetail(context),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isApproved
                    ? const Color(0xFFB3F1C6)
                    : const Color(0xFFE2E8E5),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A161C27),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Status chip + Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          ApplicationStatusChip(status: application.status),
                          if (application.appliedAt != null)
                            Text(
                              _formatDate(application.appliedAt!),
                              style: GoogleFonts.openSans(
                                fontSize: 11.5,
                                color: const Color(0xFF404942),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formattedAmount,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isApproved ? const Color(0xFF00351C) : kOnSurface,
                          ),
                        ),
                        Text(
                          'Per Annum',
                          style: GoogleFonts.outfit(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: kOnSurfaceVariant,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Scholarship Title
                Text(
                  scholarship?.title ?? 'Scholarship unavailable',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF161C27),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),

                // Provider & Proof ID
                Text.rich(
                  TextSpan(
                    text: '${scholarship?.provider ?? "National Scholarship Council"} ',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: const Color(0xFF404942),
                    ),
                    children: [
                      const TextSpan(text: '• Proof: '),
                      TextSpan(
                        text: '#REC-${application.id.substring(0, application.id.length.clamp(0, 6)).toUpperCase()}',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: kSecondary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Status-Specific Body Content
                if (application.status == ApplicationStatus.underReview) ...[
                  _buildUnderReviewSection(context),
                ] else if (isApproved) ...[
                  _buildApprovedSection(context),
                ] else if (isDraft) ...[
                  _buildDraftSection(context),
                ] else ...[
                  _buildDefaultSection(context, scholarshipKnown),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Under Review Card Section with 4-step Progress Timeline
  Widget _buildUnderReviewSection(BuildContext context) {
    return Column(
      children: [
        _ApplicationTimelineStepper(status: application.status),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F3FF),
                    foregroundColor: const Color(0xFF161C27),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _openApplicationDetail(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description_outlined, size: 15, color: kSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'View Submission PDF',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF404942),
                  side: const BorderSide(color: Color(0xFFE2E8E5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contacting DOST Scholarship Liaison...')),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.support_agent_rounded, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      'Liaison',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Approved / Won Celebration Card Section
  Widget _buildApprovedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFB3F1C6)),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_available_rounded, size: 18, color: Color(0xFF583F00)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT STEP MANDATORY',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF583F00),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Accept award package before Nov 15, 2026',
                      style: GoogleFonts.openSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF161C27),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F4D2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _openApplicationDetail(context),
            icon: const Icon(Icons.draw_rounded, size: 16),
            label: Text(
              'Review & Sign Acceptance',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Draft Card Section with Checklist
  Widget _buildDraftSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _checklistRow('Personal Statement (750 words)', 'Ready', true),
              const SizedBox(height: 6),
              _checklistRow('UP Diliman Academic Transcript', 'Uploaded', true),
              const SizedBox(height: 6),
              _checklistRow('Faculty Recommendation (1 of 2)', 'Pending', false),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.timelapse_rounded, size: 15, color: Color(0xFFBA1A1A)),
                const SizedBox(width: 4),
                Text(
                  scholarship != null
                      ? deadlineLabel(scholarship!.deadline)
                      : 'Due soon',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFBA1A1A),
                  ),
                ),
              ],
            ),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE8EEFF),
                foregroundColor: const Color(0xFF161C27),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onPressed: () => _openApplicationDetail(context),
              icon: const Icon(Icons.arrow_forward_rounded, size: 15),
              label: Text(
                'Continue',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _checklistRow(String title, String status, bool ready) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              ready ? Icons.check_circle_rounded : Icons.pending_rounded,
              size: 15,
              color: ready ? const Color(0xFF0F4D2E) : const Color(0xFFBA1A1A),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.openSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF161C27),
              ),
            ),
          ],
        ),
        Text(
          status,
          style: GoogleFonts.outfit(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: ready ? const Color(0xFF0F4D2E) : const Color(0xFFBA1A1A),
          ),
        ),
      ],
    );
  }

  /// Default / Submitted / Withdrawn / Rejected Section
  Widget _buildDefaultSection(BuildContext context, bool scholarshipKnown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (scholarshipKnown)
              _MetaChip(
                icon: Icons.event_rounded,
                label: deadlineLabel(scholarship!.deadline),
              ),
            if (application.appliedAt != null)
              _MetaChip(
                icon: Icons.send_rounded,
                label: 'Applied ${_formatDate(application.appliedAt!)}',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Review rounds commence in 8 days',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.openSans(
                  fontSize: 11.5,
                  color: kOnSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _openApplicationDetail(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Packet',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new_rounded, size: 14, color: kSecondary),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openApplicationDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ApplicationDetailScreen(
          applicationId: application.id,
          initial: application,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// 4-Step Application Progress Stepper matching Stitch timeline.
class _ApplicationTimelineStepper extends StatelessWidget {
  const _ApplicationTimelineStepper({required this.status});

  final ApplicationStatus status;

  int _currentStepIndex() {
    switch (status) {
      case ApplicationStatus.draft:
        return 0;
      case ApplicationStatus.submitted:
        return 1;
      case ApplicationStatus.underReview:
        return 2;
      case ApplicationStatus.approved:
      case ApplicationStatus.awarded:
      case ApplicationStatus.rejected:
      case ApplicationStatus.withdrawn:
        return 3;
    }
  }

  String _microStatusText() {
    switch (status) {
      case ApplicationStatus.draft:
        return 'Draft in progress';
      case ApplicationStatus.submitted:
        return 'Application received & logged';
      case ApplicationStatus.underReview:
        return 'Committee deliberating';
      case ApplicationStatus.approved:
      case ApplicationStatus.awarded:
        return 'Application approved! Award verified.';
      case ApplicationStatus.rejected:
        return 'Evaluation concluded';
      case ApplicationStatus.withdrawn:
        return 'Application withdrawn';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentStepIndex();
    const steps = ['Draft', 'Submitted', 'Review', 'Decision'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: i <= currentIndex
                          ? kPrimary
                          : const Color(0xFFC0C9C0),
                    ),
                  ),
                _StepNode(
                  label: steps[i],
                  isCompleted: i < currentIndex,
                  isActive: i == currentIndex,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                status == ApplicationStatus.underReview
                    ? Icons.hourglass_top_rounded
                    : Icons.info_outline_rounded,
                size: 14,
                color: const Color(0xFF436084),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _microStatusText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    color: const Color(0xFF404942),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status == ApplicationStatus.underReview
                    ? 'Est. Decision: Oct 20'
                    : 'Step ${currentIndex + 1} of 4',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF161C27),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.label,
    required this.isCompleted,
    required this.isActive,
  });

  final String label;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    Color circleColor;
    Widget child;

    if (isCompleted) {
      circleColor = kPrimary;
      child = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isActive) {
      circleColor = const Color(0xFF436084); // Stitch secondary
      child = Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
    } else {
      circleColor = const Color(0xFFE3E8F9);
      child = Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(
          color: Color(0xFF707971),
          shape: BoxShape.circle,
        ),
      );
    }

    return SizedBox(
      width: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? const [
                      BoxShadow(
                        color: Color(0x66ABC9F2),
                        blurRadius: 0,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: child,
          ),
          const SizedBox(height: 4),
          Text(
            '$label\u200B',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF161C27)
                  : const Color(0xFF707971),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: kPrimary),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom Encouragement Callout (Stitch lines 270-287)
class _AdmissionsMomentumCard extends ConsumerWidget {
  const _AdmissionsMomentumCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD2E4FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A161C27),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF0F4D2E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_up_rounded, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMISSIONS MOMENTUM',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: const Color(0xFF00351C),
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: 'Students who apply to ',
                    style: GoogleFonts.openSans(
                      fontSize: 12.5,
                      color: const Color(0xFF161C27),
                      height: 1.4,
                    ),
                    children: const [
                      TextSpan(
                        text: '6+ matched scholarships',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00351C)),
                      ),
                      TextSpan(text: ' have an '),
                      TextSpan(
                        text: '84% success rate',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00351C)),
                      ),
                      TextSpan(text: ' receiving at least one funding award.'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4D2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () {
                    ref.read(homeTabIndexProvider.notifier).selectTab(1);
                  },
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: Text(
                    'Find More Matches',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stitch Initial Empty State (`scholaris_no_applications_yet_tracker_initial_state`)
class _EmptyApplicationsState extends ConsumerWidget {
  const _EmptyApplicationsState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scholarshipsAsync = ref.watch(scholarshipsProvider);
    final count = scholarshipsAsync.valueOrNull?.length ?? 38;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Empty State Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x081B3A5C),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Consoling Mascot Hero
                const MascotPoseView(
                  pose: MascotPose.consoling,
                  height: 110,
                ),
                const SizedBox(height: 16),
                Text(
                  'No applications yet',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF161C27),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "You haven't applied to anything yet",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F4D2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your scholarship journey starts with your first application! Students who submit to at least 4 to 6 matched programs have an 83% higher chance of securing college funding.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: const Color(0xFF404942),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(homeTabIndexProvider.notifier).selectTab(1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start applying',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF0F4D2E)),
                    const SizedBox(width: 6),
                    Text(
                      '$count Grants eligible for your profile',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Educational Roadmap: What happens when you apply
          Row(
            children: [
              const Icon(Icons.flag_rounded, size: 20, color: Color(0xFF0F4D2E)),
              const SizedBox(width: 8),
              Text(
                'What happens when you apply',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF161C27),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
            ),
            child: Column(
              children: [
                _RoadmapStep(
                  number: '1',
                  color: const Color(0xFF00351C),
                  title: 'Browse matched Philippine grants',
                  description:
                      'Discover government & private awards from DOST-SEI, CHED Merit, and regional LGU subsidies matched to your field.',
                ),
                Container(
                  width: 2,
                  height: 16,
                  margin: const EdgeInsets.only(left: 14),
                  color: const Color(0xFFC0C9C0),
                ),
                _RoadmapStep(
                  number: '2',
                  color: const Color(0xFF0F4D2E),
                  title: 'One-tap credential submission',
                  description:
                      'Fast-track applications using your verified Philippine university credentials, authenticated CRS grades, and uploaded TCG.',
                ),
                Container(
                  width: 2,
                  height: 16,
                  margin: const EdgeInsets.only(left: 14),
                  color: const Color(0xFFC0C9C0),
                ),
                _RoadmapStep(
                  number: '3',
                  color: const Color(0xFF436084),
                  title: 'Track live review deliberation',
                  description:
                      'Receive real-time timestamp updates as evaluation committees screen requirements, schedule interviews, and release stipends.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Document Preparation Tip Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8E5), width: 1.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    size: 20,
                    color: Color(0xFF0F4D2E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DOCUMENT PREPARATION',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF436084),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Preparing grades & certs?',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF161C27),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Need tips on requesting your True Copy of Grades (TCG) or PSA birth certificate? Check requirements before deadlines arrive.',
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: const Color(0xFF404942),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Suggested For You Preview Card (Stitch lines 135-164)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suggested For You',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF161C27),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(homeTabIndexProvider.notifier).selectTab(1);
                },
                child: Text(
                  'View all ($count)',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8E5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A161C27),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: '₱40,000',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F4D2E),
                        ),
                        children: [
                          TextSpan(
                            text: ' / sem',
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: kOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F4D2E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '98% Fit',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F4D2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'DOST-SEI Merit Scholarship 2025',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF161C27),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Department of Science and Technology',
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: const Color(0xFF404942),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFBA1A1A)),
                        const SizedBox(width: 4),
                        Text(
                          'Closes in 6 days',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFBA1A1A),
                          ),
                        ),
                      ],
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F3FF),
                        foregroundColor: const Color(0xFF0F4D2E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        ref.read(homeTabIndexProvider.notifier).selectTab(1);
                      },
                      child: Text(
                        'Draft Application',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

class _RoadmapStep extends StatelessWidget {
  const _RoadmapStep({
    required this.number,
    required this.color,
    required this.title,
    required this.description,
  });

  final String number;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF161C27),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: const Color(0xFF404942),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

double _scholarshipAmountValue(Scholarship? scholarship) {
  if (scholarship == null) return 50000;
  return scholarship.amount;
}

String _grantValue(Scholarship? scholarship) {
  if (scholarship == null) return '₱50,000';
  return scholarship.formattedAmount;
}
