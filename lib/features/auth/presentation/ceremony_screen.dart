// lib/features/auth/presentation/ceremony_screen.dart
//
// Day 19: the opening route of Scholaris. Renders the graduation ceremony
// Lottie full-bleed, then navigates to /login when the ceremony completes.
// The ceremony is a one-shot opening experience — no Riverpod ceremony state,
// no global animation state.
//
// Flow:
//   /ceremony → GraduationCeremony plays → onCompleted → /login

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/features/auth/presentation/graduation_ceremony.dart';

/// Opening screen that plays the Scholaris graduation ceremony and then
/// transitions to the login screen.
class CeremonyScreen extends StatefulWidget {
  const CeremonyScreen({
    super.key,
    this.assetPath = kCeremonyAsset,
    this.autoAdvanceDuration,
  });

  /// Overridable asset path for the ceremony Lottie (used in tests).
  final String assetPath;

  /// Optional auto-advance duration (e.g. 2500ms safety timer).
  final Duration? autoAdvanceDuration;

  @override
  State<CeremonyScreen> createState() => _CeremonyScreenState();
}

class _CeremonyScreenState extends State<CeremonyScreen> {
  Timer? _advanceTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoAdvanceDuration != null) {
      _advanceTimer = Timer(widget.autoAdvanceDuration!, _onContinuePressed);
    }
  }

  void _onContinuePressed() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.go('/login');
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GraduationCeremony(
        assetPath: widget.assetPath,
        onCompleted: _onContinuePressed,
      ),
    );
  }
}