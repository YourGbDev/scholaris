import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/shared/widgets/greeting_mascot.dart';

void main() {
  testWidgets('welcome pair scales as one composition on a narrow screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(width: 272, child: MascotWelcomePair(height: 260)),
        ),
      ),
    );
    final pair = tester.getRect(
      find.image(const AssetImage('assets/mascots/greetings/welcome_pair.png')),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(pair.width, lessThanOrEqualTo(272));
    expect(pair.height, lessThanOrEqualTo(260));
    expect(tester.takeException(), isNull);
  });
  test('greeting repeats only after a full three second rest', () {
    expect(
      MascotGreetingFrame.at(const Duration(milliseconds: 700)).wave,
      isNot(0),
    );
    for (final milliseconds in [2800, 3500, 5799]) {
      final frame = MascotGreetingFrame.at(
        Duration(milliseconds: milliseconds),
      );
      expect(frame.wave, 0);
      expect(frame.tilt, 0);
    }
    expect(
      MascotGreetingFrame.at(const Duration(milliseconds: 6500)).wave,
      MascotGreetingFrame.at(const Duration(milliseconds: 700)).wave,
    );
  });

  test('both rigs keep shoulder and hair beside wrist stationary', () {
    final frame = MascotGreetingFrame.at(const Duration(milliseconds: 700));
    for (final female in [false, true]) {
      for (final point in [
        const ui.Offset(.5, .78),
        const ui.Offset(.75, .8),
      ]) {
        expect(MascotGreetingRig.deform(point, frame, female: female), point);
      }
    }
    const hair = ui.Offset(.69, .65);
    expect(MascotGreetingRig.deform(hair, frame, female: true), hair);
    const hand = ui.Offset(.81, .46);
    expect(MascotGreetingRig.deform(hand, frame, female: true), isNot(hand));
  });

  testWidgets('reduced motion never schedules a repeating greeting', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: GreetingMascotPortrait(gender: 'female', height: 140),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 8));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inactive tab stops motion and the pause timer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TickerMode(
          enabled: false,
          child: GreetingMascotPortrait(gender: 'male', height: 150),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 8));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real controller rests for three seconds before restarting', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GreetingMascotPortrait(gender: 'male', height: 150),
      ),
    );
    await tester.pump(); // Establish the ticker's first frame before measuring.
    await tester.pump(
      MascotGreetingFrame.movement + const Duration(milliseconds: 1),
    );
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(milliseconds: 2999));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('backgrounding cancels movement until resumed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GreetingMascotPortrait(gender: 'female', height: 140),
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 7));
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
