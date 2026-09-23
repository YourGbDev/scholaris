// lib/preview_provider_main.dart
// Interactive preview harness and visual verification entrypoint for Scholaris Provider & Admin Consoles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:scholaris/features/admin/presentation/admin_analytics_provider.dart';
import 'package:scholaris/features/admin/presentation/admin_applicants_provider.dart';
import 'package:scholaris/features/admin/presentation/admin_audit_logs_provider.dart';
import 'package:scholaris/features/admin/presentation/admin_home_screen.dart';
import 'package:scholaris/features/admin/repositories/admin_audit_log_repository.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/provider/presentation/individual/individual_provider_shell.dart';
import 'package:scholaris/features/provider/presentation/org/org_provider_shell.dart';
import 'package:scholaris/features/provider/presentation/org/org_provider_theme.dart';
import 'package:scholaris/features/provider/presentation/widgets/applicant_review_drawer.dart';
import 'package:scholaris/features/provider/providers/provider_scholarships_provider.dart';
import 'package:scholaris/features/provider/providers/provider_type_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

class MockIncomingAppsNotifier extends IncomingApplicationsNotifier {
  MockIncomingAppsNotifier(this._apps);
  final List<Application> _apps;

  @override
  Future<List<Application>> build() async => _apps;
}

class MockProviderScholarshipsNotifier extends ProviderScholarshipsNotifier {
  MockProviderScholarshipsNotifier(this._list);
  final List<Scholarship> _list;

  @override
  Future<List<Scholarship>> build() async => _list;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(const ProviderPreviewApp());
}

class ProviderPreviewApp extends StatefulWidget {
  const ProviderPreviewApp({super.key});

  @override
  State<ProviderPreviewApp> createState() => _ProviderPreviewAppState();
}

class _ProviderPreviewAppState extends State<ProviderPreviewApp> {
  String _screen = 'org_incoming';

  @override
  void initState() {
    super.initState();
    final uri = Uri.base;
    final screenParam = uri.queryParameters['screen'];
    if (screenParam != null && screenParam.isNotEmpty) {
      _screen = screenParam;
    }
  }

  static final _mockOrgProfile = StudentProfile(
    id: 'org-metrobank-01',
    fullName: 'Metrobank Foundation Inc.',
    gender: 'female',
    school: 'Metrobank Plaza, Makati City',
    course: 'Institutional Provider',
    yearLevel: 4,
    gpa: 1.0,
    monthlyFamilyIncome: 1000000,
    region: 'NCR',
    cityMunicipality: 'Makati City',
    setupComplete: true,
  );

  static final _mockScholarships = [
    Scholarship(
      id: 'sch-mb-2026',
      title: 'Metrobank College Scholarship Program 2026-2027',
      provider: 'Metrobank Foundation Inc.',
      description: 'Full tuition subsidy, book allowance, and monthly stipend for deserving engineering and CS undergraduates in Region VI and NCR.',
      minGpa: 1.75,
      deadline: DateTime(2026, 11, 30),
      isActive: true,
      requiredCourses: ['BS Computer Science', 'BS Information Technology', 'BS Civil Engineering'],
      slots: 50,
      createdAt: DateTime(2026, 1, 15),
    ),
    Scholarship(
      id: 'sch-gt-2026',
      title: 'GT Foundation Excellence in STEM Grant',
      provider: 'GT Foundation & Metrobank',
      description: 'Merit-based grant honoring George Ty for STEM students demonstrating academic excellence and community leadership.',
      minGpa: 1.50,
      deadline: DateTime(2026, 12, 15),
      isActive: true,
      requiredCourses: ['BS Computer Science', 'BS Applied Mathematics'],
      slots: 25,
      createdAt: DateTime(2026, 2, 1),
    ),
    Scholarship(
      id: 'sch-mb-voc-2025',
      title: 'Metrobank Technical-Vocational Education Award',
      provider: 'Metrobank Foundation Inc.',
      description: 'Financial grant for technical training and certification students in accredited institutions.',
      minGpa: 2.00,
      deadline: DateTime(2026, 8, 30),
      isActive: false,
      slots: 20,
      createdAt: DateTime(2025, 6, 1),
    ),
  ];

  static final _mockMayaProfile = StudentProfile(
    id: 'student-maya-01',
    fullName: 'Maya Santos',
    gender: 'female',
    school: 'University of the Philippines Diliman',
    course: 'BS Computer Science',
    yearLevel: 3,
    gpa: 1.25,
    monthlyFamilyIncome: 28000,
    region: 'Western Visayas (Region VI)',
    cityMunicipality: 'Iloilo City',
    setupComplete: true,
  );

  static final _mockJoshuaProfile = StudentProfile(
    id: 'student-joshua-02',
    fullName: 'Joshua D. Reyes',
    gender: 'male',
    school: 'West Visayas State University',
    course: 'BS Information Technology',
    yearLevel: 2,
    gpa: 1.45,
    monthlyFamilyIncome: 22000,
    region: 'Western Visayas (Region VI)',
    cityMunicipality: 'Passi City',
    setupComplete: true,
  );

  static final _mockBeaProfile = StudentProfile(
    id: 'student-bea-03',
    fullName: 'Bea Bianca Cruz',
    gender: 'female',
    school: 'De La Salle University',
    course: 'BS Civil Engineering',
    yearLevel: 4,
    gpa: 1.60,
    monthlyFamilyIncome: 35000,
    region: 'National Capital Region (NCR)',
    cityMunicipality: 'Manila',
    setupComplete: true,
  );

