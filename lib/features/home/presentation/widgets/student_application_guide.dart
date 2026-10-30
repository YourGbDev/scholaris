import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../scholarships/models/scholarship.dart';
import '../../../scholarships/presentation/scholarship_detail_screen.dart';
import '../../../applications/presentation/submit_application_review_dialog.dart';
import 'student_action_sheet.dart';
import 'student_guide_greeting.dart';
import 'student_swipe_cue.dart';

class StudentApplicationGuide extends StatefulWidget {
  const StudentApplicationGuide({
    super.key,
    required this.onExit,
    required this.onFinish,
    required this.onSelectTab,
    this.homeTargets = const [],
    this.navTargets = const [],
    this.profileTargets = const [],
    this.homeScroll,
    this.profileScroll,
    this.discoverScroll,
    this.discoverDetails,
    this.discoverEnd,
    this.studentName = 'Student',
    this.gender,
    this.initialStep = 0,
    this.exampleScholarship,
  });
  final VoidCallback onExit, onFinish;
  final ValueChanged<int> onSelectTab;
  final List<GlobalKey> homeTargets, navTargets, profileTargets;
  final ScrollController? homeScroll, profileScroll, discoverScroll;
  final GlobalKey? discoverDetails;
  final GlobalKey? discoverEnd;
  final String studentName;
  final String? gender;
  final int initialStep;
  final Scholarship? exampleScholarship;
  @override
  State<StudentApplicationGuide> createState() =>
      _StudentApplicationGuideState();
}

class _Stop {
  const _Stop(
    this.title,
    this.tip, {
    this.anchor,
    this.action,
    this.scroll = false,
    this.end = false,
  });
  final String title, tip;
  final String? anchor, action;
  final bool scroll, end;
}

