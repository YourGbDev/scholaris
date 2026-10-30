import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/theme/app_theme.dart';

final studentTourReplayProvider = StateProvider<int>((ref) => 0);
final _tourSeenProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  user,
) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('student_tour_v1_$user') ?? false;
});

/// Lives inside Home so auth expiry removes the guide with the protected UI.
class StudentTourLayer extends ConsumerStatefulWidget {
  const StudentTourLayer({
    super.key,
    required this.userId,
    required this.targets,
    required this.bottomClearance,
    required this.onSelectTab,
    required this.onActiveChanged,
  });
  final String? userId;
  final List<GlobalKey> targets;
  final double bottomClearance;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<bool> onActiveChanged;

  @override
  ConsumerState<StudentTourLayer> createState() => _StudentTourLayerState();
}

class _StudentTourLayerState extends ConsumerState<StudentTourLayer> {
  int? _step;
  String? _dismissedUser;
  Rect? _target;
  static const _tabs = [1, 2, 3, 3];
  static const _targets = [1, 2, 3, 4];
  static const _titles = [
    'Find your opportunities',
    'Follow your applications',
    'Make your profile count',
    'Your quick actions',
  ];
  static const _descriptions = [
    'Discover scholarships and compare their requirements with your profile. A match is guidance, not a guarantee of eligibility.',
    'Open Tracker to return to drafts and follow updates on submitted applications.',
    'Keep your academic, location, and financial information current to improve the relevance of your matches.',
    'Use the plus button to scan a scholarship QR code or upload an application document.',
  ];

  @override
  void didUpdateWidget(StudentTourLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _step = null;
      _target = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onActiveChanged(false);
      });
    }
  }

  void _showStep(int step) {
    Tooltip.dismissAllToolTips();
    setState(() {
      _step = step;
      _target = null;
    });
    widget.onActiveChanged(true);
    widget.onSelectTab(_tabs[step]);
    _measureTarget();
  }

  void _measureTarget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _step == null) return;
      Tooltip.dismissAllToolTips();
      final box = widget.targets[_targets[_step!]].currentContext
          ?.findRenderObject();
      final layer = context.findRenderObject();
      if (box is RenderBox &&
          layer is RenderBox &&
          box.hasSize &&
          layer.hasSize) {
        final rect = box.localToGlobal(Offset.zero, ancestor: layer) & box.size;
        if (rect != _target) setState(() => _target = rect);
      }
    });
  }

  Future<void> _finish() async {
    final user = widget.userId;
    setState(() {
      _step = null;
      _dismissedUser = user;
    });
    widget.onActiveChanged(false);
    if (user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool('student_tour_v1_$user', true)) {
        throw StateError('Tour preference was not saved');
      }
      if (mounted) ref.invalidate(_tourSeenProvider(user));
    } catch (_) {
      if (mounted && widget.userId == user) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tour dismissed. We could not save this preference on this device.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(studentTourReplayProvider, (_, next) {
      if (widget.userId != null) _showStep(0);
    });
    final user = widget.userId;
    if (user == null) return const SizedBox.shrink();
    final seen = ref.watch(_tourSeenProvider(user)).valueOrNull;
    final active = _step != null;
    if (!active && (seen != false || _dismissedUser == user)) {
      return const SizedBox.shrink();
    }
    if (active) _measureTarget();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bottom = math.min(
          widget.bottomClearance + 12,
          constraints.maxHeight * .48,
        );
        final maxHeight = math.max(
          80.0,
          constraints.maxHeight -
              bottom -
              MediaQuery.paddingOf(context).top -
              24,
        );
        return Stack(
          children: [
            if (active) ...[
              const Positioned.fill(
                child: ModalBarrier(
                  dismissible: false,
                  color: Colors.transparent,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _TourScrim(_target)),
                ),
              ),
            ],
            Positioned(
              left: 20,
              right: 20,
              bottom: bottom,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    maxHeight: maxHeight,
                  ),
                  child: FocusScope(
                    child: FocusTraversalGroup(
                      child: Semantics(
                        explicitChildNodes: true,
                        scopesRoute: active,
                        namesRoute: active,
                        label: active ? 'Scholaris app tour' : null,
                        child: Material(
                          color: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0x18000000),
                          borderRadius: BorderRadius.circular(24),
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (active) ...[
                                  Text(
                                    '${_step! + 1} of 4',
                                    style: geist(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Semantics(
                                  header: true,
                                  liveRegion: active,
                                  child: Text(
                                    active
                                        ? _titles[_step!]
                                        : 'Take a quick tour',
                                    style: geist(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: kOnSurface,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  active ? _descriptions[_step!] : 'Find your way around Scholaris in four short steps.',
                                  style: geist(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: const Color(0xFF59635D),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: _finish,
                                      child: Text(
                                        active ? 'Skip tour' : 'Not now',
                                      ),
                                    ),
                                    FilledButton(
                                      autofocus: active,
                                      onPressed: () {
                                        if (!active) {
                                          _showStep(0);
                                        } else if (_step! < 3) {
                                          _showStep(_step! + 1);
                                        } else {
                                          _finish();
                                        }
                                      },
                                      child: Text(
                                        active
                                            ? (_step == 3
                                                  ? 'Finish tour'
                                                  : 'Next')
                                            : 'Start tour',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TourScrim extends CustomPainter {
  const _TourScrim(this.target);
  final Rect? target;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (target != null) {
      path.addRRect(
        RRect.fromRectAndRadius(target!.inflate(3), const Radius.circular(18)),
      );
    }
    canvas.drawPath(path, Paint()..color = const Color(0x66000000));
    if (target != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(target!.inflate(3), const Radius.circular(18)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_TourScrim oldDelegate) => oldDelegate.target != target;
}
