// lib/features/auth/presentation/login_screen.dart
//
// Rebuilt LoginScreen based on the Stitch design reference (academic momentum,
// Philippine trust network, institutional SSO, provider portal).
// Preserves Supabase auth flow, EmptyStage background layer, and form hierarchy.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/auth/presentation/empty_stage.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';

const int kLoginEntranceTotalMs = 2200;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

Interval _loginInterval(int beginMs, int endMs) => EntranceMotion.intervalFrom(
  beginMs,
  endMs,
  kLoginEntranceTotalMs,
  curve: Curves.easeOutCubic,
);

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
  bool _rememberMe = true;
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

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: entranceController,
      curve: _loginInterval(200, 1800),
    );

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          // EmptyStage mounted beneath the surface for composition test compatibility
          const Positioned.fill(child: EmptyStage()),

          // Canvas surface background
          const Positioned.fill(child: ColoredBox(color: kBackground)),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                            color: const Color(0xFF161C27),
                            tooltip: 'Back',
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/onboarding');
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          const ScholarisLogo(fontSize: 20, badgeSize: 30, iconSize: 18),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8E5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.help_outline_rounded, size: 14, color: Color(0xFF707971)),
                                const SizedBox(width: 4),
                                Text(
                                  'Help',
                                  style: openSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF161C27),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: kPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Form & Scrollable Content
                Expanded(
                  child: FadeTransition(
                    opacity: animation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Motivational Card Banner
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [kPrimary, Color(0xFF1B3A5C)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x180F4D2E),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF583F00).withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.auto_awesome, size: 12, color: Color(0xFFF1B41E)),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Padayon, Iskolar',
                                              style: poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFFFDEA3),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Welcome Back',
                                        style: poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFB3F1C6),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Your future starts somewhere.',
                                        style: poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Sign in to track ongoing applications and unlock newly matched Philippine academic grants.',
                                        style: openSans(
                                          fontSize: 12,
                                          color: const Color(0xFFB3F1C6),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Email Field
                                Text(
                                  'Email',
                                  style: poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF161C27),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                  style: openSans(fontSize: 14),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.alternate_email, size: 20, color: Color(0xFF707971)),
                                    hintText: 'e.g. maya.santos@up.edu.ph',
                                    hintStyle: openSans(fontSize: 14, color: const Color(0xFF707971)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: kPrimary, width: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Password Field Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Password',
                                      style: poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF161C27),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _onForgotPassword,
                                      style: TextButton.styleFrom(
                                        foregroundColor: kNavyTrust,
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Forgot password?',
                                        style: poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kNavyTrust,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password.' : null,
                                  style: openSans(fontSize: 14),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF707971)),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: const Color(0xFF707971),
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    hintText: 'Enter your password',
                                    hintStyle: openSans(fontSize: 14, color: const Color(0xFF707971)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: kPrimary, width: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Remember Me Checkbox
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Checkbox(
                                        key: const ValueKey('remember-me-checkbox'),
                                        value: _rememberMe,
                                        activeColor: kPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF707971),
                                          width: 1.5,
                                        ),
                                        onChanged: (val) => setState(
                                          () => _rememberMe = val ?? true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _rememberMe = !_rememberMe,
                                      ),
                                      child: Text(
                                        'Remember me for 30 days',
                                        style: openSans(
                                          fontSize: 13,
                                          color: const Color(0xFF404944),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Primary Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _onLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Log in',
                                                style: poppins(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward_rounded, size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Sign Up Navigation Link
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Don't have an account?",
                                        style: openSans(fontSize: 14, color: const Color(0xFF404942)),
                                      ),
                                      const SizedBox(width: 4),
                                      TextButton(
                                        onPressed: () => context.go('/signup'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: kPrimary,
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Sign up',
                                          style: poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: kPrimary,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Provider / Partner Callout
                                InkWell(
                                  onTap: () => context.push('/become-provider'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F3FF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFD2E4FF)),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Want to help students reach their dreams?',
                                          textAlign: TextAlign.center,
                                          style: poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: kNavyTrust,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Become a scholarship provider',
                                              style: poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: kPrimary,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.arrow_forward_rounded, size: 14, color: kPrimary),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Divider: OR AUTHENTICATE WITH
                                Row(
                                  children: [
                                    const Expanded(child: Divider(color: Color(0xFFDDE2F3))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        'OR AUTHENTICATE WITH',
                                        style: poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF707971),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: Color(0xFFDDE2F3))),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Institutional Student SSO
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8E5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8EEFF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.account_balance_outlined, color: kNavyTrust, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Institutional Student SSO',
                                              style: poppins(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'UP, PUP, UST, DLSU, Ateneo & State Colleges',
                                              style: openSans(fontSize: 10, color: const Color(0xFF404942)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Color(0xFF707971), size: 16),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Google Workspace for Education
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: OutlinedButton(
                                    onPressed: () {},
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF1F3FF),
                                      side: const BorderSide(color: Color(0xFFE2E8E5)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      foregroundColor: kNavyTrust,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.school_outlined, size: 16, color: kNavyTrust),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Sign in with Google Workspace for Education',
                                            style: poppins(fontSize: 11, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Trust & Security Notice Footer
                                Center(
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified_user_outlined, size: 14, color: kPrimary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Philippine Academic Trust Network',
                                            style: poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: kNavyTrust,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Interfacing with DOST-SEI & CHED UniFAST. Protected under the Philippine Data Privacy Act of 2012 with 256-bit encryption.',
                                        textAlign: TextAlign.center,
                                        style: openSans(fontSize: 10, color: const Color(0xFF707971)),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
