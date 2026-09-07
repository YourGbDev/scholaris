// Shared test configuration — runs before every test file in this directory.
//
// The `test` package picks this file up automatically (flutter_test_config.dart)
// and passes each file's main() through [testExecutable], so anything here
// applies suite-wide without each file opting in.
//
// A tap on an off-screen or obscured widget silently misses: flutter_test only
// issues a warning, the interaction never lands, and the test then fails (or
// worse, passes) on stale UI state. Making that warning fatal turns a missed
// tap into an immediate, explicit failure at the tap site. Taps that
// intentionally miss keep working by passing `warnIfMissed: false` per call.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  await testMain();
}
