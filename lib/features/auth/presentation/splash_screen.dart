// lib/features/auth/presentation/splash_screen.dart
//
// Branded splash: a short, minimal first impression. Shows the Scholaris
// wordmark and tagline with a gentle fade, then the router's redirect logic
// (watching profileCompleteProvider) sends the user on to login / setup / home.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/app/router.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/scholaris_logo_badge.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<double>(
      begin: 8,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watching this provider runs the profile check; when it settles, the
    // router listener calls router.refresh() and redirects away from /splash.
    ref.watch(profileCompleteProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(_offset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shared brand mark (no Hero tag here: splash is a transient
                // holding screen, only intro/login participate in the flight).
                const ScholarisLogoBadge(size: 84),
                const SizedBox(height: 20),
                Text(
                  'Scholaris',
                  style: poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find scholarships that fit you',
                  style: openSans(fontSize: 15, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
