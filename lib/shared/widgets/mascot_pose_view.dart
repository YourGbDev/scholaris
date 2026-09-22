// lib/shared/widgets/mascot_pose_view.dart
//
// Centralized mascot pose widget that automatically adapts to the student's
// stored gender/pronoun field, falling back to female as the neutral default.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';

/// Available mascot emotional poses.
enum MascotPose {
  celebrating,
  consoling,
  searching,
  confused,
}

/// Helper function to resolve the asset path for a given pose and gender string.
/// Falls back to female as the neutral default when gender is unset or not male.
String getMascotAssetPath(MascotPose pose, {String? gender}) {
  final isMale = gender?.trim().toLowerCase() == 'male';
  final genderStr = isMale ? 'male' : 'female';
  return 'assets/mascots/mascot_${genderStr}_${pose.name}.png';
}

/// A responsive widget displaying the appropriate mascot pose graphic.
class MascotPoseView extends StatelessWidget {
  const MascotPoseView({
    super.key,
    required this.pose,
    this.gender,
    this.height = 120,
    this.width,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final MascotPose pose;

  /// Optional gender override. If omitted, reads from [currentProfileProvider].
  final String? gender;

  final double? height;
  final double? width;
  final BoxFit fit;
  final Alignment alignment;

  Widget _buildImage(String? effectiveGender) {
    final assetPath = getMascotAssetPath(pose, gender: effectiveGender);

    return Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[MASCOT ASSET ERROR] Failed to load $assetPath: $error');
        return SizedBox(
          height: height,
          width: width ?? height,
          child: Center(
            child: Icon(
              switch (pose) {
                MascotPose.celebrating => Icons.celebration_rounded,
                MascotPose.consoling => Icons.sentiment_dissatisfied_rounded,
                MascotPose.searching => Icons.search_rounded,
                MascotPose.confused => Icons.help_outline_rounded,
              },
              size: (height ?? 48) * 0.5,
              color: const Color(0xFF0F4D2E),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (gender != null) {
      return _buildImage(gender);
    }

    try {
      ProviderScope.containerOf(context, listen: false);
      return Consumer(
        builder: (context, ref, _) {
          final profile = ref.watch(currentProfileProvider).valueOrNull;
          return _buildImage(profile?.gender);
        },
      );
    } catch (_) {
      return _buildImage(null);
    }
  }
}
