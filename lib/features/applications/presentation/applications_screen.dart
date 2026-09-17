// lib/features/applications/presentation/applications_screen.dart
//
// "My Applications" — the student's dedicated tracking surface rebuilt to match
// the Stitch design specification. It lists only the currently authenticated user's
// applications (via [applicationsProvider]) with the associated scholarship info
// resolved from the catalog, status filter chips, potential award metrics banner,
// timeline steppers on each card, and an educational Stitch empty state.

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Applications',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF161C27),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track deadlines, submission proofs, and award decisions.',
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: const Color(0xFF404942),
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
      appBar: AppBar(title: const Text('My Applications')),
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

        // Standard Philippine grant estimate of ₱90,000 per application
        final totalPotential = (applications.length * 90000).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _PotentialAwardCard(
                totalPotential: totalPotential,
                applications: applications,
                counts: counts,
              ),
              const SizedBox(height: 8),
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
                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _ApplicationCard(
                              application: filtered[i],
                              scholarship: byId[filtered[i].scholarshipId],
                            ),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00351C), // Bridge Green Dark
            Color(0xFF0F4D2E), // Bridge Green Primary
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F4D2E),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFFB3F1C6),
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: '₱${_formatAmount(totalPotential)} ',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5.5,
                  height: 5.5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFABC28), // Golden pulse
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4.5),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: border, width: 1.0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$label ($count)',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

    return Semantics(
      button: true,
      label: scholarshipKnown
          ? 'Open application for ${scholarship!.title}'
          : 'Open application',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openApplicationDetail(context),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isApproved
                    ? const Color(0xFFB3F1C6)
                    : const Color(0xFFE2E8E5),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ApplicationStatusChip(status: application.status),
                    if (application.appliedAt != null)
                      Flexible(
                        child: Text(
                          _formatDate(application.appliedAt!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.openSans(
                            fontSize: 11.5,
                            color: const Color(0xFF404942),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  scholarship?.title ?? 'Scholarship unavailable',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF161C27),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scholarship?.provider ??
                      'This scholarship is no longer active.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    fontSize: 12.5,
                    color: const Color(0xFF404942),
                  ),
                ),
                if (scholarshipKnown) ...[
                  const SizedBox(height: 6),
                  Text(
                    scholarship!.slots == null
                        ? 'Slots not specified'
                        : '${scholarship!.slots} slot(s)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: const Color(0xFF707971),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _ApplicationTimelineStepper(status: application.status),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
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
              ],
            ),
          ),
        ),
      ),
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
    const steps = ['Drafting', 'Received', 'Screening', 'Decision'];

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
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 14),
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
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      status == ApplicationStatus.underReview
                          ? Icons.hourglass_top_rounded
                          : Icons.info_outline_rounded,
                      size: 12,
                      color: const Color(0xFF436084),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _microStatusText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          fontSize: 10.5,
                          color: const Color(0xFF404942),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Step ${currentIndex + 1} of 4',
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
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
      child = const Icon(Icons.check, size: 11, color: Colors.white);
    } else if (isActive) {
      circleColor = const Color(0xFF436084); // Stitch secondary
      child = Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
    } else {
      circleColor = const Color(0xFFE3E8F9);
      child = Container(
        width: 3.5,
        height: 3.5,
        decoration: const BoxDecoration(
          color: Color(0xFF707971),
          shape: BoxShape.circle,
        ),
      );
    }

    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(color: const Color(0xFFD2E4FF), width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: child,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFF161C27) : const Color(0xFF707971),
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

/// Stitch Initial Empty State (`scholaris_no_applications_yet_tracker_initial_state`)
class _EmptyApplicationsState extends ConsumerWidget {
  const _EmptyApplicationsState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                // Concentric Halo with Sparkles
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF4DE), // Warm gold halo
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.assignment_outlined,
                        size: 28,
                        color: Color(0xFF0F4D2E), // kPrimary
                      ),
                    ),
                    const Positioned(
                      top: -2,
                      right: -2,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: Color(0xFFFABC28),
                      ),
                    ),
                    const Positioned(
                      bottom: 0,
                      left: -4,
                      child: Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFF98D4AB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'No applications yet',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF161C27),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When you apply to a scholarship it will show up here so you can track its status. '
                  'Your scholarship journey starts with your first application!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: const Color(0xFF404942),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(homeTabIndexProvider.notifier).selectTab(0);
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
                          'Browse Matched Scholarships',
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
                        style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
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
