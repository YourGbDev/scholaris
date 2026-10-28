import 'package:flutter/material.dart';

import '../../../../shared/widgets/workspace_smooth_scroll.dart';

import '../../../../shared/theme/app_motion.dart';

/// Short, interruptible workspace changes. Outgoing views are visual only.
class OrgWorkspaceTransition extends StatelessWidget {
  const OrgWorkspaceTransition({
    super.key,
    required this.activeKey,
    required this.child,
  });
  final ValueKey<Object> activeKey;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final reduced = isReducedMotion(context);
    if (reduced) {
      return KeyedSubtree(
        key: activeKey,
        child: WorkspaceSmoothScroll(child: child),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 120),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (current, outgoing) => Stack(
        fit: StackFit.expand,
        alignment: Alignment.topLeft,
        children: [
          for (final view in outgoing)
            IgnorePointer(
              child: ExcludeFocus(
                excluding: true,
                child: ExcludeSemantics(
                  excluding: true,
                  child: TickerMode(
                    enabled: false,
                    child: view,
                  ),
                ),
              ),
            ),
          ?current,
        ],
      ),
      transitionBuilder: (view, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.006),
            end: Offset.zero,
          ).animate(animation),
          child: view,
        ),
      ),
      child: KeyedSubtree(
        key: activeKey,
        child: WorkspaceSmoothScroll(child: child),
      ),
    );
  }
}