class _StudentApplicationGuideState extends State<StudentApplicationGuide>
    with SingleTickerProviderStateMixin {
  static const _stops = [
    _Stop(
      'Welcome',
      'It’s me, Ari! Let me show you around Scholaris. We’ll explore scholarships and try an application demo. Nothing is uploaded or sent.',
    ),
    _Stop(
      'View saved scholarships',
      'Revisit the scholarships you have saved here.',
      anchor: 'home-0',
    ),
    _Stop(
      'Keep your applications moving',
      'Resume applications and check their progress here.',
      anchor: 'home-1',
    ),
    _Stop(
      'Recommended for you',
      'Swipe up to explore the scholarships below your Home summary.',
      anchor: 'home-2',
      scroll: true,
    ),
    _Stop(
      'Explore Discover',
      'Tap Discover to browse your matches and the wider scholarship catalog.',
      anchor: 'nav-1',
      action: 'Discover',
    ),
    _Stop(
      'I’m back!',
      'This is Discover. Your matches come first, followed by more scholarships to explore. Take your time browsing.',
    ),
    _Stop(
      'Browse at your own pace',
      'Swipe up through your matches and the wider catalog. I’ll wait until you reach the end before we open one scholarship.',
      scroll: true,
      end: true,
    ),
    _Stop(
      'Open one scholarship',
      'Tap View Details on this scholarship. We’ll review this one together.',
      anchor: 'discover-details',
      action: 'View Details',
    ),
    _Stop(
      'Review the scholarship',
      'Scroll through why you match, eligibility and application requirements. Take your time; reach Back to top at the bottom to continue.',
      scroll: true,
      end: true,
    ),
    _Stop(
      'Back to top',
      'You’ve reached the end. Tap Back to top to return to the application button.',
      anchor: 'back-top',
      action: 'Back to top',
    ),
    _Stop(
      'Ready to apply?',
      'After reviewing the requirements, tap Start Application. This tour only demonstrates the process.',
      anchor: 'apply',
      action: 'Start Application',
    ),
    _Stop(
      'Review your application',
      'This is the application review screen. Scroll through the packet and read the confirmations. No documents or signature are required in this demo.',
      scroll: true,
      end: true,
    ),
    _Stop(
      'Try submitting the demo',
      'The confirmations cover accuracy, authorized review and the no-guarantee reminder. Tap the final button to simulate success. Nothing will be sent.',
      anchor: 'submit',
      action: 'Submit Application (Final)',
    ),
    _Stop(
      'You did it!',
      'You’ve completed a practice application! Nothing was uploaded or sent. Let’s see where you’ll follow real submissions.',
    ),
    _Stop(
      'Track your applications',
      'Tap Tracker to see where your real applications and status updates appear.',
      anchor: 'nav-2',
      action: 'Tracker',
    ),
    _Stop(
      'Your application journey',
      'Tracker shows your real applications. A submitted application is still awaiting review; it does not mean approval. This demo has not added an application.',
    ),
    _Stop(
      'Your Profile',
      'Tap Profile to find the information used for scholarship matching.',
      anchor: 'nav-3',
      action: 'Profile',
    ),
    _Stop(
      'Keep your details current',
      'Your academic, residency and financial details help Scholaris find relevant opportunities.',
    ),
    _Stop(
      'Academic information',
      'Scroll to your academic details. Update your school, degree and grades here when they change.',
      anchor: 'profile-0',
      scroll: true,
    ),
    _Stop(
      'Location & residency',
      'Keep scrolling to your location and residency details. These can matter for regional scholarships.',
      anchor: 'profile-1',
      scroll: true,
    ),
    _Stop(
      'Financial background',
      'Find your financial details here. Keep them accurate for income-based scholarships. The tour does not edit anything.',
      anchor: 'profile-2',
      scroll: true,
    ),
    _Stop(
      'Your shortcuts',
      'Tap the plus button to see quick actions.',
      anchor: 'nav-4',
      action: 'Quick Actions',
    ),
    _Stop(
      'Chat, scan or upload',
      'Chat opens Ari’s chat screen. Scan QR code opens a scholarship link; Upload document opens your document tools. AI replies are coming soon.',
    ),
    _Stop(
      'You’re ready to explore',
      'That’s Scholaris! Replay this tour from Settings whenever you need a refresher.',
    ),
  ];
  late int _step;
  int _ticket = 0;
  Rect? _rect;
  bool _ready = false;
  bool _actionPending = false;
  Scholarship? _selectedScholarship;
  final _surface = GlobalKey();
  final _apply = GlobalKey(),
      _backTop = GlobalKey(),
      _confirmations = GlobalKey(),
      _submit = GlobalKey();
  final _detailScroll = ScrollController(), _reviewScroll = ScrollController();
  ScrollController? _observed;
  late final AnimationController _cue;
  _Stop get _stop => _stops[_step];
  bool get _reduced => MediaQuery.disableAnimationsOf(context);
  bool get _mascot => _step == 0 || _step == 5 || _step == 13;
  bool get _details => _step >= 8 && _step <= 10;
  bool get _review => _step >= 11 && _step <= 12;
  ScrollController? get _scroll => _details
      ? _detailScroll
      : _review
      ? _reviewScroll
      : _step <= 3
      ? widget.homeScroll
      : _step <= 7
      ? widget.discoverScroll
      : _step >= 17 && _step <= 20
      ? widget.profileScroll
      : null;
  GlobalKey? get _anchor {
    final name = _stop.anchor;
    if (name == null) return null;
    if (name == 'apply') return _apply;
    if (name == 'back-top') return _backTop;
    if (name == 'submit') return _submit;
    if (name == 'discover-details') return widget.discoverDetails;
    for (final entry in {
      'home-': widget.homeTargets,
      'nav-': widget.navTargets,
      'profile-': widget.profileTargets,
    }.entries) {
      if (name.startsWith(entry.key)) {
        final index = int.parse(name.substring(entry.key.length));
        return entry.value.length > index ? entry.value[index] : null;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    if (_step >= 8 && _step <= 13) {
      _selectedScholarship = widget.exampleScholarship;
    }
    _cue = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _schedule();
  }

  @override
  void dispose() {
    _ticket++;
    _observed?.removeListener(_onScroll);
    _cue.dispose();
    _detailScroll.dispose();
    _reviewScroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Lazy feed sections mount and update their extent during this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
  }

  void _schedule() {
    final ticket = ++_ticket;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || ticket != _ticket) return;
      _observed?.removeListener(_onScroll);
      _observed = _scroll;
      _observed?.addListener(_onScroll);
      if (!_reduced) _cue.forward(from: 0);
      final target = _anchor?.currentContext;
      if (!_stop.scroll && target != null) {
        await Scrollable.ensureVisible(
          target,
          alignment: .2,
          duration: _reduced
              ? Duration.zero
              : const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
      if (mounted && ticket == _ticket) _measure();
    });
  }

  void _measure() {
    if (!mounted) return;
    final box = _anchor?.currentContext?.findRenderObject();
    final surface = _surface.currentContext?.findRenderObject();
    Rect? rect;
    if (box is RenderBox &&
        surface is RenderBox &&
        box.attached &&
        box.hasSize) {
      rect = surface.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
    }
    final controller = _scroll;
    // End gates are based on the current real scroll position. No timer or swipe-distance shortcut.
    final endKey = _step == 6
        ? widget.discoverEnd
        : _step == 8
        ? _backTop
        : null;
    final endBox = endKey?.currentContext?.findRenderObject();
    final endVisible =
        endKey == null ||
        (endBox is RenderBox &&
            surface is RenderBox &&
            endBox.attached &&
            endBox.hasSize &&
            surface.globalToLocal(endBox.localToGlobal(Offset.zero)).dy +
                    endBox.size.height <=
                MediaQuery.sizeOf(context).height);
    final atEnd =
        endVisible &&
        controller?.hasClients == true &&
        controller!.position.hasContentDimensions &&
        controller.position.extentAfter <= 24;
    final visible =
        rect != null &&
        rect.bottom > 90 &&
        rect.top < MediaQuery.sizeOf(context).height - 180;
    final ready = !_stop.scroll || (_stop.end ? atEnd : visible);
    if (rect != _rect || ready != _ready) {
      setState(() {
        _rect = rect;
        _ready = ready;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_stop.scroll) return;
    final controller = _scroll;
    if (controller?.hasClients != true) return;
    controller!.jumpTo(
      (controller.offset + delta).clamp(
        controller.position.minScrollExtent,
        controller.position.maxScrollExtent,
      ),
    );
    _measure();
    if (_cue.isAnimating) _cue.stop();
  }

  void _end() {
    final controller = _scroll;
    if (_stop.scroll && controller?.hasClients == true) {
      controller!.jumpTo(controller.position.maxScrollExtent);
    }
    _measure();
  }

  void _show(int next) {
    Tooltip.dismissAllToolTips();
    _cue.stop();
    _observed?.removeListener(_onScroll);
    _observed = null;
    setState(() {
      _step = next;
      _rect = null;
      _ready = false;
    });
    widget.onSelectTab(
      next <= 4
          ? 0
          : next <= 14
          ? 1
          : next <= 16
          ? 2
          : 3,
    );
    if ((next == 5 || next == 7) && widget.discoverScroll?.hasClients == true) {
      widget.discoverScroll!.jumpTo(0);
    }
    if (next == 17 && widget.profileScroll?.hasClients == true) {
      widget.profileScroll!.jumpTo(0);
    }
    _schedule();
  }

  void _next() =>
      _step == _stops.length - 1 ? widget.onFinish() : _show(_step + 1);
  void _advance() {
    if (_stop.action == null && (!_stop.scroll || _ready)) _next();
  }

  void _back() => _step == 0 ? widget.onExit() : _show(_step - 1);
  Future<void> _action() async {
    if (_actionPending) return;
    if (_step == 7 && widget.exampleScholarship == null) return;
    if (_step == 7) _selectedScholarship = widget.exampleScholarship;
    final step = _step;
    final ticket = _ticket;
    _actionPending = true;
    try {
      if (_step == 9 && _detailScroll.hasClients) {
        await _detailScroll.animateTo(
          0,
          duration: _reduced
              ? Duration.zero
              : const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
      if (mounted && _step == step && _ticket == ticket) _next();
    } finally {
      _actionPending = false;
    }
  }

  Widget _page() {
    final scholarship = _selectedScholarship;
    if (_details && scholarship != null) {
      return ScholarshipDetailScreen(
        key: const ValueKey('tour-real-scholarship'),
        scholarshipId: scholarship.id,
        initial: scholarship,
        tour: ScholarshipDetailTourHooks(
          scrollController: _detailScroll,
          backToTopKey: _backTop,
          applyKey: _apply,
          onBackToTop: () {
            if (_step == 9) _show(10);
          },
          onApply: () {
            if (_step == 10) _show(11);
          },
          onExit: () => _show(7),
        ),
      );
    }
    if (_review && scholarship != null) {
      return Material(
        color: kStudentCanvas,
        child: SafeArea(
          child: SubmitApplicationReviewDialog(
            key: const ValueKey('tour-real-review'),
            scholarship: scholarship,
            onSaveDraft: () async {},
            initialCertificationsChecked: true,
            tour: SubmitApplicationReviewTourHooks(
              scrollController: _reviewScroll,
              confirmationsKey: _confirmations,
              submitKey: _submit,
              onSubmit: () {
                if (_step == 12) _show(13);
              },
            ),
          ),
        ),
      );
    }
    if (_step == 22) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 110),
          child: SizedBox(
            width: 240,
            child: StudentActionSheet(onSelect: (_) {}),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onExit,
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _scrollBy(160),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _scrollBy(-160),
        const SingleActivator(LogicalKeyboardKey.end): _end,
      },
      child: Focus(
        autofocus: true,
        child: Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          namesRoute: true,
          label: 'Scholaris student tour',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final large = MediaQuery.textScalerOf(context).scale(15) > 22;
              final panel = math.min(
                large ? size.height * .5 : 210.0,
                size.height - 160,
              );
              final clipped = _rect?.intersect(
                Rect.fromLTWH(12, 60, size.width - 24, size.height - 80),
              );
              final target =
                  clipped != null && clipped.height > 12 && clipped.width > 12
                  ? clipped
                  : null;
              final below =
                  target != null &&
                  target.bottom + panel + 70 < size.height - 24;
              final above =
                  target != null && !below && target.top > panel + 130;
              return Stack(
                key: _surface,
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ExcludeFocus(
                        child: ExcludeSemantics(child: _page()),
                      ),
                    ),
                  ),
                  if (_mascot)
                    Positioned.fill(
                      child: StudentGuideGreeting(
                        title: _step == 0
                            ? 'Hi, ${widget.studentName.trim().split(' ').first}!'
                            : _stop.title,
                        message: _stop.tip,
                        gender: widget.gender,
                        onContinue: _next,
                        onSkip: widget.onExit,
                        explicitContinue: _step == 0,
                        celebrating: _step == 13,
                      ),
                    )
                  else ...[
                    Positioned.fill(
                      child: Listener(
                        onPointerSignal: (event) {
                          if (event is PointerScrollEvent) {
                            _scrollBy(event.scrollDelta.dy);
                          }
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _advance,
                          onVerticalDragUpdate: (event) =>
                              _scrollBy(-event.delta.dy),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _cue,
                          builder: (_, _) => CustomPaint(
                            painter: _SpotlightPainter(
                              target: target,
                              pulse: _reduced
                                  ? 0
                                  : math.sin(_cue.value * math.pi * 4).abs(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (target != null && _stop.action != null)
                      Positioned.fromRect(
                        rect: target,
                        child: Semantics(
                          label: 'Guide action: ${_stop.action}',
                          button: true,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(onTap: _action),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 28,
                      right: 28,
                      top: below ? target.bottom + 12 : null,
                      bottom: above
                          ? size.height - target.top + 12
                          : below
                          ? null
                          : (_step == 22 ? size.height * .52 : 110),
                      child: _bubble(panel, target, above, below),
                    ),
                    if (_stop.scroll && !_ready)
                      Positioned(
                        right: 0,
                        top: size.height * .28,
                        child: GestureDetector(
                          onVerticalDragUpdate: (event) =>
                              _scrollBy(-event.delta.dy),
                          child: SizedBox(
                            key: const ValueKey('guide-scroll-cue'),
                            width: 82,
                            height: 180,
                            child: AnimatedBuilder(
                              animation: _cue,
                              builder: (_, _) => StudentSwipeCue(
                                progress: _cue.value,
                                reducedMotion: _reduced,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 4,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          _backButton(),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Skip guide',
                            onPressed: widget.onExit,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_mascot && _step > 0)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 4,
                      left: 12,
                      child: _backButton(),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
  Widget _backButton() => IconButton(
    tooltip: 'Back',
    onPressed: _back,
    style: IconButton.styleFrom(backgroundColor: Colors.white),
    icon: const Icon(Icons.arrow_back_rounded, color: kPrimary),
  );
  Widget _bubble(double height, Rect? target, bool above, bool below) =>
      Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) _scrollBy(event.scrollDelta.dy);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _advance,
          onVerticalDragUpdate: _stop.scroll
              ? (event) => _scrollBy(-event.delta.dy)
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (below) _pointer(target!, false),
              Material(
                key: const ValueKey('guide-note'),
                color: Colors.white,
                elevation: 8,
                shadowColor: const Color(0x30000000),
                borderRadius: BorderRadius.circular(22),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: height),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          header: true,
                          liveRegion: true,
                          child: Text(
                            _stop.title,
                            style: geist(
                              fontSize: 20,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _stop.tip,
                          style: geist(
                            fontSize: 15,
                            height: 1.45,
                            color: kTextSecondary,
                          ),
                        ),
                        if (_step == 7 &&
                            widget.exampleScholarship == null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'No scholarship is available right now. Skip the guide and try again when listings load.',
                            style: geist(fontSize: 14),
                          ),
                        ] else if (_stop.action != null && target == null) ...[
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'Guide action: ${_stop.action}',
                            button: true,
                            child: FilledButton(
                              onPressed: _action,
                              child: Text(
                                _stop.action!,
                                style: geist(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (above) _pointer(target!, true),
              const SizedBox(height: 14),
              Semantics(
                button: true,
                enabled: !_stop.scroll || _ready,
                label: _stop.action != null
                    ? 'Tap the highlighted button'
                    : 'Continue tour',
                child: InkWell(
                  key: const ValueKey('guide-advance'),
                  onTap: _advance,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _stop.action != null
                          ? 'Tap the highlighted button'
                          : _stop.scroll && !_ready
                          ? 'Swipe up to explore'
                          : _step == _stops.length - 1
                          ? 'Tap anywhere to finish'
                          : 'Tap anywhere to continue',
                      textAlign: TextAlign.center,
                      style: geist(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  Widget _pointer(Rect target, bool down) => Align(
    alignment: Alignment(
      ((target.center.dx - 28) / (MediaQuery.sizeOf(context).width - 56) * 2 -
              1)
          .clamp(-1.0, 1.0),
      0,
    ),
    child: CustomPaint(
      size: const Size(22, 12),
      painter: _PointerPainter(down),
    ),
  );
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({this.target, required this.pulse});
  final Rect? target;
  final double pulse;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    if (target != null) {
      path.addRRect(
        RRect.fromRectAndRadius(target!.inflate(4), const Radius.circular(16)),
      );
    }
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = const Color(0xA31A2920));
    if (target != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          target!.inflate(4 + pulse * 3),
          const Radius.circular(16),
        ),
        Paint()
          ..color = const Color(0xFFD5EBDC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.target != target || oldDelegate.pulse != pulse;
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter(this.down);
  final bool down;
  @override
  void paint(Canvas canvas, Size size) {
    final path = down
        ? (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width, 0)
            ..lineTo(size.width / 2, size.height)
            ..close())
        : (Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width / 2, 0)
            ..lineTo(size.width, size.height)
            ..close());
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) => oldDelegate.down != down;
}
