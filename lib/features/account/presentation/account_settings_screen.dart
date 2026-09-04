// lib/features/account/presentation/account_settings_screen.dart
//
// Self-service account settings, opened from the Profile tab via the app's
// standard Navigator push pattern (the same one "My Applications" uses), so
// back navigation returns naturally to the Profile tab with its state intact
// and no new go_router route is needed.
//
// Sections:
//   1. Account — the signed-in user's email and verification status, sourced
//      from the existing auth session boundary (single source of truth).
//   2. Verification — for unverified accounts: a resend action reusing the
//      Day 13 email-confirmation redirect contract. For verified accounts the
//      action is not exposed.
//   3. Change password — re-authentication-gated: current password, new
//      password (+ confirmation). Passwords live only in this State's
//      TextEditingControllers; they are never placed in provider state,
//      logged, or embedded in errors, and are cleared after success.
//
// Sign out intentionally remains owned by the Profile tab.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/account/providers/account_provider.dart';
import 'package:scholaris/features/account/repositories/account_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/success_overlay.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isSubmitting = false;
  bool _isResending = false;
  bool _passwordChanged = false;
  String? _passwordError;
  String? _resendError;
  String? _resendSuccess;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Verification resend --------------------------------------------------

  Future<void> _onResend() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _resendError = null;
      _resendSuccess = null;
    });
    try {
      await ref.read(accountRepositoryProvider).resendVerificationEmail();
      if (!mounted) return;
      setState(() => _resendSuccess = 'Verification email sent. '
          'Check your inbox.');
    } on AccountNotAuthenticatedException {
      if (!mounted) return;
      setState(
        () => _resendError = 'You must be signed in to resend the email.',
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _resendError = _friendlyAuthError(error));
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _resendError = 'We couldn\'t resend the email. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // --- Password change ------------------------------------------------------

  Future<void> _onChangePassword() async {
    if (_isSubmitting) return;
    setState(() {
      _passwordError = null;
      _passwordChanged = false;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(accountRepositoryProvider).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _passwordChanged = true;
        // Clear the sensitive fields now that the change succeeded.
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
      await SuccessOverlay.show(context);
    } on AccountNotAuthenticatedException {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _passwordError = 'You must be signed in to change your password.';
      });
    } on AccountSessionChangedException {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _passwordError = 'Your session changed. Please sign in and try again.';
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _passwordError = _friendlyAuthError(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _passwordError = 'Failed to change your password. Please try again.';
      });
    }
  }

  /// Maps auth failures to the app's friendly conventions (login /
  /// verify-email / reset-password style wording).
  String _friendlyAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Current password is incorrect.';
    }
    if (message.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (message.contains('password should be')) {
      return 'Password must be at least 6 characters.';
    }
    if (message.contains('not found') || message.contains('no user')) {
      return 'We couldn\'t find your account.';
    }
    return 'We couldn\'t complete that. Please try again.';
  }

  // --- Validators (reuse the app's existing password conventions) -----------

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your current password.';
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a new password.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    if (value == _currentPasswordController.text) {
      return 'New password must be different from your current password.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your new password.';
    if (value != _newPasswordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(currentUserEmailProvider);
    final emailConfirmed = ref.watch(emailConfirmedProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Account Settings')),
      body: ResponsiveContainer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _AccountCard(
              icon: Icons.alternate_email_rounded,
              title: 'Account',
              children: [
                _DetailRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: email ?? 'Unknown',
                ),
                _VerificationRow(
                  confirmed: emailConfirmed,
                  isResending: _isResending,
                  resendSuccess: _resendSuccess,
                  resendError: _resendError,
                  onResend: email == null || email.isEmpty ? null : _onResend,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _passwordSection(),
          ],
        ),
      ),
    );
  }

  Widget _passwordSection() {
    return _AccountCard(
      icon: Icons.lock_outline_rounded,
      title: 'Change password',
      children: [
        Text(
          'Confirm your current password to set a new one.',
          style: openSans(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _passwordField(
                controller: _currentPasswordController,
                label: 'Current Password',
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                textInputAction: TextInputAction.next,
                validator: _validateCurrentPassword,
              ),
              const SizedBox(height: 16),
              _passwordField(
                controller: _newPasswordController,
                label: 'New Password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                textInputAction: TextInputAction.next,
                validator: _validateNewPassword,
              ),
              const SizedBox(height: 16),
              _passwordField(
                controller: _confirmPasswordController,
                label: 'Confirm New Password',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onChangePassword(),
                validator: _validateConfirmPassword,
              ),
              if (_passwordError != null) ...[
                const SizedBox(height: 12),
                _InlineMessage.error(_passwordError!),
              ],
              if (_passwordChanged) ...[
                const SizedBox(height: 12),
                const _InlineMessage.success(
                  'Password updated successfully.',
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _onChangePassword,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update password'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required TextInputAction textInputAction,
    required FormFieldValidator<String> validator,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      autocorrect: false,
      enableSuggestions: false,
      validator: validator,
      style: openSans(),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.black45,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// --- Shared pieces ------------------------------------------------------------

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: kPrimarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: kPrimary),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: openSans(fontSize: 13, color: Colors.black54),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationRow extends StatelessWidget {
  const _VerificationRow({
    required this.confirmed,
    required this.isResending,
    required this.resendSuccess,
    required this.resendError,
    required this.onResend,
  });

  final bool confirmed;
  final bool isResending;
  final String? resendSuccess;
  final String? resendError;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                confirmed
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                size: 18,
                color: confirmed ? kPrimary : kAccent,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  'Status',
                  style: openSans(fontSize: 13, color: Colors.black54),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  confirmed ? 'Verified' : 'Not verified',
                  textAlign: TextAlign.right,
                  style: poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: confirmed ? kPrimary : kAccent,
                  ),
                ),
              ),
            ],
          ),
          if (!confirmed) ...[
            const SizedBox(height: 4),
            Text(
              'Verify your email to secure your account.',
              style: openSans(fontSize: 12, color: Colors.black54),
            ),
            if (resendSuccess != null) ...[
              const SizedBox(height: 8),
              const _InlineMessage.success('Verification email sent. '
                  'Check your inbox.'),
            ],
            if (resendError != null) ...[
              const SizedBox(height: 8),
              _InlineMessage.error(resendError!),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isResending ? null : onResend,
              icon: isResending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.forward_to_inbox_rounded, size: 18),
              label: Text(isResending ? 'Sending…' : 'Resend verification email'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage.error(this.message) : success = false;

  const _InlineMessage.success(this.message) : success = true;

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? kPrimary : kError;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success ? kPrimarySoft : const Color(0x14B3261E),
        borderRadius: BorderRadius.circular(kRadiusInput),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_outline_rounded : Icons.error_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: openSans(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
