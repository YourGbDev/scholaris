// lib/shared/widgets/student_mascot.dart
//
// Official Mascot component for Aris (boy) and Aria (girl) companions.
// Replaces Lumi and Eli mascots with clean vector mascot cutouts.
//
// Automatically adapts to the student's gender from their profile (defaulting to Aria),
// or accepts an explicit [gender] parameter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';

/// Available mascot companions in Scholaris.
enum MascotGender {
  male,
  female;

  static MascotGender fromString(String? value) {
    if (value == null) return MascotGender.female;
    final lower = value.trim().toLowerCase();
    if (lower == 'male' || lower == 'm' || lower == 'boy' || lower == 'man') {
      return MascotGender.male;
    }
    return MascotGender.female;
  }
}

/// The available visual poses for Aris and Aria.
enum StudentMascotPose {
  /// Hero / welcome stance with friendly, welcoming posture
  hero('hero', 'Student mascot welcoming you with bright optimism'),

  /// Core Expressions
  happy('happy', 'Student mascot smiling joyfully'),
  determined('determined', 'Student mascot determined and ready to achieve goals'),
  thinking('thinking', 'Student mascot in thoughtful reflection'),
  celebrating('celebrating', 'Student mascot celebrating academic success!'),
  curious('curious', 'Student mascot looking curious and inquisitive'),

  /// The Student Journey stages
  student('student', 'Student mascot in daily school routine with backpack'),
  applicant('applicant', 'Student mascot taking the next step with application documents'),
  scholar('scholar', 'Student mascot growing knowledge with a stack of textbooks'),
  graduate('graduate', 'Student mascot wearing graduation gown holding diploma'),

  /// Turnaround poses
  front('front', 'Student mascot front turnaround view'),
  side('side', 'Student mascot side turnaround view'),
  back('back', 'Student mascot back turnaround view'),

  // --- Backwards-compatibility aliases for Lumi / Eli poses ---
  welcome('hero', 'Student mascot welcoming you warmly'),
  neutral('happy', 'Student mascot in a relaxed stance'),
  brightGlow('celebrating', 'Student mascot celebrating your success!'),
  dimGlow('thinking', 'Student mascot pondering opportunities'),
  concerned('thinking', 'Student mascot looking thoughtful and supportive'),
  appIcon('hero', 'Student mascot official portrait'),
  guiding('determined', 'Student mascot guiding the way forward'),
  studying('scholar', 'Student mascot studying and reviewing'),
  encouraging('celebrating', 'Student mascot encouraging you'),
  peeking('curious', 'Student mascot peeking with curiosity'),
  mail('applicant', 'Student mascot presenting your application documents'),
  security('determined', 'Student mascot guiding your account security');

  const StudentMascotPose(this.assetKey, this.semanticsLabel);

  final String assetKey;
  final String semanticsLabel;

  String assetPath(MascotGender gender) {
    final prefix = gender == MascotGender.male ? 'aris' : 'aria';
    return 'assets/images/mascot/${prefix}_$assetKey.png';
  }
}

/// Backward compatibility aliases for existing code and test suites.
typedef LumiPose = StudentMascotPose;
typedef EliPose = StudentMascotPose;

/// Reusable widget for rendering the Scholaris student mascot (Aris or Aria).
class StudentMascot extends StatelessWidget {
  const StudentMascot({
    super.key,
    required this.pose,
    this.gender,
    this.height = 140,
    this.width,
    this.fit = BoxFit.contain,
    this.onTap,
    this.animate = false,
    this.filterQuality = FilterQuality.high,
  });

  /// Global toggle for idle animations on mascots.
  /// Defaults to true; can be set to false to globally disable animations
  /// on lower-end devices or in test harnesses.
  static bool enableAnimations = true;

  /// Internal flag to allow unit tests to verify idle animation mechanics.
  @visibleForTesting
  static bool forceAnimationsInTests = false;

