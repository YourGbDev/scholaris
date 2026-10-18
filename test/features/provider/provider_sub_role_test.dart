import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/provider/providers/provider_sub_role_provider.dart';

void main() {
  group('ProviderSubRole & Identity Tests', () {
    test('Evaluator identity displays correct DOST academic desk info', () {
      const evaluator = ProviderIdentityInfo(
        role: ProviderSubRole.evaluator,
        name: 'Dr. Renato U. Solidum Jr.',
        initials: 'RS',
        roleSubtitle: 'Academic Evaluator',
        topEyebrow: 'DR. RENATO U. SOLIDUM JR. • ACADEMIC EVALUATION DESK',
      );

      expect(evaluator.isEvaluator, isTrue);
      expect(evaluator.isFinance, isFalse);
      expect(evaluator.name, equals('Dr. Renato U. Solidum Jr.'));
      expect(evaluator.initials, equals('RS'));
      expect(evaluator.roleSubtitle, equals('Academic Evaluator'));
      expect(evaluator.topEyebrow, contains('ACADEMIC EVALUATION DESK'));
    });

    test('Finance Officer identity displays correct DOST treasury info', () {
      const finance = ProviderIdentityInfo(
        role: ProviderSubRole.finance,
        name: 'Engr. Maria Santos, CPA',
        initials: 'MS',
        roleSubtitle: 'Disbursing Officer',
        topEyebrow: 'ENGR. MARIA SANTOS, CPA • TREASURY & DISBURSEMENTS',
      );

      expect(finance.isFinance, isTrue);
      expect(finance.isEvaluator, isFalse);
      expect(finance.name, equals('Engr. Maria Santos, CPA'));
      expect(finance.initials, equals('MS'));
      expect(finance.roleSubtitle, equals('Disbursing Officer'));
      expect(finance.topEyebrow, contains('TREASURY & DISBURSEMENTS'));
    });
  });
}
