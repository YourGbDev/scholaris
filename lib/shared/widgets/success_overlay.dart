// lib/shared/widgets/success_overlay.dart
//
// Reusable completion overlay rebuilt to Stitch specifications.
// Pure Flutter vector checkmark with concentric halo styling and auto-dismiss.
// Completely removes Lottie animations per Stitch V2 guidelines.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/mascot_pose_view.dart';

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

  static const _duration = Duration(milliseconds: 1600);
  static const _reducedDuration = Duration(milliseconds: 1000);

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
    final cardWidget = Container(
      constraints: const BoxConstraints(maxWidth: 340),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240F4D2E),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MascotPoseView(
            pose: MascotPose.searching,
            height: 110,
          ),
          const SizedBox(height: 14),
          Text(
            'Finding your scholarship matches...',
            textAlign: TextAlign.center,
            style: outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF161C27),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Analyzing university grants, DOST, and private subsidies tailored to you.',
            textAlign: TextAlign.center,
            style: openSans(
              fontSize: 12.5,
              color: const Color(0xFF404942),
              height: 1.35,
            ),
          ),
        ],
      ),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black26,
        body: Center(
          child: widget.reduceMotion
              ? cardWidget
              : ScaleTransition(
                  scale: _scaleAnimation,
                  child: cardWidget,
                ),
        ),
      ),
    );
  }
}

