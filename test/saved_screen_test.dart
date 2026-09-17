// test/saved_screen_test.dart
//
// Comprehensive widget tests for the Stitch V2 Saved Scholarships screen.
// Validates header counter, empty state with halo & suggestions, tab navigation CTA,
// populated scholarship cards, inline search filtering, interactive bookmark toggling,
// and clean responsive rendering on narrow viewports without overflows.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:scholaris/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/features/scholarships/repositories/scholarship_repository.dart';
import 'package:scholaris/features/scholarships/screens/saved_screen.dart';
import 'package:scholaris/shared/widgets/scholarship_card.dart';

import 'helpers/fake_application_data_source.dart';
import 'helpers/fake_bookmark_data_source.dart';
import 'helpers/fake_scholarship_data_source.dart';

Widget _wrapSavedScreen({
  required FakeBookmarkDataSource bookmarks,
  FakeScholarshipDataSource? scholarships,
  FakeApplicationDataSource? applications,
  String userId = 'user-a',
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      bookmarkRepositoryProvider.overrideWith(
        (ref) => BookmarkRepository(
          dataSource: bookmarks,
          currentUserId: () => userId,
        ),
      ),
      scholarshipRepositoryProvider.overrideWith(
        (ref) => ScholarshipRepository(
          dataSource: scholarships ?? FakeScholarshipDataSource(),
        ),
      ),
      applicationRepositoryProvider.overrideWith(
        (ref) => ApplicationRepository(
          dataSource: applications ?? FakeApplicationDataSource(),
          currentUserId: () => userId,
        ),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SavedScreen(),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('SavedScreen - Stitch V2 Empty State', () {
    testWidgets('renders empty state with halo, literal copy, CTA and suggested grants',
        (tester) async {
      final bookmarks = FakeBookmarkDataSource();

      await tester.pumpWidget(_wrapSavedScreen(bookmarks: bookmarks));
      await tester.pumpAndSettle();

      // Header title and count
      expect(find.text('Saved Scholarships'), findsOneWidget);
      expect(find.text('(0 saved)'), findsOneWidget);

      // Empty state literal headline & body from Stitch code.html
      expect(
        find.text("Save scholarships you're interested in"),
        findsOneWidget,
      );
      expect(
        find.text(
          'Keep track of deadlines, compare grant stipends, and prepare your '
          'application requirements without losing your spot. Tap the bookmark '
          'icon on any scholarship card to save it here.',
        ),
        findsOneWidget,
      );

      // Primary CTA button
      expect(find.text('Discover Scholarships'), findsOneWidget);

      // Trending Grants Near You suggested section
      expect(find.text('Trending Grants Near You'), findsOneWidget);
      expect(find.text('SUGGESTED'), findsOneWidget);
      expect(
        find.text('DOST-SEI Undergraduate Merit Scholarship'),
        findsOneWidget,
      );
      expect(
        find.text('Megaworld Foundation Future Tech Leaders'),
        findsOneWidget,
      );
    });

    testWidgets('bookmarking a suggested grant adds it to the bookmark list and shows toast',
        (tester) async {
      final bookmarks = FakeBookmarkDataSource();

      await tester.pumpWidget(_wrapSavedScreen(bookmarks: bookmarks));
      await tester.pumpAndSettle();

      // Find the first bookmark icon button in the suggested cards
      final bookmarkIcon = find.byIcon(Icons.bookmark_outline_rounded).first;
      await tester.tap(bookmarkIcon);
      await tester.pumpAndSettle();

      // Bookmark should be saved to data source
      expect(await bookmarks.fetchScholarshipIds('user-a'), contains('sch-dost'));

      // Toast / SnackBar verification
      expect(find.text('Scholarship saved to your list!'), findsOneWidget);
    });
  });

  group('SavedScreen - Populated State & Search', () {
    testWidgets('displays bookmarked scholarships as full cards and updates header count',
        (tester) async {
      final bookmarks = FakeBookmarkDataSource();
      await bookmarks.addBookmark('user-a', 'sch-dost');
      await bookmarks.addBookmark('user-a', 'sch-ched');

      await tester.pumpWidget(_wrapSavedScreen(bookmarks: bookmarks));
      await tester.pumpAndSettle();

      expect(find.text('(2 saved)'), findsOneWidget);
      expect(find.byType(ScholarshipCard), findsNWidgets(2));
      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsOneWidget);
    });

    testWidgets('search button opens search field and filters saved scholarships',
        (tester) async {
      final bookmarks = FakeBookmarkDataSource();
      await bookmarks.addBookmark('user-a', 'sch-dost');
      await bookmarks.addBookmark('user-a', 'sch-ched');

      await tester.pumpWidget(_wrapSavedScreen(bookmarks: bookmarks));
      await tester.pumpAndSettle();

      // Tap search icon button in top bar
      await tester.tap(find.byTooltip('Search saved scholarships'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      // Search for DOST
      await tester.enterText(find.byType(TextField), 'dost');
      await tester.pumpAndSettle();

      expect(find.byType(ScholarshipCard), findsOneWidget);
      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsNothing);

      // Search with no matches
      await tester.enterText(find.byType(TextField), 'xyz non-existent');
      await tester.pumpAndSettle();

      expect(find.byType(ScholarshipCard), findsNothing);
      expect(find.text('No matching saved scholarships'), findsOneWidget);

      // Clear search
      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();

      expect(find.byType(ScholarshipCard), findsNWidgets(2));
    });

    testWidgets('unbookmarking removes scholarship from saved list and shows toast',
        (tester) async {
      final bookmarks = FakeBookmarkDataSource();
      await bookmarks.addBookmark('user-a', 'sch-dost');

      await tester.pumpWidget(_wrapSavedScreen(bookmarks: bookmarks));
      await tester.pumpAndSettle();

      expect(find.byType(ScholarshipCard), findsOneWidget);

      // Tap bookmark button on the card
      await tester.tap(find.byIcon(Icons.bookmark_rounded).first);
      await tester.pumpAndSettle();

      // Should now show empty state
      expect(find.byType(ScholarshipCard), findsNothing);
      expect(find.text("Save scholarships you're interested in"), findsOneWidget);
      expect(find.text('Scholarship removed from bookmarks'), findsOneWidget);
    });
  });

  group('SavedScreen - Responsive Rendering', () {
    testWidgets('empty state renders cleanly on a 360px screen with zero overflows',
        (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final bookmarks = FakeBookmarkDataSource();

      await tester.pumpWidget(_wrapSavedScreen(bookmarks: bookmarks));
      await tester.pumpAndSettle();

      expect(find.text('Saved Scholarships'), findsOneWidget);
      expect(find.text("Save scholarships you're interested in"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('populated list renders cleanly on a 360px screen with zero overflows',
        (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final bookmarks = FakeBookmarkDataSource();
      await bookmarks.addBookmark('user-a', 'sch-dost');
      await bookmarks.addBookmark('user-a', 'sch-ched');

      await tester.pumpWidget(_wrapSavedScreen(bookmarks: bookmarks));
      await tester.pumpAndSettle();

      expect(find.text('DOST-SEI Undergraduate Scholarship'), findsOneWidget);
      expect(find.text('CHED Merit Scholarship (MSRS)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
