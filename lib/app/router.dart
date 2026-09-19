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
import 'package:scholaris/features/admin/presentation/admin_home_screen.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/auth/presentation/ceremony_screen.dart';
import 'package:scholaris/features/auth/presentation/forgot_password_screen.dart';
import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/auth/presentation/reset_password_screen.dart';
import 'package:scholaris/features/auth/presentation/signup_screen.dart';
import 'package:scholaris/features/provider/presentation/provider_application_detail_screen.dart';
import 'package:scholaris/features/provider/presentation/provider_home_screen.dart';
import 'package:scholaris/features/provider/presentation/provider_review_screen.dart';
import 'package:scholaris/features/provider/presentation/provider_signup_screen.dart';
import 'package:scholaris/features/splash/presentation/splash_screen.dart';
import 'package:scholaris/features/auth/presentation/verify_email_screen.dart';
import 'package:scholaris/features/onboarding/controllers/onboarding_controller.dart';
import 'package:scholaris/features/onboarding/presentation/onboarding_screen.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/presentation/profile_setup_screen.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/applications/presentation/application_detail_screen.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:scholaris/features/scholarships/screens/saved_screen.dart';

// -----------------------------------------------------------------------------
// profileCompleteProvider / userRoleProvider
// -----------------------------------------------------------------------------
// AsyncNotifiers that report whether the signed-in user has finished the
// multi-step profile setup, and the account `role` used to pick the landing
// route. Both read the user's own `profiles` row (via the profile repository,
// which is always scoped to the authenticated user).

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

