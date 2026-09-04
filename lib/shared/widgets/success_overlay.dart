// lib/shared/widgets/success_overlay.dart
//
// Reusable completion overlay: plays "Successfully Done.json" once, then
// auto-dismisses. Reduced-motion users see a static checkmark for 1s instead
// of the Lottie.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:scholaris/shared/theme/app_theme.dart';

/// Shows the success confirmation overlay as a full-screen modal and returns
/// when it auto-dismisses.
///
/// Use it as:
/// ```dart
/// await SuccessOverlay.show(context);
/// if (mounted) context.go('/next');
/// ```
class SuccessOverlay {
  SuccessOverlay._();

  static const _asset = 'assets/animations/Successfully Done.json';
  static const _duration = Duration(milliseconds: 3400);
  static const _reducedDuration = Duration(milliseconds: 1000);

  static Future<void> show(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      transitionDuration: reduceMotion
          ? const Duration(milliseconds: 80)
          : const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _SuccessPage(reduceMotion: reduceMotion);
      },
    );
  }
}

class _SuccessPage extends StatefulWidget {
  const _SuccessPage({required this.reduceMotion});

  final bool reduceMotion;

  @override
  State<_SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<_SuccessPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleDismiss();
  }

  @override
  void didUpdateWidget(_SuccessPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion != widget.reduceMotion) {
      _scheduleDismiss();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleDismiss() {
    _timer?.cancel();
    final delay = widget.reduceMotion
        ? SuccessOverlay._reducedDuration
        : SuccessOverlay._duration;
    _timer = Timer(delay, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: widget.reduceMotion
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: kPrimary,
                    size: 96,
                  )
                : Lottie.asset(
                    SuccessOverlay._asset,
                    fit: BoxFit.contain,
                    repeat: false,
                    frameRate: FrameRate.max,
                  ),
          ),
        ),
      ),
    );
  }
}
