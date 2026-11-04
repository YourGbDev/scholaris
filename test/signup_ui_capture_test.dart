// Offline matched captures; these do not prove native iPhone rendering.
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scholaris/features/auth/presentation/signup_screen.dart';
import 'package:scholaris/features/auth/presentation/verify_email_screen.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

void main() {
  const phase = String.fromEnvironment('CAPTURE_PHASE');
  setUpAll(() async {
    for (final entry in {
      'Geist': 'assets/fonts/geist/Geist-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final verification in [false, true]) {
        final name =
            '${verification ? 'verify' : 'signup'}-${width.toInt()}-$scale';
        testWidgets(name, (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final boundary = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: scholarisTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: RepaintBoundary(key: boundary, child: child!),
              ),
              home: verification
                  ? const VerifyEmailScreen(email: 'student@example.test')
                  : const SignupScreen(),
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
            await tester.runAsync(() async {
              final render =
                  boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await render.toImage(pixelRatio: 1);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'docs/reports/2026-11-04-signup/$phase/$name.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          // Check the lower controls remain reachable at enlarged text.
          await tester.ensureVisible(
            find.text(verification ? 'Back to login' : 'Sign up'),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
      testWidgets('signup overlay at $width with $scale text', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final client = GoTrueClient(
          url: 'https://example.test/auth/v1',
          autoRefreshToken: false,
          flowType: AuthFlowType.implicit,
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'id': 'new-student',
                'aud': 'authenticated',
                'email': 'student@example.test',
                'created_at': '2026-11-04T00:00:00Z',
              }),
              200,
            ),
          ),
        );
        addTearDown(client.dispose);
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => SignupScreen(client: client),
            ),
            GoRoute(
              path: '/verify-email',
              builder: (_, _) =>
                  const VerifyEmailScreen(email: 'student@example.test'),
            ),
          ],
        );
        addTearDown(router.dispose);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp.router(
            theme: scholarisTheme(),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: RepaintBoundary(key: boundary, child: child!),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Student Example');
        await tester.enterText(fields.at(1), 'student@example.test');
        await tester.enterText(fields.at(2), 'StrongPass123!');
        await tester.enterText(fields.at(3), 'StrongPass123!');
        await tester.ensureVisible(find.text('Sign up'));
        await tester.tap(find.text('Sign up'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Continue to email verification'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (phase == 'after') {
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'docs/reports/2026-11-04-signup/$phase/overlay-${width.toInt()}-$scale.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpAndSettle();
        expect(find.text('Verify your email'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
