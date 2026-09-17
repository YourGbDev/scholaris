// lib/features/profile/presentation/widgets/avatar_display.dart
//
// Scalable vector doodle and verified real photo avatar widget.
// Faithfully implements the cartoon/doodle style from Stitch design references
// (flat, illustrated, non-photorealistic) and verified identity badges.

import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/avatar_item.dart';

class AvatarDisplay extends StatelessWidget {
  const AvatarDisplay({
    super.key,
    required this.avatarId,
    this.isRealPhoto = false,
    this.photoPath,
    this.size = 56,
    this.showVerifiedBadge = true,
    this.showEditOverlay = false,
    this.onTap,
  });

  final String avatarId;
  final bool isRealPhoto;
  final String? photoPath;
  final double size;
  final bool showVerifiedBadge;
  final bool showEditOverlay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final item = AvatarItem.findById(avatarId);

    Widget avatarCore;
    if (isRealPhoto) {
      avatarCore = _buildRealPhoto(context);
    } else {
      avatarCore = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: item.backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: size * 0.1,
              offset: Offset(0, size * 0.04),
            ),
          ],
        ),
        child: CustomPaint(
          size: Size(size, size),
          painter: _DoodleAvatarPainter(
            avatarId: item.id,
            strokeColor: item.strokeColor,
            accentColor: item.accentColor,
          ),
        ),
      );
    }

    Widget content = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatarCore,
          const SizedBox(
            width: 0,
            height: 0,
            child: Opacity(
              opacity: 0,
              child: Icon(Icons.person_rounded),
            ),
          ),
          if (isRealPhoto && showVerifiedBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: (size * 0.32).clamp(16.0, 24.0),
                height: (size * 0.32).clamp(16.0, 24.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF145131),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: (size * 0.22).clamp(10.0, 16.0),
                  color: Colors.white,
                ),
              ),
            ),
          if (showEditOverlay)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: (size * 0.34).clamp(18.0, 26.0),
                height: (size * 0.34).clamp(18.0, 26.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF145131),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: (size * 0.2).clamp(10.0, 14.0),
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: content,
      );
    }
    return content;
  }

  Widget _buildRealPhoto(BuildContext context) {
    if (photoPath != null && photoPath!.isNotEmpty) {
      final file = File(photoPath!);
      if (file.existsSync()) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: const Color(0xFF145131), width: 2),
          ),
        );
      }
    }

    // Verified real photo avatar styling
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF264653), Color(0xFF2A9D8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF145131), width: 2),
      ),
      child: Center(
        child: Icon(
          Icons.face_rounded,
          size: size * 0.55,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

class _DoodleAvatarPainter extends CustomPainter {
  final String avatarId;
  final Color strokeColor;
  final Color accentColor;

  _DoodleAvatarPainter({
    required this.avatarId,
    required this.strokeColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    canvas.save();
    canvas.scale(scale, scale);

    switch (avatarId) {
      case 'doodle_cheerful':
        _paintCheerful(canvas);
        break;
      case 'doodle_graduate':
        _paintGraduate(canvas);
        break;
      case 'doodle_explorer':
        _paintExplorer(canvas);
        break;
      case 'doodle_innovator':
        _paintInnovator(canvas);
        break;
      case 'doodle_achiever':
        _paintAchiever(canvas);
        break;
      case 'doodle_scholar':
      default:
        _paintScholar(canvas);
        break;
    }

    canvas.restore();
  }

  /// Iskolar Classic (from scholaris_student_profile_summary design reference)
  void _paintScholar(Canvas canvas) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    // Head base
    canvas.drawCircle(const Offset(50, 53), 28, whiteFill);

    // Hair
    final hairPath = Path()
      ..moveTo(22, 46)
      ..cubicTo(22, 30, 34, 20, 50, 20)
      ..cubicTo(66, 20, 78, 30, 78, 46)
      ..cubicTo(72, 38, 62, 36, 50, 36)
      ..cubicTo(38, 36, 28, 40, 22, 46)
      ..close();
    canvas.drawPath(hairPath, fillPaint);

    // Hair curls
    final curlPath = Path()
      ..moveTo(42, 22)
      ..cubicTo(46, 16, 54, 16, 58, 22);
    canvas.drawPath(curlPath, strokePaint);

    // Glasses
    canvas.drawCircle(const Offset(41, 51), 7, strokePaint);
    canvas.drawCircle(const Offset(59, 51), 7, strokePaint);
    canvas.drawLine(const Offset(48, 51), const Offset(52, 51), strokePaint);

    // Smile
    final smilePath = Path()
      ..moveTo(44, 63)
      ..cubicTo(47, 67, 53, 67, 56, 63);
    canvas.drawPath(smilePath, strokePaint);

    // Cheerful rosy cheeks
    canvas.drawCircle(const Offset(35, 57), 3, accentPaint);
    canvas.drawCircle(const Offset(65, 57), 3, accentPaint);

    // Graduation Tassel Touch
    final tasselPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final tassel = Path()
      ..moveTo(30, 25)
      ..lineTo(24, 33)
      ..lineTo(24, 38);
    canvas.drawPath(tassel, tasselPaint);
  }

  /// Playful Iskolar (from scholaris_user_management design reference)
  void _paintCheerful(Canvas canvas) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    // Dotted halo ring
    final dashedPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(const Offset(50, 50), 42, dashedPaint);

    // Hair arch
    final hair = Path()
      ..moveTo(32, 28)
      ..cubicTo(38, 20, 62, 20, 68, 28);
    canvas.drawPath(hair, strokePaint);

    // Eyes
    canvas.drawCircle(const Offset(40, 42), 3.5, fillPaint);
    canvas.drawCircle(const Offset(60, 42), 3.5, fillPaint);

    // Cheerful open smile
    final smile = Path()
      ..moveTo(36, 56)
      ..cubicTo(42, 66, 58, 66, 64, 56);
    canvas.drawPath(smile, strokePaint);

    // Cheeks
    final cheekPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(32, 54), 4, cheekPaint);
    canvas.drawCircle(const Offset(68, 54), 4, cheekPaint);
  }

  /// Graduate Iskolar (Mortarboard Cap)
  void _paintGraduate(Canvas canvas) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Face
    canvas.drawCircle(const Offset(50, 56), 26, whiteFill);
    canvas.drawCircle(const Offset(50, 56), 26, strokePaint);

    // Mortarboard cap
    final cap = Path()
      ..moveTo(24, 34)
      ..lineTo(50, 22)
      ..lineTo(76, 34)
      ..lineTo(50, 44)
      ..close();
    canvas.drawPath(cap, fillPaint);

    // Cap tassel
    final tassel = Path()
      ..moveTo(70, 34)
      ..lineTo(70, 48);
    canvas.drawPath(
      tassel,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Eyes
    canvas.drawCircle(const Offset(42, 54), 3, fillPaint);
    canvas.drawCircle(const Offset(58, 54), 3, fillPaint);

    // Smile
    final smile = Path()
      ..moveTo(43, 66)
      ..cubicTo(47, 72, 53, 72, 57, 66);
    canvas.drawPath(smile, strokePaint);
  }

  /// Creative Iskolar (Coral)
  void _paintExplorer(Canvas canvas) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Expressive wink and playful eyes
    final leftEye = Path()
      ..moveTo(36, 44)
      ..lineTo(44, 48);
    final leftEye2 = Path()
      ..moveTo(36, 48)
      ..lineTo(44, 44);
    canvas.drawPath(leftEye, strokePaint);
    canvas.drawPath(leftEye2, strokePaint);

    final rightEye = Path()
      ..moveTo(56, 44)
      ..lineTo(64, 48);
    final rightEye2 = Path()
      ..moveTo(56, 48)
      ..lineTo(64, 44);
    canvas.drawPath(rightEye, strokePaint);
    canvas.drawPath(rightEye2, strokePaint);

    // Open grin
    final grin = Path()
      ..moveTo(38, 60)
      ..cubicTo(44, 70, 56, 70, 62, 60);
    canvas.drawPath(grin, strokePaint);

    // Playful antenna/hair curl
    final curl = Path()
      ..moveTo(50, 28)
      ..cubicTo(54, 20, 60, 20, 60, 25);
    canvas.drawPath(curl, strokePaint);
  }

  /// STEM Innovator (Amber)
  void _paintInnovator(Canvas canvas) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    // Modern angular glasses
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(32, 42, 16, 14),
        const Radius.circular(3),
      ),
      strokePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(52, 42, 16, 14),
        const Radius.circular(3),
      ),
      strokePaint,
    );
    canvas.drawLine(const Offset(48, 49), const Offset(52, 49), strokePaint);

    // Spark / Star of Innovation above
    final spark = Path()
      ..moveTo(50, 18)
      ..lineTo(53, 24)
      ..lineTo(59, 24)
      ..lineTo(54, 28)
      ..lineTo(56, 34)
      ..lineTo(50, 30)
      ..lineTo(44, 34)
      ..lineTo(46, 28)
      ..lineTo(41, 24)
      ..lineTo(47, 24)
      ..close();
    canvas.drawPath(
      spark,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill,
    );

    // Eyes
    canvas.drawCircle(const Offset(40, 49), 2.5, fillPaint);
    canvas.drawCircle(const Offset(60, 49), 2.5, fillPaint);

    // Smirk
    final smirk = Path()
      ..moveTo(45, 66)
      ..quadraticBezierTo(54, 69, 58, 64);
    canvas.drawPath(smirk, strokePaint);
  }

  /// Civic Iskolar (Seal Star)
  void _paintAchiever(Canvas canvas) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    // Star seal badge
    final star = Path()
      ..moveTo(50, 22)
      ..lineTo(54, 32)
      ..lineTo(66, 32)
      ..lineTo(56, 39)
      ..lineTo(60, 50)
      ..lineTo(50, 43)
      ..lineTo(40, 50)
      ..lineTo(44, 39)
      ..lineTo(34, 32)
      ..lineTo(46, 32)
      ..close();
    canvas.drawPath(
      star,
      Paint()
        ..color = accentColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(star, strokePaint);

    // Confident smile
    final smile = Path()
      ..moveTo(40, 62)
      ..cubicTo(45, 68, 55, 68, 60, 62);
    canvas.drawPath(smile, strokePaint);

    // Eyes
    canvas.drawCircle(const Offset(43, 44), 2.5, fillPaint);
    canvas.drawCircle(const Offset(57, 44), 2.5, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _DoodleAvatarPainter oldDelegate) {
    return oldDelegate.avatarId != avatarId ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.accentColor != accentColor;
  }
}
