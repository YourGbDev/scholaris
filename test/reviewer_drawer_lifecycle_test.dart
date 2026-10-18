import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/models/application_document.dart';
import 'package:scholaris/features/applications/providers/application_document_provider.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';
import 'package:scholaris/features/provider/providers/provider_sub_role_provider.dart';
import 'package:scholaris/features/provider/presentation/widgets/applicant_review_drawer.dart';
import 'helpers/fake_application_data_source.dart';

class _Documents extends ApplicationDocumentsNotifier {
  @override
  Future<List<ApplicationDocument>> build(String arg) async => [];
}

class _PendingReview extends FakeApplicationDataSource {
  final completion = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> reviewApplication(Map<String, dynamic> params) => completion.future;
}

void main() {
  testWidgets('closing drawer restores interaction; pending committed result survives disposal', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final navigator = GlobalKey<NavigatorState>();
    final source = _PendingReview();
    var taps = 0;
    await tester.pumpWidget(ProviderScope(overrides: [
      providerSubRoleProvider.overrideWithValue(const ProviderIdentityInfo(
        role: ProviderSubRole.evaluator, name: 'Reviewer', initials: 'R',
        roleSubtitle: 'Reviewer', topEyebrow: 'REVIEWER')),
      applicationRepositoryProvider.overrideWith((ref) => ApplicationRepository(
        dataSource: source, currentUserId: () => 'reviewer')),
      applicationDocumentsProvider.overrideWith(_Documents.new),
    ], child: MaterialApp(navigatorKey: navigator, home: Builder(builder: (context) => Scaffold(
      body: Center(child: FilledButton(onPressed: () {
        taps++;
        ApplicantReviewDrawer.show(context, application: const Application(
          id: 'a', userId: 'student', scholarshipId: 's', status: ApplicationStatus.submitted));
      }, child: const Text('Open Review'))),
    )))));
    await tester.tap(find.text('Open Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Endorse to Org Admin for Decision'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Endorse to Org Admin'));
    await tester.pump();
    // Dismiss while the server transaction is in flight (e.g. screen change).
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byType(ApplicantReviewDrawer), findsNothing);
    source.completion.complete({'id': 'a', 'user_id': 'student', 'scholarship_id': 's',
      'status': 'under_review', 'endorsed_by': 'reviewer'});
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Could not record'), findsNothing);
    // A lingering invisible modal barrier would make this a fatal missed tap.
    await tester.tap(find.text('Open Review'));
    await tester.pumpAndSettle();
    expect(taps, 2);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
  });
}
