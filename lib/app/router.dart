// lib/app/router.dart
//
// Central GoRouter setup for Scholaris, including auth-aware redirects.
//
// Supabase is initialized once in lib/app/supabase_config.dart (the URL and
// anon key live there and are never hardcoded here). This file only reads the
// shared client through Supabase.instance.client.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens referenced by the routes below. Implement them in their feature
// folders; the router only wires them together. Expected contracts:
//   login_screen.dart        → LoginScreen()
//   signup_screen.dart       → SignupScreen()
//   home_screen.dart         → HomeScreen()
//   profile_setup_screen.dart → ProfileSetupScreen({required String step})
import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/auth/presentation/signup_screen.dart';
import 'package:scholaris/features/auth/presentation/splash_screen.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/presentation/profile_setup_screen.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';

// -----------------------------------------------------------------------------
// profileCompleteProvider
// -----------------------------------------------------------------------------
// AsyncNotifier that reports whether the signed-in user has finished the
// multi-step profile setup. It reads the user's own `profiles` row (via the
// profile repository, which is always scoped to the authenticated user) and
// returns the `setup_complete` flag.

final profileCompleteProvider =
    AsyncNotifierProvider<ProfileCompleteNotifier, bool>(
  ProfileCompleteNotifier.new,
);

class ProfileCompleteNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final profile =
        await ref.watch(profileRepositoryProvider).fetchCurrent();
    return profile?.setupComplete ?? false;
  }

  /// Re-check the `profiles` table. Call this after the user completes the
  /// setup flow so the router re-evaluates the redirect to /home.
  Future<void> refresh() async => ref.invalidateSelf();
}

// -----------------------------------------------------------------------------
// Router
// -----------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) => _redirect(ref, state),
    routes: <RouteBase>[
      // --- Root / splash -----------------------------------------------------
      // Shown while the redirect logic decides where to send the user.
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // --- Auth group --------------------------------------------------------
      // Unauthenticated entry points. Access is guarded in _redirect.
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // --- Main app ----------------------------------------------------------
      // Requires a signed-in user with a completed profile.
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // --- Scholarship detail ------------------------------------------------
      GoRoute(
        path: '/scholarship/:id',
        name: 'scholarship-detail',
        builder: (context, state) {
          final scholarship = state.extra as Scholarship?;
          return ScholarshipDetailScreen(
            scholarshipId: state.pathParameters['id']!,
            initial: scholarship,
          );
        },
      ),

      // --- Profile setup (multi-step) ----------------------------------------
      // 3-step wizard. The parent route simply forwards to the first step.
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        redirect: (context, state) => ProfileSetupRoute.personal,
        routes: <RouteBase>[
          GoRoute(
            path: 'personal',
            name: 'profile-setup-personal',
            builder: (context, state) =>
                const ProfileSetupScreen(step: 'personal'),
          ),
          GoRoute(
            path: 'academic',
            name: 'profile-setup-academic',
            builder: (context, state) =>
                const ProfileSetupScreen(step: 'academic'),
          ),
          GoRoute(
            path: 'financial',
            name: 'profile-setup-financial',
            builder: (context, state) =>
                const ProfileSetupScreen(step: 'financial'),
          ),
        ],
      ),
    ],
  );

  // Re-evaluate redirects whenever auth changes (login/logout) and whenever
  // the profile-completion check settles.
  //
  // A token refresh does not change the signed-in user or their profile, so it
  // must not re-run the profile check here: that check issues a DB request,
  // which goes through `auth.getSession()` and can itself trigger another
  // refresh, turning a single token renewal into an unbounded refresh loop
  // (burning refresh tokens until Supabase rate-limits with a 429 and signs
  // the user out). React only to real session changes.
  final authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    debugPrint(
      '[AUTH EVENT] event=${event.event.name} session=${event.session != null} user=${event.session?.user.id}',
    );
    if (event.event == AuthChangeEvent.tokenRefreshed) {
      return;
    }
    ref.invalidate(profileCompleteProvider);
    router.refresh();
  });
  ref.onDispose(() => authSub.cancel());

  ref.listen(profileCompleteProvider, (_, _) => router.refresh());

  return router;
});

/// Route path constants for the profile-setup wizard, so the screen can
/// advance steps with `context.go(ProfileSetupRoute.academic)`.
abstract final class ProfileSetupRoute {
  static const personal = '/profile-setup/personal';
  static const academic = '/profile-setup/academic';
  static const financial = '/profile-setup/financial';
}

/// Auth-aware redirect:
///  - signed out              → /login (except /signup)
///  - signed in, profile busy → /splash while loading
///  - signed in, complete     → /home
///  - signed in, incomplete   → /profile-setup/personal
String? _redirect(Ref ref, GoRouterState state) {
  final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
  final location = state.matchedLocation;
  final onAuthRoute = location == '/login' || location == '/signup';
  final onSetupRoute = location.startsWith('/profile-setup');

  if (!isLoggedIn) {
    return onAuthRoute ? null : '/login';
  }

  final profile = ref.read(profileCompleteProvider);
  if (profile.isLoading) {
    return location == '/splash' ? null : '/splash';
  }

  final isComplete = profile.valueOrNull ?? false;
  if (isComplete) {
    return location == '/home' ? null : '/home';
  }

  return onSetupRoute ? null : ProfileSetupRoute.personal;
}
