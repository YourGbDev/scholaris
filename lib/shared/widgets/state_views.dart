// lib/shared/widgets/state_views.dart
//
// Reusable loading / empty / error views so every discovery surface presents
// a consistent, polished state instead of a raw spinner or exception.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'mascot_pose_view.dart';



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
  });

  final IconData? icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool animateSearchIcon;

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = icon ?? Icons.inbox_rounded;
    final iconWidget = animateSearchIcon
        ? _SearchIconAnimation(icon: effectiveIcon, color: Colors.white)
        : Icon(effectiveIcon, size: 24, color: Colors.white);

    // Stitch Concentric Halo Assembly
    final visualWidget = Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kPrimary.withValues(alpha: 0.08),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kPrimary.withValues(alpha: 0.14),
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimary,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: iconWidget,
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.search_rounded,
                    size: 11,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorderLight),
          boxShadow: const [
            BoxShadow(
              color: Color(0x081B3A5C),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            visualWidget,
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: openSans(
                fontSize: 13.5,
                color: kTextSecondary,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchIconAnimation extends StatefulWidget {
  const _SearchIconAnimation({required this.icon, this.color});

  final IconData icon;
  final Color? color;

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
          child: Icon(widget.icon, size: 24, color: widget.color ?? Colors.white),
        );
      },
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.isOffline = false,
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotPoseView(
              pose: MascotPose.confused,
              height: 100,
            ),
            const SizedBox(height: 16),
            Text(
              isOffline ? 'No internet connection' : title,
              textAlign: TextAlign.center,
              style: outfit(fontSize: 18, fontWeight: FontWeight.w700, color: kTextPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isOffline
                  ? 'Please check your Wi-Fi or cellular network settings and try again.'
                  : message,
              textAlign: TextAlign.center,
              style: openSans(fontSize: 13.5, color: kTextSecondary, height: 1.4),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Try again',
                  style: outfit(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Generic inline form error banner displaying the confused mascot.
/// NEVER used on login screen.
class InlineFormErrorBanner extends StatelessWidget {
  const InlineFormErrorBanner({
    super.key,
    required this.message,
    this.title,
    this.onDismiss,
  });

  final String message;
  final String? title;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kErrorSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kError.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MascotPoseView(
            pose: MascotPose.confused,
            height: 48,
            width: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: kError,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: openSans(
                    fontSize: 12.5,
                    color: kError,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16, color: kError),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
