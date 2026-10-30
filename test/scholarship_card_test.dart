// Focused tests for the shared ScholarshipCard bookmark toggle: which icon
// renders for the saved/unsaved state, that tapping fires the toggle callback,
// and that the touch target meets the 44x44 accessibility minimum. Also covers
// the Day 15 deadline-display semantics: a future deadline inside the
// closing-soon threshold is urgent, one outside it is normal, and an expired
// deadline is "Closed" — never "Closing soon — Closed".

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';

Map<String, dynamic> _row() => {
      'id': 'sch-dost',
      'title': 'DOST-SEI Undergraduate Scholarship',
      'provider': 'Department of Science and Technology',
      'description': 'Supports students in priority STEM programs.',
      'min_gpa': 2.0,
      'required_year_levels': [1, 2, 3, 4, 5],
      'required_courses': <String>[],
      'location_restriction': null,
      'max_monthly_income': null,
      'for_pwd': false,
      'for_indigenous': false,
      'slots': 8000,
      'deadline': '2099-10-15',
      'application_url': 'https://ched.gov.ph/scholarships',
      'is_active': true,
    };

Scholarship _scholarship({String? deadline}) {
  final row = {..._row()};
  if (deadline != null) row['deadline'] = deadline;
  return Scholarship.fromJson(row);
}

Widget _wrap({required ScholarshipCard card}) =>
    MaterialApp(home: Scaffold(body: card));

