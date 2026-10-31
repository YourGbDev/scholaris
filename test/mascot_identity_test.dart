import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/shared/widgets/mascot_pose_view.dart';

void main() {
  test('mascot names follow the same gender rule as assets', () {
    expect(getMascotName(gender: 'male'), 'Ariel');
    expect(getMascotName(gender: ' Female '), 'Ari');
    expect(getMascotName(), 'Ariel');
  });
}
