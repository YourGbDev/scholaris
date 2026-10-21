import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/shared/widgets/mascot_pose_view.dart';

void main() {
  testWidgets('profile-driven mascot stays neutral until female profile resolves', (tester) async {
    final pending = Completer<StudentProfile?>();
    await tester.pumpWidget(ProviderScope(overrides: [
      currentProfileProvider.overrideWith((ref) => pending.future),
    ], child: const MaterialApp(home: MascotPoseView(pose: MascotPose.searching))));
    expect(find.byType(Image), findsNothing);
    pending.complete(const StudentProfile(id:'a',fullName:'Ana',nationality:'Filipino',region:'NCR',gpa:90,yearLevel:1,course:'BSIT',gender:'female'));
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/mascots/mascot_female_searching.png');
  });
}
