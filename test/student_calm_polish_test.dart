import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';

void main() {
  for (final safeBottom in [0.0, 34.0]) {
    testWidgets('lower dock respects bottom safe area $safeBottom', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: MediaQuery(
        data: MediaQueryData(size: const Size(390, 844), padding: EdgeInsets.only(bottom: safeBottom)),
        child: Scaffold(body: Align(alignment: Alignment.bottomCenter,
          child: StudentBottomNav(tabIndex: 0, onSelectTab: (_) {}, onQuickAction: () {}))),
      )));
      await tester.pumpAndSettle();
      final button = tester.getRect(find.byKey(const ValueKey('student-nav-quick-action')));
      expect(button.bottom, closeTo(844 - (safeBottom > 0 ? safeBottom : 10), .1));
      expect(button.bottom, lessThanOrEqualTo(844 - safeBottom));
    });
  }
}
