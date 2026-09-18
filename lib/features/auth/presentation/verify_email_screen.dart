// lib/features/auth/presentation/verify_email_screen.dart
//
// Shown after signup when Supabase email confirmation is enabled (the
// signUp call returns no session). Rebuilt to match the Stitch design
// system with Philippine context (Campus Firewall Advisory for UP, PUP,
// UST, DLSU; recipient target card; 3,200+ CHED/DOST grant impact notice).
//
// Preserves local validation, Supabase resend, and test suite contracts.

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
  bool _resent = false;

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
      setState(() => _resent = true);
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
    return error.message;
  }

  SnackBar _snackBar(String message) => SnackBar(
        content: Text(
          message,
          style: openSans(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF161C27),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    final hasEmail = email != null && email.isNotEmpty;

    return Scaffold(
      backgroundColor: kSurfaceWarm,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (Stitch V2 Header)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: kTextPrimary),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/login');
                      }
                    },
                    tooltip: 'Go back',
                  ),
                  const Spacer(),
                  Text(
                    'Scholaris',
                    style: poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded, size: 22, color: kTextSecondary),
                    tooltip: 'Help and Support',
                    onPressed: () {},
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),

                        // Geometric Envelope Graphic with Radiating Rings
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: kPrimary.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: kPrimaryLight.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.mark_email_read_rounded,
                                  color: kPrimary,
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category Pill Badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EEFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
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
                                Text(
                                  'EMAIL VERIFICATION',
                                  style: poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Heading: Verify your email
                        Text(
                          'Verify your email',
                          textAlign: TextAlign.center,
                          style: poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'We\'ve sent an official verification link to your academic or registered address:',
                          textAlign: TextAlign.center,
                          style: openSans(
                            fontSize: 13,
                            color: kTextSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Institutional Recipient Target Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kBorderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F3FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: kPrimary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recipient Target',
                                      style: openSans(
                                        fontSize: 11,
                                        color: kTextSecondary,
                                      ),
                                    ),
                                    Text(
                                      hasEmail ? email : 'No email address specified',
                                      overflow: TextOverflow.ellipsis,
                                      style: poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: kTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasEmail)
                                InkWell(
                                  onTap: () {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    } else {
                                      context.go('/signup');
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EEFF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.edit_outlined, size: 14, color: kPrimary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Edit',
                                          style: openSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: kPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Impact Guarantee Notice
                        Text(
                          'Tap the link in your email to authenticate your student credentials and unlock access to over 3,200+ CHED, DOST, and private Philippine scholarships.',
                          textAlign: TextAlign.center,
                          style: openSans(
                            fontSize: 12,
                            color: kTextSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Primary Action: Resend email
                        ElevatedButton(
                          onPressed: (hasEmail && !_isLoading) ? _onResend : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Resend email',
                                      style: poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                        if (_resent) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kPrimaryLight.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: kPrimary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Fresh verification link sent! Check your inbox.',
                                    style: openSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: kPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Campus Firewall Advisory Bento Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDDE2F3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAB928).withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: Color(0xFF583F00),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Campus Firewall Advisory (UP, PUP, UST, DLSU)',
                                      style: poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: kTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'State universities and institutional mail servers frequently filter security links into Spam or quarantine folders. Please allow 1–2 minutes before requesting a resend.',
                                      style: openSans(
                                        fontSize: 11,
                                        color: kTextSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Back to login Link
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/login'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.keyboard_backspace_rounded, size: 16, color: kPrimary),
                                const SizedBox(width: 6),
                                Text(
                                  'Back to login',
                                  style: poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
