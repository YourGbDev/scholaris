// lib/features/auth/presentation/reset_password_screen.dart
//
// Set-new-password screen shown after the user opens a password-recovery link.
// The user enters a new password twice, then calls updateUser to persist it.
// On success the auth boundary clears the recovery flag and the router redirects
// to the normal signed-in landing (home or profile-setup).
//
// V1 visual treatment (matching Login / Forgot Password / Signup): a looping
// Lottie hero fills the top band, and a clean white rounded card (top corners
// radius 24) slides up carrying the form. The hero freezes in widget tests and
// for reduced-motion users so the surface stays deterministic and calm.

import 'package:flutter/material.dart';
import 'package:scholaris/shared/widgets/student_mascot.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';
import 'package:scholaris/shared/widgets/success_overlay.dart';

// --- Tokens ----------------------------------------------------------------

/// Total entrance duration for the reset-password screen's staggered reveal.
const int kResetEntranceTotalMs = 2000;

const _inputRadius = 12.0;

// --- Entrance timeline helpers ---------------------------------------------

/// Builds an [Interval] for an entrance element that starts at [beginMs] and
/// ends at [endMs] within the screen's total duration.
Interval _resetInterval(int beginMs, int endMs) => EntranceMotion.intervalFrom(
  beginMs,
  endMs,
  kResetEntranceTotalMs,
  curve: Curves.easeOutCubic,
);

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with
        TickerProviderStateMixin<ResetPasswordScreen>,
        EntranceMotionMixin<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  Duration get entranceDuration =>
      const Duration(milliseconds: kResetEntranceTotalMs);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (!mounted) return;

      await SuccessOverlay.show(context);
      // The auth boundary clears the recovery flag on userUpdated, and the
      // router listener re-evaluates the redirect to /home or /profile-setup.
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(_friendlyError(error)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(AuthException error) {
    if (error.message.contains('Password should be')) {
      return 'Password must be at least 6 characters.';
    }
    return error.message;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a new password.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your new password.';
    if (value != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  SnackBar _snackBar(String message) => SnackBar(
        content: Text(message, style: openSans()),
      );


  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Clean white — matches the other V1 auth surfaces.
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  // Responsive split: hero takes ~42% on tall screens but
                  // shrinks on short viewports so the card always has room
                  // for both fields, the button and the sign-out row.
                  final maxHero =
                      (viewport.maxHeight - 400).clamp(0.0, double.infinity);
                  final heroHeight =
                      (viewport.maxHeight * 0.42).clamp(0.0, maxHero);
                  return Column(
                    children: [
                      // --- Top: hero Lottie animation --------------------------
                      SizedBox(
                        height: heroHeight,
                        width: double.infinity,
                        child: entranceItem(
                          index: 0,
                          offset: const Offset(0, 0.08),
                          interval: _resetInterval(200, 1000),
                          child: StudentMascot(
                            pose: StudentMascotPose.determined,
                            height: heroHeight,
                          ),
                        ),
                      ),

                      // --- Bottom: white rounded card ---------------------------
                      Expanded(
                        child: entranceItem(
                          index: 1,
                          offset: const Offset(0, 0.25),
                          interval: _resetInterval(200, 1000),
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
                                // Scrollable form region.
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
                                              interval: _resetInterval(
                                                400,
                                                820,
                                              ),
                                              child: Text(
                                                'Set new password',
                                                textAlign: TextAlign.center,
                                                style: poppins(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                  color: kPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Instructions.
                                            entranceItem(
                                              index: 1,
                                              offset: const Offset(0, 0.12),
                                              interval: _resetInterval(
                                                500,
                                                920,
                                              ),
                                              child: Text(
                                                'Enter a new password for your '
                                                'account.',
                                                textAlign: TextAlign.center,
                                                style: openSans(
                                                  fontSize: 15,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            // Form.
                                            Form(
                                              key: _formKey,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  entranceItem(
                                                    index: 2,
                                                    offset: const Offset(
                                                      0,
                                                      0.12,
                                                    ),
                                                    interval: _resetInterval(
                                                      700,
                                                      1120,
                                                    ),
                                                    child: _textField(
                                                      controller:
                                                          _passwordController,
                                                      label: 'New Password',
                                                      obscureText:
                                                          _obscurePassword,
                                                      textInputAction:
                                                          TextInputAction.next,
                                                      suffixIcon: IconButton(
                                                        icon: Icon(
                                                          _obscurePassword
                                                              ? Icons
                                                                  .visibility_off
                                                              : Icons.visibility,
                                                          color: Colors.black45,
                                                        ),
                                                        onPressed: () =>
                                                            setState(() =>
                                                                _obscurePassword =
                                                                    !_obscurePassword),
                                                      ),
                                                      validator:
                                                          _validatePassword,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  entranceItem(
                                                    index: 3,
                                                    offset: const Offset(
                                                      0,
                                                      0.12,
                                                    ),
                                                    interval: _resetInterval(
                                                      900,
                                                      1320,
                                                    ),
                                                    child: _textField(
                                                      controller:
                                                          _confirmPasswordController,
                                                      label:
                                                          'Confirm New Password',
                                                      obscureText:
                                                          _obscureConfirm,
                                                      textInputAction:
                                                          TextInputAction.done,
                                                      onFieldSubmitted: (_) =>
                                                          _onSubmit(),
                                                      suffixIcon: IconButton(
                                                        icon: Icon(
                                                          _obscureConfirm
                                                              ? Icons
                                                                  .visibility_off
                                                              : Icons.visibility,
                                                          color: Colors.black45,
                                                        ),
                                                        onPressed: () =>
                                                            setState(() =>
                                                                _obscureConfirm =
                                                                    !_obscureConfirm),
                                                      ),
                                                      validator:
                                                          _validateConfirmPassword,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  entranceItem(
                                                    index: 4,
                                                    offset: const Offset(
                                                      0,
                                                      0.12,
                                                    ),
                                                    interval: _resetInterval(
                                                      1100,
                                                      1520,
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: _isLoading
                                                          ? null
                                                          : _onSubmit,
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            kPrimary,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                  vertical: 16,
                                                                ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            _inputRadius,
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
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            )
                                                          : Text(
                                                              'Update password',
                                                              style: poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Wrap(
                                              alignment: WrapAlignment.center,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  'Remembered your password?',
                                                  style: openSans(
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => Supabase
                                                      .instance
                                                      .client
                                                      .auth
                                                      .signOut(),
                                                  child: Text(
                                                    'Sign out',
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required FormFieldValidator<String> validator,
    bool obscureText = false,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    void Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onFieldSubmitted: onFieldSubmitted,
      style: openSans(),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: openSans(color: Colors.black54),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusInput),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusInput),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }
}
