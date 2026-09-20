import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scholaris/features/onboarding/controllers/onboarding_controller.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';

/// The welcome / intro screen displayed once on first app launch before onboarding.
///
/// Features a top Scholaris brand lockup, a large organic blob illustration
/// depicting a Filipino graduation ceremony, bold mission copy, a primary
/// "Get Started →" CTA advancing to onboarding, and a secondary sign-in link.
class IntroScreen extends ConsumerWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: SafeArea(
        child: ResponsiveContainer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Top Brand Lockup: Small centered logo + "Scholaris" text + gold dot
                          _buildTopBrand(),

                          const SizedBox(height: 12),

                      // 2. Large organic blob illustration (Graduation Ceremony Scene)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 380,
                          maxHeight: constraints.maxHeight < 700 ? 250 : 320,
                        ),
                        child: Image.asset(
                          'assets/images/intro_scene.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(
                              height: 240,
                              child: Center(
                                child: Icon(
                                  Icons.school_rounded,
                                  size: 64,
                                  color: Color(0xFF0F4D2E),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. Headline & Subtext
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Your Dream,\nOur Mission.',
                            textAlign: TextAlign.center,
                            style: outfit(
                              fontSize: constraints.maxHeight < 700 ? 28 : 34,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F4D2E),
                              height: 1.15,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              'Scholaris helps Filipino students find the scholarship they truly deserve.',
                              textAlign: TextAlign.center,
                              style: openSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF717971),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 4. Action CTAs (Get Started button + Already have an account link)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Large dark green full width rounded "Get Started →" button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              key: const ValueKey('intro-get-started-button'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F4D2E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () async {
                                await ref.read(introSeenProvider.notifier).markSeen();
                                if (context.mounted) {
                                  context.go('/onboarding');
                                }
                              },
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Get Started',
                                      style: outfit(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Small dark green underlined "Already have an account? Sign In."
                          GestureDetector(
                            key: const ValueKey('intro-sign-in-button'),
                            onTap: () async {
                              await ref.read(introSeenProvider.notifier).markSeen();
                              await ref.read(onboardingSeenProvider.notifier).markSeen();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Text(
                                'Already have an account? Sign In.',
                                style: openSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F4D2E),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  ),
);
}

  Widget _buildTopBrand() {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0F4D2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Scholaris',
              style: outfit(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F4D2E),
                letterSpacing: -0.3,
              ),
            ),
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(left: 3, top: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFF1B41E),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
