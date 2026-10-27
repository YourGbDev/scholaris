import 'package:scholaris/features/home/presentation/widgets/liquid_glass_pill.dart';
// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('Student Nav Rebuild: Full-height viewport, extendBody, and LiquidGlass + button',
      (WidgetTester tester) async {
    const screenWidth = 440.0;
    const screenHeight = 956.0;
    tester.view.physicalSize = const Size(screenWidth, screenHeight);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    print('\n======================================================');
    print('  STUDENT NAV REBUILD VERIFICATION SUITE');
    print('======================================================\n');

    // 1. Assert Scaffold.extendBody == true
    final scaffoldFinder = find.byType(Scaffold).first;
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    print('[ASSERTION 1] Checking Scaffold.extendBody');
    print('  - Scaffold.extendBody: ${scaffold.extendBody}');
    expect(scaffold.extendBody, isTrue,
        reason: 'Scaffold.extendBody must be true to allow body to fill full height.');

    // Assert Scaffold has no bottomNavigationBar widget set
    print('  - Scaffold.bottomNavigationBar: ${scaffold.bottomNavigationBar}');
    expect(scaffold.bottomNavigationBar, isNull,
        reason: 'bottomNavigationBar must be null (nav is moved to Stack foreground layer).');

    // 2. Assert scroll view's viewport bottom edge equals screen height (956.0)
    print('\n[ASSERTION 2] Checking ScrollView Viewport Bounds');
    final viewportFinder = find.byType(Viewport).first;
    final renderViewport = tester.renderObject(viewportFinder) as RenderViewport;
    final viewportGlobalOffset = renderViewport.localToGlobal(Offset.zero);
    final viewportBottomEdge = viewportGlobalOffset.dy + renderViewport.size.height;

    print('  - Viewport global position: $viewportGlobalOffset');
    print('  - Viewport size: ${renderViewport.size}');
    print('  - Viewport bottom edge: $viewportBottomEdge');
    print('  - Target screen height: $screenHeight');

    expect(viewportBottomEdge, equals(screenHeight),
        reason: 'The scroll view viewport must extend to the very bottom of the screen (956.0).');

    // Also verify nav overlay bounds and height equality
    final sizedBox58Finder = find.byWidgetPredicate(
      (w) => w is SizedBox && w.height == 58.0 && w.width == null,
    );
    final outerSizedBoxBox = tester.renderObject(sizedBox58Finder.first) as RenderBox;

    final navFinder = find.descendant(
      of: find.byType(Stack),
      matching: find.byType(LiquidGlassPill),
    );
    expect(navFinder, findsNWidgets(2),
        reason: 'Both the 4-tab pill and the detached "+" button must be LiquidGlass widgets.');

    final pillRenderBox = tester.renderObject(navFinder.first) as RenderBox;
    final pillOffset = pillRenderBox.localToGlobal(Offset.zero);

    final plusRenderBox = tester.renderObject(navFinder.at(1)) as RenderBox;
    final plusOffset = plusRenderBox.localToGlobal(Offset.zero);

    print('\n[NAV OVERLAY BOUNDS]');
    print('  - Outer SizedBox(height: 58) size: ${outerSizedBoxBox.size}');
    print('  - 4-Tab Pill bounds: Offset(${pillOffset.dx}, ${pillOffset.dy}) | Size: ${pillRenderBox.size}');
    print('  - "+" Circle bounds: Offset(${plusOffset.dx}, ${plusOffset.dy}) | Size: ${plusRenderBox.size}');

    expect(outerSizedBoxBox.size.height, equals(58.0),
        reason: 'Outer SizedBox must render at height 58.0.');
    expect(pillRenderBox.size.height, equals(58.0),
        reason: '4-Tab pill must render at full 58.0 height.');
    expect(plusRenderBox.size.height, equals(58.0),
        reason: '"+" circle must render at full 58.0 height.');
    expect(pillOffset.dy, equals(plusOffset.dy),
        reason: 'Pill and "+" button must vertically align with identical dy offsets.');

    // 3. Assert the "+" button widget tree contains no Container with a solid non-transparent Color
    print('\n[ASSERTION 3] Checking "+" Button Widget Tree for Solid Containers');
    final addIconFinder = find.byIcon(Icons.add_rounded);
    expect(addIconFinder, findsOneWidget);

    final plusIconWidget = tester.widget<Icon>(addIconFinder);
    print('  - "+" Icon color: ${plusIconWidget.color}');
    expect(plusIconWidget.color, equals(const Color(0xFF141414)),
        reason: '"+" icon uses the requested near-black ink.');

    // Trace ancestors of the "+" icon up to the LiquidGlass widget
    final plusLiquidGlass = tester.widget<LiquidGlassPill>(navFinder.at(1));
    print('  - "+" LiquidGlass core blur: ${plusLiquidGlass.coreBlur}');
    print('  - "+" LiquidGlass tintOpacity: ${plusLiquidGlass.tintOpacity}');

    expect(plusLiquidGlass.coreBlur, 6.5);
    expect(plusLiquidGlass.tintOpacity, .44);

    // Verify no solid opaque Container inside the "+" button tree
    final plusSubtreeContainers = tester.widgetList<Container>(
      find.descendant(
        of: navFinder.at(1),
        matching: find.byType(Container),
      ),
    );

    for (final container in plusSubtreeContainers) {
      if (container.color != null) {
        print('  - Checking container color: ${container.color} (alpha: ${container.color!.a})');
        expect(container.color!.a, lessThan(1.0),
            reason: 'No container in "+" button may have a solid opaque color.');
      }
      final decoration = container.decoration;
      if (decoration is BoxDecoration && decoration.color != null) {
        print('  - Checking decoration color: ${decoration.color} (alpha: ${decoration.color!.a})');
        expect(decoration.color!.a, lessThan(1.0),
            reason: 'No BoxDecoration in "+" button may have a solid opaque color.');
      }
    }
    print('  - Verified: Zero solid non-transparent Containers found in "+" button tree.');

    print('\n======================================================');
    print('  All student navigation rebuild assertions passed.');
    print('======================================================\n');
  });
}
