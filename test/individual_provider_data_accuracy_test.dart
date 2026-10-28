import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/provider/models/support_ledger.dart';
import 'package:scholaris/features/provider/presentation/individual/individual_applications_tab.dart';
import 'package:scholaris/features/provider/presentation/individual/individual_grant_tab.dart';
import 'package:scholaris/features/provider/presentation/individual/individual_settings_tab.dart';
import 'package:scholaris/features/provider/providers/provider_scholarships_provider.dart';
import 'package:scholaris/features/provider/providers/provider_type_provider.dart';
import 'package:scholaris/features/provider/repositories/support_repository.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';

class Incoming extends IncomingApplicationsNotifier {
  Incoming(this.load);
  final Future<List<Application>> Function() load;
  @override
  Future<List<Application>> build() => load();
}

class Listings extends ProviderScholarshipsNotifier {
  Listings(this.rows);
  final List<Scholarship> rows;
  @override
  Future<List<Scholarship>> build() async => rows;
}

final program = Scholarship(
  id: 'sch',
  title: 'Changed listing',
  minGpa: 2.0,
  deadline: DateTime.now().add(const Duration(days: 30)),
  amount: 15000,
  slots: 5,
);
const awarded = Application(
  id: 'award1',
  userId: 'student',
  scholarshipId: 'sch',
  status: ApplicationStatus.awarded,
);
Widget harness(
  Widget page, {
  Future<List<Application>> Function()? apps,
  Future<SupportLedger> Function()? ledger,
  List<Scholarship>? programs,
}) => ProviderScope(
  overrides: [
    currentUserIdProvider.overrideWithValue('provider'),
    incomingApplicationsProvider.overrideWith(
      () => Incoming(apps ?? () async => [awarded]),
    ),
    providerScholarshipsProvider.overrideWith(
      () => Listings(programs ?? [program]),
    ),
    scholarshipsProvider.overrideWith((ref) async => [program]),
    providerApplicantProfilesProvider.overrideWith((ref) async => {}),
    supportLedgerProvider.overrideWith(
      (ref) =>
          (ledger ??
          () async => SupportLedger.fromJson({
            'commitments': [
              {
                'application_id': 'award1',
                'scholarship_id': 'sch',
                'amount_cents': 1000050,
              },
            ],
          }))(),
    ),
  ],
  child: MaterialApp(home: Scaffold(body: page)),
);
Future<void> expand(WidgetTester t) async {
  await t.tap(find.text('Your support summary'));
  await t.pumpAndSettle();
}

