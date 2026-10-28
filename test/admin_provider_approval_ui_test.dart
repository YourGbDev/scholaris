import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scholaris/features/admin/presentation/admin_providers_tab.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/provider/data/provider_verification_repository.dart';
import 'package:scholaris/features/provider/models/provider_verification.dart';
import 'package:scholaris/features/provider/providers/provider_verification_provider.dart';

class ReviewRepo extends ProviderVerificationRepository {
  ReviewRepo()
    : super(
        client: SupabaseClient(
          'https://test.supabase.co',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  final rows = [
    ProviderVerification(
      userId: 'new',
      providerType: 'individual',
      fullName: 'New person',
      submittedAt: DateTime(2026, 2),
    ),
    ProviderVerification(
      userId: 'old',
      providerType: 'organization',
      orgName: 'Older organization',
      submittedAt: DateTime(2026, 1),
    ),
    const ProviderVerification(
      userId: 'approved',
      providerType: 'individual',
      fullName: 'Already approved',
      status: 'approved',
    ),
  ];
  int calls = 0;
  String? actor, decision, note;
  bool fail = false;
  bool failFetch = false;
  Completer<void>? fetching;
  Completer<void>? pending;
  @override
  Future<List<ProviderVerification>> fetchAllVerifications() async {
    if (fetching != null) await fetching!.future;
    if (failFetch) throw StateError('private diagnostic');
    return rows;
  }

  @override
  Future<ProviderVerification> updateVerificationStatus({
    required String userId,
    required String status,
    required String adminId,
    String? expectedStatus,
    String? reviewNote,
  }) async {
    calls++;
    actor = adminId;
    decision = status;
    note = reviewNote;
    if (pending != null) await pending!.future;
    if (fail) throw StateError('Unavailable');
    return ProviderVerification(
      userId: userId,
      providerType: 'individual',
      status: status,
      reviewedBy: adminId,
      reviewNote: reviewNote,
    );
  }

  @override
  Future<ProviderVerification> reviewVerification({
    required String userId,
    required String status,
    String? expectedStatus,
    String? reviewNote,
  }) async {
    return updateVerificationStatus(
      userId: userId,
      status: status,
      adminId: 'real-admin',
      expectedStatus: expectedStatus,
      reviewNote: reviewNote,
    );
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  Future<void> open(
    WidgetTester t,
    ReviewRepo repo, {
    String? actor = 'real-admin',
    Size size = const Size(1280, 800),
    double scale = 1,
    bool settle = true,
  }) async {
    await t.binding.setSurfaceSize(size);
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          providerVerificationRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue(actor),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Scaffold(body: AdminProvidersTab()),
        ),
      ),
    );
    if (settle) await t.pumpAndSettle();
  }

