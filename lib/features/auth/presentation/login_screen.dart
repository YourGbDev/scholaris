// lib/features/auth/presentation/login_screen.dart
//
// Split-screen login: a looping login_hero Lottie animation fills the top
// ~45%, and a clean white rounded card (top corners radius 24) slides up from
// the bottom carrying the form — Welcome Back title, subtitle, email/password
// fields, forgot-password link, Log in button, sign-up link and the provider
// CTA.
//
// The empty graduation stage stays mounted beneath the surface (the ceremony
// → login handoff and its tests keep seeing it) but is painted over by the
// neutral white cover.
//
// All authentication logic (validation, Supabase sign-in, error handling,
// forgot-password navigation, signup navigation) is preserved from the
// previous implementation. Only the visual composition and entrance
// choreography have changed.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/auth/presentation/empty_stage.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';

// --- Tokens ----------------------------------------------------------------

/// Total entrance duration for the login screen's staggered reveal.
/// Matches the ~2.2s timeline in the spec.
const int kLoginEntranceTotalMs = 2200;

const _inputRadius = 12.0;
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// --- Entrance timeline helpers ---------------------------------------------

/// Builds an [Interval] for an entrance element that starts at [beginMs] and
/// ends at [endMs] within the login's total duration [kLoginEntranceTotalMs].
Interval _loginInterval(int beginMs, int endMs) => EntranceMotion.intervalFrom(
  beginMs,
  endMs,
  kLoginEntranceTotalMs,
  curve: Curves.easeOutCubic,
);

