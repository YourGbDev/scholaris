import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scholaris/features/onboarding/controllers/onboarding_controller.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';

/// Standalone welcome route; the first-launch flow reuses its content.
class IntroScreen extends ConsumerWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: ResponsiveContainer(
        maxWidth: 460,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: ScholarisLogo(compact: true),
            ),
            Expanded(
              child: StudentWelcomeContent(
                onGetStarted: () async {
                  await ref.read(introSeenProvider.notifier).markSeen();
                  if (context.mounted) context.go('/onboarding?step=1');
                },
                onLogin: () async {
                  await ref.read(introSeenProvider.notifier).markSeen();
                  await ref.read(onboardingSeenProvider.notifier).markSeen();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class StudentWelcomeContent extends StatelessWidget {
  const StudentWelcomeContent({
    super.key,
    required this.onGetStarted,
    required this.onLogin,
  });
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final artHeight = constraints.maxHeight < 650 ? 210.0 : 260.0;
      return SingleChildScrollView(
        physics: const AppleBouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/mascots/onboarding/welcome.png',
                      height: artHeight,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      cacheWidth: 1000,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Your next chapter starts here.',
                      textAlign: TextAlign.center,
                      style: appHeading(fontSize: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Find scholarships, understand your options, and take your next step with Scholaris.',
                      textAlign: TextAlign.center,
                      style: geist(
                        fontSize: 14,
                        color: kTextSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        key: const ValueKey('intro-get-started-button'),
                        onPressed: onGetStarted,
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
                          'Get Started',
                          style: geist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        key: const ValueKey('intro-sign-in-button'),
                        onPressed: onLogin,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          foregroundColor: kPrimary,
                        ),
                        child: Text(
                          'Log in',
                          style: geist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
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
    },
  );
}
