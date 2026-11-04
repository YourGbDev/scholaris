import 'package:flutter/services.dart';

// Matched desktop captures of the current Home UI; not native font proof.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/load_app_fonts.dart';

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/dashboard/presentation/student_dashboard_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

Widget _buildTestApp({
  StudentProfile? profile,
  Widget? child,
  List<Scholarship>? matches,
  bool matchesError = false,
  Future<List<Scholarship>>? pendingMatches,
  FakeApplicationDataSource? applications,
  Future<StudentProfile?>? profileFuture,
}) {
  final profileData = FakeProfileDataSource();
  if (profile != null) {
    profileData.rows['test-user'] = profile.toJson();
  } else {
    profileData.rows['test-user'] = const StudentProfile(
      id: 'test-user',
      fullName: 'Gilbert Santos',
      nationality: 'Filipino',
      region: 'NCR',
      gpa: 3.5,
      yearLevel: 3,
      course: 'BS IT',
      setupComplete: true,
    ).toJson();
  }

  return ProviderScope(
    overrides: [
      if (profileFuture != null)
        currentProfileProvider.overrideWith((ref) => profileFuture),
      if (pendingMatches != null)
        matchesProvider.overrideWith((ref) => pendingMatches)
      else if (matchesError)
        matchesProvider.overrideWith((ref) async => throw StateError('offline'))
      else if (matches != null)
        matchesProvider.overrideWith((ref) async => matches),
      currentUserIdProvider.overrideWith((ref) => 'test-user'),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileRepository(
          dataSource: profileData,
          currentUserId: () => 'test-user',
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) =>
            ScholarshipRepository(dataSource: FakeScholarshipDataSource([])),
      ),
      bookmarkRepositoryProvider.overrideWith(
        (ref) => BookmarkRepository(
          dataSource: FakeBookmarkDataSource(),
          currentUserId: () => 'test-user',
        ),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: applications ?? FakeApplicationDataSource(),
          currentUserId: () => 'test-user',
        ),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: scholarisTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: child ?? const StudentDashboardScreen(),
    ),
  );
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
  });
  const phase = String.fromEnvironment('CAPTURE_PHASE');
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('current Home at $width text $scale', (tester) async {
        await loadAppFonts();
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: _buildTestApp(matches: []),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          for (final element in find.byType(Image).evaluate()) {
            await precacheImage((element.widget as Image).image, element);
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (phase.isNotEmpty) {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final f = File(
              'docs/reports/2026-11-04-typography/$phase/home-${width.toInt()}-${(scale * 100).toInt()}.png',
            );
            await f.parent.create(recursive: true);
            await f.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
