import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/provider/presentation/provider_incoming_applications.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_scholarship_data_source.dart';

/// NOTE: This file models the intended RLS behavior for fast local regression checks — not a substitute for live policy verification.
///
/// An in-memory data source that models Supabase Row-Level Security:
///
/// 1. `Profiles are selectable by owner`:
///    `auth.uid() = id` (migration 0001)
/// 2. `Providers can select profiles of applicants to their own scholarships`:
///    `exists (select 1 from applications a join scholarships s on s.id = a.scholarship_id
///             where a.user_id = profiles.id and s.created_by = auth.uid())` (migration 0007)
class RlsEnforcingProfileDataSource implements ProfileDataSource {
  RlsEnforcingProfileDataSource({
    required this.currentUserId,
    required this.applicationDataSource,
  });

  final String? Function() currentUserId;
  final RlsEnforcingApplicationDataSource applicationDataSource;

  final Map<String, Map<String, dynamic>> rawProfiles = {};

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final callerId = currentUserId();
    if (callerId == null) return null;

    final profileRow = rawProfiles[userId];
    if (profileRow == null) return null;

    // Rule 1: Owner access (auth.uid() = id)
    if (callerId == userId) {
      return Map<String, dynamic>.of(profileRow);
    }

    // Rule 2: Provider access (migration 0007)
    // Checks if an application exists linking this user to a scholarship owned by callerId
    final hasApplicationToCallerScholarship = applicationDataSource.hasApplicationForProvider(
      applicantUserId: userId,
      providerId: callerId,
    );

    if (hasApplicationToCallerScholarship) {
      return Map<String, dynamic>.of(profileRow);
    }

    // RLS denies select: returns null (0 rows returned by PostgreSQL)
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllProfiles() async {
    final callerId = currentUserId();
    if (callerId == null) return const [];
    final results = <Map<String, dynamic>>[];
    for (final entry in rawProfiles.entries) {
      final profile = await fetchProfile(entry.key);
      if (profile != null) results.add(profile);
    }
    return results;
  }

  @override
  Future<void> upsertProfile(String userId, Map<String, dynamic> row) async {
    rawProfiles[userId] = {...rawProfiles[userId] ?? const {}, ...row};
  }
}

/// An in-memory application data source that faithfully enforces Supabase Row-Level Security:
///
/// 1. `Applications are selectable by owner`:
///    `auth.uid() = user_id` (migration 0001)
/// 2. `Providers can select applications to their own scholarships`:
///    `exists (select 1 from scholarships s where s.id = applications.scholarship_id
///             and s.created_by = auth.uid())` (migration 0005)
class RlsEnforcingApplicationDataSource implements ApplicationDataSource {
  RlsEnforcingApplicationDataSource({
    required this.currentUserId,
  });

  final String? Function() currentUserId;

  final Map<String, Map<String, dynamic>> rawScholarships = {};
  final List<Map<String, dynamic>> rawApplications = [];

