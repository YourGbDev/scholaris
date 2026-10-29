import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/shared/widgets/workspace_smooth_scroll.dart';

void main() {
  testWidgets('resizing the viewport preserves an in-bounds wheel target', (
    tester,
  ) async {
    final controller = SmoothWheelScrollController();
    addTearDown(controller.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(800, 600));
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          controller: controller,
          children: const [SizedBox(height: 3000)],
        ),
      ),
    );
    controller.position.pointerScroll(500);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.binding.setSurfaceSize(const Size(800, 500));
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(500, .1));
  });

  testWidgets('touch drag interrupts an active wheel glide', (tester) async {
    final controller = SmoothWheelScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          controller: controller,
          children: const [SizedBox(height: 3000)],
        ),
      ),
    );
    controller.position.pointerScroll(500);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final gesture = await tester.startGesture(const Offset(200, 300));
    await tester.pump(const Duration(milliseconds: 100));
    final heldOffset = controller.offset;
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.offset, heldOffset);
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    expect(controller.offset, greaterThan(heldOffset));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion and disposal stop an active glide', (
    tester,
  ) async {
    final controller = SmoothWheelScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          controller: controller,
          children: const [SizedBox(height: 3000)],
        ),
      ),
    );
    controller.position.pointerScroll(500);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final before = controller.offset;
    controller.reducedMotion = true;
    await tester.pumpAndSettle();
    expect(controller.offset, before);
    controller.position.pointerScroll(120);
    expect(controller.offset, closeTo(before + 120, .1));
    controller.reducedMotion = false;
    controller.position.pointerScroll(500);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'wheel glide keeps settling after the old fixed animation ended',
    (tester) async {
      final controller = SmoothWheelScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            controller: controller,
            children: const [SizedBox(height: 3000)],
          ),
        ),
      );
      controller.position.pointerScroll(300);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.offset, inExclusiveRange(150, 280));
      final before = controller.offset;
      controller.position.pointerScroll(120);
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.offset, greaterThan(before));
      await tester.pumpAndSettle();
      expect(controller.offset, closeTo(420, .1));
    },
  );

  testWidgets('wheel glide covers the same distance at different frame rates', (
    tester,
  ) async {
    final controller = SmoothWheelScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          controller: controller,
          children: const [SizedBox(height: 3000)],
        ),
      ),
    );
    controller.position.pointerScroll(300);
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    final highRefreshOffset = controller.offset;
    controller.jumpTo(0);
    controller.position.pointerScroll(300);
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(controller.offset, closeTo(highRefreshOffset, .01));
    await tester.pumpAndSettle();
  });

  testWidgets('a direct jump cancels the wheel target and its ticker', (
    tester,
  ) async {
    final controller = SmoothWheelScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          controller: controller,
          children: const [SizedBox(height: 3000)],
        ),
      ),
    );
    controller.position.pointerScroll(500);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    controller.jumpTo(80);
    await tester.pumpAndSettle();
    expect(controller.offset, 80);
    controller.position.pointerScroll(120);
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(200, .1));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

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
  testWidgets(
    'wheel bursts accumulate and reverse without finishing the old target',
    (tester) async {
      final controller = SmoothWheelScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            controller: controller,
            children: const [SizedBox(height: 3000)],
          ),
        ),
      );
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
    },
  );
}
