import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/provider/presentation/widgets/provider_overview_panel.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('organization shortcuts open team and activity workflows', (
    tester,
  ) async {
    var destination = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderOverviewPanel(
            name: 'Bukas Foundation',
            individual: false,
            scholarships: const [],
            applicationCount: 0,
            pendingCount: 0,
            onApplications: () {},
            onScholarships: () {},
            onTeam: () => destination = 'team',
            onActivity: () => destination = 'activity',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Manage reviewers'));
    await tester.tap(find.text('Manage reviewers'));
    expect(destination, 'team');
    await tester.ensureVisible(find.text('View activity'));
    await tester.tap(find.text('View activity'));
    expect(destination, 'activity');
  });
  for (final size in [(320.0, 2.0), (390.0, 1.0), (1280.0, 1.0)]) {
    testWidgets(
      'individual welcome stays separate from review priority at $size',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(size.$1, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var reviewed = false;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(size.$2)),
              child: child!,
            ),
            home: Scaffold(
              body: ProviderOverviewPanel(
                name: 'Elena',
                individual: true,
                scholarships: const [],
                applicationCount: 3,
                pendingCount: 3,
                onApplications: () => reviewed = true,
                onScholarships: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final mascot = find.image(
          const AssetImage('assets/mascots/greetings/ari.png'),
        );
        expect(mascot, findsOneWidget);
        expect(
          find.image(
            const AssetImage('assets/images/provider_hero_illustration.png'),
          ),
          findsNothing,
        );
        expect(find.text('Hi, Elena'), findsOneWidget);
        expect(
          tester.getRect(mascot).bottom,
          lessThan(tester.getRect(find.text('3 applications to review')).top),
        );
        await tester.ensureVisible(find.text('Review applications'));
        await tester.tap(find.text('Review applications'));
        expect(reviewed, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [360.0, 1280.0]) {
    testWidgets(
      'organization overview has one review priority and responsive workspace at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProviderOverviewPanel(
                name: 'Bukas Foundation',
                individual: false,
                scholarships: [
                  Scholarship(
                    id: 's',
                    title: 'Community Education Scholarship for Undergraduate Students',
                    minGpa: 2,
                    deadline: DateTime(2099, 12, 31),
                  ),
                ],
                applicationCount: 6,
                pendingCount: 3,
                decidedCount: 2,
                onApplications: () {},
                onScholarships: () {},
                onAnalytics: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('3 applications awaiting review'), findsOneWidget);
        expect(find.text('Upcoming deadlines'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('provider overview actions and empty state at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var destination = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderOverviewPanel(
              name: 'Elena',
              individual: true,
              scholarships: const [],
              applicationCount: 0,
              pendingCount: 0,
              onApplications: () => destination = 'applications',
              onScholarships: () => destination = 'scholarships',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hi, Elena'), findsOneWidget);
      expect(find.text('Start your first scholarship'), findsOneWidget);
      expect(find.text('Your first opportunity starts here.'), findsOneWidget);
      await tester.ensureVisible(find.text('Manage scholarships'));
      await tester.tap(find.text('Manage scholarships'));
      expect(destination, 'scholarships');
      expect(tester.takeException(), isNull);
    });
  }
}