void main() {
  testWidgets('deadline and Applied remain adjacent on a phone with a bookmark', (tester) async {
    final fonts = FontLoader('Geist')
      ..addFont(rootBundle.load('assets/fonts/geist/Geist-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/geist/Geist-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/geist/Geist-Bold.ttf'));
    await fonts.load();
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ScholarshipCard(scholarship: _scholarship(deadline: '2099-12-18'),
        matchPercentage: 98, isApplied: true, onToggleBookmark: () {}),
    ))));
    await tester.pumpAndSettle();
    final deadline = tester.getRect(find.text('Closes Dec 18'));
    final applied = tester.getRect(find.text('Applied'));
    expect(applied.center.dy, closeTo(deadline.center.dy, 2));
    expect(applied.left, greaterThan(deadline.right));
    expect(tester.takeException(), isNull);
  });
  testWidgets('award sits beside title when wide and below on a narrow screen', (tester) async {
    const profile = StudentProfile(id: 'student', fullName: 'Student', gpa: 3.0, yearLevel: 1, setupComplete: true);
    Future<void> renderAt(double width) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_wrap(card: ScholarshipCard(scholarship: _scholarship(), studentProfile: profile)));
      await tester.pumpAndSettle();
    }
    addTearDown(tester.view.reset);
    await renderAt(600);
    expect(tester.getTopLeft(find.text('₱50,000')).dx, greaterThan(tester.getTopLeft(find.text('DOST-SEI Undergraduate Scholarship')).dx + 100));
    expect(find.text('Apply Now'), findsOneWidget);
    await renderAt(320);
    expect(tester.getTopLeft(find.text('₱50,000')).dy, greaterThan(tester.getBottomLeft(find.text('DOST-SEI Undergraduate Scholarship')).dy));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Apply Now carries the application intent, View Details does not', (tester) async {
    final scholarship = _scholarship();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => Scaffold(body: ScholarshipCard(
        scholarship: scholarship,
        studentProfile: const StudentProfile(id: 'student', fullName: 'Student', gpa: 3.0, yearLevel: 1, setupComplete: true),
      ))),
      GoRoute(path: '/scholarship/:id', builder: (_, state) => Scaffold(body: Text(state.uri.queryParameters['apply'] ?? 'details'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Apply Now'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();
    expect(find.text('details'), findsOneWidget);
  });
  testWidgets('only a qualifying high match offers Apply Now', (tester) async {
    const qualified = StudentProfile(id: 'student', fullName: 'Student', gpa: 3.0, yearLevel: 1, setupComplete: true);
    const unqualified = StudentProfile(id: 'student', fullName: 'Student', gpa: 1.0, yearLevel: 1, setupComplete: true);
    await tester.pumpWidget(_wrap(card: ScholarshipCard(scholarship: _scholarship(), studentProfile: qualified, matchPercentage: 98)));
    expect(find.text('Apply Now'), findsOneWidget);
    expect(find.text('98% Fit'), findsOneWidget);
    await tester.pumpWidget(_wrap(card: ScholarshipCard(scholarship: _scholarship(), studentProfile: unqualified, matchPercentage: 98)));
    expect(find.text('Apply Now'), findsNothing);
    expect(find.text('69% Fit'), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
  });
  testWidgets('a closed scholarship does not offer quick apply', (tester) async {
    await tester.pumpWidget(_wrap(card: ScholarshipCard(
      scholarship: _scholarship(deadline: '2020-01-01'), matchPercentage: 98,
      studentProfile: const StudentProfile(id: 'student', fullName: 'Student', gpa: 3.0, yearLevel: 1, setupComplete: true),
    )));
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Apply Now'), findsNothing);
    expect(find.text('View Details'), findsOneWidget);
  });
  testWidgets('an applied scholarship does not offer quick apply', (tester) async {
    var appliedAgain = false;
    await tester.pumpWidget(_wrap(card: ScholarshipCard(
      scholarship: _scholarship(), matchPercentage: 98, isApplied: true,
      studentProfile: const StudentProfile(id: 'student', fullName: 'Student', gpa: 3.0, yearLevel: 1, setupComplete: true),
      onQuickApply: () => appliedAgain = true,
    )));
    expect(find.text('Applied'), findsOneWidget);
    expect(find.text('Apply Now'), findsNothing);
    expect(find.text('View Details'), findsOneWidget);
    expect(appliedAgain, isFalse);
  });
  testWidgets('award amount stays readable on narrow enlarged-text cards', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: ScholarshipCard(scholarship: _scholarship()),
    ))));
    await tester.pumpAndSettle();
    final amount = find.text('₱50,000');
    expect(tester.getBottomRight(amount).dy - tester.getTopLeft(amount).dy, greaterThanOrEqualTo(18));
    expect(tester.takeException(), isNull);
  });
  testWidgets('card title follows badges closely without shrinking bookmark target', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scholarship = Scholarship.fromJson(_row());
    await tester.pumpWidget(_wrap(card: ScholarshipCard(scholarship: scholarship, onToggleBookmark: () {})));
    await tester.pumpAndSettle();
    final gap = tester.getTopLeft(find.text(scholarship.title)).dy - tester.getBottomRight(find.text('94% Fit')).dy;
    expect(gap, lessThanOrEqualTo(16));
    expect(tester.getTopLeft(find.text(scholarship.title)).dy,
      greaterThanOrEqualTo(tester.getBottomRight(find.byType(IconButton)).dy));
  });
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('unsaved card shows the outline icon and tapping calls back',
      (tester) async {
    var toggled = false;

    await tester.pumpWidget(_wrap(
      card: ScholarshipCard(
        scholarship: _scholarship(),
        isBookmarked: false,
        onToggleBookmark: () => toggled = true,
      ),
    ));

    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
    expect(toggled, isTrue);
  });

  testWidgets('saved card shows the filled icon', (tester) async {
    await tester.pumpWidget(_wrap(
      card: ScholarshipCard(
        scholarship: _scholarship(),
        isBookmarked: true,
        onToggleBookmark: () {},
      ),
    ));

    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
  });

  testWidgets('card without a toggle handler renders no bookmark control',
      (tester) async {
    await tester.pumpWidget(_wrap(
      card: ScholarshipCard(scholarship: _scholarship()),
    ));

    expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
    expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
  });

  testWidgets('bookmark control meets the 44x44 touch target minimum',
      (tester) async {
    await tester.pumpWidget(_wrap(
      card: ScholarshipCard(
        scholarship: _scholarship(),
        isBookmarked: false,
        onToggleBookmark: () {},
      ),
    ));

    final button = find.byType(IconButton);
    expect(button, findsOneWidget);

    final size = tester.getSize(button);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('card actions provide a comfortable 44px touch target',
      (tester) async {
    await tester.pumpWidget(_wrap(
      card: ScholarshipCard(scholarship: _scholarship()),
    ));

    expect(tester.getSize(find.widgetWithText(TextButton, 'View Details')).height,
        greaterThanOrEqualTo(44));
    expect(find.text('Apply Now'), findsNothing);
  });

  group('applied indicator', () {
    testWidgets('applied card shows a compact Applied indicator',
        (tester) async {
      await tester.pumpWidget(_wrap(
        card: ScholarshipCard(
          scholarship: _scholarship(),
          isApplied: true,
        ),
      ));

      expect(find.text('Applied'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('non-applied card renders no Applied indicator',
        (tester) async {
      await tester.pumpWidget(_wrap(
        card: ScholarshipCard(scholarship: _scholarship()),
      ));

      expect(find.text('Applied'), findsNothing);
    });

    testWidgets('applied indicator coexists with the bookmark control',
        (tester) async {
      await tester.pumpWidget(_wrap(
        card: ScholarshipCard(
          scholarship: _scholarship(),
          isApplied: true,
          isBookmarked: true,
          onToggleBookmark: () {},
        ),
      ));

      expect(find.text('Applied'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });
  });

  group('deadline display', () {
    String isoInDays(int days) =>
        DateTime.now().add(Duration(days: days)).toIso8601String().split('T').first;

    testWidgets('a future deadline inside the threshold shows the urgent '
        'closing-soon label', (tester) async {
      await tester.pumpWidget(_wrap(
        card: ScholarshipCard(scholarship: _scholarship(deadline: isoInDays(10))),
      ));

      // 10 days out → "10 days left" on an urgent chip, never "Closed".
      expect(find.text('10 days left'), findsOneWidget);
      expect(find.text('Closed'), findsNothing);
    });

    testWidgets('a future deadline outside the threshold shows the normal '
        'deadline label', (tester) async {
      await tester.pumpWidget(_wrap(
        card: ScholarshipCard(scholarship: _scholarship(deadline: isoInDays(40))),
      ));

      // 40 days out → plain "Closes <Mon d>", never urgent, never "Closed".
      expect(find.text('Closed'), findsNothing);
      expect(find.textContaining('Closing soon'), findsNothing);
      expect(find.textContaining('Closes '), findsOneWidget);
    });

    testWidgets('an expired deadline shows Closed — never Closing soon '
        '(regression: Closing soon — Closed)', (tester) async {
      await tester.pumpWidget(_wrap(
        card: ScholarshipCard(scholarship: _scholarship(deadline: isoInDays(-1))),
      ));

      expect(find.text('Closed'), findsOneWidget);
      expect(find.textContaining('Closing soon'), findsNothing);
    });
  });

  group('Provider type color mapping', () {
    test('maps government agencies to Navy Trust', () {
      expect(providerTypeColor('Department of Science and Technology'), const Color(0xFF1B3A5C));
      expect(providerTypeColor('Commission on Higher Education'), const Color(0xFF1B3A5C));
      expect(providerTypeColor('City Government of Manila'), const Color(0xFF1B3A5C));
      expect(providerTypeColor('BARMM Ministry of Basic Education'), const Color(0xFF1B3A5C));
    });

    test('maps NGOs and foundations to Coral Connect', () {
      expect(providerTypeColor('Ayala Foundation'), const Color(0xFFFF6F59));
      expect(providerTypeColor('Philippine Women\'s Technology Alliance'), const Color(0xFFFF6F59));
      expect(providerTypeColor('Philippine Nurses Association'), const Color(0xFFFF6F59));
    });

    test('maps university and academic institutions to Bridge Green', () {
      expect(providerTypeColor('University of the Philippines'), const Color(0xFF0F4D2E));
      expect(providerTypeColor('De La Salle College of Saint Benilde'), const Color(0xFF0F4D2E));
    });

    test('maps private and corporate entities to Golden Opportunity', () {
      expect(providerTypeColor('BPI Bank'), const Color(0xFFF1B41E));
      expect(providerTypeColor('San Miguel Corporation'), const Color(0xFFF1B41E));
    });

    test('defaults unknown or null provider to Navy Trust', () {
      expect(providerTypeColor(null), const Color(0xFF1B3A5C));
      expect(providerTypeColor(''), const Color(0xFF1B3A5C));
    });

    testWidgets('provider icon uses the provider accent color', (tester) async {
      await tester.pumpWidget(_wrap(
        card: ScholarshipCard(
          scholarship: _scholarship(),
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.account_balance_outlined));
      expect(icon.color, const Color(0xFF1B3A5C));
    });
  });

  group('Stitch V2 Discover Card fidelity', () {
    testWidgets('qualified high fit card shows fit and both actions', (tester) async {
      await tester.pumpWidget(_wrap(
        card: ScholarshipCard(
          scholarship: _scholarship(),
          matchPercentage: 96,
          studentProfile: const StudentProfile(id: 'student', fullName: 'Student', gpa: 3.0, yearLevel: 1, setupComplete: true),
        ),
      ));

      // 1. Fit badge
      expect(find.text('96% Fit'), findsOneWidget);
      expect(find.textContaining('Match'), findsNothing);

      // 2. Both actions are available for a qualified student.
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Apply Now'), findsOneWidget);

      // 3. No "Why this matches you" on discover card
      expect(find.text('Why this matches you'), findsNothing);

      expect(find.textContaining('STEM Exam Qualifier'), findsOneWidget);
    });

    testWidgets('lower fit card (<90%) shows single full-width View Details button only', (tester) async {
      await tester.pumpWidget(_wrap(
        card: ScholarshipCard(
          scholarship: _scholarship(),
          matchPercentage: 88,
        ),
      ));

      // 1. Fit badge
      expect(find.text('88% Fit'), findsOneWidget);
      expect(find.textContaining('Match'), findsNothing);

      // 2. Only View Details button present; Apply Now is omitted
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Apply Now'), findsNothing);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);

      expect(find.textContaining('STEM Exam Qualifier'), findsOneWidget);
    });
  });
}