/// The signed-in user's `profiles.role` ('student' | 'provider'), defaulting
/// to 'student' when the row is missing or the column is null — the legacy
/// behaviour every existing route was built against. Read-path only: nothing
/// in the client writes role through this provider (provider signup does its
/// own one-off tag; flagged separately, out of scope here).
///
/// Derived from [currentProfileProvider] (which is already cached per user)
/// so the redirect never issues a second DB fetch — a second unlinked fetch
/// on every auth change risks the refresh-loop the profile listener here is
/// documented to avoid.
final userRoleProvider = FutureProvider<String>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  return profile?.role ?? 'student';
});

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
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDAD6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: Color(0xFFBA1A1A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF161C27),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The requested route (${state.uri.path}) does not exist.',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: const Color(0xFF404942),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const ValueKey('error-page-return-home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4D2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_rounded, size: 18),
                label: Text(
                  'Return to Home',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
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
      GoRoute(
        path: '/become-provider',
        name: 'become-provider',
        builder: (context, state) => const ProviderSignupScreen(),
      ),
      GoRoute(
        path: '/provider-review',
        name: 'provider-review',
        builder: (context, state) => const ProviderReviewScreen(),
      ),
      // Persistent landing route for signed-in users with role='provider'.
      // Placeholder content for now (same "Application Under Review" copy);
      // step 3 replaces it with the real provider console.
      GoRoute(
        path: '/provider-home',
        name: 'provider-home',
        builder: (context, state) => const ProviderHomeScreen(),
      ),
      GoRoute(
        path: '/provider-application/:id',
        name: 'provider-application-detail',
        builder: (context, state) {
          return ProviderApplicationDetailScreen(
            applicationId: state.pathParameters['id']!,
          );
        },
      ),
      // Persistent landing route for signed-in users with role='admin'.
      GoRoute(
        path: '/admin-home',
        name: 'admin-home',
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final tab = tabStr != null ? int.tryParse(tabStr) : null;
          return AdminHomeScreen(initialTab: tab);
        },
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

      // --- Saved scholarships ------------------------------------------------
      GoRoute(
        path: '/saved',
        name: 'saved',
        builder: (context, state) => const SavedScreen(),
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

      // --- Applications & Tracker Routes -------------------------------------
      GoRoute(
        path: '/applications',
        name: 'applications',
        redirect: (context, state) {
          ref.read(homeTabIndexProvider.notifier).selectTab(2);
          return '/home';
        },
      ),
      GoRoute(
        path: '/tracker',
        name: 'tracker',
        redirect: (context, state) {
          ref.read(homeTabIndexProvider.notifier).selectTab(2);
          return '/home';
        },
      ),
      GoRoute(
        path: '/discover',
        name: 'discover',
        redirect: (context, state) {
          ref.read(homeTabIndexProvider.notifier).selectTab(1);
          return '/home';
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        redirect: (context, state) {
          ref.read(homeTabIndexProvider.notifier).selectTab(3);
          return '/home';
        },
      ),
      GoRoute(
        path: '/application/:id',
        name: 'application-detail',
        builder: (context, state) => ApplicationDetailScreen(
          applicationId: state.pathParameters['id']!,
        ),
      ),

      // --- Profile setup (multi-step) ----------------------------------------
      // 3-step wizard. The parent route simply forwards to the first step.
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        redirect: (context, state) {
          // TEMP DEBUG: log parent redirect evaluation
          debugPrint('[ROUTER] parent redirect for path=${state.uri.path}');
          // Only redirect bare /profile-setup to personal; child paths must
          // pass through untouched or the Next button bounces back to step 1.
          if (state.uri.path == '/profile-setup' || state.uri.path.endsWith('/profile-setup/')) {
            return ProfileSetupRoute.personal;
          }
          return null;
        },
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
  // The provider branch of the landing decision depends on role, so a role
  // change (e.g. after provider signup tags the row) must also re-evaluate
  // redirects.
  ref.listen(userRoleProvider, (_, _) => router.refresh());

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

/// Route path constants for the provider surfaces reached through the role
/// branch of [authRedirectDecision]. /provider-review stays the post-signup
/// confirmation page; /provider-home is the persistent landing route for
/// signed-in role='provider' users.
abstract final class ProviderRoute {
  static const review = '/provider-review';
  static const home = '/provider-home';
}

/// Route path constants for the admin surfaces reached through the role
/// branch of [authRedirectDecision].
abstract final class AdminRoute {
  static const home = '/admin-home';
}

/// The classic auth screens a signed-out user may always reach. `/ceremony` is
/// handled separately by [_redirect] so it can share the signed-out behavior
/// without being treated as a login/signup target elsewhere.
///
/// `/become-provider` is included: the provider signup is an unauthenticated
/// entry point (like /signup) — omitting it made the redirect bounce
/// /become-provider → /login before the screen could ever render
/// (allowlist omission from 9de9f5f, fixed 2026-09-08).
bool _isAuthRoute(String location) =>
    location == '/login' ||
    location == '/signup' ||
    location == '/become-provider';

/// Auth-aware redirect:
///  - forgot-password route       → always allowed (public request screen)
///  - verify-email route          → allowed when signed out
///  - recovery session active     → /reset-password (before any profile read)
///  - signed out                  → /login (except /login, /signup, /ceremony)
///  - signed in, profile busy     → /splash while loading
///  - signed in, role='provider'  → /provider-home
///  - signed in, complete         → /home
///  - signed in, incomplete       → /profile-setup/personal
String? _redirect(Ref ref, GoRouterState state) {
  final location = state.matchedLocation;

  // TEMP DEBUG: log every redirect evaluation with key state
  debugPrint(
    '[ROUTER] redirect location=$location '
    'isLoggedIn=${ref.read(authSessionProvider) != null} '
    'profileLoading=${ref.read(profileCompleteProvider).isLoading} '
    'profileComplete=${ref.read(profileCompleteProvider).valueOrNull ?? false} '
    'role=${ref.read(userRoleProvider).valueOrNull ?? "..."} '
    'onSetupRoute=${location.startsWith('/profile-setup')}',
  );

  // The animated splash owns /splash until its sequence completes (or is
  // skipped instantly under reduced motion). Holding here first means the
  // 2.5s choreography always plays before the onboarding/auth gates below
  // decide the destination.
  if (location == '/splash' && !ref.read(splashCompletedProvider)) {
    debugPrint('[ROUTER] holding on /splash');
    return null;
  }

  final recoveryActive = ref.read(passwordRecoveryProvider);
  final profileAsync = ref.read(profileCompleteProvider);
  final roleAsync = ref.read(userRoleProvider);

  // When a user deep-links directly to /admin-home (e.g. ?tab=4), hold on
  // the route while their role resolves from the database so the
  // destination and query parameters are not clobbered by an unhydrated student default.
  if (location == AdminRoute.home &&
      (roleAsync.isLoading && roleAsync.value == null)) {
    debugPrint('[ROUTER] holding on /admin-home while role resolves');
    return null;
  }

  final authDecision = authRedirectDecision(
    location: location,
    isLoggedIn: ref.read(authSessionProvider) != null,
    recoveryActive: recoveryActive,
    onAuthRoute: location == '/ceremony' || _isAuthRoute(location),
    onVerifyRoute: location == AuthRoute.verifyEmail,
    onSetupRoute: location.startsWith('/profile-setup'),
    profileLoading:
        profileAsync.isLoading || (roleAsync.isLoading && roleAsync.value == null),
    profileComplete: profileAsync.valueOrNull ?? false,
    role: roleAsync.valueOrNull ?? 'student',
  );
  debugPrint('[ROUTER] authDecision=$authDecision');

  // Layered first-launch onboarding gate (see [onboardingRedirectDecision]).
  final onboarding = ref.read(onboardingSeenProvider);
  final result = onboardingRedirectDecision(
    authDecision: authDecision,
    location: location,
    onboardingLoading: onboarding.isLoading,
    onboardingSeen: onboarding.valueOrNull ?? false,
    recoveryActive: recoveryActive,
  );
  debugPrint('[ROUTER] final redirect=$result');
  return result;
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
///   - signed-in users (their auth decision is /home, /profile-setup or
///     /provider-home — see [ProviderRoute]; any of these bypasses the gate
///     outright, standing "signed-in flows are never gated" invariant),
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

  // A signed-in auth decision is a destination, not the login funnel — even
  // when it was produced while sitting on /ceremony or an auth route. Without
  // this, a provider landing on /login (auth decision /provider-home) would be
  // pulled into onboarding by the location-only funnel check below.
  final signedInDestination =
      authDecision == '/home' ||
      authDecision == ProviderRoute.home ||
      authDecision == AdminRoute.home ||
      (authDecision != null && authDecision.startsWith('/profile-setup'));
  if (signedInDestination) return authDecision;

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
///  6. Signed-in users with role='provider' land on /provider-home before
///     any student setup/completeness routing. [role] defaults to 'student'
///     so every pre-existing call site keeps its exact behaviour.
String? authRedirectDecision({
  required String location,
  required bool isLoggedIn,
  required bool recoveryActive,
  required bool onAuthRoute,
  required bool onSetupRoute,
  required bool profileLoading,
  required bool profileComplete,
  bool onVerifyRoute = false,
  String role = 'student',
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

  // Admin route protection: only users with role='admin' may access /admin-home.
  // All other users (even while profile is loading) must be redirected away
  // to their authorized destination (fails closed, never open).
  if (location == AdminRoute.home && role != 'admin') {
    if (role == 'provider') return ProviderRoute.home;
    if (profileComplete) return '/home';
    return onSetupRoute ? null : ProfileSetupRoute.personal;
  }

  if (profileLoading) {
    return null;
  }

  // Admin branch: a role='admin' account lands on its persistent console,
  // never on the student /profile-setup wizard or /home.
  if (role == 'admin') {
    return location == AdminRoute.home ? null : AdminRoute.home;
  }

  // Provider branch: a role='provider' account lands on its persistent home,
  // never on the student /profile-setup wizard or /home. Decided BEFORE the
  // profileComplete check so a provider row (whose setup_complete is
  // irrelevant) is never forced through the student wizard.
  if (role == 'provider') {
    final isProviderRoute = location == ProviderRoute.home ||
        location == '/provider-review' ||
        location.startsWith('/provider-application');
    return isProviderRoute ? null : ProviderRoute.home;
  }

  // Student protection: prevent non-providers from accessing provider routes
  if (location.startsWith('/provider-')) {
    return profileComplete ? '/home' : ProfileSetupRoute.personal;
  }

  if (profileComplete) {
    if (onAuthRoute || onSetupRoute || onVerifyRoute || location == '/onboarding' || location == '/splash') {
      return '/home';
    }
    return null;
  }

  return onSetupRoute ? null : ProfileSetupRoute.personal;
}