Widget settingsHarness(
  Future<void> Function(String) save, {
  String? user = 'provider',
}) => ProviderScope(
  overrides: [
    currentUserIdProvider.overrideWithValue(user),
    currentProfileProvider.overrideWith(
      (ref) async =>
          StudentProfile.fromJson({'id': 'provider', 'full_name': 'Elena'}),
    ),
    currentProviderTypeProvider.overrideWith((ref) async => 'individual'),
    individualProfileNameSaverProvider.overrideWithValue(save),
  ],
  child: const MaterialApp(home: Scaffold(body: IndividualSettingsTab())),
);
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
    'expanded individual summary supports 200 percent text on mobile',
    (t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        harness(
          const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: IndividualApplicationsTab(),
          ),
        ),
      );
      await t.pumpAndSettle();
      await expand(t);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('unspecified capacity never invents a single place', (t) async {
    await t.pumpWidget(
      harness(
        const IndividualGrantTab(),
        programs: [program.copyWith(slots: null)],
      ),
    );
    await t.pumpAndSettle();
    expect(find.textContaining('Capacity not set'), findsOneWidget);
    expect(find.text(' / 1 Slot'), findsNothing);
  });
  testWidgets(
    'profile saves trimmed input once and locks editing during the write',
    (t) async {
      final pending = Completer<void>();
      final saved = <String>[];
      await t.pumpWidget(
        settingsHarness((value) {
          saved.add(value);
          return pending.future;
        }),
      );
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, '  Elena Reyes  ');
      await t.ensureVisible(find.text('Save Profile Changes'));
      await t.tap(find.text('Save Profile Changes'));
      await t.pump();
      expect(saved, ['Elena Reyes']);
      expect(
        t.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        isFalse,
      );
      expect(
        t
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save Profile Changes'),
            )
            .onPressed,
        isNull,
      );
      pending.complete();
      await t.pumpAndSettle();
      expect(
        find.text('Benefactor profile updated successfully.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'profile never reports success after a failed write and retains input',
    (t) async {
      await t.pumpWidget(
        settingsHarness(
          (value) async => throw StateError('private database diagnostics'),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, 'New Name');
      await t.ensureVisible(find.text('Save Profile Changes'));
      await t.tap(find.text('Save Profile Changes'));
      await t.pumpAndSettle();
      expect(
        find.text(
          'Your profile could not be saved. Check your connection and try again.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Benefactor profile updated successfully.'),
        findsNothing,
      );
      expect(find.textContaining('private database diagnostics'), findsNothing);
      expect(
        t
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'New Name',
      );
    },
  );
  testWidgets('expired session blocks profile writes and explains recovery', (
    t,
  ) async {
    var writes = 0;
    await t.pumpWidget(
      settingsHarness((value) async {
        writes++;
      }, user: null),
    );
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Save Profile Changes'));
    await t.tap(find.text('Save Profile Changes'));
    await t.pumpAndSettle();
    expect(writes, 0);
    expect(
      find.text('Your session ended. Sign in again to save your profile.'),
      findsOneWidget,
    );
    expect(find.text('Benefactor profile updated successfully.'), findsNothing);
  });
  testWidgets(
    'approved value uses agreed centavos and awarded filter matches count',
    (t) async {
      await t.pumpWidget(harness(const IndividualApplicationsTab()));
      await t.pumpAndSettle();
      await expand(t);
      expect(find.text('₱10,000.50'), findsOneWidget);
      await t.ensureVisible(find.widgetWithText(ChoiceChip, 'Approved'));
      await t.tap(find.widgetWithText(ChoiceChip, 'Approved'));
      await t.pumpAndSettle();
      expect(find.text('No candidates in this queue'), findsNothing);
      expect(find.text('Awarded'), findsOneWidget);
    },
  );
  testWidgets(
    'summary distinguishes missing commitments and unavailable ledger',
    (t) async {
      await t.pumpWidget(
        harness(
          const IndividualApplicationsTab(),
          ledger: () async => SupportLedger.fromJson({}),
        ),
      );
      await t.pumpAndSettle();
      await expand(t);
      expect(
        find.textContaining(
          '1 approved application has no recorded commitment',
        ),
        findsOneWidget,
      );
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(
        harness(
          const IndividualApplicationsTab(),
          ledger: () async => throw StateError('offline'),
        ),
      );
      await t.pumpAndSettle();
      await expand(t);
      expect(find.text('Support totals unavailable'), findsOneWidget);
      expect(find.text('Retry support totals'), findsOneWidget);
    },
  );
  testWidgets(
    'capacity is unknown while applications load and retry recovers errors',
    (t) async {
      final pending = Completer<List<Application>>();
      var tries = 0;
      await t.pumpWidget(
        harness(
          const IndividualGrantTab(),
          apps: () {
            tries++;
            return tries == 1 ? pending.future : Future.value([awarded]);
          },
        ),
      );
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Checking capacity…'), findsOneWidget);
      pending.completeError(StateError('offline'));
      await t.pumpAndSettle();
      expect(find.text('Capacity unavailable'), findsOneWidget);
      await t.tap(find.text('Retry capacity'));
      await t.pumpAndSettle();
      expect(find.text('Capacity unavailable'), findsNothing);
      expect(find.text('1'), findsOneWidget);
    },
  );
  testWidgets('listing status reflects inactive and expired records', (
    t,
  ) async {
    await t.pumpWidget(
      harness(
        const IndividualGrantTab(),
        programs: [
          program.copyWith(isActive: false),
          program.copyWith(
            id: 'expired',
            deadline: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Active Grant'), findsNothing);
  });
  testWidgets(
    'profile rejects a blank display name before attempting a write',
    (t) async {
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith(
              (ref) async => StudentProfile.fromJson({
                'id': 'provider',
                'full_name': 'Elena',
              }),
            ),
            currentProviderTypeProvider.overrideWith(
              (ref) async => 'individual',
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: IndividualSettingsTab()),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, '  ');
      await t.ensureVisible(find.text('Save Profile Changes'));
      await t.tap(find.text('Save Profile Changes'));
      await t.pumpAndSettle();
      expect(find.text('Enter your display name'), findsOneWidget);
      expect(find.textContaining('Failed to update profile:'), findsNothing);
    },
  );
}
