// lib/features/auth/presentation/ceremony_screen.dart
//
// Day 19: the opening route of Scholaris. Renders the graduation ceremony
// Lottie full-bleed, then navigates to /login when the ceremony completes.
// The ceremony is a one-shot opening experience — no Riverpod ceremony state,
// no global animation state.
//
// Flow:
//   /ceremony → GraduationCeremony plays → onCompleted → /login

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/features/auth/presentation/graduation_ceremony.dart';

/// Opening screen that plays the Scholaris graduation ceremony and then
/// transitions to the login screen.
class CeremonyScreen extends StatelessWidget {
  const CeremonyScreen({super.key, this.assetPath = kCeremonyAsset});

  /// Overridable asset path for the ceremony Lottie (used in tests).
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GraduationCeremony(
        assetPath: assetPath,
        onCompleted: () => context.go('/login'),
      ),
    );
  }
}