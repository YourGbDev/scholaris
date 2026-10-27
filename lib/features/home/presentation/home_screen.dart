// lib/features/home/presentation/home_screen.dart
//
// Student app shell with a floating glass dock and four retained destinations.
// A separate right-hand "+" opens the existing QR/document action sheet:
//   Home         â€” student overview, stats & recommendations
//   Discover     â€” personalized matches + full catalog
//   [+] Action   â€” opens Quick Actions bottom sheet (QR Scan + Document Upload)
//   Tracker      â€” the student's status-aware tracking surface
//   Profile      â€” profile summary & credentials
//
// NOTE: "LiquidGlass" in this Flutter codebase is a cross-platform custom BackdropFilter
// shader simulation, not Apple's proprietary native Liquid Glass OS compositor material.
//
// IndexedStack preserves page state; StudentTabEntrance supplies visit feedback.

import 'dart:math' as math;
import 'widgets/student_selection_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/features/applications/presentation/applications_screen.dart';
import 'package:scholaris/features/dashboard/presentation/student_dashboard_screen.dart';
import 'package:scholaris/features/scholarships/screens/discover_screen.dart';
import 'package:scholaris/features/profile/presentation/profile_tab_screen.dart';
import 'widgets/student_action_sheet.dart';
import 'widgets/student_tab_entrance.dart';
import 'widgets/student_glass_refraction.dart';

/// The selected bottom-navigation tab. Exposed so in-page actions (e.g. the
/// Discover "See all" link) can navigate without touching routing architecture.
/// Defaults to the Discover tab.
class HomeTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) {
    if (state != index) {
      HapticFeedback.selectionClick();
      state = index;
    }
  }
}

final homeTabIndexProvider = NotifierProvider<HomeTabIndexNotifier, int>(
  HomeTabIndexNotifier.new,
);

/// Base font size for student navigation tab labels.
const double kStudentNavBaseFontSize = 10.0;
const Color kStudentNavSelectedGreen = Color(0xFF327348);

/// Size of the standalone Quick Action '+' button in accessible layout.
const double kStudentPlusButtonSize = 52.0;

/// Gap between the Quick Action '+' button and the pill dock in accessible layout.
const double kStudentPlusGap = 8.0;

/// Local visual tuning parameters for StudentBottomNav LiquidGlass material
/// Grounded in Apple HIG Materials & Depth & Apple Design Section 12 (WWDC craft standards):
/// - A light neutral veil over pale content, with background color still visible.
/// - A tighter blur avoids a wide gray haze around text beneath the dock.
/// - Directional specular rim highlight (brighter at TOP-LEFT and BOTTOM-RIGHT, softer elsewhere)
/// - Restrained multi-layer ambient & elevation shadows (eliminates cloudy diffuse smudge)
const double kStudentNavGlassTintOpacity = 0.08;
const double kStudentNavGlassBlur = 5.5;
// Preserve finer background detail through the dock; keep '+' material unchanged.
const double kStudentNavDockGlassBlur = 0.5;
const double kStudentNavDockGlassTintOpacity = 0.14;
// A defined silhouette over busy content, without blurring away its detail.
const List<BoxShadow> kStudentNavDockGlassShadow = [
  BoxShadow(color: Color(0x2417251D), blurRadius: 4, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x0C17251D), blurRadius: 12, offset: Offset(0, 4)),
];
const Border kStudentNavDockGlassBorder = Border.fromBorderSide(
  BorderSide(color: Color(0x28747775), width: .75),
);
const double kStudentNavGlassSaturation = 1.3;
const Color kStudentNavGlassLightEdge = Color(0xB3FFFFFF); // 70% white specular top highlight

// Directional specular rim gradient colors from Alignment.topLeft to Alignment.bottomRight
const Color kStudentNavGlassRimTopLeft = Color(0xD9FFFFFF); // 85% white specular key light
const Color kStudentNavGlassRimSoft = Color(0x2EFFFFFF); // 18% white soft ambient edge
const Color kStudentNavGlassRimBottomRight = Color(0x73FFFFFF); // 45% white ground bounce rim

const Border kStudentNavGlassBorder = Border.fromBorderSide(
  BorderSide(color: Color(0x10747775), width: 0.5), // A light seal rather than an outlined toolbar
);

// The dock needs a crisp rim, not an outer glow.
const List<BoxShadow> kStudentNavGlassShadow = [
  BoxShadow(color: Color(0x0A17251D), blurRadius: 3, offset: Offset(0, 1)),
];

