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
//   forgot_password_screen.dart → ForgotPasswordScreen()
//   reset_password_screen.dart → ResetPasswordScreen()
//   verify_email_screen.dart → VerifyEmailScreen({String? email})
//   home_screen.dart         → HomeScreen()
//   profile_setup_screen.dart → ProfileSetupScreen({required String step})
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/auth/presentation/ceremony_screen.dart';
import 'package:scholaris/features/auth/presentation/forgot_password_screen.dart';
import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/auth/presentation/reset_password_screen.dart';
import 'package:scholaris/features/auth/presentation/signup_screen.dart';
import 'package:scholaris/features/splash/presentation/splash_screen.dart';
import 'package:scholaris/features/auth/presentation/verify_email_screen.dart';
import 'package:scholaris/features/onboarding/controllers/onboarding_controller.dart';
import 'package:scholaris/features/onboarding/presentation/onboarding_screen.dart';
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
    // Rebuild whenever the signed-in user changes, so the redirect below is
    // never evaluated against a previous user's profile.
    ref.watch(currentUserIdProvider);
    final profile = await ref.watch(profileRepositoryProvider).fetchCurrent();
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
  // Instantiate the auth session boundary before the router registers its own
  // auth subscription below. Its onAuthStateChange listener therefore runs
  // first on every session change, invalidating every user-scoped provider
  // (through currentUserIdProvider) before the redirect re-evaluates — so a
  // redirect can never be decided from the previous user's cached state.
  ref.read(authSessionProvider);

  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) => _redirect(ref, state),
    routes: <RouteBase>[
      // --- Ceremony (opening) ------------------------------------------------
      // First-run opening for signed-out visitors: the graduation ceremony
      // Lottie, then → /login. Signed-in users are redirected away by the auth
      // logic below, so a returning user opening the app lands on splash /
      // home / setup as before.
      GoRoute(
        path: '/ceremony',
        name: 'ceremony',
        pageBuilder: (context, state) =>
            _fadeRisePage(state, child: const CeremonyScreen()),
      ),

      // --- Auth group ---------------------------------------------------------
      // Unauthenticated entry points. Access is guarded in _redirect.
      GoRoute(
        path: '/login',
        name: 'login',
        // Pure opacity cross-fade so the ceremony's cap → login transition
        // is a calm fade with no slide or rise.
        pageBuilder: (context, state) =>
            _fadeRisePage(state, child: const LoginScreen(), pureFade: true),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) =>
            VerifyEmailScreen(email: state.uri.queryParameters['email']),
      ),

      // --- First-launch onboarding --------------------------------------------
      // Shows once, before login, for signed-out users whose `onboarding_seen`
      // flag is still false. The redirect gate below never routes a signed-in
      // user here, and completing / skipping / logging in flips the flag so
      // every later launch resolves to the usual splash → login/home.
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) =>
            _fadeRisePage(state, child: const OnboardingScreen()),
      ),

      // --- Root / splash -----------------------------------------------------
      // Animated opening (cap → wordmark → tagline → fade-out). While it
      // plays, the redirect below holds /splash via splashCompletedProvider;
      // once the sequence completes, the existing onboarding/auth gates decide
      // the destination as before.
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
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

  // Re-evaluate redirects whenever auth changes (login/logout). The actual
  // user-scoped state invalidation is handled by the auth session boundary
  // (authSessionProvider → currentUserIdProvider → dependent providers), so
  // this listener only needs to re-run the redirect for the new session.
  //
  // A token refresh does not change the signed-in user or their profile, so it
  // must not re-run the profile check here: that check issues a DB request,
  // which goes through `auth.getSession()` and can itself trigger another
  // refresh, turning a single token renewal into an unbounded refresh loop
  // (burning refresh tokens until Supabase rate-limits with a 429 and signs
  // the user out). React only to real session changes.
  final authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
    event,
  ) {
    debugPrint(
      '[AUTH EVENT] event=${event.event.name} session=${event.session != null} user=${event.session?.user.id}',
    );
    if (event.event == AuthChangeEvent.tokenRefreshed) {
      return;
    }
    router.refresh();
  });
  ref.onDispose(() => authSub.cancel());

  ref.listen(profileCompleteProvider, (_, _) => router.refresh());

  // Re-evaluate the signed-out entry point once the first-launch flag resolves
  // (loading → seen/not-seen), so splash hands off to onboarding or login
  // exactly once.
  ref.listen(onboardingSeenProvider, (_, _) => router.refresh());

  // Release the splash hold once the animated sequence completes, so the
  // redirect re-runs and proceeds to onboarding/login/home.
  ref.listen(splashCompletedProvider, (_, _) => router.refresh());

  return router;
});

