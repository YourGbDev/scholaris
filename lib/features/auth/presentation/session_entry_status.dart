import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/theme/app_theme.dart';
import '../../profile/providers/profile_setup_provider.dart';

/// Authenticated loading/error surface, before a role-specific page is ready.
class SessionEntryStatus extends ConsumerWidget {
  const SessionEntryStatus({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = ref.watch(currentProfileProvider).hasError;
    return Scaffold(
      backgroundColor: kStudentCanvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!failed)
                  const CircularProgressIndicator(
                    key: ValueKey('auth-entry-busy'),
                  ),
                const SizedBox(height: 20),
                Text(
                  failed
                      ? 'We couldn’t load your account.'
                      : 'Preparing your account…',
                  textAlign: TextAlign.center,
                  style: geist(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                if (failed) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(currentProfileProvider),
                    child: const Text('Try again'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await Supabase.instance.client.auth.signOut();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not sign out. Please try again.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Sign out'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
