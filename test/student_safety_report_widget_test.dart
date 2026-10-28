import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/safety/data/safety_report_repository.dart';
import 'package:scholaris/features/safety/models/safety_report.dart';
import 'package:scholaris/features/safety/presentation/student_safety_report.dart';

class FakeSafetyReportRepo extends SafetyReportRepository {
  int submitCalls = 0;
  int attachCalls = 0;
  final List<String> attachedFiles = [];
  final List<String?> attachedKeys = [];
  Set<String> failOnFiles = {};
  Set<String> failOnKeys = {};
  bool throwAmbiguousOnce = false;
  int ambiguousThrownCount = 0;
  List<SafetyReport> studentReports = [];
  String? lastScholarshipId, lastCategory, lastRelationship, lastDescription;
  bool shouldFail = false;

  @override
  Future<String> submitReport({
    required String scholarshipId,
    required String category,
    required String relationship,
    required String description,
    DateTime? incidentOn,
  }) async {
    submitCalls++;
    lastScholarshipId = scholarshipId;
    lastCategory = category;
    lastRelationship = relationship;
    lastDescription = description;
    if (shouldFail) {
      throw StateError('Daily report submission limit reached (5 per 24 hours)');
    }
    final report = SafetyReport(
      id: 'new-report-uuid-123',
      scholarshipId: scholarshipId,
      providerId: 'prov-123',
      reporterId: 'student-123',
      category: category,
      relationship: relationship,
      description: description,
      status: 'open',
      createdAt: DateTime.now(),
      scholarshipTitle: 'Excellence STEM Grant',
      evidence: [],
    );
    studentReports.add(report);
    return 'new-report-uuid-123';
  }

  @override
  Future<String> attachEvidence({
    required String reportId,
    required Uint8List bytes,
    required String fileName,
    String? userId,
    String? attachmentKey,
  }) async {
    attachCalls++;
    if (throwAmbiguousOnce && ambiguousThrownCount == 0) {
      ambiguousThrownCount++;
      // Simulate server committed the row in database, but network connection dropped on client
      attachedFiles.add(fileName);
      attachedKeys.add(attachmentKey);
      throw StateError('Client network connection dropped before response received');
    }
    if (failOnFiles.contains(fileName) || (attachmentKey != null && failOnKeys.contains(attachmentKey))) {
      throw StateError('Simulated upload failure for $fileName');
    }
    // Idempotent: don't double register if key is already attached
    if (attachmentKey == null || !attachedKeys.contains(attachmentKey)) {
      attachedFiles.add(fileName);
      attachedKeys.add(attachmentKey);
    }
    return 'evidence-uuid-${attachedFiles.length}';
  }

  @override
  Future<List<SafetyReport>> fetchReportsForStudent(String studentId) async {
    return List.unmodifiable(studentReports);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('StudentSafetyReportButton renders and opens dialog', (tester) async {
    final fakeRepo = FakeSafetyReportRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          safetyReportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StudentSafetyReportButton(
              scholarshipId: 'sch-123',
              scholarshipTitle: 'Excellence STEM Grant',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Report concern'), findsOneWidget);

    // Tap button to open dialog
    await tester.tap(find.text('Report concern'));
    await tester.pumpAndSettle();

    expect(find.text('Report safety or integrity concern'), findsOneWidget);
    expect(find.text('Excellence STEM Grant'), findsOneWidget);
    expect(find.textContaining('Strictly confidential'), findsOneWidget);
    expect(find.text('Concern category'), findsOneWidget);
    expect(find.text('Submit report'), findsOneWidget);
  });

  testWidgets('StudentSafetyReportDialog validates description minimum length', (tester) async {
    final fakeRepo = FakeSafetyReportRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          safetyReportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StudentSafetyReportDialog(
              scholarshipId: 'sch-123',
              scholarshipTitle: 'Excellence STEM Grant',
            ),
          ),
        ),
      ),
    );

