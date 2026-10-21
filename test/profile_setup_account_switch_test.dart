import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/profile/presentation/widgets/profile_setup_account_switch.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  testWidgets(
    'cancel keeps session; confirmed switch signs out then navigates',
    (t) async {
      var signedOut = 0;
      var navigated = 0;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            profileSetupSignOutProvider.overrideWithValue(() async {
              signedOut++;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProfileSetupAccountSwitch(onSignedOut: () => navigated++),
            ),
          ),
        ),
      );
      await t.tap(find.text('Use a different account'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(signedOut, 0);
      expect(navigated, 0);
      await t.tap(find.text('Use a different account'));
      await t.pumpAndSettle();
      await t.tap(find.text('Log Out'));
      await t.pumpAndSettle();
      expect(signedOut, 1);
      expect(navigated, 1);
    },
  );
  testWidgets('failed sign-out keeps user in setup with recovery message', (
    t,
  ) async {
    var navigated = false;
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          profileSetupSignOutProvider.overrideWithValue(() async {
            throw StateError('offline');
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProfileSetupAccountSwitch(
              onSignedOut: () => navigated = true,
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Use a different account'));
    await t.pumpAndSettle();
    await t.tap(find.text('Log Out'));
    await t.pumpAndSettle();
    expect(navigated, isFalse);
    expect(find.text('Could not sign out. Please try again.'), findsOneWidget);
  });
}