  testWidgets(
    'pending is default and oldest is first; type filters retain context',
    (t) async {
      await open(t, ReviewRepo());
      expect(find.text('Already approved'), findsNothing);
      expect(
        t.getTopLeft(find.text('Older organization')).dy,
        lessThan(t.getTopLeft(find.text('New person')).dy),
      );
      await t.tap(find.widgetWithText(ChoiceChip, 'Individual'));
      await t.pumpAndSettle();
      expect(find.text('Older organization'), findsNothing);
      expect(find.text('New person'), findsOneWidget);
    },
  );
  for (final decision in ['Approve', 'Reject']) {
    testWidgets(
      '$decision requires note and confirmation and uses real session',
      (t) async {
        final repo = ReviewRepo();
        await open(t, repo);
        await t.scrollUntilVisible(
          find.byKey(const ValueKey('review-old')),
          250,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await t.ensureVisible(find.byKey(const ValueKey('review-old')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('review-old')));
        await t.pumpAndSettle();
        await t.ensureVisible(find.widgetWithText(FilledButton, decision));
        await t.tap(find.widgetWithText(FilledButton, decision));
        await t.pumpAndSettle();
        expect(repo.calls, 0);
        expect(
          find.text(
            'Explain the evidence reviewed and the reason for this decision.',
          ),
          findsWidgets,
        );
        await t.enterText(
          find.byType(TextField).last,
          'Reviewed submitted identity evidence.',
        );
        await t.ensureVisible(find.widgetWithText(FilledButton, decision));
        await t.tap(find.widgetWithText(FilledButton, decision));
        await t.pumpAndSettle();
        expect(repo.calls, 0);
        await t.tap(find.text('Confirm $decision'));
        await t.pumpAndSettle();
        expect(repo.calls, 1);
        expect(repo.actor, 'real-admin');
        expect(repo.decision, decision == 'Approve' ? 'approved' : 'rejected');
      },
    );
  }
  testWidgets(
    'Request changes requires note and confirmation and records changes_requested',
    (t) async {
      final repo = ReviewRepo();
      await open(t, repo);
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('review-old')),
        250,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.ensureVisible(find.byKey(const ValueKey('review-old')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('review-old')));
      await t.pumpAndSettle();
      await t.ensureVisible(find.widgetWithText(OutlinedButton, 'Request changes'));
      await t.tap(find.widgetWithText(OutlinedButton, 'Request changes'));
      await t.pumpAndSettle();
      expect(repo.calls, 0);
      expect(
        find.text(
          'Explain the evidence reviewed and the reason for this decision.',
        ),
        findsWidgets,
      );
      await t.enterText(
        find.byType(TextField).last,
        'Please submit official BIR 2303 registration certificate.',
      );
      await t.ensureVisible(find.widgetWithText(OutlinedButton, 'Request changes'));
      await t.tap(find.widgetWithText(OutlinedButton, 'Request changes'));
      await t.pumpAndSettle();
      expect(repo.calls, 0);
      await t.tap(find.text('Confirm Request changes'));
      await t.pumpAndSettle();
      expect(repo.calls, 1);
      expect(repo.actor, 'real-admin');
      expect(repo.decision, 'changes_requested');
      expect(repo.note, 'Please submit official BIR 2303 registration certificate.');
    },
  );
  testWidgets('failure preserves notes and permits retry', (t) async {
    final repo = ReviewRepo()..fail = true;
    await open(t, repo);
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('review-old')),
      250,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await t.ensureVisible(find.byKey(const ValueKey('review-old')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('review-old')));
    await t.pumpAndSettle();
    await t.enterText(
      find.byType(TextField).last,
      'Identity evidence reviewed.',
    );
    await t.ensureVisible(find.widgetWithText(FilledButton, 'Approve'));
    await t.tap(find.widgetWithText(FilledButton, 'Approve'));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirm Approve'));
    await t.pumpAndSettle();
    expect(
      find.text(
        'Could not save the decision. Your note is preserved. Try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Identity evidence reviewed.'), findsOneWidget);
    repo.fail = false;
    await t.ensureVisible(find.widgetWithText(FilledButton, 'Approve'));
    await t.tap(find.widgetWithText(FilledButton, 'Approve'));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirm Approve'));
    await t.pumpAndSettle();
    expect(repo.calls, 2);
  });
  testWidgets('missing session fails closed', (t) async {
    final repo = ReviewRepo();
    await open(t, repo, actor: null);
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('review-old')),
      250,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await t.ensureVisible(find.byKey(const ValueKey('review-old')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('review-old')));
    await t.pumpAndSettle();
    expect(
      find.text('Sign in again before making a decision.'),
      findsOneWidget,
    );
    expect(
      t
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Approve'))
          .onPressed,
      isNull,
    );
    expect(repo.calls, 0);
  });
  testWidgets('narrow large text review scrolls without overflow', (t) async {
    await open(t, ReviewRepo(), size: const Size(360, 800), scale: 2);
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('review-old')),
      250,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await t.ensureVisible(find.byKey(const ValueKey('review-old')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('review-old')));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -1000),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets('loading, safe error and retry stay distinct', (t) async {
    final repo = ReviewRepo()
      ..fetching = Completer<void>()
      ..failFetch = true;
    await open(t, repo, settle: false);
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('No submissions'), findsNothing);
    repo.fetching!.complete();
    await t.pumpAndSettle();
    expect(
      find.text('Could not load provider submissions. Try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('private diagnostic'), findsNothing);
    repo.failFetch = false;
    repo.fetching = null;
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle();
    expect(find.text('Older organization'), findsOneWidget);
  });
  testWidgets(
    'in-flight decision disables repeat actions and preserves review',
    (t) async {
      final repo = ReviewRepo()..pending = Completer<void>();
      await open(t, repo);
      await t.tap(find.byKey(const ValueKey('review-old')));
      await t.pumpAndSettle();
      await t.enterText(
        find.byType(TextField).last,
        'Evidence reviewed with reasons.',
      );
      await t.ensureVisible(find.widgetWithText(FilledButton, 'Approve'));
      await t.tap(find.widgetWithText(FilledButton, 'Approve'));
      await t.pumpAndSettle();
      await t.tap(find.text('Confirm Approve'));
      await t.pump(const Duration(milliseconds: 400));
      expect(repo.calls, 1);
      expect(
        t
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Approve'))
            .onPressed,
        isNull,
      );
      expect(
        t
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Reject'))
            .onPressed,
        isNull,
      );
      expect(
        t
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close))
            .onPressed,
        isNull,
      );
      repo.pending!.complete();
      await t.pumpAndSettle();
      expect(repo.calls, 1);
    },
  );
}
