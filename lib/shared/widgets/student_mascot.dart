// lib/shared/widgets/student_mascot.dart
//
// Official Mascot component for Aris (boy) and Aria (girl) companions.
// Replaces Lumi and Eli mascots with clean vector mascot cutouts.
//
// Automatically adapts to the student's gender from their profile (defaulting to Aria),
// or accepts an explicit [gender] parameter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';

/// Available mascot companions in Scholaris.
enum MascotGender {
  male,
  female;

  static MascotGender fromString(String? value) {
    if (value == null) return MascotGender.female;
    final lower = value.trim().toLowerCase();
    if (lower == 'male' || lower == 'm' || lower == 'boy' || lower == 'man') {
      return MascotGender.male;
    }
    return MascotGender.female;
  }
}

/// The available visual poses for Aris and Aria.
enum StudentMascotPose {
  /// Hero / welcome stance with friendly, welcoming posture
  hero('hero', 'Student mascot welcoming you with bright optimism'),

  /// Core Expressions
  happy('happy', 'Student mascot smiling joyfully'),
  determined('determined', 'Student mascot determined and ready to achieve goals'),
  thinking('thinking', 'Student mascot in thoughtful reflection'),
  celebrating('celebrating', 'Student mascot celebrating academic success!'),
  curious('curious', 'Student mascot looking curious and inquisitive'),

  /// The Student Journey stages
  student('student', 'Student mascot in daily school routine with backpack'),
  applicant('applicant', 'Student mascot taking the next step with application documents'),
  scholar('scholar', 'Student mascot growing knowledge with a stack of textbooks'),
  graduate('graduate', 'Student mascot wearing graduation gown holding diploma'),

  /// Turnaround poses
  front('front', 'Student mascot front turnaround view'),
  side('side', 'Student mascot side turnaround view'),
  back('back', 'Student mascot back turnaround view'),

  // --- Backwards-compatibility aliases for Lumi / Eli poses ---
  welcome('hero', 'Student mascot welcoming you warmly'),
  neutral('happy', 'Student mascot in a relaxed stance'),
  brightGlow('celebrating', 'Student mascot celebrating your success!'),
  dimGlow('thinking', 'Student mascot pondering opportunities'),
  concerned('thinking', 'Student mascot looking thoughtful and supportive'),
  appIcon('hero', 'Student mascot official portrait'),
  guiding('determined', 'Student mascot guiding the way forward'),
  studying('scholar', 'Student mascot studying and reviewing'),
  encouraging('celebrating', 'Student mascot encouraging you'),
  peeking('curious', 'Student mascot peeking with curiosity'),
  mail('applicant', 'Student mascot presenting your application documents'),
  security('determined', 'Student mascot guiding your account security');

  const StudentMascotPose(this.assetKey, this.semanticsLabel);

  final String assetKey;
  final String semanticsLabel;

  String assetPath(MascotGender gender) {
    final prefix = gender == MascotGender.male ? 'aris' : 'aria';
    return 'assets/images/mascot/${prefix}_$assetKey.png';
  }
}

/// Backward compatibility aliases for existing code and test suites.
typedef LumiPose = StudentMascotPose;
typedef EliPose = StudentMascotPose;

/// Reusable widget for rendering the Scholaris student mascot (Aris or Aria).
class StudentMascot extends StatelessWidget {
  const StudentMascot({
    super.key,
    required this.pose,
    this.gender,
    this.height = 140,
    this.width,
    this.fit = BoxFit.contain,
    this.onTap,
  });

  final StudentMascotPose pose;
  final MascotGender? gender;
  final double? height;
  final double? width;
  final BoxFit fit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (gender != null) {
      return _buildImage(context, gender!);
    }

    final hasScope = context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() != null;
    if (!hasScope) {
      return _buildImage(context, MascotGender.female);
    }

    return Consumer(
      builder: (context, ref, _) {
        final profile = ref.watch(currentProfileProvider).valueOrNull;
        final resolvedGender = profile?.gender != null
            ? MascotGender.fromString(profile!.gender)
            : MascotGender.female;
        return _buildImage(context, resolvedGender);
      },
    );
  }

  Widget _buildImage(BuildContext context, MascotGender activeGender) {
    final path = pose.assetPath(activeGender);

    Widget image = Image.asset(
      path,
      height: height,
      width: width,
      fit: fit,
      filterQuality: FilterQuality.medium,
      semanticLabel: pose.semanticsLabel,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          height: height,
          width: width ?? height,
          child: const Center(
            child: Icon(Icons.school_rounded, size: 48, color: Colors.grey),
          ),
        );
      },
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: image,
      );
    }

    return image;
  }
}

/// Backward compatibility aliases for existing widgets.
typedef LumiMascot = StudentMascot;
typedef EliMascot = StudentMascot;