// --- Screen ----------------------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with
        TickerProviderStateMixin<LoginScreen>,
        EntranceMotionMixin<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Duration get entranceDuration =>
      const Duration(milliseconds: kLoginEntranceTotalMs);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    debugPrint('[LOGIN] calling signInWithPassword');
    try {
      final result = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      debugPrint(
        '[LOGIN] signInWithPassword succeeded session=${result.session != null}',
      );
    } on AuthException catch (error) {
      debugPrint(
        '[LOGIN] AuthException statusCode=${error.statusCode} code=${error.code} message=${error.message}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(_snackBar(_friendlyError(error)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onForgotPassword() {
    context.go('/forgot-password');
  }

  String _friendlyError(AuthException error) {
    if (error.message.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (error.message.contains('Email not confirmed') ||
        error.message.contains('email_not_confirmed')) {
      return 'Your email has not been confirmed yet. Check your inbox, or '
          'request a new link.';
    }
    return error.message;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email.';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  SnackBar _snackBar(String message) =>
      SnackBar(content: Text(message, style: GoogleFonts.openSans()));

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Clean white — matches the onboarding slides, not the warm off-white.
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Full-bleed empty stage environment. Kept mounted (the ceremony
          // handoff and composition tests rely on it) but hidden behind the
          // neutral cover below so the login surface reads clean white.
          const Positioned.fill(child: EmptyStage()),

          // Neutral cover: paints over the stage's warm cream/gold tones.
          const Positioned.fill(child: ColoredBox(color: Colors.white)),

          // Split-screen content: hero illustration on top, white card
          // (rounded at the top) below.
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  // Responsive split: hero takes ~40% on tall screens, but
                  // shrinks further on short viewports so the card always
                  // has room for the form without immediate scrolling.
                  // 380px is the minimum card height needed to show title,
                  // both fields, the primary button, and secondary actions
                  // without scrolling on the smallest supported phones.
                  final heroHeight = (viewport.maxHeight * 0.40)
                      .clamp(180.0, viewport.maxHeight - 400);
                  return Column(
                    children: [
                      // --- Top: hero Lottie animation --------------------------
                      SizedBox(
                        height: heroHeight,
                        width: double.infinity,
                        child: entranceItem(
                          index: 0,
                          offset: const Offset(0, 0.08),
                          interval: _loginInterval(200, 1000),
                          // The Lottie file has built-in looping motion (49
                          // animated properties), so no float wrapper —
                          // stacking the ±4px breathing on top would
                          // double-animate. Frozen on its first frame for
                          // reduced-motion users and in widget tests.
                          child: Lottie.asset(
                            'assets/animations/Sign up.json',
                            fit: BoxFit.contain,
                            animate:
                                !(MediaQuery.maybeOf(context)
                                        ?.disableAnimations ??
                                    false) &&
                                !_isWidgetTestBinding,
                          ),
                        ),
                      ),

                      // --- Bottom: white rounded card ---------------------------
                      Expanded(
                        child: entranceItem(
                          index: 1,
                          offset: const Offset(0, 0.25),
                          interval: _loginInterval(200, 1000),
                          child: Container(
                            // Deliberately a Container, not a Card: the login
                            // composition tests assert no Card wraps the form.
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              // Soft top shadow keeps the card distinct from
                              // the white hero area.
                              boxShadow: [
                                BoxShadow(
                                  color: kCardShadow,
                                  blurRadius: 24,
                                  offset: const Offset(0, -6),
                                ),
                              ],
                            ),
                            child: Column(
                              // When the card is taller than the form, the
                              // whole block (fields + actions) centers so the
                              // leftover space never lands between the last
                              // field and the actions below it.
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // Scrollable heading + fields region.
                                // Shrink-wraps to its content when the card is
                                // tall (Flexible, not Expanded) — otherwise the
                                // slack would open a large gap between the
                                // password field and the pinned cluster below.
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
                                            // 0. Welcome Back title
                                            entranceItem(
                                              index: 0,
                                              offset: const Offset(0, 0.12),
                                              interval: _loginInterval(
                                                400,
                                                820,
                                              ),
                                              child: Text(
                                                'Welcome Back',
                                                textAlign: TextAlign.center,
                                                style: poppins(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                  color: kPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // 1. Subtitle
                                            entranceItem(
                                              index: 1,
                                              offset: const Offset(0, 0.12),
                                              interval: _loginInterval(
                                                500,
                                                920,
                                              ),
                                              child: Text(
                                                'Your future starts '
                                                'somewhere.',
                                                textAlign: TextAlign.center,
                                                style: openSans(
                                                  fontSize: 15,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),

                                            // The form wraps only the two
                                            // fields; validation stays intact.
                                            Form(
                                              key: _formKey,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  // 2. Email
                                                  entranceItem(
                                                    index: 2,
                                                    offset: const Offset(
                                                      0,
                                                      0.12,
                                                    ),
                                                    interval: _loginInterval(
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
                                                      validator: _validateEmail,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),

                                                  // 3. Password
                                                  entranceItem(
                                                    index: 3,
                                                    offset: const Offset(
                                                      0,
                                                      0.12,
                                                    ),
                                                    interval: _loginInterval(
                                                      900,
                                                      1320,
                                                    ),
                                                    child: _textField(
                                                      controller:
                                                          _passwordController,
                                                      label: 'Password',
                                                      obscureText:
                                                          _obscurePassword,
                                                      textInputAction:
                                                          TextInputAction.done,
                                                      onFieldSubmitted: (_) =>
                                                          _onLogin(),
                                                      suffixIcon: IconButton(
                                                        icon: Icon(
                                                          _obscurePassword
                                                              ? Icons
                                                                    .visibility_off
                                                              : Icons
                                                                    .visibility,
                                                          color: Colors.black45,
                                                        ),
                                                        onPressed: () => setState(
                                                          () => _obscurePassword =
                                                              !_obscurePassword,
                                                        ),
                                                      ),
                                                      validator: (value) =>
                                                          (value == null ||
                                                              value.isEmpty)
                                                          ? 'Enter your '
                                                                'password.'
                                                          : null,
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
                                // Capped spacer between form and bottom actions.
                                // Keeps the gap reasonable on tall viewports
                                // without pushing content below the fold.
                                const SizedBox(height: 24),
                                // Pinned bottom cluster: forgot link, Log in
                                // button, sign-up link, provider CTA. Always
                                // on screen so short surfaces still expose the
                                // primary actions.
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
                                        16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // 4. Forgot password
                                          entranceItem(
                                            index: 4,
                                            offset: const Offset(0, 0.12),
                                            interval: _loginInterval(
                                              1100,
                                              1520,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton(
                                                onPressed: _onForgotPassword,
                                                child: Text(
                                                  'Forgot password?',
                                                  style: poppins(
                                                    fontWeight: FontWeight.w600,
                                                    color: kPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),

                                          // 5. Log in button
                                          entranceItem(
                                            index: 5,
                                            offset: const Offset(0, 0.12),
                                            interval: _loginInterval(
                                              1300,
                                              1720,
                                            ),
                                            child: ElevatedButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _onLogin,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: kPrimary,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
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
                                                      'Log in',
                                                      style: poppins(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),

                                          // 6. Don't have an account? Sign up
                                          entranceItem(
                                            index: 6,
                                            offset: const Offset(0, 0.12),
                                            interval: _loginInterval(
                                              1500,
                                              1920,
                                            ),
                                            child: Wrap(
                                              alignment: WrapAlignment.center,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  "Don't have an account?",
                                                  style: openSans(
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      context.push('/signup'),
                                                  child: Text(
                                                    'Sign up',
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
                                          const SizedBox(height: 12),

                                          // 7. Provider CTA (visual
                                          // affordance only — no navigation)
                                          entranceItem(
                                            index: 7,
                                            offset: const Offset(0, 0.12),
                                            interval: _loginInterval(
                                              1700,
                                              2120,
                                            ),
                                            child: _buildProviderCta(),
                                          ),
                                        ],
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

  /// Quiet, secondary visual affordance for scholarship providers. This is a
  /// static visual element only — it does not navigate, does not invoke any
  /// provider logic, and has no tap handler.
  Widget _buildProviderCta() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Want to help students reach their dreams?',
            textAlign: TextAlign.center,
            style: openSans(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Become a scholarship provider',
                  style: poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 14, color: kPrimary),
              ],
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
      style: GoogleFonts.openSans(),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.openSans(color: Colors.black54),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
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
///
/// The login hero Lottie loops forever; a repeating animation would keep the
/// test harness's `pumpAndSettle` from ever settling — it only stops when no
/// frame is scheduled. Freezing the hero there keeps the widget tests fast
/// and deterministic; real app runs (debug, profile, release, web) always
/// animate.
bool get _isWidgetTestBinding {
  final type = WidgetsBinding.instance.runtimeType.toString();
  return type == 'AutomatedTestWidgetsFlutterBinding' ||
      type == 'LiveTestWidgetsFlutterBinding';
}
