import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'mascot_pose_view.dart';

/// One greeting followed by three seconds of complete stillness.
class MascotGreetingFrame {
  const MascotGreetingFrame(this.wave, this.tilt);
  final double wave;
  final double tilt;
  static const movement = Duration(milliseconds: 2800);
  static const rest = Duration(seconds: 3);

  factory MascotGreetingFrame.at(Duration elapsed) {
    final t = (elapsed.inMicroseconds % 5800000) / 1000000;
    if (t >= 2.8) return const MascotGreetingFrame(0, 0);
    final envelope = _smooth(.15, .5, t) * (1 - _smooth(2.1, 2.8, t));
    return MascotGreetingFrame(
      math.sin((t - .15) * math.pi * 2.1) * .095 * envelope,
      -.045 * math.sin(math.pi * ((t - .25) / 2.3).clamp(0, 1)) * envelope,
    );
  }
}

double _smooth(double a, double b, double value) {
  final t = ((value - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Local pivots are normalized to the canonical transparent portraits.
class MascotGreetingRig {
  static ui.Offset deform(
    ui.Offset point,
    MascotGreetingFrame frame, {
    required bool female,
  }) {
    final x = point.dx, y = point.dy;
    final hand = female
        ? _smooth(.705, .74, x) *
              (1 - _smooth(.91, .96, x)) *
              _smooth(.37, .42, y) *
              (1 - _smooth(.59, .65, y))
        : _smooth(.13, .18, x) *
              (1 - _smooth(.36, .40, x)) *
              _smooth(.30, .35, y) *
              (1 - _smooth(.56, .63, y));
    final waved = _rotate(
      point,
      female ? const Offset(.77, .61) : const Offset(.25, .60),
      frame.wave * hand,
    );
    final head = female
        ? _smooth(.20, .28, x) *
              (1 - _smooth(.64, .70, x)) *
              _smooth(0, .03, y) *
              (1 - _smooth(.47, .54, y))
        : _smooth(.34, .42, x) *
              (1 - _smooth(.80, .84, x)) *
              _smooth(0, .03, y) *
              (1 - _smooth(.47, .53, y));
    return _rotate(
      waved,
      female ? const Offset(.53, .54) : const Offset(.57, .53),
      frame.tilt * head,
    );
  }

  static Offset _rotate(Offset p, Offset pivot, double angle) {
    if (angle == 0) return p;
    final d = p - pivot, c = math.cos(angle), s = math.sin(angle);
    return pivot + Offset(c * d.dx - s * d.dy, s * d.dx + c * d.dy);
  }
}

class GreetingMascotPortrait extends StatefulWidget {
  const GreetingMascotPortrait({super.key, this.gender, required this.height});
  final String? gender;
  final double height;

  @override
  State<GreetingMascotPortrait> createState() => _GreetingMascotPortraitState();
}

class _GreetingMascotPortraitState extends State<GreetingMascotPortrait>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  Timer? _pause;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;
  bool _enabled = false;
  bool _foreground = true;
  String? _asset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller =
        AnimationController(vsync: this, duration: MascotGreetingFrame.movement)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _enabled) {
              _pause = Timer(MascotGreetingFrame.rest, () {
                if (mounted && _enabled) _controller.forward(from: 0);
              });
            }
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant GreetingMascotPortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gender != widget.gender) _resolveImage();
  }

  void _resolveImage() {
    final asset = getMascotGreetingAssetPath(gender: widget.gender);
    if (_asset == asset) return;
    _asset = asset;
    if (_listener != null) _stream?.removeListener(_listener!);
    _image?.dispose();
    _image = null;
    _stream = AssetImage(asset).resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener((info, synchronous) {
      if (!mounted) {
        info.dispose();
        return;
      }
      _image?.dispose();
      _image = info.image.clone();
      info.dispose();
      if (!synchronous) setState(() {});
    });
    _stream!.addListener(_listener!);
  }

  void _syncMotion() {
    final enabled =
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (_enabled == enabled) return;
    _enabled = enabled;
    _pause?.cancel();
    _controller.stop();
    _controller.value = 0;
    if (enabled) _controller.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pause?.cancel();
    if (_listener != null) _stream?.removeListener(_listener!);
    _controller.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: widget.height,
      child: _image == null
          ? Image.asset(_asset!, fit: BoxFit.contain)
          : CustomPaint(
              painter: _GreetingPainter(
                _image!,
                _controller,
                female: getMascotName(gender: widget.gender) == 'Ari',
              ),
              size: Size.infinite,
            ),
    ),
  );
}

class _GreetingPainter extends CustomPainter {
  _GreetingPainter(this.image, this.animation, {required this.female})
    : super(repaint: animation);
  final ui.Image image;
  final AnimationController animation;
  final bool female;

  @override
  void paint(Canvas canvas, Size size) {
    final fitted = applyBoxFit(
      BoxFit.contain,
      Size(image.width.toDouble(), image.height.toDouble()),
      size,
    ).destination;
    canvas.save();
    canvas.translate(
      (size.width - fitted.width) / 2,
      (size.height - fitted.height) / 2,
    );
    canvas.scale(fitted.width / image.width, fitted.height / image.height);
    final frame = MascotGreetingFrame.at(
      Duration(microseconds: (animation.value * 2800000).round()),
    );
    const divisions = 40;
    final positions = <Offset>[], texture = <Offset>[], indices = <int>[];
    for (var y = 0; y <= divisions; y++) {
      for (var x = 0; x <= divisions; x++) {
        final point = Offset(x / divisions, y / divisions);
        final moved = MascotGreetingRig.deform(point, frame, female: female);
        positions.add(Offset(moved.dx * image.width, moved.dy * image.height));
        texture.add(Offset(point.dx * image.width, point.dy * image.height));
        if (x < divisions && y < divisions) {
          final a = y * (divisions + 1) + x, b = a + 1, c = a + divisions + 1;
          indices.addAll([a, b, c, b, c + 1, c]);
        }
      }
    }
    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: texture,
      indices: indices,
    );
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
      );
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
    vertices.dispose();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GreetingPainter old) =>
      old.image != image || old.female != female || old.animation != animation;
}

/// One joined illustration preserves the close pose and shared straight crop.
class MascotWelcomePair extends StatelessWidget {
  const MascotWelcomePair({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/mascots/greetings/welcome_pair.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    ),
  );
}