/// Directional specular rim painter for LiquidGlass navigation components.
/// Draws a rounded-rectangle stroke with directional illumination:
/// - Top-Left: Bright specular key-light highlight (85% white)
/// - Bottom-Right: Ground bounce rim highlight (45% white)
/// - Top-Right / Bottom-Left: Soft ambient transition (18% white)
/// Grounded in Apple Design Section 12 (Materials & Depth) and liquid-glass.md.
class DirectionalGlassRimPainter extends CustomPainter {
  const DirectionalGlassRimPainter({
    required this.borderRadius,
    this.strokeWidth = 1.0,
    this.useCrispSingleRim = false,
  });

  final double borderRadius;
  final double strokeWidth;
  final bool useCrispSingleRim;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final halfStroke = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      halfStroke,
      halfStroke,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(math.max(0.0, borderRadius - halfStroke)),
    );

    if (useCrispSingleRim) {
      // Tarsi-style single crisp specular rim:
      // Razor-thin (0.75px) perimeter stroke with specular top highlight,
      // subtle sides, and a crisp bottom white line ("the secret sauce")
      // that defines the physical glass boundary sharply without doubling border thickness.
      final rimPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xD9FFFFFF), // 85% white top specular key light
            Color(0x38FFFFFF), // 22% white soft ambient edge on sides
            Color(0x8CFFFFFF), // 55% white crisp bottom edge
          ],
          stops: [0.0, 0.45, 1.0],
        ).createShader(rect);

      canvas.drawRRect(rrect, rimPaint);
      return;
    }

    // Keep the pale-background silhouette separate from the inset light rim.
    canvas.drawRRect(rrect, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0x14535D57));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          kStudentNavGlassRimTopLeft,
          kStudentNavGlassRimSoft,
          kStudentNavGlassRimSoft,
          kStudentNavGlassRimBottomRight,
        ],
        stops: [0.0, 0.35, 0.65, 1.0],
      ).createShader(rect);

    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(.8),
      Radius.circular(math.max(0, borderRadius - halfStroke - .8))), paint);
  }

  @override
  bool shouldRepaint(covariant DirectionalGlassRimPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || oldDelegate.strokeWidth != strokeWidth;
}

