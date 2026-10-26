import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Opt-in backdrop lens experiment. Unsupported renderers retain the real dock.
class StudentGlassRefraction extends StatefulWidget {
  const StudentGlassRefraction({super.key, required this.child, this.enabled = false, this.radius = 29});
  final Widget child;
  final bool enabled;
  final double radius;

  @override
  State<StudentGlassRefraction> createState() => _StudentGlassRefractionState();
}

class _StudentGlassRefractionState extends State<StudentGlassRefraction> {
  ui.FragmentShader? _shader;
  bool _loading = false;

  @override
  void didChangeDependencies() { super.didChangeDependencies(); _load(); }
  @override
  void didUpdateWidget(StudentGlassRefraction oldWidget) { super.didUpdateWidget(oldWidget); _load(); }

  Future<void> _load() async {
    if (!widget.enabled || !ui.ImageFilter.isShaderFilterSupported || _loading || _shader != null) return;
    _loading = true;
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/student_glass_lens.frag');
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (_) {
      // Asset/renderer failures leave the existing accessible material intact.
    } finally { _loading = false; }
  }

  @override
  void dispose() { _shader?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final shader = _shader;
    if (!widget.enabled || shader == null || media.highContrast || media.disableAnimations || media.accessibleNavigation) return widget.child;
    return LayoutBuilder(builder: (context, constraints) {
      if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) return widget.child;
      // First vec2 and sampler are supplied by the engine; our geometry follows.
      shader.setFloat(2, constraints.maxWidth * media.devicePixelRatio);
      shader.setFloat(3, constraints.maxHeight * media.devicePixelRatio);
      shader.setFloat(4, widget.radius * media.devicePixelRatio);
      shader.setFloat(5, 5 * media.devicePixelRatio);
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: BackdropFilter(filter: ui.ImageFilter.shader(shader), child: widget.child),
      );
    });
  }
}