    // Attempt submit with empty description
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please provide at least 10 characters describing the issue.'),
      findsOneWidget,
    );
    expect(fakeRepo.submitCalls, 0);

    // Enter short text (< 10 chars)
    await tester.enterText(find.byType(TextFormField), 'Too short');
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please provide at least 10 characters describing the issue.'),
      findsOneWidget,
    );
    expect(fakeRepo.submitCalls, 0);

    // Enter valid description and submit
    await tester.enterText(
      find.byType(TextFormField),
      'The sponsor asked for payment of processing fee via private GCash.',
    );
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(fakeRepo.submitCalls, 1);
    expect(fakeRepo.lastScholarshipId, 'sch-123');
    expect(
      fakeRepo.lastDescription,
      'The sponsor asked for payment of processing fee via private GCash.',
    );
    expect(find.text('Report submitted'), findsOneWidget);
  });

  testWidgets('StudentSafetyReportDialog displays rate limit error and preserves text', (tester) async {
    final fakeRepo = FakeSafetyReportRepo()..shouldFail = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          safetyReportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StudentSafetyReportDialog(
              scholarshipId: 'sch-123',
              scholarshipTitle: 'Excellence STEM Grant',
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField),
      'Concern description that will hit the rate limit.',
    );
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('You have reached the daily report limit'),
      findsOneWidget,
    );
    // Preserves text input
    expect(
      find.text('Concern description that will hit the rate limit.'),
      findsOneWidget,
    );
  });

  testWidgets('StudentSafetyReportHistoryDialog displays reporter history', (tester) async {
    const studentId = 'test-student-123';
    final pastReports = [
      const SafetyReport(
        id: 'rep-1',
        scholarshipId: 'sch-1',
        providerId: 'prov-1',
        reporterId: studentId,
        category: 'fraud',
        relationship: 'experienced',
        description: 'Sponsor asked for registration payment',
        status: 'under_review',
        scholarshipTitle: 'STEM Merit Grant',
      ),
      const SafetyReport(
        id: 'rep-2',
        scholarshipId: 'sch-2',
        providerId: 'prov-2',
        reporterId: studentId,
        category: 'unsafe_meetup',
        relationship: 'witnessed',
        description: 'Private off-campus meeting condition',
        status: 'resolved',
        resolutionNote: 'Provider notified and listing updated.',
        scholarshipTitle: 'Future Leaders Award',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(studentId),
          studentSafetyReportsProvider(studentId).overrideWith(
            (ref) async => pastReports,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StudentSafetyReportHistoryDialog(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your safety reports'), findsOneWidget);
    expect(find.text('STEM Merit Grant'), findsOneWidget);
    expect(find.text('UNDER REVIEW'), findsOneWidget);
    expect(find.text('Future Leaders Award'), findsOneWidget);
    expect(find.text('RESOLVED'), findsOneWidget);
    expect(
      find.text('Update from safety team: Provider notified and listing updated.'),
      findsOneWidget,
    );
  });

  testWidgets('StudentSafetyReportDialog recovers from first attachment failure without duplicating report', (tester) async {
    final fakeRepo = FakeSafetyReportRepo()..failOnFiles = {'doc1.png'};

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('student-123'),
          safetyReportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StudentSafetyReportDialog(
              scholarshipId: 'sch-123',
              scholarshipTitle: 'Excellence STEM Grant',
              initialAttachments: [
                (name: 'doc1.png', bytes: Uint8List.fromList([1, 2, 3]), size: 3),
                (name: 'doc2.pdf', bytes: Uint8List.fromList([4, 5, 6]), size: 3),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Enter description
    await tester.enterText(
      find.byType(TextFormField),
      'Concern description with attached evidence files.',
    );
    await tester.pumpAndSettle();

    // Submit report
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    // Report was submitted once, but attachment failed
    expect(fakeRepo.submitCalls, 1);
    expect(fakeRepo.attachCalls, 1);
    expect(
      find.text('Report recorded, but evidence upload failed. Tap "Retry Evidence Upload" to complete attaching files.'),
      findsOneWidget,
    );
    expect(find.text('Retry Evidence Upload'), findsOneWidget);

    // Clear failure condition and retry
    fakeRepo.failOnFiles.clear();
    await tester.tap(find.text('Retry Evidence Upload'));
    await tester.pumpAndSettle();

    // Submit report was NOT called again (preserved persistedReportId, zero duplicate report errors)
    expect(fakeRepo.submitCalls, 1);
    expect(fakeRepo.attachedFiles, containsAll(['doc1.png', 'doc2.pdf']));
    expect(find.text('Report submitted'), findsOneWidget);
  });

  testWidgets('StudentSafetyReportDialog recovers from second attachment failure and only retries failed file', (tester) async {
    final fakeRepo = FakeSafetyReportRepo()..failOnFiles = {'doc2.pdf'};

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('student-123'),
          safetyReportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StudentSafetyReportDialog(
              scholarshipId: 'sch-123',
              scholarshipTitle: 'Excellence STEM Grant',
              initialAttachments: [
                (name: 'doc1.png', bytes: Uint8List.fromList([1, 2, 3]), size: 3),
                (name: 'doc2.pdf', bytes: Uint8List.fromList([4, 5, 6]), size: 3),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'Concern description where second attachment fails.',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(fakeRepo.submitCalls, 1);
    expect(fakeRepo.attachedFiles, ['doc1.png']); // First succeeded
    expect(
      find.text('Report recorded, but evidence upload failed. Tap "Retry Evidence Upload" to complete attaching files.'),
      findsOneWidget,
    );
    expect(find.text('Retry Evidence Upload'), findsOneWidget);

    // Retry after failure resolved
    fakeRepo.failOnFiles.clear();
    await tester.tap(find.text('Retry Evidence Upload'));
    await tester.pumpAndSettle();

    // Submit report was NOT called again
    expect(fakeRepo.submitCalls, 1);
    // doc1 was NOT re-uploaded, doc2 was uploaded
    expect(fakeRepo.attachedFiles, ['doc1.png', 'doc2.pdf']);
    expect(find.text('Report submitted'), findsOneWidget);
  });

  testWidgets('distinct selected files with same name are both attached and retried', (tester) async {
    final fakeRepo = FakeSafetyReportRepo()..failOnKeys = {'att_2'};

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('student-123'),
          safetyReportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StudentSafetyReportDialog(
              scholarshipId: 'sch-123',
              scholarshipTitle: 'Excellence STEM Grant',
              initialAttachments: [
                (name: 'receipt.png', bytes: Uint8List.fromList([1, 2, 3]), size: 3),
                (name: 'receipt.png', bytes: Uint8List.fromList([4, 5, 6]), size: 3),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'Concern description for distinct attachments having identical filenames.',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(fakeRepo.submitCalls, 1);
    expect(fakeRepo.attachCalls, 2);
    expect(fakeRepo.attachedFiles, ['receipt.png']); // First receipt succeeded, second failed
    expect(
      find.text('Report recorded, but evidence upload failed. Tap "Retry Evidence Upload" to complete attaching files.'),
      findsOneWidget,
    );

    // Clear failure condition and retry
    fakeRepo.failOnKeys.clear();
    await tester.tap(find.text('Retry Evidence Upload'));
    await tester.pumpAndSettle();

    // Submit report was not called again; only att_2 was retried
    expect(fakeRepo.submitCalls, 1);
    expect(fakeRepo.attachCalls, 3);
    expect(fakeRepo.attachedFiles, ['receipt.png', 'receipt.png']);
    expect(find.text('Report submitted'), findsOneWidget);
  });

  testWidgets('partial success invalidates history cache immediately so preloaded-empty history reflects the new open report even if attachment fails', (tester) async {
    final fakeRepo = FakeSafetyReportRepo()..failOnFiles = {'doc1.png'};

    // Build widget where studentSafetyReportsProvider is already pre-warmed/cached with empty list
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('student-123'),
          safetyReportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                // Pre-warm the cache:
                ref.watch(studentSafetyReportsProvider('student-123'));
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => StudentSafetyReportDialog(
                          scholarshipId: 'sch-123',
                          scholarshipTitle: 'Excellence STEM Grant',
                          initialAttachments: [
                            (name: 'doc1.png', bytes: Uint8List.fromList([1, 2, 3]), size: 3),
                          ],
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'Report description to verify immediate cache invalidation on report persistence.',
    );
    await tester.pumpAndSettle();

    // Submit report -> report succeeds, attachment fails
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(fakeRepo.submitCalls, 1);
    expect(
      find.text('Report recorded, but evidence upload failed. Tap "Retry Evidence Upload" to complete attaching files.'),
      findsOneWidget,
    );

    // Tap "View your report history" link inside the dialog
    await tester.ensureVisible(find.text('View your report history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View your report history'));
    await tester.pumpAndSettle();

    // Assert the history dialog displays the new open report rather than stale empty cache
    expect(find.text('Your safety reports'), findsOneWidget);
    expect(find.text('Excellence STEM Grant'), findsOneWidget);
    expect(find.textContaining('Fraud or scam'), findsOneWidget);
  });

  testWidgets('ambiguous server commit / response loss reconciles existing registration on retry without consuming extra quota', (tester) async {
    final fakeRepo = FakeSafetyReportRepo()..throwAmbiguousOnce = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('student-123'),
          safetyReportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StudentSafetyReportDialog(
              scholarshipId: 'sch-123',
              scholarshipTitle: 'Excellence STEM Grant',
              initialAttachments: [
                (name: 'doc1.png', bytes: Uint8List.fromList([1, 2, 3]), size: 3),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'Testing ambiguous server-commit network drop and idempotent recovery.',
    );
    await tester.pumpAndSettle();

    // First attempt -> server committed but response dropped, throwing error to dialog
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(fakeRepo.submitCalls, 1);
    expect(fakeRepo.ambiguousThrownCount, 1);
    expect(
      find.text('Report recorded, but evidence upload failed. Tap "Retry Evidence Upload" to complete attaching files.'),
      findsOneWidget,
    );

    // Tap Retry Evidence Upload -> reconciles existing committed record
    await tester.tap(find.text('Retry Evidence Upload'));
    await tester.pumpAndSettle();

    expect(fakeRepo.submitCalls, 1);
    expect(fakeRepo.attachCalls, 2);
    // Does not duplicate registration
    expect(fakeRepo.attachedFiles.length, 1);
    expect(find.text('Report submitted'), findsOneWidget);
  });
}
