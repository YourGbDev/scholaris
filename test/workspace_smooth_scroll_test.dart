import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/shared/widgets/workspace_smooth_scroll.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets('wheel scrolling respects reduced motion $reduced', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: WorkspaceSmoothScroll(
              child: ListView(children: const [SizedBox(height: 3000)]),
            ),
          ),
        ),
      );
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(200, 200));
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(200, 200),
          scrollDelta: Offset(0, 120),
        ),
      );
      await tester.pump();
      expect(scrollable.position.pixels, reduced ? 120 : 0);
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, closeTo(120, .1));
      await gesture.removePointer();
    });
  }
  testWidgets('wheel bursts accumulate and reverse without finishing the old target', (tester) async {
    final controller = SmoothWheelScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(home: ListView(controller: controller, children: const [SizedBox(height: 3000)])));
    controller.position.pointerScroll(120);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    controller.position.pointerScroll(120);
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(240, .1));
    controller.position.pointerScroll(300);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final turningPoint = controller.offset;
    controller.position.pointerScroll(-80);
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(turningPoint - 80, .1));
    controller.position.pointerScroll(10000);
    await tester.pumpAndSettle();
    expect(controller.offset, controller.position.maxScrollExtent);
  });}
