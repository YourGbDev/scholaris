// Day 11 — Journey regression test.
//
// Exercises the real product flow as far as the test architecture allows:
//
//   Scholarship Detail → Apply → Applications → Application Detail →
//   Withdraw → Applications reflects Withdrawn → Pending decreases →
//   Discover/Saved applied-state updates
//
// A single ProviderContainer is shared across the pumps so provider state
// (the application) carries through the journey exactly like the real app's
// reactive graph. Scholarship cards route through go_router, so the journey
// enters the scholarship detail directly (as the existing apply_ux_test does)
// rather than tapping a discover card.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/presentation/application_detail_screen.dart';
import 'package:scholaris/features/applications/presentation/application_status_chip.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

StudentProfile _student() => StudentProfile(
      id: 'user-a',
      fullName: 'Maria Santos',
      nationality: 'Filipino',
      region: 'NCR',
      gpa: 3.2,
      yearLevel: 2,
      course: 'BS Computer Science',
      monthlyFamilyIncome: 15000,
      setupComplete: true,
    );

Scholarship _scholarship() =>
    Scholarship.fromJson(FakeScholarshipDataSource.defaultRows.first);

class _JourneyHarness {
  _JourneyHarness() {
    final profileSource = FakeProfileDataSource();
    profileSource.upsertProfile('user-a', _student().toDbRow());

    container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-a'),
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepository(
            dataSource: profileSource,
            currentUserId: () => 'user-a',
          ),
        ),
        bookmarkRepositoryProvider.overrideWith(
          (ref) => BookmarkRepository(
            dataSource: FakeBookmarkDataSource(),
            currentUserId: () => 'user-a',
          ),
        ),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(
            dataSource: FakeScholarshipDataSource(),
          ),
        ),
        applicationRepositoryProvider.overrideWith(
          (ref) => ApplicationRepository(
            dataSource: applications,
            currentUserId: () => 'user-a',
          ),
        ),
      ],
    );
  }

  final FakeApplicationDataSource applications = FakeApplicationDataSource();
  late final ProviderContainer container;
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  Widget child,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('full lifecycle: apply → withdraw → pending decreases → '
      'applied-state updates', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final h = _JourneyHarness();
    addTearDown(h.container.dispose);

    // ---- Step 1: Scholarship Detail → Apply ------------------------------
    await _pump(
      tester,
      h.container,
      ScholarshipDetailScreen(
        scholarshipId: _scholarship().id,
        initial: _scholarship(),
      ),
    );

    expect(find.text('Apply now'), findsOneWidget);
    await tester.tap(find.text('Apply now'));
    await tester.pumpAndSettle();

    // Day 15: the write only happens after the pre-apply confirmation.
    expect(find.text('Apply to this scholarship?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('apply-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Application submitted!'), findsOneWidget);
    expect(find.text('Application submitted'), findsOneWidget);
    expect(await h.applications.fetchApplications('user-a'), hasLength(1));

    // ---- Step 2: Home → Applications shows pending -----------------------
    await _pump(tester, h.container, const HomeScreen());

    await tester.tap(find.text('Applications'));
    await tester.pumpAndSettle();

    expect(find.text('My Applications'), findsOneWidget);
    expect(find.text('1 Total'), findsOneWidget);
    expect(find.text('1 Pending'), findsOneWidget);
    expect(find.text('0 Approved'), findsOneWidget);
    expect(find.text('Withdrawn (0)'), findsOneWidget);

    // ---- Step 3: Open the application detail ------------------------------
    await tester.tap(find.text('DOST-SEI Undergraduate Scholarship'));
    await tester.pumpAndSettle();

    expect(find.byType(ApplicationDetailScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('withdraw-action')), findsOneWidget);

    // ---- Step 4: Withdraw (confirmation) ---------------------------------
    await tester.ensureVisible(find.byKey(const ValueKey('withdraw-action')));
    await tester.tap(find.byKey(const ValueKey('withdraw-action')));
    await tester.pumpAndSettle();

    expect(find.text('Withdraw application?'), findsOneWidget);

    // ---- Step 5: Applications reflects Withdrawn; pending decreases ------
    await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
    await tester.pump();

    final rows = await h.applications.fetchApplications('user-a');
    expect(rows.single['status'], 'withdrawn');

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('withdraw-action')), findsNothing);
    expect(find.textContaining('kept in your history'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    // The pending count dropped; the withdrawn filter chip exists.
    expect(find.text('0 Pending'), findsOneWidget);
    expect(find.text('1 Total'), findsOneWidget);
    expect(find.text('Withdrawn (1)'), findsOneWidget);

    // The withdrawn filter surfaces the historical application.
    await tester.ensureVisible(find.text('Withdrawn (1)'));
    await tester.tap(find.text('Withdrawn (1)'));
    await tester.pumpAndSettle();

    expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
    expect(find.byType(ApplicationStatusChip), findsOneWidget);

    // Back to All.
    await tester.ensureVisible(find.text('All (1)'));
    await tester.tap(find.text('All (1)'));
    await tester.pumpAndSettle();

    // ---- Step 6: Discover/Saved applied-state updates --------------------
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    // The withdrawn application no longer reads as "Applied" on the card.
    final dostCard = find.ancestor(
      of: find.text('DOST-SEI Undergraduate Scholarship'),
      matching: find.byType(ScholarshipCard),
    );
    expect(
      find.descendant(of: dostCard, matching: find.text('Applied')),
      findsNothing,
    );

    // The "Applied" dashboard count still counts the preserved record.
    expect(find.text('1 Applied'), findsOneWidget);

    // ---- Step 7: Scholarship detail still blocks re-application ----------
    await _pump(
      tester,
      h.container,
      ScholarshipDetailScreen(
        scholarshipId: _scholarship().id,
        initial: _scholarship(),
      ),
    );

    // The duplicate guard is unchanged: the preserved (withdrawn) record
    // still shows the applied banner, not a re-apply affordance.
    expect(find.text('Application submitted'), findsOneWidget);
    expect(find.text('Apply now'), findsNothing);
  });
}
