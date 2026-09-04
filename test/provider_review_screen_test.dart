// Provider review screen: renders confirmation and back-to-login navigation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/features/provider/presentation/provider_review_screen.dart';

void main() {
  group('ProviderReviewScreen', () {
    testWidgets('renders heading and back-to-login button', (tester) async {
      final router = GoRouter(
        initialLocation: '/provider-review',
        routes: [
          GoRoute(
            path: '/provider-review',
            builder: (context, state) =>
                const ProviderReviewScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(
                  body: Center(
                    child: Text('Login'),
                  ),
                ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Application Under Review'), findsOneWidget);
      expect(
        find.text(
          'Thanks for your interest in becoming a scholarship '
          'provider. Our team will review your application and '
          'get back to you within 3–5 business days.',
        ),
        findsOneWidget,
      );
      expect(find.text('Back to login'), findsOneWidget);
    });

    testWidgets('back-to-login button navigates to /login', (tester) async {
      final router = GoRouter(
        initialLocation: '/provider-review',
        routes: [
          GoRoute(
            path: '/provider-review',
            builder: (context, state) =>
                const ProviderReviewScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(
                  body: Center(
                    child: Text('Login'),
                  ),
                ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Back to login'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });
  });
}