/// Calm fade + slight rise used for the first-run surfaces. Restrained by
/// design: no bounce, no zoom; the content simply settles into place. The
/// ~400ms duration keeps the hand-off alive without feeling abrupt or sluggish
/// (350–450ms target).
///
/// When [pureFade] is true the slide is dropped and the transition becomes a
/// pure opacity cross-fade (no slide, no rise) — used for the ceremony → login
/// hand-off where the graduating cap should dissolve straight into the empty
/// stage rather than glide across the screen.
CustomTransitionPage<void> _fadeRisePage(
  GoRouterState state, {
  required Widget child,
  bool pureFade = false,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      // The outgoing page (the route beneath this one) fades out via
      // secondaryAnimation so the ceremony → login hand-off is a clean
      // cross-fade. Without this, the outgoing content stays fully opaque
      // during the first ~50ms of the transition (easeOut starts slow),
      // causing two overlapping surfaces for a few frames. The easeOut +
      // Interval(0.0, 0.15) on the outgoing fade compresses the fade-out into
      // the first ~15% of the transition so the underlying frame is gone
      // (~21ms at 400ms transition duration) before the incoming one becomes
      // visible.
      final outgoingFade = CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
      );

      if (pureFade) {
        return FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(outgoingFade),
          child: FadeTransition(opacity: curved, child: child),
        );
      }

      return FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(outgoingFade),
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Route path constants for the profile-setup wizard, so the screen can
/// advance steps with `context.go(ProfileSetupRoute.academic)`.
abstract final class ProfileSetupRoute {
  static const personal = '/profile-setup/personal';
  static const academic = '/profile-setup/academic';
  static const financial = '/profile-setup/financial';
}

/// Route path constants for password recovery, shared by the redirect logic
/// and the auth screens.
abstract final class AuthRoute {
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const verifyEmail = '/verify-email';
}

/// The classic auth screens a signed-out user may always reach. `/ceremony` is
/// handled separately by [_redirect] so it can share the signed-out behavior
/// without being treated as a login/signup target elsewhere.
bool _isAuthRoute(String location) =>
    location == '/login' || location == '/signup';

/// Auth-aware redirect:
///  - forgot-password route       → always allowed (public request screen)
///  - verify-email route          → allowed when signed out
///  - recovery session active     → /reset-password (before any profile read)
///  - signed out                  → /login (except /login, /signup, /ceremony)
///  - signed in, profile busy     → /splash while loading
///  - signed in, complete         → /home
///  - signed in, incomplete       → /profile-setup/personal
String? _redirect(Ref ref, GoRouterState state) {
  final location = state.matchedLocation;

  // The animated splash owns /splash until its sequence completes (or is
  // skipped instantly under reduced motion). Holding here first means the
  // 2.5s choreography always plays before the onboarding/auth gates below
  // decide the destination.
  if (location == '/splash' && !ref.read(splashCompletedProvider)) {
    return null;
  }

  final recoveryActive = ref.read(passwordRecoveryProvider);
  final authDecision = authRedirectDecision(
    location: location,
    isLoggedIn: ref.read(authSessionProvider) != null,
    recoveryActive: recoveryActive,
    onAuthRoute: location == '/ceremony' || _isAuthRoute(location),
    onVerifyRoute: location == AuthRoute.verifyEmail,
    onSetupRoute: location.startsWith('/profile-setup'),
    profileLoading: ref.read(profileCompleteProvider).isLoading,
    profileComplete: ref.read(profileCompleteProvider).valueOrNull ?? false,
  );

  // Layered first-launch onboarding gate (see [onboardingRedirectDecision]).
  final onboarding = ref.read(onboardingSeenProvider);
  return onboardingRedirectDecision(
    authDecision: authDecision,
    location: location,
    onboardingLoading: onboarding.isLoading,
    onboardingSeen: onboarding.valueOrNull ?? false,
    recoveryActive: recoveryActive,
  );
}

