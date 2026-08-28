// lib/features/auth/controllers/auth_controller.dart
//
// Reactive authentication boundary for Scholaris.
//
// Every user-scoped provider (profile, profile-setup draft, bookmarks,
// matches, profile-completeness) depends on [currentUserIdProvider]. Because
// Riverpod re-computes a provider whenever a dependency it watches changes,
// keying user-scoped state on the authenticated user id guarantees:
//   - signing out clears user-scoped state (the id becomes null),
//   - signing in as another user initializes fresh state for that user,
//   - a previous user's cached state can never be served to the next user.
//
// This is the single session boundary the rest of the app derives user
// identity from. Supabase remains the source of truth; this controller only
// turns its imperative auth API into reactive Riverpod state.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The authenticated session snapshot the app keys user-scoped state on.
class AuthSession {
  const AuthSession({required this.userId, this.passwordRecovery = false});

  final String userId;

  /// True when the session was established through a password-recovery deep
  /// link. While active the router forces the user onto the set-new-password
  /// screen and skips profile hydration.
  final bool passwordRecovery;
}

/// Reactive auth session. Holds the current [AuthSession] (or null when signed
/// out) and stays in sync with Supabase auth events. Lived for the whole app:
/// it is never autoDisposed, so a session change is always observable.
final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSession?>(
  AuthSessionNotifier.new,
);

class AuthSessionNotifier extends Notifier<AuthSession?> {
  @override
  AuthSession? build() {
    final client = _initializedClient();
    if (client == null) return null;

    final subscription = client.auth.onAuthStateChange.listen((event) {
      // A token refresh keeps the same user; it must not touch user state.
      if (event.event == AuthChangeEvent.tokenRefreshed) return;
      final next = AuthSessionNotifier._fromSession(
        event.session,
        passwordRecovery: event.event == AuthChangeEvent.passwordRecovery,
      );
      if (next == state) return;
      state = next;
    });
    ref.onDispose(subscription.cancel);

    return AuthSessionNotifier._fromSession(client.auth.currentSession);
  }

  static AuthSession? _fromSession(
    Session? session, {
    bool passwordRecovery = false,
  }) =>
      session == null
          ? null
          : AuthSession(
              userId: session.user.id,
              passwordRecovery: passwordRecovery,
            );

  /// The initialized Supabase client, or null when Supabase was never
  /// initialized (e.g. isolated widget tests). Falling back to null keeps the
  /// boundary functional as a signed-out state in those environments.
  static SupabaseClient? _initializedClient() {
    try {
      final instance = Supabase.instance;
      return instance.isInitialized ? instance.client : null;
    } catch (_) {
      return null;
    }
  }
}

/// The signed-in user's id, or null when signed out. User-scoped providers
/// watch this so their state cannot survive an auth transition.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authSessionProvider)?.userId,
);

/// True while a password-recovery session is active (the user opened a
/// recovery link and must set a new password before normal routing resumes).
/// The router redirects to /reset-password and skips profile hydration while
/// this is true.
final passwordRecoveryProvider = Provider<bool>(
  (ref) => ref.watch(authSessionProvider)?.passwordRecovery ?? false,
);
