// test/screenshots/generate_stitch_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

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
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:scholaris/features/scholarships/screens/discover_screen.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

import '../helpers/fake_application_data_source.dart';
import '../helpers/fake_bookmark_data_source.dart';
import '../helpers/fake_profile_data_source.dart';
import '../helpers/fake_scholarship_data_source.dart';

Future<void> _loadFonts() async {
  final iconFile = File(r'C:\flutter\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf');
  if (iconFile.existsSync()) {
    final loader = FontLoader('MaterialIcons');
    loader.addFont(Future.value(ByteData.view(iconFile.readAsBytesSync().buffer)));
    await loader.load();
  }

  final robotoFile = File(r'C:\flutter\flutter\bin\cache\artifacts\material_fonts\roboto-regular.ttf');
  final robotoBoldFile = File(r'C:\flutter\flutter\bin\cache\artifacts\material_fonts\roboto-bold.ttf');
  if (robotoFile.existsSync()) {
    final regBytes = robotoFile.readAsBytesSync();
    final boldBytes = robotoBoldFile.existsSync() ? robotoBoldFile.readAsBytesSync() : regBytes;

    final families = <String>[
      'Outfit',
      'Outfit_regular',
      'Outfit_400',
      'Outfit_500',
      'Outfit_600',
      'Outfit_700',
      'Outfit_bold',
      'OpenSans',
      'OpenSans_regular',
      'OpenSans_400',
      'OpenSans_500',
      'OpenSans_600',
      'OpenSans_700',
      'OpenSans_bold',
      'Open Sans',
      'Roboto',
    ];

    for (final family in families) {
      final loader = FontLoader(family);
      loader.addFont(Future.value(ByteData.view(regBytes.buffer)));
      loader.addFont(Future.value(ByteData.view(boldBytes.buffer)));
      await loader.load();
    }
  }
}

List<Map<String, dynamic>> _stitchRows() {
  final now = DateTime.now();
  return [
    {
      'id': 'sch-1',
      'title': 'The Women in Technology Leadership Scholarship',
      'provider': 'AnitaB / TechForward Collective',
      'description': 'Women in STEM grant.',
      'min_gpa': 3.2,
      'required_year_levels': [1, 2, 3, 4, 5],
      'required_courses': <String>[],
      'location_restriction': null,
      'max_monthly_income': null,
      'for_pwd': false,
      'for_indigenous': false,
      'slots': 200,
      'deadline': now.add(const Duration(days: 4)).toIso8601String().split('T').first,
      'application_url': 'https://example.com',
      'is_active': true,
    },
    {
      'id': 'sch-2',
      'title': 'Future Innovators STEM Grant',
      'provider': 'National Science Endowment',
      'description': 'Supports students in priority STEM programs.',
      'min_gpa': 3.0,
      'required_year_levels': [1, 2, 3, 4, 5],
      'required_courses': <String>[],
      'location_restriction': null,
      'max_monthly_income': 15000,
      'for_pwd': false,
      'for_indigenous': false,
      'slots': 8000,
      'deadline': now.add(const Duration(days: 5)).toIso8601String().split('T').first,
      'application_url': 'https://example.com',
      'is_active': true,
    },
    {
      'id': 'sch-3',
      'title': 'Civic Leadership Fellowship',
      'provider': 'Horizon Foundation',
      'description': 'Support for community leadership.',
      'min_gpa': 3.5,
      'required_year_levels': [1, 2, 3, 4, 5],
      'required_courses': <String>[],
      'location_restriction': null,
      'max_monthly_income': null,
      'for_pwd': false,
      'for_indigenous': false,
      'slots': 500,
      'deadline': now.add(const Duration(days: 24)).toIso8601String().split('T').first,
      'application_url': 'https://example.com',
      'is_active': true,
    },
  ];
}

