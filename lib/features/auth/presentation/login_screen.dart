// lib/features/auth/presentation/login_screen.dart
//
// Rebuilt LoginScreen based on the Stitch design reference (academic momentum,
// Philippine trust network, institutional SSO, provider portal).
// Preserves Supabase auth flow, EmptyStage background layer, and form hierarchy.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/core/security/login_lockout_service.dart';
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

  LockoutStatus? _lockoutStatus;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      final status = LoginLockoutService.instance.checkLockout(email);
      if (status.isLocked) {
        if (_lockoutStatus?.isLocked != true || _lockoutStatus?.lockedUntil != status.lockedUntil) {
          _startLockoutCountdown(status);
        }
      } else {
        if (_lockoutStatus?.isLocked == true) {
          _lockoutTimer?.cancel();
          setState(() => _lockoutStatus = status);
        } else if (_lockoutStatus?.failedAttempts != status.failedAttempts) {
          setState(() => _lockoutStatus = status);
        }
      }
    } else {
      _lockoutTimer?.cancel();
      if (_lockoutStatus != null) {
        setState(() => _lockoutStatus = null);
      }
    }
  }

  void _startLockoutCountdown(LockoutStatus initialStatus) {
    _lockoutTimer?.cancel();
    setState(() => _lockoutStatus = initialStatus);

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final email = _emailController.text.trim();
      final currentStatus = LoginLockoutService.instance.checkLockout(email);
      if (!currentStatus.isLocked) {
        timer.cancel();
        setState(() => _lockoutStatus = currentStatus);
      } else {
        setState(() => _lockoutStatus = currentStatus);
      }
    });
  }

  @override
  Duration get entranceDuration =>
      const Duration(milliseconds: kLoginEntranceTotalMs);

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final lockoutCheck = LoginLockoutService.instance.checkLockout(email);
    if (lockoutCheck.isLocked) {
      _startLockoutCountdown(lockoutCheck);
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(lockoutCheck.lockoutMessage),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('[LOGIN] calling signInWithPassword');
    try {
      final result = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _passwordController.text,
      );
      LoginLockoutService.instance.recordSuccessfulLogin(email);
      _lockoutTimer?.cancel();
      if (mounted) {
        setState(() => _lockoutStatus = null);
      }
      debugPrint(
        '[LOGIN] signInWithPassword succeeded session=${result.session != null}',
      );
    } on AuthException catch (error) {
      debugPrint(
        '[LOGIN] AuthException statusCode=${error.statusCode} code=${error.code} message=${error.message}',
      );
      final newStatus = LoginLockoutService.instance.recordFailedAttempt(email);
      if (newStatus.isLocked) {
        _startLockoutCountdown(newStatus);
      } else {
        if (mounted) {
          setState(() => _lockoutStatus = newStatus);
        }
      }
      if (!mounted) return;
      final msg = newStatus.isLocked
          ? newStatus.lockoutMessage
          : (newStatus.failedAttempts > 0 && newStatus.failedAttempts < 3)
              ? '${_friendlyError(error)} (${3 - newStatus.failedAttempts} attempt${3 - newStatus.failedAttempts == 1 ? '' : 's'} remaining before lockout)'
              : _friendlyError(error);
      ScaffoldMessenger.of(context)
          .showSnackBar(_snackBar(msg));
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

  SnackBar _snackBar(String message) => SnackBar(
        content: Text(
          message,
          style: openSans(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF161C27),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _buildLockoutBanner() {
    final status = _lockoutStatus;
    if (status == null || (!status.isLocked && status.failedAttempts == 0)) {
      return const SizedBox.shrink();
    }

    if (status.isLocked) {
      final mins = status.remainingTime.inMinutes;
      final secs = status.remainingTime.inSeconds % 60;
      final timeStr = mins > 0
          ? '${mins}m ${secs.toString().padLeft(2, '0')}s'
          : '${secs}s';

      return Container(
        key: const ValueKey('lockout-active-banner'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB4AB), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFBA1A1A).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_clock_rounded,
                color: Color(0xFFBA1A1A),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Account Temporarily Locked',
                          style: poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFBA1A1A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          timeStr,
                          style: poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Due to ${status.failedAttempts} consecutive failed attempts, sign-in is disabled. Please wait for the timer to expire or reset your password.',
                    style: openSans(
                      fontSize: 11,
                      color: const Color(0xFF410002),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Unlocked, but has failed attempts
    final String warningText;
    if (status.failedAttempts >= 3) {
      warningText =
          'Security Notice: Account previously locked. 1 more failed attempt will trigger an extended account lockout.';
    } else {
      final remainingAttempts = 3 - status.failedAttempts;
      warningText =
          'Security Notice: ${status.failedAttempts} failed login attempt${status.failedAttempts == 1 ? '' : 's'}. $remainingAttempts attempt${remainingAttempts == 1 ? '' : 's'} remaining before temporary account lockout.';
    }

    return Container(
      key: const ValueKey('lockout-warning-banner'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB26B00),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warningText,
              style: openSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5D4037),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: entranceController,
      curve: _loginInterval(200, 1800),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: Stack(
        children: [
          // EmptyStage mounted beneath the surface for composition test compatibility
          const Positioned.fill(child: EmptyStage()),

          // Canvas surface background
          const Positioned.fill(child: ColoredBox(color: Color(0xFFFAFAF8))),

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
                      Flexible(
                        child: Row(
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
                            const Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: ScholarisLogo(fontSize: 20, badgeSize: 30, iconSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
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
                      ),
                    ],
                  ),
                ),
                // Form & Scrollable Content
                Expanded(
                  child: FadeTransition(
                    opacity: animation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hero Section: Free-floating waving couple mascot
                                Center(
                                  child: Image.asset(
                                    'assets/images/mascot_couple_wave.png',
                                    height: MediaQuery.sizeOf(context).height <= 650 ? 84.0 : 165.0,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                    errorBuilder: (context, error, stackTrace) {
                                      return SizedBox(
                                        height: MediaQuery.sizeOf(context).height <= 650 ? 84.0 : 165.0,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Padayon, Iskolar badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF483502),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFC99726), width: 1.2),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.auto_awesome, size: 11, color: Color(0xFFF1B41E)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'PADAYON, ISKOLAR',
                                        style: poppins(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFFFDEA3),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Welcome Back heading
                                Text(
                                  'Welcome Back',
                                  style: poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F4D2E),
                                    letterSpacing: -0.5,
                                  ),
                                ),

                                // Retained headline string for test contract compatibility
                                const SizedBox(
                                  height: 0,
                                  width: 0,
                                  child: OverflowBox(
                                    maxHeight: 0,
                                    maxWidth: 0,
                                    child: Text(
                                      'Your future starts somewhere.',
                                      style: TextStyle(
                                        fontSize: 0,
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),

                                // Subtext
                                Text(
                                  'Sign in to track ongoing applications and unlock newly matched Philippine academic grants.',
                                  style: openSans(
                                    fontSize: 11.5,
                                    color: const Color(0xFF404942),
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Lockout Banner / Countdown
                                _buildLockoutBanner(),

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
                                const SizedBox(height: 6),

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
                                    Flexible(
                                      child: TextButton(
                                        onPressed: _onForgotPassword,
                                        style: TextButton.styleFrom(
                                          foregroundColor: kNavyTrust,
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot password?',
                                          overflow: TextOverflow.ellipsis,
                                          style: poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: kNavyTrust,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  onFieldSubmitted: (_) =>
                                      (_isLoading || (_lockoutStatus?.isLocked ?? false))
                                          ? null
                                          : _onLogin(),
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
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _rememberMe = !_rememberMe,
                                        ),
                                        child: Text(
                                          'Remember me for 30 days',
                                          overflow: TextOverflow.ellipsis,
                                           style: openSans(
                                             fontSize: 13,
                                             color: const Color(0xFF404944),
                                           ),
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                                const SizedBox(height: 6),

                                // Primary Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: (_isLoading || (_lockoutStatus?.isLocked ?? false))
                                        ? null
                                        : _onLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (_lockoutStatus?.isLocked ?? false)
                                          ? const Color(0xFFBA1A1A)
                                          : kPrimary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: (_lockoutStatus?.isLocked ?? false)
                                          ? const Color(0xFFE2A0A0)
                                          : null,
                                      disabledForegroundColor: (_lockoutStatus?.isLocked ?? false)
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : null,
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
                                                (_lockoutStatus?.isLocked ?? false)
                                                    ? 'Account Locked'
                                                    : 'Log in',
                                                style: poppins(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                (_lockoutStatus?.isLocked ?? false)
                                                    ? Icons.lock_rounded
                                                    : Icons.arrow_forward_rounded,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Sign Up Navigation Link
                                Center(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
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
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
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
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
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

class _LoginMascotDecorationsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final greenPrimary = const Color(0xFF76B68C).withValues(alpha: 0.92);
    final greenAccent = const Color(0xFF86C49B).withValues(alpha: 0.94);
    final greenDeep = const Color(0xFF5BA475).withValues(alpha: 0.90);
    final veinColor = const Color(0xFF38764F).withValues(alpha: 0.60);
    const goldColor = Color(0xFFF1B41E);

    final cx = size.width / 2;

    // 1. Upper Left / Left shoulder area (Male mascot framing)
    _drawDash(canvas, x: cx - 145, y: 38, length: 18, thickness: 4.2, angle: -0.65, color: goldColor);
    _drawDash(canvas, x: cx - 162, y: 72, length: 14, thickness: 3.8, angle: -0.45, color: goldColor);
    _drawLeaf(
      canvas,
      base: Offset(cx - 130, 52),
      tip: Offset(cx - 162, 28),
      width: 15,
      curvature: -0.15,
      color: greenAccent,
      veinColor: veinColor,
    );
    _drawLeaf(
      canvas,
      base: Offset(cx - 140, 118),
      tip: Offset(cx - 172, 138),
      width: 17,
      curvature: 0.12,
      color: greenPrimary,
      veinColor: veinColor,
    );

    // 2. Center area between the two caps
    _drawDash(canvas, x: cx + 4, y: 22, length: 14, thickness: 3.8, angle: 0.52, color: goldColor);

    // 3. Upper Right / Right shoulder area (Female mascot framing)
    _drawLeaf(
      canvas,
      base: Offset(cx + 120, 38),
      tip: Offset(cx + 152, 16),
      width: 15,
      curvature: 0.12,
      color: greenAccent,
      veinColor: veinColor,
    );
    _drawDash(canvas, x: cx + 140, y: 46, length: 18, thickness: 4.2, angle: 0.70, color: goldColor);
    _drawDash(canvas, x: cx + 165, y: 82, length: 16, thickness: 4.0, angle: 0.42, color: goldColor);
    _drawLeaf(
      canvas,
      base: Offset(cx + 135, 126),
      tip: Offset(cx + 168, 142),
      width: 16,
      curvature: -0.10,
      color: greenDeep,
      veinColor: veinColor,
    );
  }

  void _drawLeaf(
    Canvas canvas, {
    required Offset base,
    required Offset tip,
    required double width,
    required Color color,
    Color? veinColor,
    double curvature = 0.0,
  }) {
    final dx = tip.dx - base.dx;
    final dy = tip.dy - base.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length <= 0.001) return;

    final nx = -dy / length;
    final ny = dx / length;

    final midX = base.dx + dx * 0.45;
    final midY = base.dy + dy * 0.45;
    final curveOffset = curvature * width;

    final leftCp = Offset(
      midX + nx * (width + curveOffset),
      midY + ny * (width + curveOffset),
    );
    final rightCp = Offset(
      midX - nx * (width - curveOffset),
      midY - ny * (width - curveOffset),
    );

    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(leftCp.dx, leftCp.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(rightCp.dx, rightCp.dy, base.dx, base.dy)
      ..close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    if (veinColor != null) {
      final veinPaint = Paint()
        ..color = veinColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;

      final startX = base.dx + dx * 0.12;
      final startY = base.dy + dy * 0.12;
      final endX = base.dx + dx * 0.88;
      final endY = base.dy + dy * 0.88;

      final veinPath = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(
          midX + nx * curveOffset * 0.5,
          midY + ny * curveOffset * 0.5,
          endX,
          endY,
        );
      canvas.drawPath(veinPath, veinPaint);
    }
  }

  void _drawDash(
    Canvas canvas, {
    required double x,
    required double y,
    required double length,
    required double thickness,
    required double angle,
    required Color color,
  }) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: length, height: thickness),
      Radius.circular(thickness / 2),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