class _StudentNavTabItemData {
  const _StudentNavTabItemData({
    required this.keyName,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String keyName;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const List<_StudentNavTabItemData> _kStudentNavTabs = [
  _StudentNavTabItemData(
    keyName: 'student-nav-home',
    icon: CupertinoIcons.house_alt,
    selectedIcon: CupertinoIcons.house_alt,
    label: 'Home',
  ),
  _StudentNavTabItemData(
    keyName: 'student-nav-discover',
    icon: CupertinoIcons.compass,
    selectedIcon: CupertinoIcons.compass,
    label: 'Discover',
  ),
  _StudentNavTabItemData(
    keyName: 'student-nav-tracker',
    icon: CupertinoIcons.doc_text,
    selectedIcon: CupertinoIcons.doc_text,
    label: 'Tracker',
  ),
  _StudentNavTabItemData(
    keyName: 'student-nav-profile',
    icon: CupertinoIcons.person,
    selectedIcon: CupertinoIcons.person,
    label: 'Profile',
  ),
];

/// Determines whether the navigation dock should adopt an adaptive accessible
/// arrangement (e.g. 2-row reflowed layout) to comfortably accommodate scaled text.
/// Respects nonlinear TextScaler by scaling kStudentNavBaseFontSize directly.
bool isStudentNavAccessible(TextScaler textScaler, {double screenWidth = 440.0}) {
  final scaled = textScaler.scale(kStudentNavBaseFontSize);
  return scaled > 13.5 || (screenWidth < 360.0 && scaled > 11.5);
}

/// Computes the adaptive dock height based on text scaling and screen width.
/// Respects nonlinear TextScaler using scale(kStudentNavBaseFontSize), not scale(1.0).
/// Standard 1-row dock: 58.0.
/// Accessible mode: total component height including the standalone '+' button (52.0),
/// vertical gap (8.0), and full-width 2x2 pill dock height.
double computeStudentDockHeight(dynamic scalerOrScale, {double screenWidth = 440.0}) {
  final TextScaler textScaler;
  if (scalerOrScale is TextScaler) {
    textScaler = scalerOrScale;
  } else if (scalerOrScale is num) {
    textScaler = TextScaler.linear(scalerOrScale.toDouble());
  } else {
    textScaler = TextScaler.noScaling;
  }

  if (!isStudentNavAccessible(textScaler, screenWidth: screenWidth)) {
    return 58.0;
  }

  final scaledFontSize = textScaler.scale(kStudentNavBaseFontSize);
  final singleRowHeight = (20.0 + (scaledFontSize * 1.15) + 12.0).clamp(44.0, 76.0);
  final pillHeight = (singleRowHeight * 2 + 16.0).clamp(104.0, 168.0);
  return kStudentPlusButtonSize + kStudentPlusGap + pillHeight;
}

/// Computes the required bottom scroll clearance for child screens so their
/// bottommost content is never occluded by the floating dock:
/// safe bottom + floating margin + actual adaptive dock height + clearance margin.
/// Respects nonlinear TextScaler using scale(baseFont), not scale(1.0).
double computeStudentContentClearance(BuildContext context) {
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  final bottomPad = safeBottom > 0 ? safeBottom + 4.0 : 16.0;
  final textScaler = MediaQuery.textScalerOf(context);
  final screenWidth = MediaQuery.sizeOf(context).width;
  final dockHeight = computeStudentDockHeight(textScaler, screenWidth: screenWidth);
  return bottomPad + dockHeight + 16.0;
}

/// Narrowly scoped controller managing scroll-collapsible dock state,
/// directional scroll hysteresis, user drag intent lifecycle, and keyboard focus lock.
/// Shared between production [HomeScreen] and standalone dev preview fixtures.
class StudentScrollDockController extends ChangeNotifier {
  StudentScrollDockController({
    this.collapseThreshold = kCollapseThreshold,
    this.expandThreshold = kExpandThreshold,
    this.topThreshold = kTopThreshold,
  });

  static const double kCollapseThreshold = 24.0;
  static const double kExpandThreshold = 16.0;
  static const double kTopThreshold = 12.0;

  final double collapseThreshold;
  final double expandThreshold;
  final double topThreshold;

  bool _isCollapsed = false;
  bool _isUserScrolling = false;
  bool _hasUserIntent = false;
  double _pendingDelta = 0.0;
  bool _isNavFocused = false;
  bool _isSheetOpen = false;
  double _cumulativeScrollDelta = 0.0;

  bool get isCollapsed => _isCollapsed;
  bool get isUserScrolling => _isUserScrolling;
  bool get hasUserIntent => _hasUserIntent;
  double get pendingDelta => _pendingDelta;
  bool get isNavFocused => _isNavFocused;
  bool get isSheetOpen => _isSheetOpen;
  bool get isLockedExpanded => _isNavFocused || _isSheetOpen;
  bool get effectiveCollapsed => _isCollapsed && !isLockedExpanded;
  double get cumulativeScrollDelta => _cumulativeScrollDelta;

  void expand() {
    if (_isCollapsed || _cumulativeScrollDelta != 0.0 || _pendingDelta != 0.0) {
      _isCollapsed = false;
      _cumulativeScrollDelta = 0.0;
      _pendingDelta = 0.0;
      notifyListeners();
    }
  }

  void collapse() {
    if (isLockedExpanded) return;
    if (!_isCollapsed || _cumulativeScrollDelta != 0.0 || _pendingDelta != 0.0) {
      _isCollapsed = true;
      _cumulativeScrollDelta = 0.0;
      _pendingDelta = 0.0;
      notifyListeners();
    }
  }

  void setCollapsedManually(bool collapsed) {
    if (collapsed) {
      collapse();
    } else {
      expand();
    }
  }

  void onTabChanged() {
    _isCollapsed = false;
    _cumulativeScrollDelta = 0.0;
    _pendingDelta = 0.0;
    _isUserScrolling = false;
    _hasUserIntent = false;
    notifyListeners();
  }

  void setNavFocused(bool focused) {
    if (_isNavFocused != focused) {
      _isNavFocused = focused;
      if (_isNavFocused && _isCollapsed) {
        _isCollapsed = false;
        _cumulativeScrollDelta = 0.0;
        _pendingDelta = 0.0;
      }
      notifyListeners();
    }
  }

  void setSheetOpen(bool open) {
    if (_isSheetOpen != open) {
      _isSheetOpen = open;
      if (_isSheetOpen && _isCollapsed) {
        _isCollapsed = false;
        _cumulativeScrollDelta = 0.0;
        _pendingDelta = 0.0;
      }
      notifyListeners();
    }
  }

  void _applyDelta(double delta, {double? currentPixels}) {
    if (delta == 0.0) return;

    // When user scrolls DOWN (delta > 0):
    if (delta > 0) {
      if (_cumulativeScrollDelta < 0) {
        _cumulativeScrollDelta = 0.0;
      }
      _cumulativeScrollDelta += delta;
      if (_cumulativeScrollDelta >= collapseThreshold) {
        if (currentPixels == null || currentPixels > topThreshold) {
          collapse();
        }
      }
    }
    // When user scrolls UP (delta < 0): Signed negative accumulator
    else if (delta < 0) {
      if (_cumulativeScrollDelta > 0) {
        _cumulativeScrollDelta = 0.0;
      }
      _cumulativeScrollDelta += delta; // Accumulate negative delta
      if (_cumulativeScrollDelta <= -expandThreshold) {
        expand();
      }
    }
  }

  bool handleScrollNotification(ScrollNotification notification) {
    // Only primary vertical scrolling on active tab influences dock
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.depth != 0) return false;

    final currentPixels = notification.metrics.pixels;

    // 1. User-scroll intent lifecycle & out-of-order delta rescue:
    // ScrollStartNotification:
    // - If dragDetails != null, set _isUserScrolling = true; _hasUserIntent = true;
    // - If dragDetails == null, reset _hasUserIntent = false; _pendingDelta = 0.0;
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        _isUserScrolling = true;
        _hasUserIntent = true;
      } else if (!_hasUserIntent) {
        _isUserScrolling = false;
        _pendingDelta = 0.0;
      }
    }
    // UserScrollNotification:
    // - If direction != ScrollDirection.idle:
    //   - Set _isUserScrolling = true; _hasUserIntent = true;
    //   - Direction alone does not expand: deltas must cross the threshold.
    //   - If _pendingDelta != 0.0: apply _pendingDelta and reset _pendingDelta = 0.0.
    // - If direction == ScrollDirection.idle:
    //   - Set _isUserScrolling = false; _hasUserIntent = false; _pendingDelta = 0.0;
    else if (notification is UserScrollNotification) {
      if (notification.direction != ScrollDirection.idle) {
        _isUserScrolling = true;
        _hasUserIntent = true;
        if (_pendingDelta != 0.0) {
          _applyDelta(_pendingDelta, currentPixels: currentPixels);
          _pendingDelta = 0.0;
        }
      } else {
        _isUserScrolling = false;
        _hasUserIntent = false;
        _pendingDelta = 0.0;
      }
    }
    // ScrollEndNotification:
    // - Set _isUserScrolling = false; _hasUserIntent = false; _pendingDelta = 0.0;
    // - Do NOT wipe _cumulativeScrollDelta so multiple small wheel notches (e.g. 3x 10px) accumulate across pulses.
    else if (notification is ScrollEndNotification) {
      _isUserScrolling = false;
      _hasUserIntent = false;
      _pendingDelta = 0.0;
    }

    // Return to top immediately restores full dock if collapsed
    if (_isCollapsed && currentPixels <= topThreshold) {
      expand();
      return false;
    }

    // ScrollUpdateNotification:
    // - If _isUserScrolling || _hasUserIntent || notification.dragDetails != null:
    //   - Apply delta directly (_applyDelta(delta)).
    // - Else:
    //   - Buffer _pendingDelta += delta;. If UserScrollNotification follows, it is rescued;
    //     if ScrollEndNotification follows with no user intent (programmatic jumpTo/animateTo), _pendingDelta is dropped.
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      if (delta != null && delta != 0.0) {
        final hasIntent = _isUserScrolling || _hasUserIntent || notification.dragDetails != null;
        if (hasIntent) {
          _applyDelta(delta, currentPixels: currentPixels);
        } else {
          _pendingDelta += delta;
        }
      }
    }

