// lib/features/auth/presentation/verify_email_screen.dart
//
// Shown after signup when Supabase email confirmation is enabled (the
// signUp call returns no session). Explains that a confirmation email is on
// its way and lets the user request a fresh link if the first one was missed.
// The link in the confirmation email returns to the app through the
// platform-aware redirect in emailConfirmationRedirect. All state is local to
// this screen, matching the other auth screens.
//
// V1 visual treatment (matching Login / Forgot Password / Signup / Reset
// Password): a looping Lottie hero fills the top band and a clean white
// rounded card (top corners radius 24) slides up carrying the content. The
// paper-plane hero reuses the Forgot Password asset — a send/receive moment,
// the closest themed asset in the library. Frozen in widget tests and for
// reduced-motion users.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scholaris/shared/widgets/eli_mascot.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/app/confirmation_redirect.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';

// --- Tokens ----------------------------------------------------------------

/// Total entrance duration for the verify-email screen's staggered reveal.
const int kVerifyEntranceTotalMs = 1800;

// --- Entrance timeline helpers ---------------------------------------------

/// Builds an [Interval] for an entrance element that starts at [beginMs] and
/// ends at [endMs] within the screen's total duration.
Interval _verifyInterval(int beginMs, int endMs) => EntranceMotion.intervalFrom(
  beginMs,
  endMs,
  kVerifyEntranceTotalMs,
  curve: Curves.easeOutCubic,
);

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.email});

  /// The address the confirmation link was sent to. When null (e.g. the user
  /// reached this screen without signing up) the resend action is disabled.
  final String? email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with
        TickerProviderStateMixin<VerifyEmailScreen>,
        EntranceMotionMixin<VerifyEmailScreen> {
  bool _isLoading = false;

  @override
  Duration get entranceDuration =>
      const Duration(milliseconds: kVerifyEntranceTotalMs);

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
    return error.message;
  }

  SnackBar _snackBar(String message) => SnackBar(
        content: Text(message, style: openSans()),
      );


  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    final hasEmail = email != null && email.isNotEmpty;

    return Scaffold(
      // Clean white — matches the other V1 auth surfaces.
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  // Responsive split: hero takes ~40% on tall screens but
                  // shrinks on short viewports so the card keeps room for
                  // the mail chip, message, resend button and back link.
                  final maxHero =
                      (viewport.maxHeight - 400).clamp(0.0, double.infinity);
                  final heroHeight =
                      (viewport.maxHeight * 0.40).clamp(0.0, maxHero);
                  return Column(
                    children: [
                      // --- Top: hero Lottie animation --------------------------
                      SizedBox(
                        height: heroHeight,
                        width: double.infinity,
                        child: entranceItem(
                          index: 0,
                          offset: const Offset(0, 0.08),
                          interval: _verifyInterval(200, 900),
                          child: EliMascot(
                            pose: EliPose.mail,
                            height: heroHeight,
                          ),
                        ),
                      ),

                      // --- Bottom: white rounded card ---------------------------
                      Expanded(
                        child: entranceItem(
                          index: 1,
                          offset: const Offset(0, 0.25),
                          interval: _verifyInterval(200, 900),
                          child: Container(
                            // Deliberately a Container, not a Card — matches
                            // the login screen's V1 card treatment.
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kCardShadow,
                                  blurRadius: 24,
                                  offset: const Offset(0, -6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Scrollable content region.
                                Flexible(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      24,
                                      24,
                                      8,
                                    ),
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 420,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            // Heading.
                                            entranceItem(
                                              index: 0,
                                              offset: const Offset(0, 0.12),
                                              interval: _verifyInterval(
                                                400,
                                                820,
                                              ),
                                              child: Text(
                                                'Verify your email',
                                                textAlign: TextAlign.center,
                                                style: poppins(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                  color: kPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            // The sent-to mail chip.
                                            entranceItem(
                                              index: 1,
                                              offset: const Offset(0, 0.12),
                                              interval: _verifyInterval(
                                                500,
                                                920,
                                              ),
                                              child: _buildMailCard(),
                                            ),
                                            const SizedBox(height: 16),
                                            // Instructions.
                                            entranceItem(
                                              index: 2,
                                              offset: const Offset(0, 0.12),
                                              interval: _verifyInterval(
                                                600,
                                                1020,
                                              ),
                                              child: Text(
                                                hasEmail
                                                    ? 'We sent a verification '
                                                        'link to $email. Tap '
                                                        'the link in the email '
                                                        'to activate your '
                                                        'account.'
                                                    : 'Check your inbox for a '
                                                        'verification link and '
                                                        'tap it to activate '
                                                        'your account.',
                                                textAlign: TextAlign.center,
                                                style: openSans(
                                                  fontSize: 15,
                                                  color: Colors.black54,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            // Resend action.
                                            entranceItem(
                                              index: 3,
                                              offset: const Offset(0, 0.12),
                                              interval: _verifyInterval(
                                                700,
                                                1120,
                                              ),
                                              child: ElevatedButton(
                                                onPressed: (hasEmail &&
                                                        !_isLoading)
                                                    ? _onResend
                                                    : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: kPrimary,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 16,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      kRadiusInput,
                                                    ),
                                                  ),
                                                ),
                                                child: _isLoading
                                                    ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : Text(
                                                        'Resend email',
                                                        style: poppins(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Wrap(
                                              alignment: WrapAlignment.center,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  'Changed your mind?',
                                                  style: openSans(
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      context.go('/login'),
                                                  child: Text(
                                                    'Back to login',
                                                    style: poppins(
                                                      color: kPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMailCard() {
    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kPrimarySoft,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.mark_email_read_outlined,
        color: kPrimary,
        size: 44,
      ),
    );
  }
}