  static final _mockApplications = [
    Application(
      id: 'app-maya-01',
      userId: 'student-maya-01',
      scholarshipId: 'sch-mb-2026',
      status: ApplicationStatus.submitted,
      appliedAt: DateTime.now().subtract(const Duration(days: 2)),
      notes: 'Applying for tuition assistance and research laptop grant. Dean’s Lister for 4 consecutive terms.',
    ),
    Application(
      id: 'app-joshua-02',
      userId: 'student-joshua-02',
      scholarshipId: 'sch-mb-2026',
      status: ApplicationStatus.underReview,
      appliedAt: DateTime.now().subtract(const Duration(days: 5)),
      notes: 'First generation college student seeking financial aid for final capstone project expenses.',
    ),
    Application(
      id: 'app-bea-03',
      userId: 'student-bea-03',
      scholarshipId: 'sch-gt-2026',
      status: ApplicationStatus.approved,
      appliedAt: DateTime.now().subtract(const Duration(days: 12)),
      notes: 'Endorsed by faculty chair for outstanding performance in structural engineering analytics.',
    ),
  ];

  static final _mockProfilesMap = {
    'student-maya-01': _mockMayaProfile,
    'student-joshua-02': _mockJoshuaProfile,
    'student-bea-03': _mockBeaProfile,
  };

  static final _mockAuditLogs = [
    AuditLog(
      id: 'log-01',
      actorEmail: 'admin@ched.gov.ph',
      actorRole: 'admin',
      action: 'scholarship_create',
      targetType: 'scholarships',
      targetId: 'sch-mb-2026',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AuditLog(
      id: 'log-02',
      actorEmail: 'evaluator@metrobank.org',
      actorRole: 'provider',
      action: 'status_transition_approved',
      targetType: 'applications',
      targetId: 'app-bea-03',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AuditLog(
      id: 'log-03',
      actorEmail: 'admin@ched.gov.ph',
      actorRole: 'admin',
      action: 'provider_verify',
      targetType: 'profiles',
      targetId: 'org-metrobank-01',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) => Future.value(_mockOrgProfile)),
        incomingApplicationsProvider.overrideWith(() => MockIncomingAppsNotifier(_mockApplications)),
        scholarshipsProvider.overrideWith((ref) => Future.value(_mockScholarships)),
        providerScholarshipsProvider.overrideWith(() => MockProviderScholarshipsNotifier(_mockScholarships)),
        providerApplicantProfilesProvider.overrideWith((ref) => Future.value(_mockProfilesMap)),
        adminApplicantsProvider.overrideWith((ref) => Future.value(_mockProfilesMap.values.toList())),
        adminAllApplicationsProvider.overrideWith((ref) => Future.value(_mockApplications)),
        adminAuditLogsProvider.overrideWith((ref) => Future.value(_mockAuditLogs)),
        activeProviderTypeProvider.overrideWith((ref) =>
          _screen.startsWith('individual') ? 'individual' : 'organization',
        ),
        providerTypeOverrideProvider.overrideWith((ref) =>
          _screen.startsWith('individual') ? 'individual' : 'organization',
        ),
      ],
      child: MaterialApp(
        title: 'Scholaris Console Preview',
        debugShowCheckedModeBanner: false,
        theme: scholarisTheme(),
        home: _buildScreenContent(),
      ),
    );
  }

  Widget _buildScreenContent() {
    switch (_screen) {
      // Organization Provider Console Screens
      case 'org_incoming':
        return const OrgProviderShell(initialTab: 0);
      case 'org_scholarships':
        return const OrgProviderShell(initialTab: 1);
      case 'org_analytics':
        return const OrgProviderShell(initialTab: 2);
      case 'org_disbursements':
        return const OrgProviderShell(initialTab: 3);
      case 'org_settings':
        return const OrgProviderShell(initialTab: 4);
      case 'org_review_drawer':
        return Scaffold(
          backgroundColor: const Color(0xFF161C27).withValues(alpha: 0.5),
          body: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 720,
              height: double.infinity,
              child: ApplicantReviewDrawer(
                application: _mockApplications[0],
                scholarship: _mockScholarships[0],
                applicantProfile: _mockMayaProfile,
              ),
            ),
          ),
        );

      // Individual Provider Benefactor Screens
      case 'individual_applications':
        return const IndividualProviderShell(initialIndex: 0);
      case 'individual_grant':
        return const IndividualProviderShell(initialIndex: 1);
      case 'individual_settings':
        return const IndividualProviderShell(initialIndex: 2);
      case 'individual_review_sheet':
        return Scaffold(
          backgroundColor: kOrgCanvas,
          body: ApplicantReviewDrawer(
            application: _mockApplications[0],
            scholarship: _mockScholarships[0],
            applicantProfile: _mockMayaProfile,
          ),
        );

      // Admin Console Screens
      case 'admin_overview':
        return const AdminHomeScreen(initialTab: 0);
      case 'admin_scholarships':
        return const AdminHomeScreen(initialTab: 1);
      case 'admin_providers':
        return const AdminHomeScreen(initialTab: 2);
      case 'admin_applicants':
        return const AdminHomeScreen(initialTab: 3);
      case 'admin_users':
        return const AdminHomeScreen(initialTab: 4);
      case 'admin_analytics':
        return const AdminHomeScreen(initialTab: 5);
      case 'admin_audit_logs':
        return const AdminHomeScreen(initialTab: 6);

      default:
        return const OrgProviderShell(initialTab: 0);
    }
  }
}
