import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/presentation/profile_setup_screen.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';

import 'helpers/fake_profile_data_source.dart';
import 'helpers/load_app_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final step in ['personal', 'academic', 'financial']) {
    for (final save in [true, false]) {
      testWidgets(
        '$step edit ${save ? 'saves changes' : 'back cancels'} and returns to Profile',
        (tester) async {
          tester.view.physicalSize = const Size(440, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          const userId = 'editing-student';
          final source = FakeProfileDataSource();
          await source.upsertProfile(userId, {
            'full_name': 'Maria Santos',
            'nationality': 'Filipino',
            'gender': 'female',
            'gpa': 90.0,
            'gpa_scale': 'percentage',
            'year_level': 2,
            'course': 'BS Computer Science',
            'school': 'University of the Philippines',
            'region': 'National Capital Region (NCR)',
            'monthly_family_income': 35000.0,
            'profile_setup_step': 3,
            'setup_complete': true,
          });
          final repository = ProfileRepository(
            dataSource: source,
            currentUserId: () => userId,
          );
          final container = ProviderContainer(
            overrides: [
              currentUserIdProvider.overrideWithValue(userId),
              profileRepositoryProvider.overrideWithValue(repository),
            ],
          );
          addTearDown(container.dispose);
          await container.read(currentProfileProvider.future);
          await container
              .read(profileSetupProvider(userId).notifier)
              .hydrationComplete;
          final router = GoRouter(
            initialLocation: '/profile-setup/$step',
            redirect: (_, state) => authRedirectDecision(
              location: state.uri.path,
              isLoggedIn: true,
              recoveryActive: false,
              onAuthRoute: false,
              onSetupRoute: state.uri.path.startsWith('/profile-setup'),
              profileLoading: false,
              profileComplete: true,
            ),
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const Scaffold(body: Text('Returned home')),
              ),
              for (final section in ['personal', 'academic', 'financial'])
                GoRoute(
                  path: '/profile-setup/$section',
                  builder: (_, _) => ProfileSetupScreen(step: section),
                ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(routerConfig: router),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Save Changes'), findsOneWidget);
          expect(find.textContaining(RegExp(r'Step [123] of 3')), findsNothing);
          expect(find.text('66%'), findsNothing);
          final original = switch (step) {
            'personal' => 'Maria Santos',
            'academic' => 'BS Computer Science',
            _ => '35000',
          };
          final replacement = switch (step) {
            'personal' => 'Maria Reyes',
            'academic' => 'BS Mathematics',
            _ => '22000',
          };
          final field = find.byWidgetPredicate(
            (widget) =>
                widget is TextFormField && widget.controller?.text == original,
          );
          await tester.ensureVisible(field);
          await tester.enterText(field, replacement);
          await tester.testTextInput.receiveAction(TextInputAction.done);
          if (save) {
            await tester.ensureVisible(find.text('Save Changes'));
            await tester.tap(find.text('Save Changes'));
          } else {
            await tester.tap(find.byTooltip('Back to profile'));
          }
          await tester.pumpAndSettle();
          if (save) {
            await tester.pump(const Duration(seconds: 2));
            await tester.pumpAndSettle();
          }
          expect(router.routeInformationProvider.value.uri.path, '/home');
          expect(container.read(homeTabIndexProvider), 3);
          final persisted = await repository.fetchCurrent();
          expect(persisted!.setupComplete, isTrue);
          expect(
            persisted.fullName,
            save && step == 'personal' ? 'Maria Reyes' : 'Maria Santos',
          );
          expect(
            persisted.course,
            save && step == 'academic'
                ? 'BS Mathematics'
                : 'BS Computer Science',
          );
          expect(
            persisted.monthlyFamilyIncome,
            save && step == 'financial' ? 22000 : 35000,
          );
          await container
              .read(profileSetupProvider(userId).notifier)
              .hydrationComplete;
          expect(
            container.read(profileSetupProvider(userId)).fullName,
            persisted.fullName,
          );
          expect(
            container.read(profileSetupProvider(userId)).course,
            persisted.course,
          );
        },
      );
    }
  }
}
