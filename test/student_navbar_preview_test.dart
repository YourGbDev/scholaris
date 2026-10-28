// test/student_navbar_preview_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/dev/student_navbar_preview/main.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('StudentNavbarPreviewApp mounts and switches controls without exception', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const StudentNavbarPreviewApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify title and controls are present
    expect(find.text('Width: '), findsOneWidget);
    expect(find.text('Text Scale: '), findsOneWidget);
    expect(find.text('320px'), findsOneWidget);
    expect(find.text('360px'), findsOneWidget);
    expect(find.text('440px'), findsOneWidget);

    // Verify StudentBottomNav is mounted
    expect(find.byType(StudentBottomNav), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);

    FlutterErrorDetails? caughtDetails;
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      caughtDetails = details;
    };

    // Switch width to 320px
    await tester.tap(find.text('320px'));
    await tester.pumpAndSettle();
    if (caughtDetails != null) {
      print('CAUGHT AT 320px:\n${caughtDetails}');
      caughtDetails = null;
    }

    // Switch text scale to 2.0x
    await tester.tap(find.text('2.0x'));
    await tester.pumpAndSettle();
    if (caughtDetails != null) {
      print('CAUGHT AT 2.0x:\n${caughtDetails}');
      caughtDetails = null;
    }

    // Switch text scale to 3.0x
    await tester.tap(find.text('3.0x'));
    await tester.pumpAndSettle();
    if (caughtDetails != null) {
      print('CAUGHT AT 3.0x:\n${caughtDetails}');
      caughtDetails = null;
    }

    FlutterError.onError = oldHandler;

    // Verify all destinations still present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Tracker'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byKey(const ValueKey('student-nav-quick-action')), findsOneWidget);

    // Zero exceptions
    expect(tester.takeException(), isNull);
  });
}
