// Local presentation review only. Every record/action below is fictional.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_theme.dart';

import '../../../admin/screens/platform_overview_screen.dart';
import '../../../features/admin/presentation/admin_analytics_provider.dart';
import '../../../features/admin/presentation/admin_home_screen.dart';
import '../../../features/applications/models/application.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/profile/models/student_profile.dart';
import '../../../features/profile/providers/profile_setup_provider.dart';
import '../../../features/provider/data/provider_verification_repository.dart';
import '../../../features/provider/models/provider_verification.dart';
import '../../../features/provider/providers/provider_verification_provider.dart';
import '../../../features/provider/repositories/support_concern_repository.dart';
import '../../../features/provider/repositories/support_repository.dart';
import '../../../features/safety/data/safety_report_repository.dart';
import '../../../features/safety/models/safety_report.dart';
import '../../../features/safety/presentation/student_safety_report.dart';
import '../../../features/scholarships/models/scholarship.dart';
import '../../../features/scholarships/providers/scholarships_provider.dart';
import '../provider_preview/fake_support_concerns.dart';
import '../provider_preview/fake_support_repository.dart';
import 'student_report_preview.dart';

void main() => runApp(buildAdminPreview());

Widget buildAdminPreview({bool errorPreview = false}) {
  final previewNavigator = GlobalKey<NavigatorState>();
  final errors = errorPreview || Uri.base.queryParameters['errors'] == 'true';
  final scale = double.tryParse(Uri.base.queryParameters['textScale'] ?? '')
      ?.clamp(1.0, 2.5);
  final concerns = PreviewSupportConcerns();
  final now = DateTime.now();
  concerns.rows.addAll([
    for (var n = 1; n <= 3; n++)
      {
        'id': 'report-$n',
        'application_id': 'application-$n',
        'reporter_id': 'student-$n',
        'category': n == 1 ? 'unsafe_request' : 'other',
        'description': n == 1
            ? 'Fictional example: a provider asked for a private meeting as a condition of receiving support.'
            : 'Fictional example: a friend raised a concern about this scholarship.',
        'relationship': n == 1 ? 'experienced' : 'told',
        'status': 'open',
        'created_at': now.subtract(Duration(hours: n)).toIso8601String(),
      },
    {
      'id': 'other-report',
      'application_id': 'org-application',
      'reporter_id': 'student-4',
      'category': 'release_fee',
      'description':
          'Fictional example: a student received a request to pay a fee.',
      'status': 'under_review',
      'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    },
    {
      'id': 'provider-correction',
      'application_id': 'application-1',
      'reporter_id': 'provider-1',
      'category': 'payment_record_correction',
      'description':
          'Fictional provider request to correct a payment reference.',
      'status': 'open',
      'payment_id': 'payment-1',
      'created_at': now.toIso8601String(),
    },
  ]);
  final programs = [
    Scholarship(
      id: 'individual-program',
      title: 'Bright Futures Scholarship',
      provider: 'Elena Reyes',
      createdBy: 'provider-1',
      minGpa: 2,
      deadline: now.add(const Duration(days: 60)),
      amount: 30000,
    ),
    Scholarship(
      id: 'org-program',
      title: 'Bukas Access Award',
      provider: 'Bukas Foundation',
      createdBy: 'provider-2',
      minGpa: 2,
      deadline: now.add(const Duration(days: 40)),
      amount: 50000,
    ),
  ];
  final applications = [
    for (var n = 1; n <= 3; n++)
      Application(
        id: 'application-$n',
        userId: 'student-$n',
        scholarshipId: 'individual-program',
        status: ApplicationStatus.submitted,
      ),
    const Application(
      id: 'org-application',
      userId: 'student-4',
      scholarshipId: 'org-program',
      status: ApplicationStatus.approved,
    ),
  ];
  final verification = PreviewProviderReviews(errors: errors);
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('preview-admin'),
      currentProfileProvider.overrideWith(
        (ref) async => const StudentProfile(
          id: 'preview-admin',
          fullName: 'Platform owner',
          role: 'admin',
          setupComplete: true,
        ),
      ),
      providerVerificationRepositoryProvider.overrideWithValue(verification),
      supportConcernRepositoryProvider.overrideWithValue(concerns),
      safetyReportRepositoryProvider.overrideWithValue(
        PreviewSafetyReportRepository(errors: errors),
      ),
      supportConcernsProvider(null).overrideWith((ref) async {
        if (errors) throw StateError('Fictional queue failure');
        return concerns.load(null);
      }),
      supportRepositoryProvider.overrideWithValue(PreviewSupportRepository()),
      adminAllApplicationsProvider.overrideWith((ref) async => applications),
      scholarshipsProvider.overrideWith((ref) async => programs),
      platformOverviewDataProvider.overrideWith(
        (ref) async => const PlatformOverviewData(
          registeredUsers: 6,
          activeScholarships: 2,
          totalScholarshipValue: 80000,
          applications: 4,
          providerVerifications: 3,
          auditEvents: 0,
          loginAttempts: 0,
          bookmarks: 0,
        ),
      ),
    ],
    child: MaterialApp(
      navigatorKey: previewNavigator,
      debugShowCheckedModeBanner: false,
      theme: scholarisTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: scale == null ? null : TextScaler.linear(scale),
          disableAnimations: Uri.base.queryParameters['reducedMotion'] == 'true'
              ? true
              : null,
        ),
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Column(
            children: [
              Material(
                color: const Color(0xFFFFF3D8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: [
                      const Text(
                        'LOCAL UI PREVIEW · Fictional records · No backend connection',
                      ),
                      Consumer(
                        builder: (context, ref, _) => TextButton(
                          onPressed: () => showStudentReportPreview(
                            previewNavigator.currentState!.overlay!.context,
                            onAdd: (row) {
                              concerns.rows.add({
                                ...row,
                                'id': 'preview-${concerns.rows.length}',
                                'application_id': 'application-1',
                                'reporter_id': 'preview-friend',
                                'created_at': DateTime.now().toIso8601String(),
                                'status': 'open',
                              });
                              ref.invalidate(supportConcernsProvider(null));
                            },
                          ),
                          child: const Text('Preview student report'),
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, _) => TextButton(
                          onPressed: () {
                            showDialog<bool>(
                              context: previewNavigator.currentState!.overlay!.context,
                              builder: (ctx) => const StudentSafetyReportDialog(
                                scholarshipId: 'individual-program',
                                scholarshipTitle: 'Bright Futures Scholarship',
                              ),
                            );
                          },
                          child: const Text('Live safety report dialog'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: child!),
            ],
          ),
        ),
      ),
      home: const AdminHomeScreen(),
    ),
  );
}

class PreviewProviderReviews extends ProviderVerificationRepository {
  PreviewProviderReviews({this.errors = false})
    : super(
        client: SupabaseClient(
          'https://preview.invalid',
          'fictional-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  final bool errors;
  final records = [
    ProviderVerification(
      userId: 'provider-2',
      providerType: 'organization',
      orgName: 'Bukas Foundation',
      orgType: 'Foundation',
      repName: 'Mika Santos',
      repEmail: 'mika@example.com',
      submittedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ProviderVerification(
      userId: 'provider-1',
      providerType: 'individual',
      fullName: 'Elena Reyes',
      email: 'elena@example.com',
      sourceOfFunds: 'Personal income (self-reported)',
      monthlyGivingBudget: '30000',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ProviderVerification(
      userId: 'approved-provider',
      providerType: 'individual',
      fullName: 'Marco Cruz',
      status: 'approved',
      reviewNote: 'Fictional reviewed application.',
      submittedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];
  @override
  Future<List<ProviderVerification>> fetchAllVerifications() async {
    if (errors) throw StateError('Fictional provider failure');
    return List.of(records);
  }

  @override
  Future<ProviderVerification> updateVerificationStatus({
    required String userId,
    required String status,
    required String adminId,
    String? expectedStatus,
    String? reviewNote,
  }) async {
    final i = records.indexWhere((v) => v.userId == userId);
    if (i < 0) throw StateError('Preview record unavailable');
    records[i] = records[i].copyWith(
      status: status,
      reviewedBy: adminId,
      reviewedAt: DateTime.now(),
      reviewNote: reviewNote,
    );
    return records[i];
  }

  @override
  Future<ProviderVerification> reviewVerification({
    required String userId,
    required String status,
    String? expectedStatus,
    String? reviewNote,
  }) async {
    return updateVerificationStatus(
      userId: userId,
      status: status,
      adminId: 'preview-admin',
      expectedStatus: expectedStatus,
      reviewNote: reviewNote,
    );
  }
}

class PreviewSafetyReportRepository extends SafetyReportRepository {
  PreviewSafetyReportRepository({this.errors = false})
      : super(
          client: SupabaseClient(
            'https://preview.invalid',
            'fictional-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );
  final bool errors;
  final List<SafetyReport> reports = [
    SafetyReport(
      id: 'preview-report-1',
      scholarshipId: 'individual-program',
      providerId: 'provider-1',
      reporterId: 'preview-admin',
      category: 'fraud',
      relationship: 'experienced',
      description: 'Fictional safety report for testing in-memory preview dialog.',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      scholarshipTitle: 'Bright Futures Scholarship',
      evidence: [],
    ),
  ];

  @override
  Future<String> submitReport({
    required String scholarshipId,
    required String category,
    required String relationship,
    required String description,
    DateTime? incidentOn,
  }) async {
    if (errors) throw StateError('Fictional report submission failure');
    final id = 'preview-report-${reports.length + 1}';
    reports.insert(
      0,
      SafetyReport(
        id: id,
        scholarshipId: scholarshipId,
        providerId: 'provider-1',
        reporterId: 'preview-admin',
        category: category,
        relationship: relationship,
        description: description,
        incidentOn: incidentOn,
        status: 'open',
        createdAt: DateTime.now(),
        scholarshipTitle: 'Bright Futures Scholarship',
        evidence: [],
      ),
    );
    return id;
  }

  @override
  Future<String> attachEvidence({
    required String reportId,
    required Uint8List bytes,
    required String fileName,
    String? userId,
    String? attachmentKey,
  }) async {
    if (errors) throw StateError('Fictional attachment failure');
    final ext = fileName.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'pdf', 'webp'].contains(ext)) {
      throw const FormatException('Only JPG, PNG, WEBP, and PDF files are supported for evidence.');
    }
    final evidId = 'preview-evid-${DateTime.now().millisecondsSinceEpoch}';
    final i = reports.indexWhere((r) => r.id == reportId);
    if (i >= 0) {
      final updatedEvidence = List<SafetyReportEvidence>.from(reports[i].evidence)
        ..add(SafetyReportEvidence(
          id: evidId,
          reportId: reportId,
          filePath: '${userId ?? "preview-admin"}/$reportId/$fileName',
          fileName: fileName,
          fileSizeBytes: bytes.length,
          mimeType: ext == 'pdf' ? 'application/pdf' : 'image/$ext',
          uploadedAt: DateTime.now(),
        ));
      reports[i] = reports[i].copyWith(evidence: updatedEvidence);
    }
    return evidId;
  }

  @override
  Future<List<SafetyReport>> fetchReportsForStudent(String studentId) async {
    if (errors) throw StateError('Fictional safety report fetch failure');
    return reports.where((r) => r.reporterId == studentId).toList();
  }

  @override
  Future<List<SafetyReport>> fetchAllReportsForAdmin() async {
    if (errors) throw StateError('Fictional safety reports failure');
    return List.of(reports);
  }
}
