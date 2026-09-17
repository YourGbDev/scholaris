// lib/shared/widgets/success_overlay.dart
//
// Reusable completion overlay rebuilt to Stitch specifications.
// Pure Flutter vector checkmark with concentric halo styling and auto-dismiss.
// Completely removes Lottie animations per Stitch V2 guidelines.

import 'dart:async';

import 'package:flutter/material.dart';

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

  static const _duration = Duration(milliseconds: 1200);
  static const _reducedDuration = Duration(milliseconds: 800);

  static Future<void> show(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      transitionDuration: reduceMotion
          ? const Duration(milliseconds: 80)
          : const Duration(milliseconds: 200),
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

class _SuccessPageState extends State<_SuccessPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
    if (!widget.reduceMotion) {
      _scaleController.forward();
    }
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
    _scaleController.dispose();
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
    final iconWidget = Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F4D2E),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: kPrimaryFixed,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: kPrimaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: widget.reduceMotion
              ? iconWidget
              : ScaleTransition(
                  scale: _scaleAnimation,
                  child: iconWidget,
                ),
        ),
      ),
    );
  }
}

