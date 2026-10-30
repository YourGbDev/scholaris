import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/applications/presentation/submit_application_review_dialog.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/providers/scholarship_capacity_provider.dart';
import 'package:scholaris/features/schools/providers/school_provider.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';

final scholarship = Scholarship(
  id: 'actual-grant',
  title: 'Actual grant title',
  provider: 'Actual provider',
  minGpa: 2,
  deadline: DateTime(2030),
);
Widget wrap(Widget child) => ProviderScope(
  overrides: [
    currentUserIdProvider.overrideWithValue(null),
    currentProfileProvider.overrideWith((ref) async => null),
    schoolsProvider.overrideWith((ref) async => []),
    scholarshipCapacityProvider(scholarship.id)
        .overrideWith((ref) async => null),
    scholarshipEligibleSchoolsProvider(scholarship.id)
        .overrideWith((ref) async => []),
    applicationRepositoryProvider.overrideWith(
      (ref) => ApplicationRepository(
        dataSource: FakeApplicationDataSource(),
        currentUserId: () => null,
      ),
    ),
    bookmarkRepositoryProvider.overrideWith(
      (ref) => BookmarkRepository(
        dataSource: FakeBookmarkDataSource(),
        currentUserId: () => null,
      ),
    ),
  ],
  child: MaterialApp(home: child),
);

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await (FontLoader('Geist')
          ..addFont(rootBundle.load('assets/fonts/geist/Geist-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/geist/Geist-SemiBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/geist/Geist-Bold.ttf')))
        .load();
  });
  testWidgets(
    'real detail allows manual exploration and returns to the real demo apply action',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final back = GlobalKey();
      final apply = GlobalKey();
      var returns = 0;
      var applies = 0;
      var exits = 0;
      await tester.pumpWidget(
        wrap(
          ScholarshipDetailScreen(
            scholarshipId: scholarship.id,
            initial: scholarship,
            startApplication: true,
            tour: ScholarshipDetailTourHooks(
              scrollController: scroll,
              backToTopKey: back,
              applyKey: apply,
              onBackToTop: () => returns++,
              onApply: () => applies++,
              onExit: () => exits++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(scroll.offset, 0);
      expect(find.text('Actual grant title'), findsOneWidget);
      expect(
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.qr_code_rounded)).onPressed,
        isNull,
      );
      for (
        var i = 0;
        i < 30 && !find.byKey(back).hitTestable().evaluate().isNotEmpty;
        i++
      ) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      expect(scroll.offset, greaterThan(500));
      expect(find.byKey(back).hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(back));
      await tester.pumpAndSettle();
      expect(scroll.offset, 0);
      expect(returns, 1);
      await tester.tap(find.byKey(apply));
      await tester.pumpAndSettle();
      expect(applies, 1);
      expect(find.byType(SubmitApplicationReviewDialog), findsNothing);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();
      expect(exits, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'real review preserves confirmations and limits submit to the demo callback',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final confirmations = GlobalKey();
      final submit = GlobalKey();
      var saves = 0;
      var submits = 0;
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: Center(
              child: SubmitApplicationReviewDialog(
                scholarship: scholarship,
                onSaveDraft: () async {
                  saves++;
                },
                initialCertificationsChecked: true,
                tour: SubmitApplicationReviewTourHooks(
                  scrollController: scroll,
                  confirmationsKey: confirmations,
                  submitKey: submit,
                  onSubmit: () => submits++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(scroll.offset, 0);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Upload supporting document'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('apply-save-draft')));
      await tester.pump();
      expect(saves, 0);
      await tester.ensureVisible(find.byKey(confirmations));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .every((c) => c.value == true),
        isTrue,
      );
      await tester.tap(find.byKey(submit));
      await tester.pump();
      expect(submits, 1);
      expect(saves, 0);
      expect(find.byType(SubmitApplicationReviewDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
