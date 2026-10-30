import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'student_guide_greeting.dart';
import 'student_application_guide.dart';
import '../../../scholarships/models/scholarship.dart';

final studentTourReplayProvider = StateProvider<int>((ref) => 0);
final _tourSeenProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  user,
) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('student_tour_v1_$user') ?? false;
});

/// The guide stays in Home's tree so account changes/auth teardown remove it.
class StudentTourLayer extends ConsumerStatefulWidget {
  const StudentTourLayer({
    super.key,
    required this.userId,
    required this.targets,
    required this.bottomClearance,
    required this.onSelectTab,
    required this.onActiveChanged,
    this.homeTargets = const [],
    this.profileTargets = const [],
    this.homeScroll,
    this.profileScroll,
    this.discoverScroll,
    this.discoverDetails,
    this.discoverEnd,
    this.studentName = 'Student',
    this.gender,
    this.exampleScholarship,
    this.profileReady = true,
  });
  final String? userId;
  final List<GlobalKey> targets;
  final List<GlobalKey> homeTargets;
  final List<GlobalKey> profileTargets;
  final ScrollController? homeScroll;
  final ScrollController? profileScroll;
  final ScrollController? discoverScroll;
  final GlobalKey? discoverDetails;
  final GlobalKey? discoverEnd;
  final String studentName;
  final String? gender;
  final bool profileReady;
  final Scholarship? exampleScholarship;
  final double bottomClearance;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<bool> onActiveChanged;

  @override
  ConsumerState<StudentTourLayer> createState() => _StudentTourLayerState();
}

class _StudentTourLayerState extends ConsumerState<StudentTourLayer> {
  bool _active = false;
  int _initialStep = 0;
  bool _invitationNotified = false;
  String? _dismissedUser;
  String? _pendingReplayUser;

  @override
  void didUpdateWidget(StudentTourLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _active = false;
      _invitationNotified = false;
      _pendingReplayUser = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onActiveChanged(false);
      });
    }
    if (widget.profileReady &&
        _pendingReplayUser == widget.userId &&
        widget.userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pendingReplayUser == widget.userId) {
          _start(replay: true);
        }
      });
    }
  }

  void _start({bool replay = false}) {
    if (widget.userId == null) return;
    if (!widget.profileReady) {
      if (replay) _pendingReplayUser = widget.userId;
      return;
    }
    if (_active) return;
    _pendingReplayUser = null;
    Tooltip.dismissAllToolTips();
    widget.onSelectTab(0);
    setState(() {
      _active = true;
      _initialStep = replay ? 0 : 1;
    });
    widget.onActiveChanged(true);
  }

  Future<void> _finish() async {
    final user = widget.userId;
    setState(() {
      _active = false;
      _dismissedUser = user;
    });
    widget.onActiveChanged(false);
    widget.onSelectTab(0);
    if (user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool('student_tour_v1_$user', true)) {
        throw StateError('Guide preference was not saved');
      }
      if (mounted && widget.userId == user) {
        ref.invalidate(_tourSeenProvider(user));
      }
    } catch (_) {
      if (mounted && widget.userId == user) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Guide closed. We could not save this preference on this device.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(studentTourReplayProvider, (_, next) {
      if (widget.userId != null) _start(replay: true);
    });
    final user = widget.userId;
    if (user == null || !widget.profileReady) return const SizedBox.shrink();
    final seen = ref.watch(_tourSeenProvider(user)).valueOrNull;
    if (_active) {
      return StudentApplicationGuide(
        key: ValueKey(user),
        onExit: _finish,
        onFinish: _finish,
        homeTargets: widget.homeTargets,
        navTargets: widget.targets,
        onSelectTab: widget.onSelectTab,
        profileTargets: widget.profileTargets,
        homeScroll: widget.homeScroll,
        profileScroll: widget.profileScroll,
        discoverScroll: widget.discoverScroll,
        discoverDetails: widget.discoverDetails,
        discoverEnd: widget.discoverEnd,
        studentName: widget.studentName,
        gender: widget.gender,
        initialStep: _initialStep,
        exampleScholarship: widget.exampleScholarship,
      );
    }
    if (seen != false || _dismissedUser == user) return const SizedBox.shrink();

    if (!_invitationNotified) {
      _invitationNotified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            widget.userId == user &&
            widget.profileReady &&
            !_active) {
          widget.onActiveChanged(true);
        }
      });
    }

    return StudentGuideGreeting(
      title: 'Hi, ${widget.studentName.trim().split(' ').first}!',
      message: 'It’s me, Ari! Let me show you around Scholaris. We’ll explore scholarships and try an application demo. Nothing is uploaded or sent.',
      gender: widget.gender,
      onContinue: _start,
      onSkip: _finish,
    );
  }
}
