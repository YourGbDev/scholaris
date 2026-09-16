// test/format_peso_test.dart
//
// Verifies Philippine peso currency formatting (₱) across utility helpers
// and ensures no monetary amounts render with a dollar sign ($).

import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/shared/utils/constants.dart';

void main() {
  group('formatPeso currency helper', () {
    test('formats round amounts with peso sign and thousand separators', () {
      expect(formatPeso(500), '₱500');
      expect(formatPeso(5000), '₱5,000');
      expect(formatPeso(50000), '₱50,000');
      expect(formatPeso(100000), '₱100,000');
      expect(formatPeso(1250000), '₱1,250,000');
    });

    test('always uses peso symbol and never dollar sign', () {
      final formatted = formatPeso(50000);
      expect(formatted.startsWith('₱'), isTrue);
      expect(formatted.contains(r'$'), isFalse);
    });
  });
}