Widget _wrapScreen({required Widget screen, required int selectedTab}) {
  final profileSource = FakeProfileDataSource();
  profileSource.upsertProfile(
    'user-maya',
    StudentProfile(
      id: 'user-maya',
      fullName: 'Maya Santos',
      nationality: 'Filipino',
      region: 'NCR',
      gpa: 3.8,
      yearLevel: 3,
      course: 'BS Computer Science',
      monthlyFamilyIncome: 15000,
      setupComplete: true,
    ).toDbRow(),
  );

  final bookmarkSource = FakeBookmarkDataSource();
  bookmarkSource.addBookmark('user-maya', 'sch-1');
  bookmarkSource.addBookmark('user-maya', 'sch-2');
  bookmarkSource.addBookmark('user-maya', 'sch-3');

  final appSource = FakeApplicationDataSource();
  appSource.insertApplication('user-maya', {
    'id': 'app-1',
    'scholarship_id': 'sch-1',
    'status': 'in_review',
    'submitted_at': DateTime.now().toIso8601String(),
  });
  appSource.insertApplication('user-maya', {
    'id': 'app-2',
    'scholarship_id': 'sch-2',
    'status': 'submitted',
    'submitted_at': DateTime.now().toIso8601String(),
  });

  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-maya'),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileRepository(
          dataSource: profileSource,
          currentUserId: () => 'user-maya',
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) => ScholarshipRepository(
          dataSource: FakeScholarshipDataSource(_stitchRows()),
        ),
      ),
      bookmarkRepositoryProvider.overrideWith(
        (ref) => BookmarkRepository(
          dataSource: bookmarkSource,
          currentUserId: () => 'user-maya',
        ),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: appSource,
          currentUserId: () => 'user-maya',
        ),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackground,
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        backgroundColor: kBackground,
        body: screen,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: kBorderLight, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: selectedTab,
            onDestinationSelected: (_) {},
            backgroundColor: Colors.white,
            indicatorColor: kPrimary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            height: 64,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: Colors.white),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded, color: Colors.white),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded, color: Colors.white),
                label: 'Tracker',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: Colors.white),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  const artifactDir = r'C:\Users\Windows 11\.gemini\antigravity\brain\a8192a18-f75c-413a-8c05-4303be2aa2da';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
  });

  testWidgets('Capture Stitch Flutter Dashboard', skip: true, (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('GoogleFonts') ||
          details.exceptionAsString().contains('allowRuntimeFetching')) {
        return;
      }
      originalOnError?.call(details);
    };
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      if (error.toString().contains('GoogleFonts') ||
          error.toString().contains('allowRuntimeFetching')) {
        return true;
      }
      return false;
    };

    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.reset();
      FlutterError.onError = originalOnError;
    });

    final dashboardKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: dashboardKey,
        child: _wrapScreen(screen: const StudentDashboardScreen(), selectedTab: 0),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final dashboardBoundary = dashboardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final dashboardImage = await dashboardBoundary.toImage(pixelRatio: 2.0);
    final dashboardByteData = await dashboardImage.toByteData(format: ui.ImageByteFormat.png);
    File('$artifactDir/flutter_dashboard.png').writeAsBytesSync(dashboardByteData!.buffer.asUint8List());
  });

  testWidgets('Capture Stitch Flutter Discover', skip: true, (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('GoogleFonts') ||
          details.exceptionAsString().contains('allowRuntimeFetching')) {
        return;
      }
      originalOnError?.call(details);
    };
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      if (error.toString().contains('GoogleFonts') ||
          error.toString().contains('allowRuntimeFetching')) {
        return true;
      }
      return false;
    };

    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.reset();
      FlutterError.onError = originalOnError;
    });

    final discoverKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: discoverKey,
        child: _wrapScreen(screen: const DiscoverScreen(), selectedTab: 1),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final discoverBoundary = discoverKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final discoverImage = await discoverBoundary.toImage(pixelRatio: 2.0);
    final discoverByteData = await discoverImage.toByteData(format: ui.ImageByteFormat.png);
    File('$artifactDir/flutter_discover.png').writeAsBytesSync(discoverByteData!.buffer.asUint8List());
  });
}
