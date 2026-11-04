import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Geist');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      fonts.addFont(rootBundle.load('assets/fonts/geist/Geist-$weight.ttf'));
    }
    await fonts.load();
  });

  testWidgets(
    'scholarship card spends emphasis on title and amount, not metadata',
    (tester) async {
      final scholarship = Scholarship.fromJson({
        'id': 'typography-card',
        'title': 'José Rizal Science and Technology Leadership Scholarship',
        'provider': 'Fundación Educación • Philippines',
        'description':
            'Opportunities for students pursuing science and technology.',
        'min_gpa': 2.0,
        'required_year_levels': [1, 2, 3, 4],
        'required_courses': <String>[],
        'slots': 120,
        'deadline': '2099-12-18',
        'is_active': true,
      });
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: scholarisTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScholarshipCard(scholarship: scholarship),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Text label(String value) => tester.widget<Text>(find.text(value));
      expect(label(scholarship.title).style!.fontWeight, FontWeight.w600);
      expect(label(scholarship.provider!).style!.fontWeight, FontWeight.w500);
      expect(label(scholarship.provider!).style!.fontSize, 13);
      expect(label(scholarship.provider!).style!.height, 1.45);
      expect(label(scholarship.provider!).style!.letterSpacing, 0);
      expect(label(scholarship.provider!).style!.color, kTextSecondary);
      final amount = tester.widget<Text>(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.textSpan?.toPlainText().startsWith('₱50,000') == true,
        ),
      );
      expect(amount.style!.fontWeight, FontWeight.w700);
      final frequency =
          (amount.textSpan as TextSpan).children!.last as TextSpan;
      expect(frequency.style!.fontWeight, FontWeight.w400);
      expect(label('View Details').style!.fontWeight, FontWeight.w600);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large text and system Bold Text remain effective with semantic styles',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: scholarisTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              boldText: true,
            ),
            child: Scaffold(
              body: Text(
                'José • ₱50,000 🎓',
                style: AppTypography.style(AppTextRole.body, fontSize: 14),
              ),
            ),
          ),
        ),
      );
      final rich = tester.widget<RichText>(find.byType(RichText).first);
      expect(rich.textScaler.scale(14), 28);
      expect(rich.text.style!.fontWeight, FontWeight.bold);
      expect(tester.takeException(), isNull);
    },
  );
}
