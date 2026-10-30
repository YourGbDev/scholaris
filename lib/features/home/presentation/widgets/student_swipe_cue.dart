import 'package:flutter/material.dart';

/// A rounded one-finger hand demonstrates an upward swipe along the screen edge.
class StudentSwipeCue extends StatelessWidget {
  const StudentSwipeCue({super.key, required this.progress, required this.reducedMotion});
  final double progress;
  final bool reducedMotion;
  @override
  Widget build(BuildContext context) {
    final phase = progress >= 1 ? 1.0 : (progress * 2) % 1;
    final position = reducedMotion ? 0.5 : Curves.easeInOutCubic.transform(phase);
    return IgnorePointer(child: SizedBox(width: 82, height: 180,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(left: 15, top: 30, bottom: 25, child: Container(width: 3,
          decoration: BoxDecoration(color: const Color(0x80FFFFFF), borderRadius: BorderRadius.circular(3)))),
        Positioned(left: 9, top: 22, child: CustomPaint(size: const Size(15, 12), painter: _ArrowTip())),
        Positioned(left: 4, top: 76 - position * 68,
          child: CustomPaint(key: const ValueKey('swipe-hand'), size: const Size(78, 96), painter: _HandPainter())),
      ])));
  }
}

class _ArrowTip extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(Path()..moveTo(1, 10)..lineTo(7.5, 3)..lineTo(14, 10),
    Paint()..color = const Color(0xDDFFFFFF)..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  @override
  bool shouldRepaint(_ArrowTip oldDelegate) => false;
}

class _HandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save(); canvas.scale(size.width / 100, size.height / 120);
    final hand = Path()..moveTo(41, 95)..cubicTo(29, 84, 23, 74, 18, 66)
      ..cubicTo(13, 58, 17, 51, 23, 52)..lineTo(34, 64)..lineTo(28, 19)
      ..cubicTo(26, 6, 41, 3, 44, 16)..lineTo(50, 44)
      ..cubicTo(53, 33, 66, 34, 68, 45)..cubicTo(74, 37, 86, 42, 85, 52)
      ..cubicTo(95, 48, 100, 58, 97, 66)..lineTo(92, 82)
      ..cubicTo(89, 95, 82, 100, 76, 106)..close();
    canvas.drawShadow(hand, const Color(0xAA10251A), 7, true);
    canvas.drawPath(hand, Paint()..shader = const LinearGradient(begin: Alignment.topLeft,
      end: Alignment.bottomRight, colors: [Color(0xFFFFE8C8), Color(0xFFECC79F), Color(0xFFBE936D)])
      .createShader(const Rect.fromLTWH(15, 8, 85, 100)));
    canvas.drawPath(hand, Paint()..color = const Color(0xFFB78E68)..style = PaintingStyle.stroke
      ..strokeWidth = 1.4..strokeJoin = StrokeJoin.round);
    final creases = Path()..moveTo(50, 45)..lineTo(54, 60)..moveTo(68, 46)..lineTo(70, 61)
      ..moveTo(85, 53)..lineTo(84, 66)..moveTo(35, 66)..quadraticBezierTo(44, 63, 51, 73);
    canvas.drawPath(creases, Paint()..color = const Color(0x66885F3B)..style = PaintingStyle.stroke
      ..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    final cuff = Path()..moveTo(36, 94)..lineTo(77, 102)..lineTo(74, 118)..lineTo(32, 109)..close();
    canvas.drawPath(cuff, Paint()..shader = const LinearGradient(colors: [Color(0xFF7CA88A), Color(0xFF215338)])
      .createShader(const Rect.fromLTWH(32, 94, 45, 24)));
    canvas.restore();
  }
  @override
  bool shouldRepaint(_HandPainter oldDelegate) => false;
}
