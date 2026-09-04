// lib/features/auth/presentation/verify_email_screen.dart
//
// Shown after signup when Supabase email confirmation is enabled (the
// signUp call returns no session). Explains that a confirmation email is on
// its way and lets the user request a fresh link if the first one was missed.
// The link in the confirmation email returns to the app through the
// platform-aware redirect in emailConfirmationRedirect. All state is local to
// this screen, matching the other auth screens.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/app/confirmation_redirect.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.email});

  /// The address the confirmation link was sent to. When null (e.g. the user
  /// reached this screen without signing up) the resend action is disabled.
  final String? email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = false;

  Future<void> _onResend() async {
    final email = widget.email;
    if (email == null || email.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: emailConfirmationRedirect,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar('Verification email sent. Check your inbox.'),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(_friendlyError(error)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar('Something went wrong. Please try again.'),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(AuthException error) {
    if (error.message.contains('rate limit') ||
        error.message.contains('Rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (error.message.contains('not found') ||
        error.message.contains('No user')) {
      return 'We couldn\'t find an account for that email.';
    }
    return 'We couldn\'t resend the email. Please try again.';
  }

  SnackBar _snackBar(String message) => SnackBar(
        content: Text(message, style: openSans()),
      );

  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    final hasEmail = email != null && email.isNotEmpty;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildWordmark(),
                  const SizedBox(height: 32),
                  _buildCard(email: email, hasEmail: hasEmail),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordmark() {
    return Column(
      children: [
        Text(
          'Scholaris',
          textAlign: TextAlign.center,
          style: poppins(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Find scholarships that fit you',
          textAlign: TextAlign.center,
          style: openSans(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildCard({required String? email, required bool hasEmail}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verify your email',
            style: poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildMailCard(),
          const SizedBox(height: 16),
          Text(
            hasEmail
                ? 'We sent a verification link to $email. Tap the link in '
                    'the email to activate your account.'
                : 'Check your inbox for a verification link and tap it to '
                    'activate your account.',
            style: openSans(color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (hasEmail && !_isLoading) ? _onResend : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusInput),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Resend email',
                    style: poppins(fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Changed your mind?',
                style: openSans(color: Colors.black54),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Back to login',
                  style: poppins(
                    color: kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMailCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kPrimarySoft,
        borderRadius: BorderRadius.circular(kRadiusInput),
      ),
      child: Icon(
        Icons.mark_email_read_outlined,
        color: kPrimary,
        size: 48,
      ),
    );
  }
}
