import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/app.dart';

void main() {
  testWidgets('App displays Scholaris title', (WidgetTester tester) async {
    await tester.pumpWidget(const ScholarisApp());

    expect(find.text('Scholaris'), findsWidgets);
    expect(find.text('Scholarship matching — in development.'), findsOneWidget);
  });
}