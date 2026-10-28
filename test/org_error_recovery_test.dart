import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/provider/presentation/org/org_team_view.dart';
import 'package:scholaris/features/provider/providers/organization_team_provider.dart';

void main() {
  testWidgets('team error hides diagnostics and retry reloads the roster', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    var attempts = 0;
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizationRosterProvider.overrideWith((ref) async {
            attempts++;
            if (attempts == 1) throw Exception('private diagnostic');
            return [];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: OrgTeamView())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('private diagnostic'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Could not load team roster'), findsNothing);
  });
}
