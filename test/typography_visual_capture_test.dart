// Matched, offline captures of real app components. Not native-platform proof.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholaris/dev/provider_preview/main.dart' as provider_preview;
import 'package:scholaris/dev/admin_preview/main.dart' as admin_preview;
import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/onboarding/presentation/onboarding_screen.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';

void main() {
  // Routine test runs must not replace reviewed before/after evidence.
  const phase = String.fromEnvironment('CAPTURE_PHASE');
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
    for (final family in ['Geist']) {
      final directory = Directory('assets/fonts/${family.toLowerCase()}');
      if (!directory.existsSync()) continue;
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
        loader.addFont(
          rootBundle.load('${directory.path}/$family-$weight.ttf'),
        );
      }
      await loader.load();
    }
  });

  final scholarship = Scholarship.fromJson({
    'id': 'typography-fixture',
    'title': 'José Rizal Science and Technology Leadership Scholarship',
    'provider': 'Fundación Educación • Philippines',
    'description': 'Supports students pursuing science and technology.',
    'min_gpa': 2.0,
    'required_year_levels': [1, 2, 3, 4],
    'required_courses': <String>[],
    'slots': 120,
    'deadline': '2099-12-18',
    'is_active': true,
    'amount': 50000,
  });

  for (final entry in <String, Widget>{
    'onboarding': const OnboardingScreen(),
    for (var page = 1; page <= 4; page++)
      'onboarding-feature-$page': OnboardingScreen(initialPage: page),
    'authentication': const LoginScreen(),
    'authentication-errors': const LoginScreen(),
    'provider-organization': provider_preview.buildApp(
      individualPreview: false,
    ),
    'provider-individual': provider_preview.buildApp(individualPreview: true),
    'admin': admin_preview.buildAdminPreview(),
    'scholarship-card': Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ScholarshipCard(scholarship: scholarship, matchPercentage: 98),
      ),
    ),
    'logout-dialog': const Scaffold(body: _DialogFixture()),
  }.entries) {
    for (final width in [320.0, 390.0]) {
      testWidgets('${entry.key} at $width matched capture', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final boundary = GlobalKey();
        final standalone =
            entry.key.startsWith('provider-') || entry.key == 'admin';
        if (standalone) {
          await tester.pumpWidget(
            RepaintBoundary(key: boundary, child: entry.value),
          );
        } else {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: scholarisTheme(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: true),
                  child: RepaintBoundary(key: boundary, child: child!),
                ),
                home: entry.value,
              ),
            ),
          );
        }
        await tester.pumpAndSettle();
        if (entry.key == 'authentication-errors') {
          tester.state<FormState>(find.byType(Form).first).validate();
          await tester.pumpAndSettle();
        }
        await tester.runAsync(() async {
          for (final element in find.byType(Image).evaluate()) {
            await precacheImage((element.widget as Image).image, element);
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (phase.isNotEmpty) {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final output = File(
            'docs/reports/2026-11-04-typography/$phase/${entry.key}-${width.toInt()}.png',
          );
          await tester.runAsync(() async {
            final image = await render.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await output.parent.create(recursive: true);
            await output.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}

class _DialogFixture extends StatefulWidget {
  const _DialogFixture();
  @override
  State<_DialogFixture> createState() => _DialogFixtureState();
}

class _DialogFixtureState extends State<_DialogFixture> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showLogoutConfirmationDialog(context);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
