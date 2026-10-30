import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';

/// The companion peeks from the edge with its lower body outside the viewport.
class StudentGuideGreeting extends StatelessWidget {
  const StudentGuideGreeting({
    super.key,
    required this.title,
    required this.message,
    required this.gender,
    required this.onContinue,
    required this.onSkip,
    this.explicitContinue = true,
    this.celebrating = false,
  });
  final String title;
  final String message;
  final String? gender;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final bool explicitContinue;
  final bool celebrating;

  @override
  Widget build(BuildContext context) {
    final female = gender?.trim().toLowerCase() == 'female';
    final asset = celebrating
        ? 'assets/mascots/mascot_${female ? 'female' : 'male'}_celebrating.png'
        : female
        ? 'assets/images/mascot_female.png'
        : 'assets/images/mascot_male_welcome_wave.png';
    return LayoutBuilder(
      builder: (context, constraints) {
        final portraitHeight = constraints.maxHeight < 500 ? 115.0 : 205.0;
        final hintSpace = explicitContinue
            ? 0.0
            : MediaQuery.textScalerOf(context).scale(14) * 3 + 12;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: explicitContinue ? null : onContinue,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xA31A2920)),
                Positioned(
                  left: -24,
                  bottom: 0,
                  width: 180,
                  height: portraitHeight,
                  child: ExcludeSemantics(
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: 0,
                        maxHeight: portraitHeight * 2.4,
                        child: Image.asset(
                          asset,
                          height: !female && !celebrating
                              ? portraitHeight * 1.35
                              : portraitHeight * 2.4,
                          width: !female && !celebrating ? 200 : 240,
                          fit: BoxFit.contain,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: portraitHeight - 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: Colors.white,
                        elevation: 6,
                        shadowColor: const Color(0x26000000),
                        borderRadius: BorderRadius.circular(22),
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                (constraints.maxHeight -
                                        portraitHeight -
                                        MediaQuery.paddingOf(context).top -
                                        52 -
                                        hintSpace)
                                    .clamp(80, 500),
                          ),
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
                                    title,
                                    style: geist(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  message,
                                  style: geist(
                                    fontSize: 15,
                                    height: 1.45,
                                    color: kTextSecondary,
                                  ),
                                ),
                                if (explicitContinue) ...[
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: onSkip,
                                        child: Text(
                                          'Skip',
                                          style: geist(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      FilledButton(
                                        onPressed: onContinue,
                                        child: Text(
                                          'Continue',
                                          style: geist(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 58),
                        child: CustomPaint(
                          size: const Size(22, 16),
                          painter: _SpeechTail(),
                        ),
                      ),
                      if (!explicitContinue)
                        Center(
                          child: Padding(
                            key: const ValueKey('guide-advance'),
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Tap anywhere to continue',
                              textAlign: TextAlign.center,
                              style: geist(
                                fontSize: 14,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!explicitContinue)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 4,
                    right: 12,
                    left: 12,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Tooltip(
                        message: 'Skip guide',
                        child: TextButton(
                          onPressed: onSkip,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kPrimary,
                          ),
                          child: Text(
                            'Skip guide',
                            style: geist(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpeechTail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(4, size.height)
      ..close(),
    Paint()..color = Colors.white,
  );
  @override
  bool shouldRepaint(_SpeechTail oldDelegate) => false;
}