/// First-launch onboarding gate, layered on top of [authRedirectDecision].
///
/// Only the normal "signed out → login" funnel is affected: while the persisted
/// flag is still resolving, splash is the holding room (so the winner is
/// decided once, without flashing login); once resolved, a user who has not
/// seen the intro is routed to /onboarding from any funnel location. After the
/// flag is set the gate is inert and the auth decision rules as before.
///
/// Deliberately inactive for:
///   - signed-in users (their auth decision is /home, /profile-setup or null),
///   - active password-recovery sessions (recovery always wins),
///   - public deep links (/forgot-password, /verify-email) and non-funnel
///     locations, which pass through untouched.
String? onboardingRedirectDecision({
  required String? authDecision,
  required String location,
  required bool onboardingLoading,
  required bool onboardingSeen,
  bool recoveryActive = false,
}) {
  // Recovery sessions are decided entirely by the auth layer.
  if (recoveryActive) return authDecision;

  // Locations that resolve to the login funnel for a signed-out user.
  final funnelsToLogin =
      authDecision == '/login' ||
      location == '/ceremony' ||
      _isAuthRoute(location);
  if (!funnelsToLogin) return authDecision;

  // Flag still loading → hold on splash.
  if (onboardingLoading) {
    return location == '/splash' ? null : '/splash';
  }

  // Flag known: seen users resume their normal entry point; first-run users
  // pass through onboarding once (staying on it while they are here).
  if (onboardingSeen) return authDecision;
  return location == '/onboarding' ? null : '/onboarding';
}

/// Pure redirect decision, extracted from [_redirect] so it can be unit-tested
/// without a live GoRouter or a Supabase instance.
///
/// Order matters:
///  1. `/forgot-password` is a public request screen — always reachable.
///  2. An active recovery session forces `/reset-password` and is decided
///     before any profile read, so a half-authenticated recovery session never
///     triggers profile hydration.
///  3. `/reset-password` is otherwise protected — a user can only reach it
///     through a live recovery session.
///  4. `/verify-email` is public while signed out so an unconfirmed user can
///     reach the resend surface.
///  5. Normal auth/profile routing follows.
String? authRedirectDecision({
  required String location,
  required bool isLoggedIn,
  required bool recoveryActive,
  required bool onAuthRoute,
  required bool onSetupRoute,
  required bool profileLoading,
  required bool profileComplete,
  bool onVerifyRoute = false,
}) {
  if (location == AuthRoute.forgotPassword) return null;

  if (recoveryActive) {
    return location == AuthRoute.resetPassword ? null : AuthRoute.resetPassword;
  }

  if (location == AuthRoute.resetPassword) return '/login';

  if (!isLoggedIn) {
    if (onVerifyRoute) return null;
    return onAuthRoute ? null : '/login';
  }

  if (profileLoading) {
    return location == '/splash' ? null : '/splash';
  }

  if (profileComplete) {
    return location == '/home' ? null : '/home';
  }

  return onSetupRoute ? null : ProfileSetupRoute.personal;
}
