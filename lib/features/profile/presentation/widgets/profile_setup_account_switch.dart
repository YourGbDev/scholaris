import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';

final profileSetupSignOutProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => Supabase.instance.client.auth.signOut(scope: SignOutScope.local),
);

class ProfileSetupAccountSwitch extends ConsumerStatefulWidget {
  const ProfileSetupAccountSwitch({
    super.key,
    required this.onSignedOut,
    this.disabled = false,
  });
  final VoidCallback onSignedOut;
  final bool disabled;
  @override
  ConsumerState<ProfileSetupAccountSwitch> createState() =>
      _ProfileSetupAccountSwitchState();
}

class _ProfileSetupAccountSwitchState
    extends ConsumerState<ProfileSetupAccountSwitch> {
  bool _busy = false;
  Future<void> _switchAccount() async {
    final confirmed = await showLogoutConfirmationDialog(
      context,
      message: 'Return to sign in with another account? Completed steps are saved. Changes on this step may be lost.',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileSetupSignOutProvider)();
      if (mounted) widget.onSignedOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not sign out. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    key: const ValueKey('profile-setup-switch-account'),
    onPressed: _busy || widget.disabled ? null : _switchAccount,
    icon: const Icon(Icons.switch_account_outlined),
    label: Text(_busy ? 'Signing out…' : 'Use a different account'),
  );
}