    return false;
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _tabs = <Widget>[
    StudentDashboardScreen(),
    DiscoverScreen(),
    ApplicationsScreen(embedded: true),
    ProfileTabScreen(),
  ];

  late final StudentScrollDockController _controller;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = StudentScrollDockController();
    _controller.addListener(_onDockStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onDockStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onDockStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(homeTabIndexProvider);
    if (tabIndex != _lastTabIndex) {
      _lastTabIndex = tabIndex;
      _controller.onTabChanged();
    }

    // Hide navigation dock when software keyboard appears to avoid occluding input
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (isKeyboardOpen && _controller.isCollapsed) {
      _controller.expand();
    }
    final contentClearance = computeStudentContentClearance(context);

    return Scaffold(
      backgroundColor: kBackground,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: MediaQuery.of(context).padding.copyWith(
                  bottom: contentClearance,
                ),
              ),
              child: IndexedStack(
                index: tabIndex,
                children: [
                  for (int i = 0; i < _tabs.length; i++)
                    NotificationListener<ScrollNotification>(
                      onNotification: (n) => tabIndex == i
                          ? _controller.handleScrollNotification(n)
                          : false,
                      child: StudentTabEntrance(active: tabIndex == i, child: _tabs[i]),
                    ),
                ],
              ),
            ),
          ),
          if (!isKeyboardOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: StudentBottomNav(
                tabIndex: tabIndex,
                onSelectTab: (index) {
                  ref.read(homeTabIndexProvider.notifier).selectTab(index);
                  _controller.expand();
                },
                onQuickAction: () async {
                  _controller.expand();
                  _controller.setSheetOpen(true);
                  try {
                    await showStudentActionSheet(context);
                  } finally {
                    if (mounted) {
                      _controller.setSheetOpen(false);
                    }
                  }
                },
                isCollapsed: _controller.effectiveCollapsed,
                onExpand: _controller.expand,
                onNavFocusChange: _controller.setNavFocused,
              ),
            ),
        ],
      ),
    );
  }
}

