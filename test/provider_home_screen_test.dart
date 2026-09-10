import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';
import 'package:scholaris/features/provider/presentation/provider_home_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_profile_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

void main() {
  Widget buildApp() {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('prov-1'),
        applicationRepositoryProvider.overrideWith(
          (ref) => ApplicationRepository(
            dataSource: FakeApplicationDataSource(),
            currentUserId: () => 'prov-1',
          ),
        ),
        scholarshipRepositoryProvider.overrideWith(
          (ref) => ScholarshipRepository(
            dataSource: FakeScholarshipDataSource(),
          ),
        ),
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepository(
            dataSource: FakeProfileDataSource(),
            currentUserId: () => 'prov-1',
          ),
        ),
      ],
      child: const MaterialApp(
        home: ProviderHomeScreen(),
      ),
    );
  }

  group('ProviderHomeScreen', () {
    testWidgets('renders Provider Console title in AppBar', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Provider Console'), findsOneWidget);
    });

    testWidgets('renders Sign out button with logout icon and tooltip', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final logoutButton = find.byTooltip('Sign out');
      expect(logoutButton, findsOneWidget);
      expect(
        find.descendant(of: logoutButton, matching: find.byIcon(Icons.logout_rounded)),
        findsOneWidget,
      );
    });
  });
}