  /// Detects whether Flutter widget tests are running with a repeating animation
  /// that would block [WidgetTester.pumpAndSettle].
  static bool get _isWidgetTestBinding {
    if (forceAnimationsInTests) return false;
    final type = WidgetsBinding.instance.runtimeType.toString();
    return type == 'AutomatedTestWidgetsFlutterBinding' ||
        type == 'LiveTestWidgetsFlutterBinding';
  }

  final StudentMascotPose pose;
  final MascotGender? gender;
  final double? height;
  final double? width;
  final BoxFit fit;
  final VoidCallback? onTap;

  /// Whether to play a subtle idle animation (gentle float/bounce + occasional blink).
  /// Recommended for persistent hero banners (Discover hero, Auth hero).
  final bool animate;

  /// Resampling filter quality when scaling the mascot asset.
  /// Defaults to [FilterQuality.high] (bicubic) for smooth, unpixelated line art.
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    if (gender != null) {
      return _buildImage(context, gender!);
    }

    final hasScope = context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() != null;
    if (!hasScope) {
      return _buildImage(context, MascotGender.female);
    }

    return Consumer(
      builder: (context, ref, _) {
        final profile = ref.watch(currentProfileProvider).valueOrNull;
        final resolvedGender = profile?.gender != null
            ? MascotGender.fromString(profile!.gender)
            : MascotGender.female;
        return _buildImage(context, resolvedGender);
      },
    );
  }

  Widget _buildImage(BuildContext context, MascotGender activeGender) {
    final path = pose.assetPath(activeGender);

    Widget image = Image.asset(
      path,
      height: height,
      width: width,
      fit: fit,
      filterQuality: filterQuality,
      semanticLabel: pose.semanticsLabel,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          height: height,
          width: width ?? height,
          child: const Center(
            child: Icon(Icons.school_rounded, size: 48, color: Colors.grey),
          ),
        );
      },
    );

    final shouldAnimate = animate &&
        StudentMascot.enableAnimations &&
        !_isWidgetTestBinding &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

    if (shouldAnimate) {
      image = _IdleMascotWrapper(child: image);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: image,
      );
    }

    return image;
  }
}

/// Internal widget providing a subtle, battery-efficient idle animation loop:
/// - Gentle vertical bounce (2-4px) paired with natural breathing scale.
/// - Occasional eyelid flutter / blink micro-compression (140ms duration every ~4s).
/// - Automatically pauses ticking when offstage or inactive via [TickerMode].
class _IdleMascotWrapper extends StatefulWidget {
  const _IdleMascotWrapper({
    required this.child,
  });

  final Widget child;

  @override
  State<_IdleMascotWrapper> createState() => _IdleMascotWrapperState();
}

class _IdleMascotWrapperState extends State<_IdleMascotWrapper>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  late final AnimationController _blinkController;
  late final Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Gentle vertical bounce + breathing float (2800ms oscillation)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOutSine,
    );

    // 2. Occasional blink micro-compression (every 4000ms, 140ms active blink)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _blinkAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 96.5, // ~3860ms resting open eyes
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 1.75, // ~70ms closing
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 1.75, // ~70ms reopening
      ),
    ]).animate(_blinkController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceAnimation, _blinkAnimation]),
      builder: (context, child) {
        final bounce = _bounceAnimation.value;
        final blink = _blinkAnimation.value;

        // Gentle vertical float (0 to -3px)
        final dy = -3.0 * bounce;

        // Subtle breathing scale (1.2% vertical expansion, volume-conserving 0.6% horizontal contraction)
        final breathScaleY = 1.0 + (0.012 * bounce);
        final breathScaleX = 1.0 - (0.006 * bounce);

        // Blink micro-compression (6% dip in height around eye level)
        final blinkScaleY = 1.0 - (0.06 * blink);

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scaleX: breathScaleX,
            scaleY: breathScaleY,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scaleY: blinkScaleY,
              // Eye-level anchor for Aris and Aria (upper 1/3 of figure)
              alignment: const Alignment(0, -0.32),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Backward compatibility aliases for existing widgets.
typedef LumiMascot = StudentMascot;
typedef EliMascot = StudentMascot;