/// Floating student bottom navigation dock.
/// Encapsulates the 4-tab pill dock and separate '+' quick action button.
class StudentBottomNav extends StatelessWidget {
  const StudentBottomNav({
    super.key,
    required this.tabIndex,
    required this.onSelectTab,
    required this.onQuickAction,
    this.isCollapsed = false,
    this.onExpand,
    this.onNavFocusChange,
    this.enableRefraction = false,
    this.dockBlur,
    this.dockTintOpacity,
    this.useCrispSingleRim = false,
  });

  final bool enableRefraction;
  final int tabIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onQuickAction;
  final bool isCollapsed;
  final VoidCallback? onExpand;
  final ValueChanged<bool>? onNavFocusChange;
  final double? dockBlur;
  final double? dockTintOpacity;
  final bool useCrispSingleRim;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _buildDock(context,
      math.min(MediaQuery.sizeOf(context).width, constraints.maxWidth)),
  );

  Widget _buildDock(BuildContext context, double screenWidth) {
    final horizontalPad = screenWidth < 360 ? 8.0 : 16.0;
    // Elegant floating island elevation above the safe area / home indicator
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomPad = safeBottom > 0 ? safeBottom + 4.0 : 16.0;

    final textScaler = MediaQuery.textScalerOf(context);
    final isAccessible = isStudentNavAccessible(textScaler, screenWidth: screenWidth);
    final dockHeight = computeStudentDockHeight(textScaler, screenWidth: screenWidth);

    // Transparency is treated separately from reduced motion:
    // Solid opaque fallback is strictly used when high contrast is active.
    // Under reduced motion, glass is preserved with animations disabled.
    final isHighContrast = MediaQuery.highContrastOf(context);

    // Disable collapse if accessible large text layout is active or
    // if screen-reader accessible navigation is requested.
    final isAccessibilityActive = isAccessible || MediaQuery.accessibleNavigationOf(context);
    final effectiveCollapsed = isCollapsed && !isAccessibilityActive;

    final availableRowWidth = math.min(screenWidth - (horizontalPad * 2), 440.0 - (horizontalPad * 2));
    final expandedPillWidth = math.max(0.0, availableRowWidth - dockHeight - 8.0);
    final Duration animDuration = isReducedMotion(context) ? Duration.zero : kDurationSlow;

    final Widget navDockContent;
    if (!isAccessible) {
      final activeTab = _kStudentNavTabs[tabIndex.clamp(0, _kStudentNavTabs.length - 1)];

      navDockContent = LayoutBuilder(builder: (context, constraints) {
        // Derive every position from the material's presented width. Reversing
        // the outer animation therefore reverses the icon without a crossfade.
        final progress = expandedPillWidth <= 52 ? 0.0 :
            ((expandedPillWidth - constraints.maxWidth) / (expandedPillWidth - 52)).clamp(0.0, 1.0);
        if (progress >= .9999) {
          return _StudentNavCompactControl(
            key: const ValueKey('student-nav-compact-control'),
            tabIndex: tabIndex, label: activeTab.label, icon: activeTab.icon,
            selectedIcon: activeTab.selectedIcon, onExpand: onExpand ?? () {},
            itemHeight: 52, onFocusChange: onNavFocusChange,
          );
        }
        final cellWidth = expandedPillWidth / 4;
        final labels = ['Home', 'Discover', 'Tracker', 'Profile'];
        final keys = ['home', 'discover', 'tracker', 'profile'];
        final icons = [CupertinoIcons.house_alt, CupertinoIcons.compass,
          CupertinoIcons.doc_text, CupertinoIcons.person];
        final fading = (1 - progress * 2).clamp(0.0, 1.0);
        return Stack(
          key: const ValueKey('student-nav-expanded-row'),
          clipBehavior: Clip.none,
          children: [
            Positioned(left: 0, top: 0, width: expandedPillWidth, height: constraints.maxHeight,
              child: Opacity(opacity: fading, child: StudentSelectionIndicator(
                index: tabIndex, duration: animDuration,
              )),
            ),
            for (var i = 0; i < 4; i++)
              Positioned(
                left: i == tabIndex
                    ? i * cellWidth * (1 - progress) + (26 - cellWidth / 2) * progress
                    : i * cellWidth,
                top: 0, width: cellWidth, height: constraints.maxHeight,
                child: IgnorePointer(ignoring: effectiveCollapsed,
                  child: ExcludeSemantics(excluding: effectiveCollapsed,
                    child: Opacity(opacity: i == tabIndex ? 1 : fading,
                      child: KeyedSubtree(
                        key: i == 0 ? const ValueKey('student-nav-dashboard') : null,
                        child: _StudentNavItem(
                          key: ValueKey('student-nav-${keys[i]}'),
                          icon: icons[i], selectedIcon: icons[i], label: labels[i],
                          selected: tabIndex == i, onTap: () => onSelectTab(i),
                          itemHeight: constraints.maxHeight,
                          collapseProgress: i == tabIndex ? progress : 0,
                          onFocusChange: onNavFocusChange,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (effectiveCollapsed && progress > 0)
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: '${activeTab.label} Tab. Tap to expand navigation',
                  onTap: onExpand,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onExpand,
                  ),
                ),
              ),
          ],
        );
      });
    } else {
      // Adaptive 2-row accessible layout for large text / narrow widths
      final pillHeight = dockHeight - kStudentPlusButtonSize - kStudentPlusGap;
      final cellHeight = (pillHeight - 16.0) / 2;
      navDockContent = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: KeyedSubtree(
                      key: const ValueKey('student-nav-dashboard'),
                      child: _StudentNavItem(
                        key: const ValueKey('student-nav-home'),
                        icon: CupertinoIcons.house_alt,
                        selectedIcon: CupertinoIcons.house_alt,
                        label: 'Home',
                        selected: tabIndex == 0,
                        onTap: () => onSelectTab(0),
                        itemHeight: cellHeight,
                        isAccessible: true,
                        onFocusChange: onNavFocusChange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _StudentNavItem(
                      key: const ValueKey('student-nav-discover'),
                      icon: CupertinoIcons.compass,
                      selectedIcon: CupertinoIcons.compass,
                      label: 'Discover',
                      selected: tabIndex == 1,
                      onTap: () => onSelectTab(1),
                      itemHeight: cellHeight,
                      isAccessible: true,
                      onFocusChange: onNavFocusChange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _StudentNavItem(
                      key: const ValueKey('student-nav-tracker'),
                      icon: CupertinoIcons.doc_text,
                      selectedIcon: CupertinoIcons.doc_text,
                      label: 'Tracker',
                      selected: tabIndex == 2,
                      onTap: () => onSelectTab(2),
                      itemHeight: cellHeight,
                      isAccessible: true,
                      onFocusChange: onNavFocusChange,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StudentNavItem(
                      key: const ValueKey('student-nav-profile'),
                      icon: CupertinoIcons.person,
                      selectedIcon: CupertinoIcons.person,
                      label: 'Profile',
                      selected: tabIndex == 3,
                      onTap: () => onSelectTab(3),
                      itemHeight: cellHeight,
                      isAccessible: true,
                      onFocusChange: onNavFocusChange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final double pillBorderRadius = isAccessible ? 28.0 : dockHeight / 2;

    Widget navDock = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: isHighContrast || isAccessible
              ? DecoratedBox(decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(pillBorderRadius),
                  border: Border.all(
                    color: isHighContrast ? const Color(0xFF1C1C1E) : const Color(0x30747775),
                    width: isHighContrast ? 1.5 : .7),
                ))
              : CustomPaint(
                  foregroundPainter: DirectionalGlassRimPainter(
                    borderRadius: pillBorderRadius,
                    strokeWidth: 1,
                    useCrispSingleRim: useCrispSingleRim,
                  ),
                  child: LiquidGlass(
                    borderRadius: pillBorderRadius,
                    blur: dockBlur ?? kStudentNavDockGlassBlur,
                    saturation: kStudentNavGlassSaturation,
                    tintOpacity: dockTintOpacity ?? kStudentNavDockGlassTintOpacity,
                    border: kStudentNavDockGlassBorder,
                    showLightEdge: false,
                    preserveBlurWithReducedMotion: true,
                    boxShadow: kStudentNavDockGlassShadow,
                    child: const SizedBox.expand(),
                  ),
                ),
        ),
        navDockContent,
      ],
    );

    if (enableRefraction) {
      navDock = StudentGlassRefraction(enabled: true, radius: pillBorderRadius, child: navDock);
    }
    final Widget dockBody;
    if (!isAccessible) {
      // Standard 1-row layout (pill dock + separate '+' button beside it)
      // When scrolling down, the 4-tab pill dock collapses into the active tab's compact pill
      // anchored at the left, while the '+' button remains separate at the right.
      dockBody = LayoutBuilder(
        builder: (context, constraints) {
          final maxPillWidth = math.max(0.0, constraints.maxWidth - dockHeight - 8.0);
          final pillWidth = effectiveCollapsed ? 52.0 : maxPillWidth;
          return SizedBox(
            height: dockHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: animDuration,
                      curve: Curves.easeInOutCubic,
                      width: pillWidth,
                      height: effectiveCollapsed ? 52 : dockHeight,
                      child: navDock,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StudentQuickActionButton(
                  onTap: onQuickAction,
                  size: dockHeight,
                  isCollapsed: effectiveCollapsed,
                  isHighContrast: isHighContrast,
                  onFocusChange: onNavFocusChange,
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Accessible 2x2 layout: '+' button above, aligned right; full-width pill dock below
      dockBody = SizedBox(
        height: dockHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _StudentQuickActionButton(
                onTap: onQuickAction,
                size: kStudentPlusButtonSize,
                isHighContrast: true,
                onFocusChange: onNavFocusChange,
              ),
            ),
            const SizedBox(height: kStudentPlusGap),
            Expanded(child: navDock),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPad, 0, horizontalPad, bottomPad),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: availableRowWidth),
          child: dockBody,
        ),
      ),
    );
  }
}

/// Compact floating control for the active tab when the dock collapses on scroll-down.
/// Anchored at the left, displaying active icon only in Scholaris green on mint circle capsule.
/// Retains full Semantics accessibility announcement and >=44pt touch target.
/// Tapping restores the full 4-tab dock.
class _StudentNavCompactControl extends StatefulWidget {
  const _StudentNavCompactControl({
    super.key,
    required this.tabIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onExpand,
    required this.itemHeight,
    this.onFocusChange,
  });

  final int tabIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onExpand;
  final double itemHeight;
  final ValueChanged<bool>? onFocusChange;

  @override
  State<_StudentNavCompactControl> createState() => _StudentNavCompactControlState();
}

class _StudentNavCompactControlState extends State<_StudentNavCompactControl> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        widget.onFocusChange?.call(focused);
        if (focused) {
          widget.onExpand();
        }
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ButtonActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onExpand()),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => widget.onExpand()),
      },
      mouseCursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: '${widget.label} Tab. Navigation collapsed, tap to expand navigation',
        hint: 'Restores all navigation tabs',
        onTap: widget.onExpand,
        child: SizedBox(
          width: 52.0,
          height: widget.itemHeight,
          child: DecoratedBox(
            decoration: _isFocused
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0F4D2E),
                      width: 2.0,
                    ),
                  )
                : const BoxDecoration(),
            child: ExcludeSemantics(
              child: PressableScale(
                scale: isReducedMotion(context) ? 1.0 : 0.94,
                onTap: widget.onExpand,
                child: Center(
                  child: Icon(
                    widget.selectedIcon,
                    size: 24,
                    color: kStudentNavSelectedGreen,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentNavItem extends StatefulWidget {
  const _StudentNavItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.itemHeight,
    this.isAccessible = false,
    this.collapseProgress = 0,
    this.onFocusChange,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double itemHeight;
  final bool isAccessible;
  final double collapseProgress;
  final ValueChanged<bool>? onFocusChange;

  @override
  State<_StudentNavItem> createState() => _StudentNavItemState();
}

class _StudentNavItemState extends State<_StudentNavItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
    tween: ColorTween(end: widget.selected ? kStudentNavSelectedGreen : const Color(0xFF1C1C1E)),
    duration: isReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
    builder: (context, ink, _) => _buildItem(context, ink!),
  );

  Widget _buildItem(BuildContext context, Color ink) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 360;
    final isVeryNarrow = screenWidth < 340;

    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        widget.onFocusChange?.call(focused);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ButtonActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap()),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => widget.onTap()),
      },
      mouseCursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: '${widget.label} Tab',
        hint: 'Switches to ${widget.label}',
        onTap: widget.onTap,
        child: SizedBox(
          height: widget.itemHeight,
          child: DecoratedBox(
            decoration: _isFocused
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0F4D2E),
                      width: 2.0,
                    ),
                  )
                : const BoxDecoration(),
            child: ExcludeSemantics(
              child: PressableScale(
                scale: isReducedMotion(context) ? 1.0 : 0.94,
                onTap: widget.onTap,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVeryNarrow ? 4.0 : (isNarrow ? 6.0 : 8.0),
                      vertical: widget.isAccessible ? 1.0 : 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: widget.selected && widget.isAccessible ? const Color(0xFFE7ECE8) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: Offset(0, widget.collapseProgress * 7.3),
                          child: AnimatedScale(
                            duration: isReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            scale: isReducedMotion(context) || !widget.selected ? 1 : 1.04,
                            child: Icon(
                          widget.selected ? widget.selectedIcon : widget.icon,
                          size: widget.isAccessible ? 18.0 : 21.0 + 3 * widget.collapseProgress,
                          color: ink,
                        ),
                        ),
                        ),
                        SizedBox(height: widget.isAccessible ? 1.0 : 2.0),
                        Opacity(
                          opacity: (1 - widget.collapseProgress * 2).clamp(0.0, 1.0),
                          child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            softWrap: false,
                            style: outfit(
                              fontSize: kStudentNavBaseFontSize,
                              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                              color: ink,
                            ),
                          ),
                        ),
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
    );
  }
}

