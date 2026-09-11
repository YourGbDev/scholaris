import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

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
                                flex: 4,
                                child: Text(
                                  'Applicant / Name',
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
                                  'Course & School',
                                  style: adminLabelStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminNavyTrust,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
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
                                flex: 2,
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
                                flex: 3,
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
                                flex: 2,
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
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
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
                                      flex: 4,
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
                                      flex: 2,
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
                                      flex: 2,
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
                                      flex: 3,
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
                                      flex: 2,
                                      child: Center(
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          onPressed: () => _showApplicantDetails(context, p),
                                          child: Text(
                                            'Inspect',
                                            style: adminLabelStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: kAdminBridgeGreen,
                                            ),
                                          ),
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

  void _showApplicantDetails(BuildContext context, StudentProfile p) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Nationality', p.nationality),
              _detailRow('Course', p.course),
              if (p.school != null) _detailRow('School', p.school!),
              _detailRow('Year Level', 'Year ${p.yearLevel}'),
              _detailRow('Cumulative GPA', p.gpa.toStringAsFixed(2)),
              _detailRow('Region', p.region),
              if (p.province != null) _detailRow('Province', p.province!),
              if (p.cityMunicipality != null) _detailRow('City / Municipality', p.cityMunicipality!),
              if (p.hasDisability) _detailRow('Disability (PWD)', 'Declared'),
              if (p.isIndigenous) _detailRow('Indigenous Group', 'Declared'),
            ],
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
