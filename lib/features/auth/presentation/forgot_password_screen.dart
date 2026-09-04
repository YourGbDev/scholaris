// lib/features/auth/presentation/forgot_password_screen.dart
//
// Requests a password-reset email against Supabase. The recovery link the user
// receives opens the app (via a configured deep link) and establishes a
// password-recovery session, which the auth boundary turns into recovery mode
// so the router sends the user to the set-new-password screen. All form state
// is local to this screen.
//
// Visual treatment matches the login/signup screens: a looping Lottie hero
// fills the top ~45%, and a clean white rounded card carries the form.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/app/recovery_redirect.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';

// --- Tokens ----------------------------------------------------------------

/// Total entrance duration for the forgot-password screen's staggered reveal.
const int kForgotEntranceTotalMs = 2200;

const _inputRadius = 12.0;
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// --- Entrance timeline helpers ---------------------------------------------

Interval _forgotInterval(int beginMs, int endMs) => EntranceMotion.intervalFrom(
      beginMs,
      endMs,
      kForgotEntranceTotalMs,
      curve: Curves.easeOutCubic,
    );

// --- Screen ----------------------------------------------------------------

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with
        TickerProviderStateMixin<ForgotPasswordScreen>,
        EntranceMotionMixin<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  Duration get entranceDuration =>
      const Duration(milliseconds: kForgotEntranceTotalMs);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: resetPasswordRedirect,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(
          'If an account exists for that email, a password reset link is on '
          'its way.',
        ),
      );
      context.go('/login');
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
    if (error.message.contains('User not found')) {
      return 'No account found for that email.';
    }
    return error.message;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email.';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  SnackBar _snackBar(String message) => SnackBar(
        content: Text(message, style: openSans()),
      );

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          // Full-bleed Lottie hero fills the top ~45%.
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  final heroHeight = viewport.maxHeight * 0.45;
                  return Column(
                    children: [
                      SizedBox(
                        height: heroHeight,
                        width: double.infinity,
                        child: entranceItem(
                          index: 0,
                          offset: const Offset(0, 0.08),
                          interval: _forgotInterval(200, 1000),
                          child: Lottie.asset(
                            'assets/animations/Forgot password.json',
                            fit: BoxFit.contain,
                            animate:
                                !(MediaQuery.maybeOf(context)
                                        ?.disableAnimations ??
                                    false) &&
                                !_isWidgetTestBinding,
                          ),
                        ),
                      ),
                      // White rounded card below.
                      Expanded(
                        child: entranceItem(
                          index: 1,
                          offset: const Offset(0, 0.25),
                          interval: _forgotInterval(200, 1000),
                          child: Container(
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
                                              interval: _forgotInterval(
                                                400,
                                                820,
                                              ),
                                              child: Text(
                                                'Forgot Password?',
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
                                              interval: _forgotInterval(
                                                500,
                                                920,
                                              ),
                                              child: Text(
                                                'Enter the email you registered '
                                                'with and we’ll send you a link '
                                                'to set a new password.',
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
                                                    interval: _forgotInterval(
                                                      700,
                                                      1120,
                                                    ),
                                                    child: _textField(
                                                      controller:
                                                          _emailController,
                                                      label: 'Email',
                                                      keyboardType:
                                                          TextInputType
                                                              .emailAddress,
                                                      textInputAction:
                                                          TextInputAction.next,
                                                      validator:
                                                          _validateEmail,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  entranceItem(
                                                    index: 3,
                                                    offset: const Offset(
                                                      0,
                                                      0.12,
                                                    ),
                                                    interval: _forgotInterval(
                                                      900,
                                                      1320,
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: _isLoading
                                                          ? null
                                                          : _onSubmit,
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor: kPrimary,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                  vertical: 16,
                                                                ),
                                                        shape: RoundedRectangleBorder(
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
                                                                color: Colors.white,
                                                              ),
                                                            )
                                                          : Text(
                                                              'Send reset link',
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
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Pinned bottom actions.
                                Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 420,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        4,
                                        24,
                                        20,
                                      ),
                                      child: entranceItem(
                                        index: 4,
                                        offset: const Offset(0, 0.12),
                                        interval: _forgotInterval(
                                          1500,
                                          1920,
                                        ),
                                        child: Wrap(
                                          alignment:
                                              WrapAlignment.center,
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
                                              onPressed: () =>
                                                  context.go('/login'),
                                              child: Text(
                                                'Log in',
                                                style: poppins(
                                                  color: kPrimary,
                                                  fontWeight:
                                                      FontWeight.w600,
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
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Back arrow — pinned to the top-left above the hero.
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: entranceItem(
                index: 5,
                offset: const Offset(0, 0.12),
                interval: _forgotInterval(200, 800),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => context.go('/login'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Shared text field builder -------------------------------------------

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required FormFieldValidator<String> validator,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onFieldSubmitted: onFieldSubmitted,
      style: openSans(),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: openSans(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }
}

/// True while running inside a widget test
/// (`AutomatedTestWidgetsFlutterBinding` / `LiveTestWidgetsFlutterBinding`).
bool get _isWidgetTestBinding {
  final type = WidgetsBinding.instance.runtimeType.toString();
  return type == 'AutomatedTestWidgetsFlutterBinding' ||
      type == 'LiveTestWidgetsFlutterBinding';
}
