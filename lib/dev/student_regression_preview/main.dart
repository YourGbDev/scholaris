// Local-only visual fixture. Run this target explicitly; no Supabase connection.
// ?width=360&height=800&scale=1&tab=0&state=populated
// States: populated, empty, loading, error. Tabs: 0–3.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scholaris/features/applications/presentation/application_detail_screen.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/dashboard/presentation/widgets/student_notifications_sheet.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:scholaris/features/scholarships/screens/saved_screen.dart';
import 'package:scholaris/main.dart' show ScholarisSmoothScrollBehavior;
import 'package:scholaris/shared/theme/app_theme.dart';

import '../provider_preview/fake_application_data_source.dart';
import '../provider_preview/fake_profile_data_source.dart';
import '../provider_preview/fake_scholarship_data_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final params = Uri.base.queryParameters;
  final state = params['state'] ?? 'populated';
  const user = 'local-preview-student';
  final profiles = FakeProfileDataSource();
  await profiles.upsertProfile(
    user,
    const StudentProfile(
      id: user,
      fullName: 'Maria Santos',
      nationality: 'Filipino',
      region: 'NCR',
      school: 'University of the Philippines Diliman',
      course: 'Bachelor of Science in Computer Science',
      yearLevel: 3,
      gpa: 3.5,
      monthlyFamilyIncome: 15000,
      setupComplete: true,
    ).toDbRow(),
  );
  final applications = FakeApplicationDataSource();
  if (state != 'empty') {
    for (final entry in [
      ('sch-dost', 'submitted'),
      ('sch-ched', 'withdrawn'),
    ]) {
      await applications.insertApplication(user, {
        'user_id': user,
        'scholarship_id': entry.$1,
        'status': entry.$2,
        'applied_at': DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
      });
    }
  }
  final rows = state == 'empty'
      ? <Map<String, dynamic>>[]
      : FakeScholarshipDataSource.defaultRows
            .map(
              (row) => {
                ...row,
                'deadline': DateTime.now()
                    .add(const Duration(days: 12))
                    .toIso8601String(),
              },
            )
            .toList();
  final scope = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(user),
      profileRepositoryProvider.overrideWith(
        (ref) =>
            ProfileRepository(dataSource: profiles, currentUserId: () => user),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: applications,
          currentUserId: () => user,
        ),
      ),
      bookmarkRepositoryProvider.overrideWith(
        (ref) => BookmarkRepository(
          dataSource: _PreviewBookmarks(),
          currentUserId: () => user,
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) =>
            ScholarshipRepository(dataSource: FakeScholarshipDataSource(rows)),
      ),
      studentNotificationsProvider.overrideWith((ref) async => []),
      if (state == 'loading') ...[
        scholarshipsProvider.overrideWith(
          (ref) => Completer<List<Scholarship>>().future,
        ),
        currentProfileProvider.overrideWith(
          (ref) => Completer<StudentProfile?>().future,
        ),
        applicationsProvider.overrideWith(_LoadingApplications.new),
      ],
      if (state == 'error') ...[
        scholarshipsProvider.overrideWith(
          (ref) => Future.error(StateError('Preview unavailable')),
        ),
        currentProfileProvider.overrideWith(
          (ref) => Future.error(StateError('Preview unavailable')),
        ),
        applicationsProvider.overrideWith(_ErrorApplications.new),
      ],
    ],
  );
  scope
      .read(homeTabIndexProvider.notifier)
      .selectTab(int.tryParse(params['tab'] ?? '') ?? 0);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
      GoRoute(
        path: '/scholarship/:id',
        builder: (_, state) =>
            ScholarshipDetailScreen(scholarshipId: state.pathParameters['id']!, startApplication: state.uri.queryParameters['apply'] == '1'),
      ),
      GoRoute(
        path: '/application/:id',
        builder: (_, state) =>
            ApplicationDetailScreen(applicationId: state.pathParameters['id']!),
      ),
    ],
  );
  runApp(
    UncontrolledProviderScope(
      container: scope,
      child: MaterialApp.router(
        title: 'Scholaris • local fictional student preview',
        debugShowCheckedModeBanner: false,
        theme: scholarisTheme(),
        scrollBehavior: const ScholarisSmoothScrollBehavior(),
        routerConfig: router,
        builder: (context, child) {
          final width = double.tryParse(params['width'] ?? '') ?? 360;
          final height = double.tryParse(params['height'] ?? '') ?? 800;
          return ColoredBox(
            color: const Color(0xFFDEE3E0),
            child: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(width, height),
                    textScaler: TextScaler.linear(
                      double.tryParse(params['scale'] ?? '') ?? 1,
                    ),
                    disableAnimations: params['motion'] == 'off',
                  ),
                  child: child!,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _LoadingApplications extends ApplicationsNotifier {
  @override
  Future<List<Never>> build() => Completer<List<Never>>().future;
}

class _ErrorApplications extends ApplicationsNotifier {
  @override
  Future<List<Never>> build() =>
      Future.error(StateError('Preview unavailable'));
}

class _PreviewBookmarks implements BookmarkDataSource {
  final _ids = <String>{};
  @override
  Future<List<String>> fetchScholarshipIds(String userId) async =>
      _ids.toList();
  @override
  Future<void> addBookmark(String userId, String scholarshipId) async {
    _ids.add(scholarshipId);
  }

  @override
  Future<void> removeBookmark(String userId, String scholarshipId) async {
    _ids.remove(scholarshipId);
  }
}
