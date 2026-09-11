// lib/shared/widgets/state_views.dart
//
// Reusable loading / empty / error views so every discovery surface presents
// a consistent, polished state instead of a raw spinner or exception.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'eli_mascot.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(48),
      child: Center(
        child: SizedBox(
          key: Key('loading-indicator'),
          height: 32,
          width: 32,
          child: _LoadingSpinner(),
        ),
      ),
    );
  }
}

class _LoadingSpinner extends StatefulWidget {
  const _LoadingSpinner();

  @override
  State<_LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<_LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1, milliseconds: 200),
      vsync: this,
    )..repeat();
    _rotation = _controller.drive(Tween(begin: 0, end: 1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotation,
      child: const _LoadingArc(),
    );
  }
}

class _LoadingArc extends StatelessWidget {
  const _LoadingArc();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(32, 32),
      painter: _LoadingArcPainter(),
    );
  }
}

class _LoadingArcPainter extends CustomPainter {
  _LoadingArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - paint.strokeWidth;

    // Arc 1: kPrimary, ~120 degrees.
    paint.color = kPrimary;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2.09,
      false,
      paint,
    );

    // Arc 2: kAccent, ~120 degrees, rotated ~180 degrees.
    paint.color = kAccent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14,
      2.09,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoadingArcPainter old) => false;
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.animateSearchIcon = false,
    this.mascotPose = EliPose.thinking,
  });

  final IconData? icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool animateSearchIcon;
  final EliPose? mascotPose;

  @override
  Widget build(BuildContext context) {
    final Widget visualWidget;
    if (mascotPose != null) {
      visualWidget = EliMascot(
        pose: mascotPose!,
        height: 140,
      );
    } else {
      final iconWidget = animateSearchIcon
          ? _SearchIconAnimation(icon: icon ?? Icons.inbox_rounded)
          : Icon(icon ?? Icons.inbox_rounded, size: 36, color: kPrimary);

      visualWidget = Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: kPrimarySoft,
          shape: BoxShape.circle,
        ),
        child: iconWidget,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          visualWidget,
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: openSans(fontSize: 14, color: Colors.black54),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchIconAnimation extends StatefulWidget {
  const _SearchIconAnimation({required this.icon});

  final IconData icon;

  @override
  State<_SearchIconAnimation> createState() => _SearchIconAnimationState();
}

class _SearchIconAnimationState extends State<_SearchIconAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _tilt;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1, milliseconds: 400),
      vsync: this,
    )..repeat(reverse: true);
    _tilt = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0, end: 0.18), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 0.18, end: -0.18), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -0.18, end: 0), weight: 1),
      ],
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tilt,
      builder: (context, child) {
        return Transform.rotate(
          angle: _tilt.value,
          child: Icon(widget.icon, size: 36, color: kPrimary),
        );
      },
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.mascotPose = EliPose.concerned,
  });

  final String message;
  final VoidCallback? onRetry;
  final EliPose? mascotPose;

  @override
  Widget build(BuildContext context) {
    final Widget visualWidget = mascotPose != null
        ? EliMascot(
            pose: mascotPose!,
            height: 120,
          )
        : const Icon(Icons.cloud_off, size: 36, color: kError);

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          visualWidget,
          const SizedBox(height: 12),
          Text(
            'Something went wrong',
            textAlign: TextAlign.center,
            style: poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: openSans(fontSize: 14, color: Colors.black54),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              child: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}
