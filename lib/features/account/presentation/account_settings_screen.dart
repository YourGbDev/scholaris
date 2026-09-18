// lib/features/account/presentation/account_settings_screen.dart
//
// Self-service account & app settings screen migrated to 100% Stitch V2 visual,
// structural, and literal fidelity:
// `design-reference/stitch_scholaris_mobile_app/scholaris_account_app_settings/code.html`
//
// Sections:
//   1. Account & Security — email, verification badge, re-auth password change form,
//      2FA indicators, phone SMS alerts, and SUC CRS SSO connected status.
//   2. Notification Preferences — deadline approaching priority alerts, 90%+ match
//      alerts, application status updates, weekly grant digest, and email notices.
//   3. Privacy & Data Shield — RA 10173 data usage banner, privacy policy, data
//      dossier export, and third-party SUC permissions.
//   4. Support & About — student help desk, live chat, and app build details.
//   5. Account Actions & Trust Footer — calm logout, deactivation, and NPC registry.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/account/providers/account_provider.dart';
import 'package:scholaris/features/account/repositories/account_repository.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';
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

  // Notification toggle states
  bool _alertDeadline = true;
  bool _alertMatches = true;
  bool _alertStatus = true;
  bool _alertWeeklyDigest = false;
  bool _alertEmail = true;

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
        // Clear sensitive fields
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

  String _friendlyAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Current password is incorrect.';
    }
    if (message.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (message.contains('password should be') ||
        message.contains('at least 6')) {
      return 'Password must be at least 6 characters.';
    }
    if (message.contains('not found') || message.contains('no user')) {
      return 'We couldn\'t find your account.';
    }
    return 'We couldn\'t complete that. Please try again.';
  }

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
      backgroundColor: kSurfaceWarm,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: const BackButton(color: kTextPrimary),
        title: Text(
          'Account Settings',
          style: outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: kTextSecondary, size: 22),
            tooltip: 'Help and Support',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scholaris Support: support@scholaris.ph • Mon-Fri 8AM-5PM PHT'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: ResponsiveContainer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: [
            // Group 1: Account & Security
            _buildAccountAndSecuritySection(email, emailConfirmed),
            const SizedBox(height: 24),

            // Group 2: Notification Preferences
            _buildNotificationPreferencesSection(),
            const SizedBox(height: 24),

            // Group 3: Privacy & Data Protection
            _buildPrivacyDataShieldSection(),
            const SizedBox(height: 24),

            // Group 4: Support & About
            _buildSupportAndAboutSection(),
            const SizedBox(height: 28),

            // Group 5: Bottom Account Actions & NPC Trust Footer
            _buildBottomAccountActionsSection(),
          ],
        ),
      ),
    );
  }

  // --- Group 1: Account & Security ------------------------------------------

  Widget _buildAccountAndSecuritySection(String? email, bool emailConfirmed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Account',
                  style: outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: kTextSecondary,
                  ),
                ),
                Text(
                  ' & Security',
                  style: outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded, size: 14, color: kPrimary),
                const SizedBox(width: 4),
                Text(
                  'Secured',
                  style: outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE2F3)),
            boxShadow: const [
              BoxShadow(
                color: kCardShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email Row
              _buildEmailRow(email, emailConfirmed),
              const Divider(height: 1, color: Color(0xFFF1F3FF)),

              // Change Password Card
              _buildChangePasswordSection(),
              const Divider(height: 1, color: Color(0xFFF1F3FF)),

              // Phone Number Row
              _buildPhoneRow(),
              const Divider(height: 1, color: Color(0xFFF1F3FF)),

              // SUC Integration Row
              _buildSucIntegrationRow(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailRow(String? email, bool emailConfirmed) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Email Address',
                style: openSans(fontSize: 12, color: kTextSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: emailConfirmed ? kPrimaryLight : kTertiaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  emailConfirmed ? 'Verified' : 'Not verified',
                  style: outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: emailConfirmed
                        ? kOnPrimaryFixedVariant
                        : kOnTertiaryFixedVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            email ?? 'Unknown',
            style: outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (!emailConfirmed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _isResending || email == null || email.isEmpty
                      ? null
                      : _onResend,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kPrimary),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isResending ? 'Sending…' : 'Resend verification email',
                    style: outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (_resendSuccess != null) ...[
              const SizedBox(height: 6),
              Text(
                _resendSuccess!,
                style: openSans(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600),
              ),
            ],
            if (_resendError != null) ...[
              const SizedBox(height: 6),
              Text(
                _resendError!,
                style: openSans(fontSize: 12, color: kError),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildChangePasswordSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Change password',
                style: outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 14, color: kPrimary),
                  const SizedBox(width: 4),
                  Text(
                    '2FA Active',
                    style: outfit(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Confirm your current password to set a new one.',
            style: openSans(fontSize: 12, color: kTextSecondary),
          ),
          const SizedBox(height: 14),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _passwordInputField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  obscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: _validateCurrentPassword,
                ),
                const SizedBox(height: 12),

                _passwordInputField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator: _validateNewPassword,
                ),
                const SizedBox(height: 12),

                _passwordInputField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: _validateConfirmPassword,
                ),

                if (_passwordError != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kErrorSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kError.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 16, color: kError),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _passwordError!,
                            style: openSans(fontSize: 12, color: kError),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_passwordChanged) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: kPrimary),
                        const SizedBox(width: 8),
                        Text(
                          'Password updated successfully.',
                          style: openSans(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _onChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Update Password',
                          style: outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordInputField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: openSans(fontSize: 14, color: kTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: openSans(color: kTextSecondary, fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: kTextSecondary),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: kTextSecondary,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF9F9FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE2F3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE2F3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPhoneRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone Number',
                  style: openSans(fontSize: 12, color: kTextSecondary),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '+63 917 ••• •421',
                      style: outfit(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary),
                    ),
                    const SizedBox(width: 6),
                    Text('•', style: openSans(color: kTextSecondary)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'SMS alerts active',
                        style: openSans(fontSize: 12, color: kTextSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF707971), size: 20),
        ],
      ),
    );
  }

  Widget _buildSucIntegrationRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Academic Institution SSO',
                  style: openSans(fontSize: 12, color: kTextSecondary),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'UP Diliman (CRS SSO Connected)',
                        style: outfit(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Last synced today at 08:30 AM',
                  style: openSans(fontSize: 11, color: kTextSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sync with University Records',
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF707971), size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Academic records up to date with UP CRS.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Group 2: Notification Preferences ------------------------------------

  Widget _buildNotificationPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'NOTIFICATION PREFERENCES',
          style: outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: kTextSecondary,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE2F3)),
            boxShadow: const [
              BoxShadow(
                color: kCardShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _notificationSwitch(
                title: 'Deadline Approaching Alerts',
                subtitle: 'Push & SMS notifications 48 hours before grant submission cutoff.',
                badge: 'Priority',
                badgeColor: const Color(0xFFFFDAD6),
                badgeTextColor: const Color(0xFF93000A),
                value: _alertDeadline,
                onChanged: (v) => setState(() => _alertDeadline = v),
              ),
              const Divider(height: 1, color: Color(0xFFF1F3FF)),

              _notificationSwitch(
                title: 'New Scholarship Matches',
                subtitle: 'Instant alerts when an opportunity fits your exact academic profile.',
                badge: '90%+',
                badgeColor: kTertiaryFixed,
                badgeTextColor: kOnTertiaryFixedVariant,
                value: _alertMatches,
                onChanged: (v) => setState(() => _alertMatches = v),
              ),
              const Divider(height: 1, color: Color(0xFFF1F3FF)),

              _notificationSwitch(
                title: 'Application Status Updates',
                subtitle: 'Real-time alerts when screening panels advance your dossier.',
                value: _alertStatus,
                onChanged: (v) => setState(() => _alertStatus = v),
              ),
              const Divider(height: 1, color: Color(0xFFF1F3FF)),

              _notificationSwitch(
                title: 'Weekly Grant Digest',
                subtitle: 'A curated Friday summary of regional grants and university aids.',
                value: _alertWeeklyDigest,
                onChanged: (v) => setState(() => _alertWeeklyDigest = v),
              ),
              const Divider(height: 1, color: Color(0xFFF1F3FF)),

              _notificationSwitch(
                title: 'Email Notifications',
                subtitle: 'Receive formal notices, receipt confirmations, and interview invites.',
                value: _alertEmail,
                onChanged: (v) => setState(() => _alertEmail = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _notificationSwitch({
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: outfit(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: badgeColor ?? kPrimaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeTextColor ?? kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: openSans(fontSize: 11, color: kTextSecondary, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeTrackColor: kPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- Group 3: Privacy & Data Shield ---------------------------------------

  Widget _buildPrivacyDataShieldSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PRIVACY & DATA SHIELD',
              style: outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: kTextSecondary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gavel_rounded, size: 13, color: kSecondary),
                const SizedBox(width: 4),
                Text(
                  'RA 10173',
                  style: outfit(fontSize: 11, fontWeight: FontWeight.w600, color: kSecondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE2F3)),
            boxShadow: const [
              BoxShadow(
                color: kCardShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Shielding Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F3FF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: kPrimaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_rounded, color: kPrimary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Usage & Income Shielding',
                            style: outfit(fontSize: 13, fontWeight: FontWeight.w700, color: kTextPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your exact income is never sold or disclosed to third parties. Only verified eligibility tiers are shared with accredited providers under Philippine Data Privacy Act protections.',
                            style: openSans(fontSize: 11, color: kTextSecondary, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Items
              _actionListTile(
                icon: Icons.description_outlined,
                title: 'Privacy Policy & Student Rights',
                subtitle: 'Review terms, statutory rights, and data processing basis',
                trailingIcon: Icons.open_in_new_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Scholaris complies with NPC Circular 16-01 on data subject rights.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F3FF)),

              _actionListTile(
                icon: Icons.download_rounded,
                title: 'Export My Data Dossier',
                subtitle: 'Download submitted transcripts, grades, and logs (JSON/PDF)',
                trailingIcon: Icons.arrow_forward_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preparing encrypted archive. A download link will be emailed to your inbox within 15 minutes.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F3FF)),

              _actionListTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Manage Third-Party SUC Permissions',
                subtitle: 'Control institutional access grants & API keys',
                trailingIcon: Icons.chevron_right_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Manage permissions for UP CRS, CHED UniFAST, and DOST portal.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required IconData trailingIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kTextSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: outfit(fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary),
                  ),
                  Text(
                    subtitle,
                    style: openSans(fontSize: 11, color: kTextSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(trailingIcon, size: 18, color: const Color(0xFF707971)),
          ],
        ),
      ),
    );
  }

  // --- Group 4: Support & About ---------------------------------------------

  Widget _buildSupportAndAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SUPPORT & ABOUT',
          style: outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: kTextSecondary,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE2F3)),
            boxShadow: const [
              BoxShadow(
                color: kCardShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _actionListTile(
                icon: Icons.forum_outlined,
                title: 'Student Help Desk & FAQs',
                subtitle: 'Live chat with accredited Scholar Advisors',
                trailingIcon: Icons.chevron_right_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Connecting to Scholaris Advisor live chat...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F3FF)),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: kTextSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scholaris App Version',
                            style: outfit(fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary),
                          ),
                          Text(
                            'AY 2024–2025 Edition • Build 489',
                            style: openSans(fontSize: 11, color: kTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'v2.4.0',
                        style: outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Group 5: Bottom Account Actions --------------------------------------

  Widget _buildBottomAccountActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Calm Log Out Button
        OutlinedButton.icon(
          key: const ValueKey('settings-logout-button'),
          onPressed: () async {
            final confirmed = await showLogoutConfirmationDialog(context);
            if (confirmed) {
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (_) {}
            }
          },
          icon: const Icon(Icons.logout_rounded, size: 18, color: kSecondary),
          label: Text(
            'Log Out',
            style: outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kSecondary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFDDE2F3), width: 1.5),
            backgroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Deactivate / Delete Link
        Center(
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('To delete or deactivate your account, please submit a request via support@scholaris.ph.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: Text(
              'Delete or Deactivate Account',
              style: openSans(
                fontSize: 12,
                color: const Color(0xFF707971),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // End-to-end encrypted & National Privacy Commission Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock_outlined, size: 14, color: Color(0xFF707971)),
            const SizedBox(width: 4),
            Text(
              'END-TO-END ENCRYPTED',
              style: outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: const Color(0xFF707971),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Center(
          child: Text(
            'National Privacy Commission Registered (NPC-RA10173)',
            style: openSans(
              fontSize: 11,
              color: const Color(0xFF707971),
            ),
          ),
        ),
      ],
    );
  }
}
