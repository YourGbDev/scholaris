// lib/admin/screens/applications_oversight_screen.dart
//
// Admin Console: Applications Oversight (Screen 3 Mockup-Fidelity Rebuild)
// Visual tokens: scholaris_sequoia/DESIGN.md
// Strictly real data: 100% wired to public.applications, public.profiles, and public.scholarships.
// Zero fabricated metrics, zero fake compliance stamps, zero fake candidate identities.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/admin/presentation/admin_theme.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/widgets/state_views.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// 1. Domain Model: ApplicationRecord
// =============================================================================

class ApplicationRecord {
  const ApplicationRecord({
    required this.id,
    required this.userId,
    required this.scholarshipId,
    required this.status,
    required this.notes,
    required this.appliedAt,
    required this.updatedAt,
    this.applicantName,
    this.school,
    this.course,
    this.yearLevel,
    this.gpa,
    this.region,
    this.cityMunicipality,
    this.email,
    this.scholarshipTitle,
    this.scholarshipAmount,
  });

  final String id;
  final String userId;
  final String scholarshipId;
  final String status;
  final String? notes;
  final DateTime? appliedAt;
  final DateTime updatedAt;

  // Joined from public.profiles
  final String? applicantName;
  final String? school;
  final String? course;
  final int? yearLevel;
  final double? gpa;
  final String? region;
  final String? cityMunicipality;
  final String? email;

  // Joined from public.scholarships
  final String? scholarshipTitle;
  final double? scholarshipAmount;

  factory ApplicationRecord.fromMap(
    Map<String, dynamic> row, {
    Map<String, dynamic>? profile,
  }) {
    // 1. Check if scholarship was embedded in query
    final scholarshipMap = row['scholarships'] as Map<String, dynamic>?;

    // 2. Parse applied_at and updated_at
    final appliedAtStr = row['applied_at'] as String?;
    final appliedAt = appliedAtStr != null && appliedAtStr.isNotEmpty
        ? DateTime.tryParse(appliedAtStr)
        : null;

    final updatedAtStr = row['updated_at'] as String?;
    final updatedAt = updatedAtStr != null && updatedAtStr.isNotEmpty
        ? DateTime.parse(updatedAtStr)
        : DateTime.now();

    // 3. Extract profile details: strictly from public.profiles, null if missing
    final applicantName = (profile?['full_name'] as String?)?.trim();
    final school = (profile?['school'] as String?)?.trim();
    final course = (profile?['course'] as String?)?.trim();
    final yearLevel = profile?['year_level'] as int?;
    final gpa = (profile?['gpa'] as num?)?.toDouble();
    final region = (profile?['region'] as String?)?.trim();
    final cityMunicipality =
        (profile?['city_municipality'] as String?)?.trim();
    final email = (profile?['email'] as String?)?.trim();

    final title = scholarshipMap?['title'] as String?;
    final amount = (scholarshipMap?['amount'] as num?)?.toDouble();

    return ApplicationRecord(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      scholarshipId: row['scholarship_id'] as String,
      status: row['status'] as String? ?? 'draft',
      notes: row['notes'] as String?,
      appliedAt: appliedAt,
      updatedAt: updatedAt,
      applicantName: (applicantName != null && applicantName.isNotEmpty)
          ? applicantName
          : null,
      school: (school != null && school.isNotEmpty) ? school : null,
      course: (course != null && course.isNotEmpty) ? course : null,
      yearLevel: yearLevel,
      gpa: gpa,
      region: (region != null && region.isNotEmpty) ? region : null,
      cityMunicipality: (cityMunicipality != null &&
              cityMunicipality.isNotEmpty)
          ? cityMunicipality
          : null,
      email: (email != null && email.isNotEmpty) ? email : null,
      scholarshipTitle: title,
      scholarshipAmount: amount,
    );
  }
}

// =============================================================================
// 2. Data Fetching State Providers
// =============================================================================

