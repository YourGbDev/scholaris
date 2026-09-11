import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/presentation/application_status_chip.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import 'admin_analytics_provider.dart';
import 'admin_applicants_provider.dart';
import 'admin_theme.dart';

class AdminApplicantsTab extends ConsumerStatefulWidget {
  const AdminApplicantsTab({super.key});

  @override
  ConsumerState<AdminApplicantsTab> createState() => _AdminApplicantsTabState();
}

class _AdminApplicantsTabState extends ConsumerState<AdminApplicantsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicantsAsync = ref.watch(adminApplicantsProvider);
    final searchQuery = ref.watch(adminApplicantSearchQueryProvider);
    final allApps = ref.watch(adminAllApplicationsProvider).valueOrNull ?? const <Application>[];
    final scholarships = ref.watch(scholarshipsProvider).valueOrNull ?? const <Scholarship>[];

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Directory',
                  style: adminHeaderStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kAdminNavyTrust,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inspect student applicant profiles and academic credentials across the platform.',
                  style: adminLabelStyle(
                    fontSize: 13,
                    color: kAdminTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    style: adminBodyStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by applicant name, course, school, or region...',
                      hintStyle: adminLabelStyle(
                        fontSize: 13,
                        color: kAdminTextSecondary.withValues(alpha: 0.7),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: kAdminTextSecondary,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: kAdminTextSecondary,
                              ),
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                ref.read(adminApplicantSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(
                        borderRadius: kAdminCardRadius,
                        borderSide: BorderSide(color: kAdminHairline, width: 1),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: kAdminCardRadius,
                        borderSide: BorderSide(color: kAdminHairline, width: 1),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: kAdminCardRadius,
                        borderSide: BorderSide(color: kAdminBridgeGreen, width: 1.5),
                      ),
                    ),
                    onChanged: (val) => ref
                        .read(adminApplicantSearchQueryProvider.notifier)
                        .state = val.trim().toLowerCase(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: applicantsAsync.when(
              loading: () => const LoadingView(),
              error: (_, _) => const ErrorView(
                message: 'Failed to load applicant directory.',
              ),
              data: (allApplicants) {
                var list = allApplicants;
                if (searchQuery.isNotEmpty) {
                  list = list.where((p) {
                    final nameMatch = p.fullName.toLowerCase().contains(searchQuery);
                    final courseMatch = p.course.toLowerCase().contains(searchQuery);
                    final schoolMatch = p.school?.toLowerCase().contains(searchQuery) ?? false;
                    final regionMatch = p.region.toLowerCase().contains(searchQuery);
                    return nameMatch || courseMatch || schoolMatch || regionMatch;
                  }).toList();
                }

                if (list.isEmpty) {
                  return const EmptyView(
                    icon: Icons.person_search_rounded,
                    title: 'No applicants found',
                    message: 'Try modifying your search query.',
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: kAdminTableRadius,
                      border: Border.all(color: kAdminHairline, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          color: const Color(0xFFF9FAFB),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Applicant / name',
                                  style: adminLabelStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminNavyTrust,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Course & school',
                                  style: adminLabelStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminNavyTrust,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Year',
                                  textAlign: TextAlign.right,
                                  style: adminLabelStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminNavyTrust,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'GPA',
                                  textAlign: TextAlign.right,
                                  style: adminLabelStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminNavyTrust,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Region',
                                  style: adminLabelStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminNavyTrust,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'Action',
                                  textAlign: TextAlign.center,
                                  style: adminLabelStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminNavyTrust,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: kAdminHairline),
                        // Table Rows
                        Expanded(
                          child: ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1, color: kAdminHairline),
                            itemBuilder: (context, i) {
                              final p = list[i];
                              final studentApps = allApps.where((a) => a.userId == p.id).toList();
                              final approvedApp = studentApps.where((a) => a.status == ApplicationStatus.approved).firstOrNull;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        p.fullName,
                                        style: adminHeaderStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kAdminNavyTrust,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            p.course,
                                            style: adminBodyStyle(
                                              fontSize: 13,
                                              color: kAdminNavyTrust,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (p.school != null && p.school!.isNotEmpty)
                                            Text(
                                              p.school!,
                                              style: adminLabelStyle(
                                                fontSize: 11,
                                                color: kAdminTextSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Yr ${p.yearLevel}',
                                        textAlign: TextAlign.right,
                                        style: adminDataMono(
                                          fontSize: 12,
                                          color: kAdminNavyTrust,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        p.gpa.toStringAsFixed(1),
                                        textAlign: TextAlign.right,
                                        style: adminDataMono(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: kAdminNavyTrust,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        p.region,
                                        style: adminBodyStyle(
                                          fontSize: 12,
                                          color: kAdminTextSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Center(
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              onPressed: () => _showApplicantDetails(context, p, studentApps, scholarships),
                                              child: Text(
                                                'Inspect',
                                                style: adminLabelStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: kAdminBridgeGreen,
                                                ),
                                              ),
                                            ),
                                            if (approvedApp != null)
                                              FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: kAdminBridgeGreen,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  shape: const RoundedRectangleBorder(borderRadius: kAdminCardRadius),
                                                ),
                                                onPressed: () => _onAwardTapped(context, p, approvedApp, scholarships),
                                                child: const Text(
                                                  'Award',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showApplicantDetails(
    BuildContext context,
    StudentProfile p, [
    List<Application> studentApps = const [],
    List<Scholarship> scholarships = const [],
  ]) {
    final apps = studentApps.isNotEmpty
        ? studentApps
        : (ref.read(adminAllApplicationsProvider).valueOrNull ?? const <Application>[])
            .where((a) => a.userId == p.id)
            .toList();
    final schs = scholarships.isNotEmpty
        ? scholarships
        : (ref.read(scholarshipsProvider).valueOrNull ?? const <Scholarship>[]);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: kAdminChromeRadius),
        title: Text(
          p.fullName,
          style: adminHeaderStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Nationality', p.nationality),
                _detailRow('Course', p.course),
                if (p.school != null) _detailRow('School', p.school!),
                _detailRow('Year level', 'Year ${p.yearLevel}'),
                _detailRow('Cumulative GPA', p.gpa.toStringAsFixed(2)),
                _detailRow('Region', p.region),
                if (p.province != null) _detailRow('Province', p.province!),
                if (p.cityMunicipality != null) _detailRow('City / municipality', p.cityMunicipality!),
                if (p.hasDisability) _detailRow('Disability (PWD)', 'Declared'),
                if (p.isIndigenous) _detailRow('Indigenous group', 'Declared'),
                if (apps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: kAdminHairline),
                  const SizedBox(height: 12),
                  Text(
                    'Scholarship applications',
                    style: adminHeaderStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  for (final app in apps) ...[
                    Builder(
                      builder: (cardContext) {
                        final schTitle = schs.where((s) => s.id == app.scholarshipId).firstOrNull?.title ?? 'Scholarship';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: kAdminCardRadius,
                            border: Border.all(color: kAdminHairline, width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      schTitle,
                                      style: adminHeaderStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (app.appliedAt != null)
                                      Text(
                                        'Applied ${_formatDate(app.appliedAt!)}',
                                        style: adminLabelStyle(fontSize: 11, color: kAdminTextSecondary),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ApplicationStatusChip(status: app.status),
                              if (app.status == ApplicationStatus.approved) ...[
                                const SizedBox(width: 8),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: kAdminBridgeGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: const RoundedRectangleBorder(borderRadius: kAdminCardRadius),
                                  ),
                                  onPressed: () async {
                                    Navigator.of(dialogContext).pop();
                                    await _onAwardTapped(context, p, app, schs);
                                  },
                                  child: const Text(
                                    'Confirm award',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Close',
              style: adminLabelStyle(fontSize: 13, color: kAdminNavyTrust),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAwardTapped(
    BuildContext context,
    StudentProfile p,
    Application app,
    List<Scholarship> scholarships,
  ) async {
    final schTitle = scholarships
            .where((s) => s.id == app.scholarshipId)
            .firstOrNull
            ?.title ??
        'this scholarship';
    final confirmed = await _confirmAward(
      context,
      applicantName: p.fullName,
      scholarshipTitle: schTitle,
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    try {
      await ref.read(applicationRepositoryProvider).confirmAward(app.id);
      ref.invalidate(adminAllApplicationsProvider);
      ref.invalidate(incomingApplicationsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scholarship awarded to ${p.fullName}.',
            style: adminBodyStyle(fontSize: 12, color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to award scholarship.',
            style: adminBodyStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<bool> _confirmAward(
    BuildContext context, {
    required String applicantName,
    required String scholarshipTitle,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: kAdminChromeRadius,
        ),
        title: Text(
          'Confirm Award',
          style: adminHeaderStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to officially award the "$scholarshipTitle" scholarship to $applicantName? This is the final step in the application lifecycle and marks the award as final.',
          style: adminBodyStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: adminLabelStyle(
                fontSize: 13,
                color: kAdminTextSecondary,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kAdminBridgeGreen,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: kAdminCardRadius,
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Confirm award',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: adminLabelStyle(fontSize: 12, color: kAdminTextSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: adminBodyStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kAdminNavyTrust),
            ),
          ),
        ],
      ),
    );
  }
}
