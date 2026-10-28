import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/provider/data/provider_verification_repository.dart';
import 'package:scholaris/features/provider/models/provider_verification.dart';
import 'package:scholaris/features/provider/presentation/widgets/provider_verification_banner.dart';
import 'package:scholaris/features/provider/providers/provider_verification_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeVerificationRepo extends ProviderVerificationRepository {
  _FakeVerificationRepo(this._record)
      : super(
          client: SupabaseClient(
            'https://fake.invalid',
            'fake-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );
  ProviderVerification _record;
  Map<String, dynamic>? lastPayload;
  int resubmitCalls = 0;
  final List<String> uploadedDocs = [];

  @override
  Future<ProviderVerification?> fetchVerificationForUser(String userId) async => _record;

  @override
  Future<String> uploadDocument({
    required String userId,
    required String docType,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = '$userId/${docType}_uploaded.pdf';
    uploadedDocs.add(path);
    return path;
  }

  @override
  Future<ProviderVerification> resubmitVerification(Map<String, dynamic> payload) async {
    resubmitCalls++;
    lastPayload = payload;
    _record = _record.copyWith(status: 'pending', reviewNote: null);
    return _record;
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('ProviderVerificationBanner opens resubmission dialog on changes_requested', (tester) async {
    final fakeRepo = _FakeVerificationRepo(
      const ProviderVerification(
        userId: 'provider-1',
        providerType: 'organization',
        status: 'changes_requested',
        orgName: 'Bukas Foundation',
        regNumber: 'SEC-12345',
        repPosition: 'Executive Director',
        reviewNote: 'Please provide valid SEC registration certificate',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('provider-1'),
          providerVerificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ProviderVerificationBanner(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accreditation Status: Updates Requested'), findsOneWidget);
    expect(
      find.textContaining('Please provide valid SEC registration certificate'),
      findsOneWidget,
    );
    expect(find.text('Update Documents & Resubmit'), findsOneWidget);

    // Tap Update Documents & Resubmit
    await tester.tap(find.text('Update Documents & Resubmit'));
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.text('Update Documentation & Resubmit'), findsOneWidget);
    expect(find.text('Reviewer feedback:'), findsOneWidget);
    expect(find.text('Please provide valid SEC registration certificate'), findsOneWidget);
    expect(find.text('Bukas Foundation'), findsOneWidget);
    expect(find.text('SEC-12345'), findsOneWidget);
    expect(find.text('Executive Director'), findsOneWidget);

    // Submit resubmission
    await tester.tap(find.text('Resubmit for Review'));
    await tester.pumpAndSettle();

    expect(fakeRepo.resubmitCalls, 1);
    expect(fakeRepo.lastPayload?['org_name'], 'Bukas Foundation');
    expect(fakeRepo.lastPayload?['reg_number'], 'SEC-12345');
    expect(fakeRepo.lastPayload?['rep_position'], 'Executive Director');
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text('Verification resubmitted. Your documents are now pending review.'),
      findsOneWidget,
    );
  });

  testWidgets('ProviderResubmitDialog uploads replacement SEC certificate and sends path in payload', (tester) async {
    final fakeRepo = _FakeVerificationRepo(
      const ProviderVerification(
        userId: 'provider-org-1',
        providerType: 'organization',
        status: 'changes_requested',
        orgName: 'Bukas Foundation',
        regNumber: 'SEC-12345',
        repPosition: 'Executive Director',
        reviewNote: 'SEC certificate page 2 is missing',
      ),
    );

    var resubmittedCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('provider-org-1'),
          providerVerificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProviderResubmitDialog(
              verification: fakeRepo._record,
              onResubmitted: () => resubmittedCalled = true,
              initialSecFile: (
                bytes: Uint8List.fromList([1, 2, 3, 4]),
                name: 'replacement_sec_cert.pdf',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify replacement document section rendered
    expect(find.text('Replacement documents (optional unless requested)'), findsOneWidget);
    expect(find.text('replacement_sec_cert.pdf'), findsOneWidget);

    // Tap Resubmit for Review
    await tester.tap(find.text('Resubmit for Review'));
    await tester.pumpAndSettle();

    expect(fakeRepo.uploadedDocs, ['provider-org-1/sec_certificate_uploaded.pdf']);
    expect(fakeRepo.resubmitCalls, 1);
    expect(fakeRepo.lastPayload?['sec_cert_path'], 'provider-org-1/sec_certificate_uploaded.pdf');
    expect(fakeRepo.lastPayload?['org_name'], 'Bukas Foundation');
    expect(resubmittedCalled, true);
  });

  testWidgets('ProviderResubmitDialog for individual provider uploads replacement photo ID and sends path in payload', (tester) async {
    final fakeRepo = _FakeVerificationRepo(
      const ProviderVerification(
        userId: 'provider-indiv-1',
        providerType: 'individual',
        status: 'changes_requested',
        fullName: 'Juan Dela Cruz',
        govIdNumber: 'PRC-998877',
        sourceOfFunds: 'Private Practice Income',
        reviewNote: 'Photo ID is blurry, please provide clearer photo',
      ),
    );

    var resubmittedCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('provider-indiv-1'),
          providerVerificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProviderResubmitDialog(
              verification: fakeRepo._record,
              onResubmitted: () => resubmittedCalled = true,
              initialGovIdFile: (
                bytes: Uint8List.fromList([5, 6, 7, 8]),
                name: 'clear_prc_id.jpg',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Government-Issued Photo ID'), findsOneWidget);
    expect(find.text('clear_prc_id.jpg'), findsOneWidget);

    await tester.tap(find.text('Resubmit for Review'));
    await tester.pumpAndSettle();

    expect(fakeRepo.uploadedDocs, ['provider-indiv-1/gov_id_front_uploaded.pdf']);
    expect(fakeRepo.resubmitCalls, 1);
    expect(fakeRepo.lastPayload?['gov_id_front_path'], 'provider-indiv-1/gov_id_front_uploaded.pdf');
    expect(fakeRepo.lastPayload?['full_name'], 'Juan Dela Cruz');
    expect(resubmittedCalled, true);
  });
}
