
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_motion.dart';

/// An orientation cue for aggregate totals, never a live announcement of frames.
class OrgMetricCount extends StatefulWidget {
  const OrgMetricCount({
    super.key,
    required this.motionId,
    required this.targetValue,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.formatWithCommas = true,
  });
  final String motionId, prefix, suffix;
  final int targetValue;
  final TextStyle? style;
  final bool formatWithCommas;
  @override
  State<OrgMetricCount> createState() => _OrgMetricCountState();
}

class _OrgMetricCountState extends State<OrgMetricCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = isReducedMotion(context);
    if (!_started) {
      _started = true;
      final bucket = PageStorage.maybeOf(context);
      final seen =
          bucket?.readState(context, identifier: widget.motionId) == true;
      bucket?.writeState(context, true, identifier: widget.motionId);
      if (reduced || seen || widget.targetValue == 0) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    } else if (reduced) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(OrgMetricCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Filters and refreshes deliver data, not a new entrance sequence.
    if (oldWidget.targetValue != widget.targetValue) _controller.value = 1;
  }

  String _format(int value) {
    final digits = widget.formatWithCommas
        ? value.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          )
        : '$value';
    return '${widget.prefix}$digits${widget.suffix}';
  }

  @override
  Widget build(BuildContext context) {
    final label = _format(widget.targetValue);
    final style = DefaultTextStyle.of(context).style
        .merge(widget.style)
        .copyWith(fontFeatures: [const FontFeature.tabularFigures()]);
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Text(
            _format(
              (widget.targetValue *
                      Curves.easeOutCubic.transform(_controller.value))
                  .round(),
            ),
            style: style,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
