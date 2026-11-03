import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scholaris/features/intro/presentation/intro_screen.dart';
import 'package:scholaris/features/onboarding/controllers/onboarding_controller.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';

/// Welcome plus four skippable feature introductions. No account data is collected.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.initialPage = 0});
  final int initialPage;
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _controller;
  late int _page;
  static const _features = [
    (
      title: 'Find your scholarship',
      body: 'Explore scholarships, compare their benefits, and see what you need before applying.',
      pose: 'discover',
    ),
    (
      title: 'See what fits your profile',
      body: 'Add your academic and personal details to discover scholarships that match the listed requirements.',
      pose: 'match',
    ),
    (
      title: 'Know your next step',
      body: 'Keep your applications, documents, and status updates together. Pick up where you left off.',
      pose: 'track',
    ),
    (
      title: 'Meet your scholarship companion',
      body: 'Ari and Ariel are here to make the journey feel a little less overwhelming. Open Chat from the + button.',
      pose: 'companion',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(0, _features.length);
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(introSeenProvider.notifier).markSeen();
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (mounted) context.go('/login');
  }

  Future<void> _next() async {
    if (_page == _features.length) {
      await _finish();
      return;
    }
    if (!mounted) return;
    await _moveTo(_page + 1);
  }

  Future<void> _moveTo(int page) async {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
    } else {
      await _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: ResponsiveContainer(
        maxWidth: 460,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 14, 0),
              child: Row(
                children: [
                  const Expanded(child: ScholarisLogo(compact: true)),
                  if (_page > 0)
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        foregroundColor: kTextSupporting,
                      ),
                      child: Text(
                        'Skip',
                        style: geist(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
            if (_page > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    Semantics(
                      label: 'Introduction, step $_page of ${_features.length}',
                      child: ExcludeSemantics(
                        child: Row(
                          children: [
                            for (var i = 0; i < _features.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: i < _features.length - 1 ? 6 : 0,
                                  ),
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: i < _page
                                          ? kPrimary
                                          : kSurfaceContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$_page of ${_features.length}',
                        style: geist(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: kTextSupporting,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              key: const ValueKey('onboarding-pages'),
              child: PageView(
                controller: _controller,
                physics: const AppleBouncingScrollPhysics(),
                onPageChanged: (page) {
                  HapticFeedback.selectionClick();
                  setState(() => _page = page);
                },
                children: [
                  StudentWelcomeContent(onGetStarted: _next, onLogin: _finish),
                  for (final feature in _features)
                    _FeaturePage(
                      title: feature.title,
                      body: feature.body,
                      pose: feature.pose,
                    ),
                ],
              ),
            ),
            if (_page > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 24, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _moveTo(_page - 1),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(64, 48),
                        foregroundColor: kTextPrimary,
                      ),
                      child: Text(
                        'Back',
                        style: geist(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('onboarding-next'),
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _page == _features.length ? 'Get Started' : 'Next',
                          textAlign: TextAlign.center,
                          style: geist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({
    required this.title,
    required this.body,
    required this.pose,
  });
  final String title;
  final String body;
  final String pose;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      key: ValueKey('onboarding-content-$pose'),
      physics: const AppleBouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/mascots/onboarding/$pose.png',
                height: constraints.maxHeight < 520 ? 180 : 230,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                cacheWidth: 1200,
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: appHeading(fontSize: 24),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: geist(fontSize: 14, color: kTextSecondary, height: 1.5),
              ),
              if (pose == 'companion') ...[
                const SizedBox(height: 20),
                Text(
                  'Coming soon',
                  style: geist(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find scholarships, summarize requirements, and prepare drafts with AI. QR and document tools will join the conversation.',
                  textAlign: TextAlign.center,
                  style: geist(
                    fontSize: 13,
                    color: kTextSupporting,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