final adminApplicationsProvider =
    FutureProvider<List<ApplicationRecord>>((ref) async {
  final supabase = Supabase.instance.client;

  // Step 1: Fetch applications with scholarships join
  final appsResponse = await supabase
      .from('applications')
      .select('''
        id,
        user_id,
        scholarship_id,
        status,
        notes,
        applied_at,
        updated_at,
        scholarships!scholarship_id (
          title,
          amount
        )
      ''')
      .order('updated_at', ascending: false);

  final appsList = List<Map<String, dynamic>>.from(appsResponse);

  // Step 2: Collect all unique user_ids from result, then fetch their profiles
  final userIds =
      appsList.map((a) => a['user_id'] as String).toSet().toList();
  final profilesResponse = await supabase
      .from('profiles')
      .select(
          'id, full_name, school, course, year_level, gpa, region, city_municipality, email')
      .inFilter('id', userIds);

  // Build a lookup map
  final profileMap = <String, Map<String, dynamic>>{
    for (final p in profilesResponse) p['id'] as String: p,
  };

  // Step 3: When building ApplicationRecord, look up profile from profileMap
  return appsList
      .map((app) => ApplicationRecord.fromMap(
            app,
            profile: profileMap[app['user_id'] as String],
          ))
      .toList();
});

final adminApplicationSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final adminApplicationStatusFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all');

// =============================================================================
// 3. UI Component: ApplicationsOversightScreen
// =============================================================================

class ApplicationsOversightScreen extends ConsumerStatefulWidget {
  const ApplicationsOversightScreen({
    super.key,
    this.initialInspectApproved = false,
  });

  final bool initialInspectApproved;

  @override
  ConsumerState<ApplicationsOversightScreen> createState() =>
      _ApplicationsOversightScreenState();
}

