import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/provider/presentation/org/org_scholarships_tab.dart';
import 'package:scholaris/features/provider/presentation/org/org_incoming_applications_tab.dart';
import 'package:scholaris/features/provider/presentation/org/org_settings_tab.dart';
import 'package:scholaris/dev/provider_preview/main.dart' as preview;
import 'package:scholaris/features/provider/providers/provider_scholarships_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';

class _Programs extends ProviderScholarshipsNotifier {
  @override
  Future<List<Scholarship>> build() async => [];
}

class _Applications extends IncomingApplicationsNotifier {
  @override
  Future<List<Application>> build() async => [
    const Application(
      id: 'a',
      userId: 'u',
      scholarshipId: 'missing',
      status: ApplicationStatus.approved,
    ),
  ];
}

void main() {
  testWidgets('organization program card actions fit the desktop workspace', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(preview.buildApp(individualPreview: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Scholarships'));
    await tester.pumpAndSettle();
  });
  for (final width in [360.0, 440.0, 1280.0]) {
    testWidgets('organization Settings fits workspace at $width', (
      tester,
    ) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(preview.buildApp(individualPreview: false));
      await tester.pumpAndSettle();
      if (width < 900) {
        await tester.tap(find.byIcon(Icons.menu_rounded));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'organization settings renders without direct backend initialization',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerScholarshipsProvider.overrideWith(_Programs.new),
            currentProfileProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(home: Scaffold(body: OrgSettingsTab())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Save organization name'), findsOneWidget);
    },
  );
  testWidgets(
    'application summary never invents award values or a recorded budget',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerScholarshipsProvider.overrideWith(_Programs.new),
            incomingApplicationsProvider.overrideWith(_Applications.new),
            providerApplicantProfilesProvider.overrideWith((ref) async => {}),
            currentProfileProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(
            home: Scaffold(body: OrgIncomingApplicationsTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Application summary'));
      await tester.pumpAndSettle();
      expect(find.textContaining('₱50,000'), findsNothing);
      expect(find.textContaining('grant budget'), findsNothing);
      expect(find.textContaining('1 award value unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'approval never invents a payment and program segments work by keyboard',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.binding.setSurfaceSize(const Size(1024, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerScholarshipsProvider.overrideWith(_Programs.new),
            incomingApplicationsProvider.overrideWith(_Applications.new),
            currentProfileProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(home: Scaffold(body: OrgScholarshipsTab())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Program summary'));
      await tester.pumpAndSettle();
      expect(find.text('Not a payment total'), findsOneWidget);
      expect(find.text('₱50,000'), findsNothing);
      expect(find.text('Tranche 1 Disbursed'), findsNothing);
      expect(
        find.textContaining('Funding verification not recorded'),
        findsOneWidget,
      );
      Focus.of(tester.element(find.text('Archived & Historical')))
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('No Archived Endowments'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
