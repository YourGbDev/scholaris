// lib/shared/widgets/eli_mascot.dart
//
// Reusable mascot component for Eli the Scholaris Eagle.
// Provides standard poses (welcome, celebrating, thinking).
// Follows the Scholaris motion principles (calm, resolves, respects reduced motion).

import 'package:flutter/material.dart';

/// The available visual poses for Eli the Scholaris Eagle.
enum EliPose {
  /// Standing, smiling, and waving warmly with one wing.
  /// Used for Welcome, Onboarding, and Login headers.
  welcome('assets/images/mascot/eli_welcome.png', 'Eli welcoming you to Scholaris'),

  /// Jumping joyfully with graduation cap tossed in the air and confetti.
  /// Used for Application Submitted, Acceptance, and Celebration modals.
  celebrating('assets/images/mascot/eli_celebrating.png', 'Eli celebrating your success!'),

  /// Hand on chin in thought with a small green sprout seedling at his feet.
  /// Used for Empty States, Search, and Tips.
  thinking('assets/images/mascot/eli_thinking.png', 'Eli thinking curious thoughts'),

  /// Holding a sealed invitation envelope with a golden Scholaris wax seal.
  /// Used for Email Verification and Inbox confirmations.
  mail('assets/images/mascot/eli_mail.png', 'Eli presenting your verification email'),

  /// Holding a shiny golden key for account protection and recovery.
  /// Used for Forgot Password and Reset Password screens.
  security('assets/images/mascot/eli_security.png', 'Eli holding a golden key to help you recover access'),

  /// Soft empathetic tilt with hands on chest.
  /// Used for Error Views and Connection Retries.
  concerned('assets/images/mascot/eli_concerned.png', 'Eli looking concerned and empathetic'),

  /// Official square app icon portrait of Eli on Scholaris emerald green background.
  appIcon('assets/images/mascot/eli_app_icon.png', 'Eli the Scholaris Eagle official app icon');

  const EliPose(this.assetPath, this.semanticsLabel);

  final String assetPath;
  final String semanticsLabel;
}

class EliMascot extends StatelessWidget {
  const EliMascot({
    super.key,
    required this.pose,
    this.height = 140,
    this.width,
    this.fit = BoxFit.contain,
    this.onTap,
  });

  final EliPose pose;
  final double? height;
  final double? width;
  final BoxFit fit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      pose.assetPath,
      height: height,
      width: width,
      fit: fit,
      semanticLabel: pose.semanticsLabel,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          height: height,
          width: width ?? height,
          child: const Center(
            child: Icon(Icons.school, size: 48, color: Colors.grey),
          ),
        );
      },
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: image,
      );
    }

    return image;
  }
}
