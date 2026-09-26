// test/provider_verification_model_test.dart
// Unit tests for ProviderVerification model, ID masking, and formatting.

import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/provider/models/provider_verification.dart';

void main() {
  group('ProviderVerification Model Tests', () {
    test('masks government ID correctly preserving only last 4 digits', () {
      final verification = ProviderVerification(
        id: 'verif-123',
        userId: 'user-456',
        providerType: 'individual',
        status: 'pending',
        submittedAt: DateTime(2026, 3, 20),
        govIdType: 'PhilSys National ID',
        govIdNumber: '1234-5678-9012-3456',
        tin: '987654321',
      );

      expect(verification.maskedIdNumber, equals('•••• •••• 3456'));
      expect(verification.maskedTin, equals('•••-•••-4321'));
      expect(verification.isPending, isTrue);
      expect(verification.isApproved, isFalse);
      expect(verification.isRejected, isFalse);
    });

    test('handles short ID numbers gracefully when masking', () {
      final verification = ProviderVerification(
        id: 'verif-124',
        userId: 'user-789',
        providerType: 'individual',
        status: 'approved',
        submittedAt: DateTime(2026, 3, 21),
        govIdNumber: '42',
      );

      expect(verification.maskedIdNumber, equals('•••• 42'));
      expect(verification.isApproved, isTrue);
    });

    test('converts to/from JSON map correctly without losing data', () {
      final original = ProviderVerification(
        id: 'verif-999',
        userId: 'user-999',
        providerType: 'organization',
        status: 'pending',
        submittedAt: DateTime.utc(2026, 3, 24, 12, 0, 0),
        orgName: 'Ayala Foundation',
        orgType: 'Foundation',
        regNumber: 'SEC-2026-99999',
        repName: 'Jaime Zobel',
        repPosition: 'Executive Director',
        repEmail: 'jz@ayala.org.ph',
        repPhone: '+639171112233',
        secCertPath: 'org_user_999/sec.pdf',
        bir2303Path: 'org_user_999/bir.pdf',
        boardResolutionPath: 'org_user_999/board.pdf',
      );

      final map = original.toJson();
      expect(map['org_name'], equals('Ayala Foundation'));
      expect(map['reg_number'], equals('SEC-2026-99999'));
      expect(map['status'], equals('pending'));

      final reconstructed = ProviderVerification.fromJson(map);
      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.orgName, equals('Ayala Foundation'));
      expect(reconstructed.repName, equals('Jaime Zobel'));
      expect(reconstructed.isPending, isTrue);
    });
  });
}
