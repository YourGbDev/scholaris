// lib/features/auth/presentation/signup_screen.dart
//
// Account creation against Supabase. Validates locally, signs up, then sends
// the user into the profile-setup wizard. All form state is local; no
// separate auth provider yet.
//
// V1 visual treatment (matches the login screen): a gently floating hero
// illustration fills the top ~45%, and a clean white rounded card (top
// corners radius 24) carries the form — Poppins Bold heading, Open Sans body,
// fields, and a pinned full-width Sign up CTA + log-in link so the primary
// actions stay reachable on short surfaces.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/app/confirmation_redirect.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';

const _inputRadius = 12.0;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// True while running inside a widget test
/// (`AutomatedTestWidgetsFlutterBinding` / `LiveTestWidgetsFlutterBinding`).
///
/// A repeating controller would keep the test harness's `pumpAndSettle` from
/// ever settling — the same gate the onboarding and login floats use. Real
/// app runs (debug, profile, release, web) always animate.
bool get _isWidgetTestBinding {
  final type = WidgetsBinding.instance.runtimeType.toString();
  return type == 'AutomatedTestWidgetsFlutterBinding' ||
      type == 'LiveTestWidgetsFlutterBinding';
}

/// Calm vertical float for the hero illustration: ±4px up/down on a 2.5s
/// easeInOut loop (8px peak-to-peak), forever. Reduced-motion aware — when
/// the platform requests reduced animations the illustration renders in its
/// settled (neutral) position with no motion at all.
class _FloatMotion extends StatefulWidget {
  const _FloatMotion({required this.child});

  final Widget child;

  @override
  State<_FloatMotion> createState() => _FloatMotionState();
}

class _FloatMotionState extends State<_FloatMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  );
  late final Animation<double> _dy = Tween<double>(
    begin: -4,
    end: 4,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce || _isWidgetTestBinding) {
      // Settled: park at the tween midpoint so the illustration is neutral.
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _dy.value), child: child),
      child: widget.child,
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin, EntranceMotionMixin<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'full_name': _fullNameController.text.trim()},
        emailRedirectTo: emailConfirmationRedirect,
      );

      if (!mounted) return;

      if (response.session == null) {
        // Email confirmation is enabled; the user must verify their inbox.
        // Send them to the dedicated screen so they can resend the link.
        context.go(
          '/verify-email?email=${Uri.encodeQueryComponent(_emailController.text.trim())}',
        );
        return;
      }
      context.go('/profile-setup/personal');
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(_snackBar(_friendlyError(error)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(AuthException error) {
    if (error.message.contains('already registered')) {
      return 'An account with this email already exists.';
    }
    return error.message;
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your full name.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email.';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    if (value != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  SnackBar _snackBar(String message) =>
      SnackBar(content: Text(message, style: GoogleFonts.openSans()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Clean white — the same V1 backdrop as the login screen.
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            // Split-screen: floating hero on top, white rounded card below.
            final heroHeight = viewport.maxHeight * 0.45;
            return Column(
              children: [
                // --- Top: floating hero illustration -------------------------
                SizedBox(
                  height: heroHeight,
                  width: double.infinity,
                  child: entranceItem(
                    index: 0,
                    child: _FloatMotion(
                      // Reuses the onboarding "Education" illustration —
                      // thematically right for joining a scholarship app.
                      child: SvgPicture.asset(
                        'assets/images/onboarding_slide2.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // --- Bottom: white rounded card ------------------------------
                Expanded(
                  child: Container(
                    // Deliberately a Container, not a Card — matches the
                    // login screen's V1 card treatment.
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      // Soft top shadow keeps the card distinct from the
                      // white hero area.
                      boxShadow: [
                        BoxShadow(
                          color: kCardShadow,
                          blurRadius: 24,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Column(
                      // When the card is taller than the form, the whole
                      // block (fields + actions) centers so leftover space
                      // never lands between the last field and the actions.
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Scrollable heading + fields region.
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Heading — Poppins Bold, brand green.
                                      entranceItem(
                                        index: 1,
                                        child: Text(
                                          'Create your account',
                                          textAlign: TextAlign.center,
                                          style: poppins(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: kPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      entranceItem(
                                        index: 2,
                                        child: _textField(
                                          controller: _fullNameController,
                                          label: 'Full Name',
                                          textInputAction: TextInputAction.next,
                                          validator: _validateFullName,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      entranceItem(
                                        index: 3,
                                        child: _textField(
                                          controller: _emailController,
                                          label: 'Email',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          validator: _validateEmail,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      entranceItem(
                                        index: 4,
                                        child: _textField(
                                          controller: _passwordController,
                                          label: 'Password',
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.next,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.black45,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                          ),
                                          validator: _validatePassword,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      entranceItem(
                                        index: 5,
                                        child: _textField(
                                          controller:
                                              _confirmPasswordController,
                                          label: 'Confirm Password',
                                          obscureText: _obscureConfirm,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _onSignUp(),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirm
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.black45,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscureConfirm =
                                                  !_obscureConfirm,
                                            ),
                                          ),
                                          validator: _validateConfirmPassword,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Pinned bottom cluster: the CTA stays on screen so
                        // short surfaces still expose the primary action.
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Full-width primary CTA, 24px gutters.
                                  entranceItem(
                                    index: 6,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _onSignUp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            _inputRadius,
                                          ),
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
                                              'Sign up',
                                              style: poppins(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  entranceItem(
                                    index: 7,
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account?',
                                          style: openSans(
                                            color: Colors.black54,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => context.go('/login'),
                                          child: Text(
                                            'Log in',
                                            style: poppins(
                                              color: kPrimary,
                                              fontWeight: FontWeight.w600,
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
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
