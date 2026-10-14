// lib/features/auth/presentation/ceremony_screen.dart
//
// Day 19: the opening route of Scholaris. Renders the graduation ceremony
// Lottie full-bleed, then navigates to /login when the ceremony completes.
// Also supports standalone award celebration mode when invoked by students
// viewing their approved or awarded grant packages.
//
// Flow:
//   Default:     /ceremony -> GraduationCeremony plays -> onCompleted -> /login
//   Celebration: CeremonyScreen(title, subtitle, onCompleted) -> plays -> onCompleted()

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/features/auth/presentation/graduation_ceremony.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

/// Opening screen that plays the Scholaris graduation ceremony and then
/// transitions to the login screen, or optionally displays an award celebration
/// with custom title/subtitle and a return callback.
class CeremonyScreen extends StatefulWidget {
  const CeremonyScreen({
    super.key,
    this.assetPath = kCeremonyAsset,
    this.autoAdvanceDuration,
    this.onCompleted,
    this.title,
    this.subtitle,
  });

  /// Overridable asset path for the ceremony Lottie (used in tests).
  final String assetPath;

  /// Optional auto-advance duration (e.g. 2500ms safety timer).
  final Duration? autoAdvanceDuration;

  /// Optional callback invoked upon ceremony completion or dismissal.
  /// If provided, this callback is invoked instead of navigating to /login.
  final VoidCallback? onCompleted;

  /// Optional celebratory title shown in an overlay banner.
  final String? title;

  /// Optional celebratory subtitle shown in an overlay banner.
  final String? subtitle;

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
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasBanner = widget.title != null || widget.subtitle != null;

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          GraduationCeremony(
            assetPath: widget.assetPath,
            onCompleted: _onContinuePressed,
          ),
          if (hasBanner)
            Positioned(
              top: 0,
              left: 20,
              right: widget.onCompleted != null ? 72 : 20,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.title != null)
                          Text(
                            widget.title!,
                            style: outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F4D2E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            style: outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF404942),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (widget.onCompleted != null)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Semantics(
                    button: true,
                    label: 'Close ceremony celebration',
                    child: IconButton(
                      key: const ValueKey('ceremony-close-btn'),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF0F4D2E),
                      ),
                      tooltip: 'Close celebration',
                      onPressed: _onContinuePressed,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        elevation: 2,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}