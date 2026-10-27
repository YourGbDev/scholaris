// Verify visible destinations and retained elements independently of shell layout.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/applications/presentation/applications_screen.dart';
import 'package:scholaris/features/dashboard/presentation/student_dashboard_screen.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/presentation/profile_tab_screen.dart';
import 'package:scholaris/features/scholarships/screens/discover_screen.dart';
import 'package:scholaris/shared/theme/app_motion.dart';

void main() {
  testWidgets(
    'tab switches show the destination immediately and retain every page',
    (tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await tester.pump();
      final pages = <Type>[
        StudentDashboardScreen,
        DiscoverScreen,
        ApplicationsScreen,
        ProfileTabScreen,
      ];
      final elements = [
        for (final page in pages)
          tester.element(find.byType(page, skipOffstage: false)),
      ];
      expect(find.byType(TabContentCrossFade), findsNothing);
      final keys = ['home', 'discover', 'tracker', 'profile'];
      for (final index in [1, 2, 3, 0]) {
        await tester.tap(find.byKey(ValueKey('student-nav-${keys[index]}')));
        await tester.pump();
        expect(find.byType(pages[index]), findsOneWidget);
        for (var i = 0; i < pages.length; i++) {
          expect(
            tester.element(find.byType(pages[i], skipOffstage: false)),
            same(elements[i]),
          );
          if (i != index) expect(find.byType(pages[i]), findsNothing);
        }
      }
    },
  );
}
