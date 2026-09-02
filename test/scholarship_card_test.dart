// Focused tests for the shared ScholarshipCard bookmark toggle: which icon
// renders for the saved/unsaved state, that tapping fires the toggle callback,
// and that the touch target meets the 44x44 accessibility minimum. Also covers
// the Day 15 deadline-display semantics: a future deadline inside the
// closing-soon threshold is urgent, one outside it is normal, and an expired
// deadline is "Closed" — never "Closing soon — Closed".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';

Map<String, dynamic> _row() => {
      'id': 'sch-dost',
      'name': 'DOST-SEI Undergraduate Scholarship',
      'provider': 'Department of Science and Technology',
      'description': 'Supports students in priority STEM programs.',
      'min_gpa': 2.0,
      'year_levels': [1, 2, 3, 4, 5],
      'eligible_courses': <String>[],
      'citizenship_required': 'Filipino',
      'regions_eligible': <String>[],
      'max_income_bracket': 'any',
      'is_pwd_priority': false,
      'is_working_student_priority': false,
      'slots_available': 8000,
      'deadline': '2026-10-15',
      'amount': 70000,
      'coverage_type': 'full',
      'tags': const ['stem', 'stipend'],
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
}
