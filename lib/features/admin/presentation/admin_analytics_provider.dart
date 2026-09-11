import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';

import 'admin_applicants_provider.dart';

class AdminAnalyticsData {
  const AdminAnalyticsData({
    required this.totalApplications,
    required this.totalScholarships,
    required this.activeScholarships,
    required this.totalApplicants,
    required this.schoolCounts,
    required this.statusCounts,
    required this.regionCounts,
    required this.acceptanceRate,
  });

  final int totalApplications;
  final int totalScholarships;
  final int activeScholarships;
  final int totalApplicants;
  final Map<String, int> schoolCounts;
  final Map<ApplicationStatus, int> statusCounts;
  final Map<String, int> regionCounts;
  final double acceptanceRate;
}

final adminAllApplicationsProvider = FutureProvider<List<Application>>((ref) async {
  final repository = ref.watch(applicationRepositoryProvider);
  return repository.fetchAllApplications();
});

final adminAnalyticsDataProvider = FutureProvider<AdminAnalyticsData>((ref) async {
  final scholarships = await ref.watch(scholarshipsProvider.future);
  final applicants = await ref.watch(adminApplicantsProvider.future);
  final applications = await ref.watch(adminAllApplicationsProvider.future);

  final activeCount = scholarships.where((s) => s.isActive).length;

  final schoolCounts = <String, int>{};
  for (final applicant in applicants) {
    final school = applicant.school?.trim();
    if (school != null && school.isNotEmpty) {
      schoolCounts[school] = (schoolCounts[school] ?? 0) + 1;
    }
  }

  final statusCounts = <ApplicationStatus, int>{
    for (final s in ApplicationStatus.values) s: 0,
  };
  for (final app in applications) {
    statusCounts[app.status] = (statusCounts[app.status] ?? 0) + 1;
  }

  final regionCounts = <String, int>{};
  for (final applicant in applicants) {
    if (applicant.region.isNotEmpty) {
      regionCounts[applicant.region] = (regionCounts[applicant.region] ?? 0) + 1;
    }
  }

  final approvedCount = statusCounts[ApplicationStatus.approved] ?? 0;
  final totalApps = applications.length;
  final rate = totalApps > 0 ? (approvedCount / totalApps) * 100 : 0.0;

  return AdminAnalyticsData(
    totalApplications: totalApps,
    totalScholarships: scholarships.length,
    activeScholarships: activeCount,
    totalApplicants: applicants.length,
    schoolCounts: schoolCounts,
    statusCounts: statusCounts,
    regionCounts: regionCounts,
    acceptanceRate: rate,
  );
});
