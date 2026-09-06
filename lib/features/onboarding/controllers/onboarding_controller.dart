// lib/features/onboarding/controllers/onboarding_controller.dart
//
// First-launch onboarding flag for Scholaris.
//
// A single persisted boolean — `onboarding_seen` — decides whether the
// intro slides show on startup. It starts `false`, flips to `true` when the
// user completes or skips the slides, and is never reset, so the onboarding
// screen shows exactly once per install.
//
// The flag lives in shared_preferences (local device storage) and is
// deliberately independent of Supabase/auth state: a returning signed-out
// user skips onboarding, a brand-new signed-out user sees it first.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// shared_preferences key holding the first-launch onboarding flag.
const String kOnboardingSeenKey = 'onboarding_seen';

/// Persisted first-launch flag: false until the user completes or skips the
/// onboarding slides, then true forever.
class OnboardingSeenNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kOnboardingSeenKey) ?? false;
  }

  /// Marks onboarding as seen (completed or skipped) and persists the flag so
  /// the screen never shows again. Await before navigating away, so the next
  /// redirect is already evaluated against `onboarding_seen == true`.
  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingSeenKey, true);
    state = const AsyncValue.data(true);
  }
}

/// The first-launch onboarding flag. Lived for the whole app: the router
/// listens to it so the redirect re-evaluates once the flag resolves.
final onboardingSeenProvider =
    AsyncNotifierProvider<OnboardingSeenNotifier, bool>(
      OnboardingSeenNotifier.new,
    );
