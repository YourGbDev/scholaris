import 'package:scholaris/features/applications/providers/application_document_provider.dart';
import 'package:scholaris/features/applications/models/application_document.dart';
import 'package:scholaris/features/provider/repositories/support_concern_repository.dart';
import 'package:scholaris/admin/screens/support_concerns_screen.dart';

import 'fake_support_concerns.dart';

import 'package:scholaris/features/provider/repositories/support_repository.dart';

import 'fake_support_repository.dart';

// Local UI review only. Fictional fixtures; no Supabase connection.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/provider/presentation/org/org_provider_shell.dart';
import 'package:scholaris/features/provider/providers/provider_sub_role_provider.dart';
import 'package:scholaris/features/provider/providers/provider_type_provider.dart';
import 'package:scholaris/features/provider/providers/organization_team_provider.dart';
import 'package:scholaris/features/provider/providers/organization_activity_provider.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'package:scholaris/dev/provider_preview/fake_application_data_source.dart';
import 'package:scholaris/dev/provider_preview/fake_profile_data_source.dart';
import 'package:scholaris/dev/provider_preview/fake_scholarship_data_source.dart';

import 'package:scholaris/features/provider/presentation/individual/individual_provider_shell.dart';

void main() => runApp(buildApp());
Widget buildApp({bool? individualPreview}) {
  final individual =
      individualPreview ?? (Uri.base.queryParameters['type'] == 'individual');
  // Browser-only accessibility/error probes; this entry point uses fictional data.
  final probe = individualPreview == null
      ? Uri.base.queryParameters
      : <String, String>{};
  final textScale = double.tryParse(probe['textScale'] ?? '')?.clamp(1.0, 2.5);
  final support = PreviewSupportRepository();
  final concerns = PreviewSupportConcerns();
  final showAdminSupport =
      individualPreview == null &&
      Uri.base.queryParameters['type'] == 'admin-support';
  if (showAdminSupport) {
    concerns.report(
      'app-1',
      'unsafe_request',
      'Fictional preview report: a student received a request for a private meeting.',
    );
  }
  final fakeProfileDs = FakeProfileDataSource();
  fakeProfileDs.rows['prov-1'] = {
    'id': 'prov-1',
    'email': 'ayala.provider@scholaris.ph',
    'full_name': individual ? 'Elena Reyes' : 'Bukas Foundation',
    'role': 'provider',
    'status': 'active',
    'setup_complete': true,
    'region': 'NCR',
    'provider_type': individual ? 'individual' : 'organization',
  };
  fakeProfileDs.rows['stud-1'] = {
    'id': 'stud-1',
    'email': 'sofia@example.com',
    'full_name': 'Sofia Cruz',
    'role': 'student',
    'status': 'active',
    'setup_complete': true,
    'school': 'University of Santo Tomas',
    'course': 'BS Nursing',
    'gpa': 1.30,
    'year_level': 3,
    'region': 'NCR',
  };

  final fakeAppDs = _PreviewApplications(support);
  fakeAppDs.scholarshipIndex['sch-1'] = {
    'id': 'sch-1',
    'title': 'Next Chapter Scholarship',
    'created_by': 'prov-1',
    'award_amount': 50000,
  };
  fakeAppDs.insertApplication('stud-1', {
    'user_id': 'stud-1',
    'scholarship_id': 'sch-1',
    'status': 'submitted',
  });

  final fakeScholDs = FakeScholarshipDataSource([
    {
      'id': 'sch-1',
      'title': 'Next Chapter Scholarship',
      'description': 'Test description',
      'min_gpa': 2.0,
      'amount': 50000,
      'award_amount': 50000,
      'deadline': '2026-12-31T00:00:00Z',
      'tags': ['STEM'],
      'is_active': true,
      'created_by': 'prov-1',
    },
  ]);

  return ProviderScope(
    overrides: [
      applicationDocumentsProvider.overrideWith(
        _PreviewApplicationDocuments.new,
      ),
      supportConcernRepositoryProvider.overrideWithValue(concerns),
      supportRepositoryProvider.overrideWithValue(support),
      currentProviderTypeProvider.overrideWith(
        (ref) async => individual ? 'individual' : 'organization',
      ),
      organizationRosterProvider.overrideWith((ref) async {
        if (probe['errors'] == 'true') {
          throw StateError('Fictional roster failure');
        }
        return [];
      }),
      organizationActivityLogsProvider.overrideWith((ref) async {
        if (probe['errors'] == 'true') {
          throw StateError('Fictional activity failure');
        }
        return [];
      }),
      organizationMembershipProvider.overrideWith(
        (ref) async => individual
            ? null
            : {
                'user_id': 'prov-1',
                'organization_id': 'prov-1',
                'role': 'org_admin',
              },
      ),
      currentUserIdProvider.overrideWithValue('prov-1'),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileRepository(
          dataSource: fakeProfileDs,
          currentUserId: () => 'prov-1',
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) => ScholarshipRepository(dataSource: fakeScholDs),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: fakeAppDs,
          currentUserId: () => 'prov-1',
        ),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: textScale == null ? null : TextScaler.linear(textScale),
          disableAnimations: probe['reducedMotion'] == 'true' ? true : null,
        ),
        child: child!,
      ),
      theme: ThemeData(
        fontFamily: 'Geist',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F4D2E)),
      ),
      home: showAdminSupport
          ? const Scaffold(body: SupportConcernsScreen())
          : individual
          ? const IndividualProviderShell()
          : const OrgProviderShell(),
    ),
  );
}

class _PreviewApplications extends FakeApplicationDataSource {
  _PreviewApplications(this.support);
  final PreviewSupportRepository support;
  @override
  Future<Map<String, dynamic>> reviewApplication(
    Map<String, dynamic> params,
  ) async {
    final rows = await fetchAllApplications();
    final app = rows.firstWhere((a) => a['id'] == params['p_application_id']);
    if (app['status'] != params['p_expected_status']) {
      throw StateError('Application changed');
    }
    final action = params['p_action'];
    final status = action == 'approve'
        ? 'approved'
        : action == 'reject'
        ? 'rejected'
        : 'under_review';
    await updateApplicationStatus(app['id'] as String, status);
    if (action == 'approve') {
      await support.recordCommitment(app['id'] as String, 5000000);
    }
    return {...app, 'status': status};
  }
}

class _PreviewApplicationDocuments extends ApplicationDocumentsNotifier {
  @override
  Future<List<ApplicationDocument>> build(String arg) async => [];
}