class _ApplicationsOversightScreenState
    extends ConsumerState<ApplicationsOversightScreen> {
  final _searchController = TextEditingController();
  bool _isDetailOpen = false;

  @override
  void didUpdateWidget(ApplicationsOversightScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialInspectApproved) {
      _checkAndAutoOpen();
    }
  }

  void _checkAndAutoOpen([List<ApplicationRecord>? appsList]) {
    if (_isDetailOpen) return;
    final apps = appsList ?? ref.read(adminApplicationsProvider).valueOrNull;
    if (apps != null) {
      final approvedApp = apps.cast<ApplicationRecord?>().firstWhere(
        (a) => a?.status.toLowerCase().trim() == 'approved',
        orElse: () => null,
      );
      if (approvedApp != null) {
        _isDetailOpen = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showApplicationDetail(context, approvedApp).then((_) {
              _isDetailOpen = false;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Formatting Helpers ---------------------------------------------------

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return '₱0';
    final rounded = amount.toInt();
    final chars = rounded.toString().split('');
    final buffer = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(chars[i]);
    }
    return '₱$buffer';
  }

  String? _formatCourseYear(String? course, int? yearLevel) {
    final hasCourse = course != null && course.trim().isNotEmpty;
    final hasYear = yearLevel != null && yearLevel > 0;
    if (hasCourse && hasYear) return '$course · Year $yearLevel';
    if (hasCourse) return course;
    if (hasYear) return 'Year $yearLevel';
    return null;
  }

  // --- Main Build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(adminApplicationsProvider);
    final searchQuery = ref.watch(adminApplicationSearchQueryProvider);
    final activeStatusFilter = ref.watch(adminApplicationStatusFilterProvider);

    return Scaffold(
      backgroundColor: kSeqSurface,
      body: appsAsync.when(
        loading: () => _buildSkeleton(context),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorView(
              title: 'Unable to Load Applications Oversight',
              message: 'Failed to query live applications registry: $err',
              onRetry: () => ref.invalidate(adminApplicationsProvider),
            ),
          ),
        ),
        data: (allApplications) {
          final totalCount = allApplications.length;

          if (!_isDetailOpen &&
              (widget.initialInspectApproved ||
                  Uri.base.queryParameters['inspect'] == 'approved')) {
            _checkAndAutoOpen(allApplications);
          }

          // Status Counts computed strictly from live database rows
          final statusCounts = <String, int>{
            'all': totalCount,
            'draft': 0,
            'submitted': 0,
            'under_review': 0,
            'shortlisted': 0,
            'awarded': 0,
            'approved': 0,
            'rejected': 0,
            'withdrawn': 0,
          };

          for (final app in allApplications) {
            final st = app.status.toLowerCase().trim();
            statusCounts[st] = (statusCounts[st] ?? 0) + 1;
          }

          // Filter by status
          List<ApplicationRecord> filtered = allApplications;
          if (activeStatusFilter != 'all') {
            filtered = filtered.where((a) {
              final st = a.status.toLowerCase().trim();
              if (activeStatusFilter == 'under_review') {
                return st == 'under_review' || st == 'underreview';
              }
              return st == activeStatusFilter;
            }).toList();
          }

          // Filter by search query (applicant name or scholarship title)
          if (searchQuery.isNotEmpty) {
            filtered = filtered.where((a) {
              final name = (a.applicantName ?? '').toLowerCase();
              final title = (a.scholarshipTitle ?? '').toLowerCase();
              final school = (a.school ?? '').toLowerCase();
              return name.contains(searchQuery) ||
                  title.contains(searchQuery) ||
                  school.contains(searchQuery);
            }).toList();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3a. Header Bar
                _buildHeaderBar(context, totalCount: totalCount),
                const SizedBox(height: 18),

                // Live Telemetry KPI Summary Strip
                _buildTelemetryStrip(
                  context,
                  totalCount: totalCount,
                  submittedCount: statusCounts['submitted'] ?? 0,
                  underReviewCount: statusCounts['under_review'] ?? 0,
                  approvedCount: (statusCounts['approved'] ?? 0) +
                      (statusCounts['awarded'] ?? 0),
                ),
                const SizedBox(height: 18),

                // 3b & 3c. Filter and Search Shelf
                _buildFilterAndSearchShelf(
                  context,
                  statusCounts: statusCounts,
                  activeFilter: activeStatusFilter,
                  searchQuery: searchQuery,
                ),
                const SizedBox(height: 16),

                // 3d & 3f. Applications List or Empty State
                if (filtered.isEmpty)
                  _buildEmptyState(
                    activeTab: _getFilterLabel(activeStatusFilter),
                    searchQuery: searchQuery,
                  )
                else
                  _buildApplicationsList(context, filtered),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 3a. Header Bar --------------------------------------------------------

  Widget _buildHeaderBar(BuildContext context, {required int totalCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live data tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kSeqSurfaceContainerHighest.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: kSeqPrimaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Live data',
                style: seqLabelSm(
                  color: kSeqOnSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Title
        Text(
          'Applications Oversight',
          style: seqHeadlineLg(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),

        // Subtitle: strictly live database count
        Text(
          '$totalCount applications on platform',
          style: seqBodyMd(color: kSeqOnSurfaceVariant),
        ),
      ],
    );
  }

  // --- Telemetry Summary Strip -----------------------------------------------

  Widget _buildTelemetryStrip(
    BuildContext context, {
    required int totalCount,
    required int submittedCount,
    required int underReviewCount,
    required int approvedCount,
  }) {
    final width = MediaQuery.sizeOf(context).width;

    final cards = [
      _buildKpiCard(
        title: 'TOTAL INTAKE REGISTRY',
        value: '$totalCount',
        subtitle: 'All live applications',
        icon: Icons.assignment_outlined,
        color: kSeqOnSurface,
        containerBg: kSeqSurfaceContainerLow,
      ),
      _buildKpiCard(
        title: 'SUBMITTED INTAKE',
        value: '$submittedCount',
        subtitle: 'Awaiting evaluation',
        icon: Icons.send_rounded,
        color: kSeqSecondary,
        containerBg: kSeqSecondaryFixed.withValues(alpha: 0.4),
      ),
      _buildKpiCard(
        title: 'UNDER COMMITTEE REVIEW',
        value: '$underReviewCount',
        subtitle: 'In-flight assessment',
        icon: Icons.schedule_rounded,
        color: kSeqTertiaryContainer,
        containerBg: kSeqTertiaryFixed.withValues(alpha: 0.4),
      ),
      _buildKpiCard(
        title: 'APPROVED & AWARDED',
        value: '$approvedCount',
        subtitle: 'Approved applications',
        icon: Icons.check_circle_rounded,
        color: kSeqPrimaryContainer,
        containerBg: kSeqPrimaryFixed.withValues(alpha: 0.4),
      ),
    ];

    if (width >= 1024) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: c,
                  ),
                ))
            .toList(),
      );
    } else if (width >= 600) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 8),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 8),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: c,
                ))
            .toList(),
      );
    }
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color containerBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
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
              Flexible(
                child: Text(
                  title,
                  style: seqLabelSm(
                    color: kSeqOutline,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: seqHeadlineLg(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: seqBodySm(color: kSeqOnSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- 3b & 3c. Filter and Search Shelf --------------------------------------

  Widget _buildFilterAndSearchShelf(
    BuildContext context, {
    required Map<String, int> statusCounts,
    required String activeFilter,
    required String searchQuery,
  }) {
    final tabs = [
      {'key': 'all', 'label': 'All'},
      {'key': 'draft', 'label': 'Draft'},
      {'key': 'submitted', 'label': 'Submitted'},
      {'key': 'under_review', 'label': 'Under Review'},
      {'key': 'shortlisted', 'label': 'Shortlisted'},
      {'key': 'awarded', 'label': 'Awarded'},
      {'key': 'approved', 'label': 'Approved'},
      {'key': 'rejected', 'label': 'Rejected'},
      {'key': 'withdrawn', 'label': 'Withdrawn'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3b. Status Filter Tabs (Segmented Control style matching Screens 1 & 2)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: tabs.map((t) {
                  final key = t['key']!;
                  final label = t['label']!;
                  final count = statusCounts[key] ?? 0;
                  final isSelected = activeFilter == key;

                  return _buildTabPill(
                    key: key,
                    label: '$label ($count)',
                    isSelected: isSelected,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3c. Search Bar
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: kSeqOutline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: seqBodyMd(),
                    decoration: InputDecoration(
                      hintText:
                          'Filter by applicant name, school, or scholarship title...',
                      hintStyle: seqBodySm(color: kSeqOutline),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (val) {
                      ref
                          .read(adminApplicationSearchQueryProvider.notifier)
                          .state = val.trim().toLowerCase();
                    },
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: kSeqOutline),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _searchController.clear();
                      ref
                          .read(adminApplicationSearchQueryProvider.notifier)
                          .state = '';
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required String key,
    required String label,
    required bool isSelected,
  }) {
    return PressableScale(
      child: GestureDetector(
        onTap: () {
          ref.read(adminApplicationStatusFilterProvider.notifier).state = key;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? kSeqSurfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: seqLabelSm(
              color: isSelected ? kSeqOnSurface : kSeqOnSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _getFilterLabel(String key) {
    switch (key) {
      case 'all':
        return 'All';
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'shortlisted':
        return 'Shortlisted';
      case 'awarded':
        return 'Awarded';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'withdrawn':
        return 'Withdrawn';
      default:
        return key;
    }
  }

  // --- 3d. Applications List -------------------------------------------------

  Widget _buildApplicationsList(
      BuildContext context, List<ApplicationRecord> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) => _buildApplicationCard(ctx, list[index]),
    );
  }

  Widget _buildApplicationCard(BuildContext context, ApplicationRecord item) {
    final applicantDisplayName = item.applicantName ?? 'Name not set';
    final hasApplicantName = item.applicantName != null;
    final schoolDisplayName = item.school ?? 'School not set';
    final hasSchool = item.school != null;
    final courseYearText = _formatCourseYear(item.course, item.yearLevel);
    final scholarshipTitleText = item.scholarshipTitle ?? 'General Bursary';
    final scholarshipAmountText = _formatCurrency(item.scholarshipAmount);
    final appliedAtText = _formatDate(item.appliedAt);
    final updatedAtText = _formatDate(item.updatedAt);

    // Initials for avatar
    final initials = applicantDisplayName.trim().isNotEmpty
        ? applicantDisplayName
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
            .join()
        : 'AP';

    return PressableScale(
      child: InkWell(
        onTap: () => _showApplicationDetail(context, item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSeqSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: kSeqOutlineVariant.withValues(alpha: 0.35)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Candidate info + Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Candidate Avatar Initials
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: kSeqPrimaryFixed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: seqLabelSm(
                        color: kSeqOnPrimaryFixedVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name, School, Course + Year Level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicantDisplayName,
                          style: seqLabelLg(
                            color: hasApplicantName
                                ? kSeqOnSurface
                                : kSeqOutline,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          schoolDisplayName,
                          style: seqBodySm(
                            color: hasSchool
                                ? kSeqOnSurfaceVariant
                                : kSeqOutline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (courseYearText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            courseYearText,
                            style: seqLabelSm(
                              color: kSeqOutline,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status Badge
                  StatusBadge(status: item.status),
                ],
              ),
              const SizedBox(height: 12),

              // Middle Divider
              Divider(
                color: kSeqOutlineVariant.withValues(alpha: 0.2),
                height: 1,
              ),
              const SizedBox(height: 12),

              // Middle Row: Scholarship Program & Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROGRAM & GRANT POOL',
                          style: seqLabelSm(
                            color: kSeqOutline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scholarshipTitleText,
                          style: seqBodyMd(
                            color: kSeqOnSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ALLOCATION',
                        style: seqLabelSm(
                          color: kSeqOutline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scholarshipAmountText,
                        style: seqHeadlineSm(
                          color: kSeqPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom Row: Timestamps & Inspect Link
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kSeqSurfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Applied: $appliedAtText',
                              style: seqLabelSm(color: kSeqOnSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('•',
                              style: seqLabelSm(color: kSeqOutline)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Updated: $updatedAtText',
                              style: seqLabelSm(color: kSeqOutline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Inspect Dossier',
                          style: seqLabelSm(
                            color: kSeqSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: kSeqSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3e. Application Detail Drawer / Dialog (Read-Only) --------------------

  Future<void> _showApplicationDetail(BuildContext context, ApplicationRecord item) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final applicantDisplayName = item.applicantName ?? 'Name not set';
    final schoolDisplayName = item.school ?? 'School not set';
    final courseYearText = _formatCourseYear(item.course, item.yearLevel);
    final scholarshipTitleText = item.scholarshipTitle ?? 'General Bursary';
    final scholarshipAmountText = _formatCurrency(item.scholarshipAmount);
    final appliedAtFormatted = _formatDate(item.appliedAt);
    final updatedAtFormatted = _formatDate(item.updatedAt);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kSeqSurfaceContainerLowest,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Application Dossier',
                style: seqHeadlineSm(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: item.status),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Applicant Identity Section
                Text(
                  'APPLICANT PROFILE',
                  style: seqLabelSm(
                    color: kSeqOutline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _dossierRow('Candidate Name', applicantDisplayName),
                if (item.email != null && item.email!.isNotEmpty)
                  _dossierRow('Email Address', item.email!),
                _dossierRow('Educational Institution', schoolDisplayName),
                if (courseYearText != null)
                  _dossierRow('Course & Year', courseYearText),
                if (item.gpa != null && item.gpa! > 0)
                  _dossierRow('Academic GWA', item.gpa!.toStringAsFixed(2)),
                if (item.region != null && item.region!.isNotEmpty)
                  _dossierRow('Administrative Region', item.region!),
                if (item.cityMunicipality != null &&
                    item.cityMunicipality!.isNotEmpty)
                  _dossierRow(
                      'City / Municipality', item.cityMunicipality!),
                const SizedBox(height: 14),
                Divider(color: kSeqOutlineVariant.withValues(alpha: 0.25)),
                const SizedBox(height: 10),

                // Scholarship Program Section
                Text(
                  'SCHOLARSHIP PROGRAM',
                  style: seqLabelSm(
                    color: kSeqOutline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _dossierRow('Grant Program', scholarshipTitleText),
                _dossierRow('Committed Allocation', scholarshipAmountText),
                _dossierRow('Scholarship ID', item.scholarshipId),
                const SizedBox(height: 14),
                Divider(color: kSeqOutlineVariant.withValues(alpha: 0.25)),
                const SizedBox(height: 10),

                // Intake & Clearance State Section
                Text(
                  'INTAKE & CLEARANCE STATE',
                  style: seqLabelSm(
                    color: kSeqOutline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                // Status with badge + raw enum value below
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 170,
                        child: Text(
                          'Clearance Status',
                          style: seqLabelSm(
                            color: kSeqOutline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusBadge(status: item.status),
                            const SizedBox(height: 3),
                            Text(
                              item.status,
                              style: GoogleFonts.robotoMono(
                                fontSize: 11,
                                color: kSeqOutline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                _dossierRow('Applied At (Formatted)', appliedAtFormatted),
                _dossierRow(
                  'Applied At (ISO Timestamp)',
                  item.appliedAt != null
                      ? item.appliedAt!.toIso8601String()
                      : '—',
                ),
                _dossierRow('Updated At (Formatted)', updatedAtFormatted),
                _dossierRow(
                  'Updated At (ISO Timestamp)',
                  item.updatedAt.toIso8601String(),
                ),
                _dossierRow('Application ID', item.id),
                _dossierRow('User ID', item.userId),

                const SizedBox(height: 14),
                Divider(color: kSeqOutlineVariant.withValues(alpha: 0.25)),
                const SizedBox(height: 10),

                // Notes Field
                Text(
                  'APPLICATION NOTES',
                  style: seqLabelSm(
                    color: kSeqOutline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kSeqSurfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: kSeqOutlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    item.notes != null && item.notes!.trim().isNotEmpty
                        ? item.notes!
                        : 'No notes',
                    style: item.notes != null && item.notes!.trim().isNotEmpty
                        ? seqBodySm(color: kSeqOnSurface)
                        : seqBodySm(color: kSeqOutline),
                  ),
                ),

              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.status.toLowerCase().trim() == 'approved') ...[
                FutureBuilder<Map<String, dynamic>?>(
                  future: Supabase.instance.client
                      .from('disbursements')
                      .select('id')
                      .eq('application_id', item.id)
                      .maybeSingle(),
                  builder: (fContext, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final existing = snapshot.data;
                    if (existing != null) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: kSeqPrimaryFixed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: kSeqPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '● Disbursement on record',
                              style: seqLabelSm(
                                color: kSeqOnPrimaryFixedVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          _openCreateDisbursementSheet(
                            context,
                            dialogContext,
                            item,
                          );
                        },
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text('Create Disbursement'),
                        style: FilledButton.styleFrom(
                          backgroundColor: kSeqPrimary,
                          foregroundColor: kSeqOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: seqLabelMd(
                            fontWeight: FontWeight.w600,
                            color: kSeqOnPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Close',
                    style: seqLabelMd(
                      color: kSeqOnSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openCreateDisbursementSheet(
    BuildContext parentContext,
    BuildContext dialogContext,
    ApplicationRecord item,
  ) {
    showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CreateDisbursementSheet(
          item: item,
          onSuccess: () {
            Navigator.of(sheetContext).pop();
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(parentContext).showSnackBar(
              const SnackBar(
                content: Text('Disbursement created successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            ref.invalidate(adminApplicationsProvider);
          },
        );
      },
    );
  }

  Widget _dossierRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: seqLabelSm(
                color: kSeqOutline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: seqBodySm(
                color: kSeqOnSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3f. Empty State -------------------------------------------------------

  Widget _buildEmptyState({
    required String activeTab,
    required String searchQuery,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLow,
              shape: BoxShape.circle,
              border:
                  Border.all(color: kSeqOutlineVariant.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 26,
              color: kSeqOutline,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No applications found',
            style: seqHeadlineSm(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            searchQuery.isNotEmpty
                ? 'No applications match your search query "$searchQuery".'
                : 'There are currently 0 applications in the "$activeTab" category.',
            style: seqBodySm(color: kSeqOnSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Skeleton Loading ------------------------------------------------------

  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBand(width: 260, height: 16),
          const SizedBox(height: 10),
          const SkeletonBand(width: 320, height: 32),
          const SizedBox(height: 10),
          const SkeletonBand(width: 440, height: 16),
          const SizedBox(height: 24),

          // KPI Strip Skeleton
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 12 : 0),
                  height: 90,
                  decoration: BoxDecoration(
                    color: kSeqSurfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Filter Shelf Skeleton
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),

          // Cards Skeleton
          Column(
            children: List.generate(
              3,
              (i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 130,
                decoration: BoxDecoration(
                  color: kSeqSurfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. StatusBadge Component (Matching Screen 2 Sequoia DNA)
// =============================================================================

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final st = status.toLowerCase().trim();

    Color bg;
    Color fg;
    Color dotColor;
    String label;

    switch (st) {
      case 'approved':
        bg = kSeqPrimaryFixed;
        fg = kSeqOnPrimaryFixedVariant;
        dotColor = kSeqPrimaryContainer;
        label = 'Approved';
        break;
      case 'awarded':
        bg = kSeqPrimaryFixed;
        fg = kSeqOnPrimaryFixedVariant;
        dotColor = kSeqPrimaryContainer;
        label = 'Awarded';
        break;
      case 'submitted':
        bg = kSeqSecondaryFixed;
        fg = kSeqOnSecondaryFixedVariant;
        dotColor = kSeqSecondary;
        label = 'Submitted';
        break;
      case 'under_review':
      case 'underreview':
        bg = kSeqTertiaryFixed;
        fg = kSeqOnTertiaryFixedVariant;
        dotColor = kSeqTertiaryContainer;
        label = 'Under Review';
        break;
      case 'shortlisted':
        bg = const Color(0xFFE8DEF8);
        fg = const Color(0xFF21005D);
        dotColor = const Color(0xFF6750A4);
        label = 'Shortlisted';
        break;
      case 'rejected':
        bg = kSeqErrorContainer;
        fg = kSeqOnErrorContainer;
        dotColor = kSeqError;
        label = 'Rejected';
        break;
      case 'withdrawn':
        bg = kSeqSurfaceContainerHigh;
        fg = kSeqOnSurfaceVariant;
        dotColor = kSeqOutline;
        label = 'Withdrawn';
        break;
      case 'draft':
      default:
        bg = kSeqSurfaceContainer;
        fg = kSeqOnSurfaceVariant;
        dotColor = kSeqOutline;
        label = st.isNotEmpty ? st[0].toUpperCase() + st.substring(1) : 'Draft';
        break;
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: seqLabelSm(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 5. Create Disbursement Bottom Sheet
// =============================================================================

class _CreateDisbursementSheet extends StatefulWidget {
  const _CreateDisbursementSheet({
    required this.item,
    required this.onSuccess,
  });

  final ApplicationRecord item;
  final VoidCallback onSuccess;

  @override
  State<_CreateDisbursementSheet> createState() =>
      _CreateDisbursementSheetState();
}

class _CreateDisbursementSheetState extends State<_CreateDisbursementSheet> {
  static const _paymentMethods = [
    {'value': 'gcash', 'label': 'GCash'},
    {'value': 'bank_transfer', 'label': 'Bank Transfer'},
    {'value': 'cash', 'label': 'Cash'},
    {'value': 'check', 'label': 'Check'},
  ];

  late String _selectedPaymentMethod;
  late final TextEditingController _referenceController;
  late final TextEditingController _notesController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = 'gcash';
    _referenceController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '₱0';
    final rounded = amount.toInt();
    final chars = rounded.toString().split('');
    final buffer = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(chars[i]);
    }
    return '₱$buffer';
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('disbursements').insert({
        'application_id': widget.item.id,
        'scholarship_id': widget.item.scholarshipId,
        'recipient_id': widget.item.userId,
        'amount': widget.item.scholarshipAmount ?? 0,
        'status': 'pending',
        'payment_method': _selectedPaymentMethod,
        'reference_number': _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create disbursement: $e'),
            backgroundColor: kSeqError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final recipientName = widget.item.applicantName ?? 'Name not set';
    final scholarshipTitle = widget.item.scholarshipTitle ?? 'General Bursary';
    final amountFormatted = _formatAmount(widget.item.scholarshipAmount);

    return Container(
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: kSeqOutlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create Disbursement',
                  style: seqHeadlineSm(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Read-only pre-filled card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSeqSurfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kSeqOutlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  _readOnlyRow('Recipient', recipientName),
                  const SizedBox(height: 8),
                  _readOnlyRow('Scholarship', scholarshipTitle),
                  const SizedBox(height: 8),
                  _readOnlyRow('Amount', amountFormatted),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Payment Method Dropdown
            Text(
              'PAYMENT METHOD',
              style:
                  seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: kSeqSurfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kSeqOutlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPaymentMethod,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  items: _paymentMethods.map((pm) {
                    return DropdownMenuItem<String>(
                      value: pm['value'],
                      child: Text(
                        pm['label']!,
                        style: seqBodyMd(color: kSeqOnSurface),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPaymentMethod = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Reference Number
            Text(
              'REFERENCE NUMBER (OPTIONAL)',
              style:
                  seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                hintText: 'e.g. GC-2026-XXXX',
                hintStyle: seqBodySm(color: kSeqOutline),
                filled: true,
                fillColor: kSeqSurfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: kSeqOutlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: kSeqOutlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kSeqPrimary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Notes
            Text(
              'NOTES (OPTIONAL)',
              style:
                  seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add internal disbursement notes or instructions...',
                hintStyle: seqBodySm(color: kSeqOutline),
                filled: true,
                fillColor: kSeqSurfaceContainerLow,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: kSeqOutlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: kSeqOutlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kSeqPrimary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: kSeqPrimary,
                  foregroundColor: kSeqOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: seqLabelMd(
                    fontWeight: FontWeight.w700,
                    color: kSeqOnPrimary,
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm Disbursement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: seqLabelSm(color: kSeqOutline, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: seqBodySm(color: kSeqOnSurface, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