class _StudentQuickActionButton extends StatefulWidget {
  const _StudentQuickActionButton({
    required this.onTap,
    required this.size,
    required this.isHighContrast,
    this.onFocusChange,
    this.isCollapsed = false,
  });

  final VoidCallback onTap;
  final double size;
  final bool isCollapsed;
  final bool isHighContrast;
  final ValueChanged<bool>? onFocusChange;

  @override
  State<_StudentQuickActionButton> createState() => _StudentQuickActionButtonState();
}

class _StudentQuickActionButtonState extends State<_StudentQuickActionButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Icon(
        Icons.add_rounded,
        color: Color(0xFF161C27),
        size: 23,
      ),
    );

    Widget buttonSurface = widget.isHighContrast
        ? Container(
            key: const ValueKey('student-nav-quick-action'),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF1C1C1E),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: content,
          )
        : CustomPaint(
            foregroundPainter: DirectionalGlassRimPainter(
              borderRadius: widget.size / 2,
              strokeWidth: 1.0,
            ),
            child: LiquidGlass(
              key: const ValueKey('student-nav-quick-action'),
              borderRadius: widget.size / 2,
              blur: kStudentNavGlassBlur,
              saturation: kStudentNavGlassSaturation,
              tintOpacity: kStudentNavGlassTintOpacity,
              border: kStudentNavGlassBorder,
              showLightEdge: false,
                    preserveBlurWithReducedMotion: true,
              boxShadow: kStudentNavGlassShadow,
              child: content,
            ),
          );

    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        widget.onFocusChange?.call(focused);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ButtonActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap()),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => widget.onTap()),
      },
      mouseCursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: 'Quick actions',
        hint: 'Opens QR scan and document upload',
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: DecoratedBox(
            decoration: _isFocused
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0F4D2E),
                      width: 2.5,
                    ),
                  )
                : const BoxDecoration(),
            child: ExcludeSemantics(
              child: PressableScale(
                scale: isReducedMotion(context) ? 1.0 : 0.92,
                onTap: widget.onTap,
                child: Center(
                  child: AnimatedContainer(
                    duration: isReducedMotion(context) ? Duration.zero : kDurationSlow,
                    curve: Curves.easeInOutCubic,
                    width: widget.isCollapsed ? 48 : widget.size,
                    height: widget.isCollapsed ? 48 : widget.size,
                    child: buttonSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