  bool hasApplicationForProvider({
    required String applicantUserId,
    required String providerId,
  }) {
    for (final app in rawApplications) {
      if (app['user_id'] == applicantUserId) {
        final schId = app['scholarship_id'];
        final scholarship = rawScholarships[schId];
        if (scholarship != null && scholarship['created_by'] == providerId) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchApplications(String userId) async {
    final callerId = currentUserId();
    if (callerId == null || callerId != userId) return const [];
    return [
      for (final a in rawApplications)
        if (a['user_id'] == userId) Map<String, dynamic>.of(a),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllApplications() async {
    final callerId = currentUserId();
    if (callerId == null) return const [];
    final results = <Map<String, dynamic>>[];
    for (final app in rawApplications) {
      final isOwner = app['user_id'] == callerId;
      final sch = rawScholarships[app['scholarship_id']];
      final isProvider = sch != null && sch['created_by'] == callerId;
      if (isOwner || isProvider) {
        results.add(Map<String, dynamic>.of(app));
      }
    }
    return results;
  }

  @override
  Future<List<String>> fetchProviderScholarshipIds(String providerId) async {
    final callerId = currentUserId();
    if (callerId == null || callerId != providerId) return const [];
    return [
      for (final s in rawScholarships.values)
        if (s['created_by'] == providerId && s['id'] is String) s['id'] as String,
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchApplicationsForScholarships(
    List<String> scholarshipIds,
  ) async {
    final callerId = currentUserId();
    if (callerId == null) return const [];

    // Enforce migration 0005: provider can only select applications for scholarships
    // where s.created_by = auth.uid()
    final allowedScholarshipIds = scholarshipIds.where((id) {
      final s = rawScholarships[id];
      return s != null && s['created_by'] == callerId;
    }).toSet();

    return [
      for (final a in rawApplications)
        if (allowedScholarshipIds.contains(a['scholarship_id']))
          Map<String, dynamic>.of(a),
    ];
  }

  @override
  Future<Map<String, dynamic>?> fetchApplicationByScholarship(
    String userId,
    String scholarshipId,
  ) async {
    final callerId = currentUserId();
    if (callerId == null) return null;
    final sch = rawScholarships[scholarshipId];
    final isOwner = callerId == userId;
    final isProvider = sch != null && sch['created_by'] == callerId;
    if (!isOwner && !isProvider) return null;

    for (final a in rawApplications) {
      if (a['user_id'] == userId && a['scholarship_id'] == scholarshipId) {
        return Map<String, dynamic>.of(a);
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> fetchApplication(
    String userId,
    String applicationId,
  ) async {
    final callerId = currentUserId();
    if (callerId == null) return null;

    for (final a in rawApplications) {
      if (a['id'] == applicationId) {
        final sch = rawScholarships[a['scholarship_id']];
        final isOwner = callerId == userId;
        final isProvider = sch != null && sch['created_by'] == callerId;
        if (isOwner || isProvider) {
          return Map<String, dynamic>.of(a);
        }
        return null;
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> insertApplication(
    String userId,
    Map<String, dynamic> row,
  ) async {
    final created = {...row, 'id': 'app-${rawApplications.length + 1}'};
    rawApplications.add(created);
    return Map<String, dynamic>.of(created);
  }

  @override
  Future<void> updateApplication(
    String userId,
    String applicationId,
    Map<String, dynamic> row,
  ) async {
    final i = rawApplications.indexWhere((a) => a['id'] == applicationId);
    if (i != -1) {
      rawApplications[i] = {...rawApplications[i], ...row};
    }
  }
}

void main() {
  const providerAId = 'provider-a-1111';
  const providerBId = 'provider-b-2222';

  const scholarshipAId = 'sch-provider-a';
  const scholarshipBId = 'sch-provider-b';

  const applicantXId = 'student-applicant-x';
  const applicantYId = 'student-applicant-y';

  late String? activeAuthUserId;
  late RlsEnforcingApplicationDataSource appDataSource;
  late RlsEnforcingProfileDataSource profileDataSource;
  late ApplicationRepository appRepo;
  late ProfileRepository profileRepo;

  setUp(() {
    activeAuthUserId = providerAId;

    appDataSource = RlsEnforcingApplicationDataSource(
      currentUserId: () => activeAuthUserId,
    );

    profileDataSource = RlsEnforcingProfileDataSource(
      currentUserId: () => activeAuthUserId,
      applicationDataSource: appDataSource,
    );

    appRepo = ApplicationRepository(
      dataSource: appDataSource,
      currentUserId: () => activeAuthUserId,
    );

    profileRepo = ProfileRepository(
      dataSource: profileDataSource,
      currentUserId: () => activeAuthUserId,
    );

    // Seed Scholarships:
    // Scholarship A is owned by Provider A
    appDataSource.rawScholarships[scholarshipAId] = {
      'id': scholarshipAId,
      'title': 'Provider A STEM Scholarship',
      'created_by': providerAId,
    };

    // Scholarship B is owned by Provider B
    appDataSource.rawScholarships[scholarshipBId] = {
      'id': scholarshipBId,
      'title': 'Provider B Arts Scholarship',
      'created_by': providerBId,
    };

    // Seed Profiles:
    // Applicant X: ONLY applied to Provider B
    profileDataSource.rawProfiles[applicantXId] = {
      'id': applicantXId,
      'full_name': 'Applicant X Confidentials',
      'gpa': 3.95,
      'year_level': 3,
      'course': 'BS Computer Science',
      'school': 'University of the Philippines',
      'region': 'NCR',
      'nationality': 'Filipino',
      'setup_complete': true,
    };

    // Applicant Y: Applied to Provider A
    profileDataSource.rawProfiles[applicantYId] = {
      'id': applicantYId,
      'full_name': 'Applicant Y Dela Cruz',
      'gpa': 3.20,
      'year_level': 2,
      'course': 'BS Nursing',
      'school': 'UST',
      'region': 'Region III',
      'nationality': 'Filipino',
      'setup_complete': true,
    };

    // Seed Applications:
    // Applicant X applied ONLY to Provider B's scholarship (with confidential note)
    appDataSource.rawApplications.add({
      'id': 'app-x-to-b',
      'user_id': applicantXId,
      'scholarship_id': scholarshipBId,
      'status': 'submitted',
      'notes': 'Confidential financial emergency note strictly for Provider B.',
      'applied_at': DateTime.now().toUtc().toIso8601String(),
    });

    // Applicant Y applied to Provider A's scholarship
    appDataSource.rawApplications.add({
      'id': 'app-y-to-a',
      'user_id': applicantYId,
      'scholarship_id': scholarshipAId,
      'status': 'submitted',
      'notes': 'Note for Provider A review.',
      'applied_at': DateTime.now().toUtc().toIso8601String(),
    });
  });

  group('RLS Scoping Proof: Cross-Provider Applicant Data Isolation', () {
    test('Provider A CANNOT fetch applications or confidential notes for an applicant who only applied to Provider B', () async {
      activeAuthUserId = providerAId;

      final incoming = await appRepo.fetchIncomingApplications();

      // Provider A only receives applications to their own scholarship (scholarshipAId)
      expect(incoming.length, 1);
      expect(incoming.first.scholarshipId, scholarshipAId);
      expect(incoming.first.userId, applicantYId);
      expect(incoming.first.notes, 'Note for Provider A review.');

      // Proved: Applicant X's application and note are completely absent
      final hasApplicantX = incoming.any((a) => a.userId == applicantXId);
      expect(hasApplicantX, isFalse);

      final hasConfidentialNote = incoming.any(
        (a) => a.notes != null && a.notes!.contains('Confidential financial emergency note'),
      );
      expect(hasConfidentialNote, isFalse);
    });

    test('Provider A CANNOT fetch profile data (GPA, Region, Nationality) of an applicant who only applied to Provider B', () async {
      activeAuthUserId = providerAId;

      // Provider A attempts to query Applicant X's profile directly by ID
      final profileX = await profileRepo.fetchProfileById(applicantXId);

      // PROOF: Under RLS policy `providers_select_applicant_profiles` (migration 0007),
      // the subquery exists(select 1 from applications join scholarships where created_by = auth.uid())
      // evaluates to FALSE because Applicant X only applied to Provider B.
      // Therefore, the database returns 0 rows (null), preventing ANY data leakage.
      expect(profileX, isNull, reason: 'RLS must deny Provider A access to Applicant X profile');

      // Conversely, Provider A CAN legitimately fetch Applicant Y's profile (applied to Provider A)
      final profileY = await profileRepo.fetchProfileById(applicantYId);
      expect(profileY, isNotNull);
      expect(profileY!.fullName, 'Applicant Y Dela Cruz');
      expect(profileY.gpa, 3.20);
      expect(profileY.region, 'Region III');
      expect(profileY.nationality, 'Filipino');
    });

    test('Provider B CAN fetch Applicant X profile and application, but CANNOT see Applicant Y', () async {
      // Switch active auth session to Provider B
      activeAuthUserId = providerBId;

      final incomingB = await appRepo.fetchIncomingApplications();
      expect(incomingB.length, 1);
      expect(incomingB.first.scholarshipId, scholarshipBId);
      expect(incomingB.first.userId, applicantXId);
      expect(incomingB.first.notes, 'Confidential financial emergency note strictly for Provider B.');

      // Provider B can fetch Applicant X's profile
      final profileX = await profileRepo.fetchProfileById(applicantXId);
      expect(profileX, isNotNull);
      expect(profileX!.fullName, 'Applicant X Confidentials');
      expect(profileX.gpa, 3.95);
      expect(profileX.region, 'NCR');
      expect(profileX.nationality, 'Filipino');

      // Provider B CANNOT fetch Applicant Y's profile (RLS blocks it)
      final profileY = await profileRepo.fetchProfileById(applicantYId);
      expect(profileY, isNull, reason: 'RLS must deny Provider B access to Applicant Y profile');
    });

    testWidgets('Provider A UI console never displays Applicant X credentials or notes in presentation layer', (tester) async {
      activeAuthUserId = providerAId;

      final scholarshipsDS = FakeScholarshipDataSource([
        {
          ...FakeScholarshipDataSource.defaultRows.first,
          'id': scholarshipAId,
          'title': 'Provider A STEM Scholarship',
          'created_by': providerAId,
        },
        {
          ...FakeScholarshipDataSource.defaultRows.first,
          'id': scholarshipBId,
          'title': 'Provider B Arts Scholarship',
          'created_by': providerBId,
        },
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(providerAId),
            applicationRepositoryProvider.overrideWithValue(appRepo),
            profileRepositoryProvider.overrideWithValue(profileRepo),
            scholarshipRepositoryProvider.overrideWith(
              (ref) => ScholarshipRepository(dataSource: scholarshipsDS),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProviderIncomingApplications()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Provider A's queue summary bar
      expect(find.text('1 Total'), findsOneWidget);
      expect(find.text('1 Pending'), findsOneWidget);

      // Applicant Y is present
      expect(find.text('Applicant Y Dela Cruz'), findsOneWidget);
      expect(find.text('Provider A STEM Scholarship'), findsOneWidget);

      // Applicant X is completely absent from Provider A's console
      expect(find.text('Applicant X Confidentials'), findsNothing);
      expect(find.text('Provider B Arts Scholarship'), findsNothing);
      expect(find.textContaining('Confidential financial emergency note'), findsNothing);

      // Tap Applicant Y to open bottom sheet credentials
      await tester.tap(find.text('Provider A STEM Scholarship'));
      await tester.pumpAndSettle();

      // Applicant Y credentials are visible
      expect(find.text('Year 2 · GPA 3.2'), findsOneWidget);
      expect(find.text('Region III'), findsOneWidget);
      expect(find.text('Note for Provider A review.'), findsOneWidget);

      // Applicant X credentials (GPA 3.95, NCR, confidential note) are nowhere in the tree
      expect(find.text('Year 3 · GPA 4.0'), findsNothing);
      expect(find.text('Year 3 · GPA 3.9'), findsNothing);
      expect(find.text('NCR'), findsNothing);
      expect(find.textContaining('strictly for Provider B'), findsNothing);
    });
  });
}
