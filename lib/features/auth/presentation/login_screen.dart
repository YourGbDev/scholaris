import 'package:scholaris/shared/widgets/greeting_mascot.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import 'session_entry_status.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:scholaris/app/landing_config.dart';
import 'package:scholaris/core/security/login_lockout_service.dart';
import 'package:scholaris/core/security/captcha_challenge.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';

final loginCaptchaProvider = Provider((ref) => acquireCaptcha);

const int kLoginEntranceTotalMs = 200;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.showProviderCta});

  /// Override for testing or explicit host configuration.
  /// When null, defaults to [isProviderCtaVisible].
  final bool? showProviderCta;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with
        TickerProviderStateMixin<LoginScreen>,
        EntranceMotionMixin<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  int _loginEpoch = 0;

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
        if (_lockoutStatus?.isLocked != true ||
            _lockoutStatus?.lockedUntil != status.lockedUntil) {
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
    if (_isLoading || !_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final epoch = _loginEpoch;
    final lockoutCheck = await LoginLockoutService.instance.checkLockoutRemote(
      email,
    );
    if (!mounted) return;
    if (lockoutCheck.isLocked) {
      _startLockoutCountdown(lockoutCheck);
      ScaffoldMessenger.of(context)
          .showSnackBar(_snackBar(lockoutCheck.lockoutMessage));
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('[LOGIN] calling signInWithPassword');
    try {
      final captcha = await ref.read(loginCaptchaProvider)(context);
      if (!mounted || epoch != _loginEpoch || !captcha.allowed) return;
      final result = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
        captchaToken: captcha.token,
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
      if (!mounted || epoch != _loginEpoch) return;
      if (error.message.contains('Email not confirmed') ||
          error.message.contains('email_not_confirmed')) {
        if (!mounted) return;
        final email = _emailController.text.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar(
            'Your email has not been confirmed yet. Enter the verification code sent to your email.',
          ),
        );
        context.go('/verify-email?email=${Uri.encodeQueryComponent(email)}');
        return;
      }
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
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(msg));
    } catch (_) {
      if (!mounted || epoch != _loginEpoch) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar('Could not complete the security check. Please try again.'),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onForgotPassword() {
    context.go('/forgot-password');
  }

  bool get _shouldShowProviderCta =>
      widget.showProviderCta ?? isProviderCtaVisible;

  Future<void> _openProviderPortal() async {
    final uri = providerLandingUri;
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      } catch (e) {
        debugPrint('Could not launch provider portal URL: $e');
      }
    }
    if (kIsWeb) {
      if (!mounted) return;
      context.push('/become-provider');
    }
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
    content: Text(message, style: geist(color: Colors.white, fontSize: 13)),
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
                          style: geist(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFBA1A1A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          timeStr,
                          style: geist(
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
                    style: geist(
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
      warningText = 'Security Notice: Account previously locked. 1 more failed attempt will trigger an extended account lockout.';
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
              style: geist(
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

  InputDecoration _fieldDecoration(
    String label,
    String hint, {
    Widget? suffix,
  }) => InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: geist(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
    ),
    hintText: hint,
    hintStyle: geist(fontSize: 14, color: kTextSecondary),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFCDD5CF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFCDD5CF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimary, width: 1.5),
    ),
    errorStyle: geist(fontSize: 12, color: const Color(0xFFBA1A1A)),
    errorMaxLines: 3,
  );

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (_, _) => _loginEpoch++);
    final session = ref.watch(authSessionProvider);
    if (session != null && !session.passwordRecovery) {
      return const SessionEntryStatus();
    }
    final locked = _lockoutStatus?.isLocked ?? false;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (entranceController.isAnimating) entranceController.value = 1.0;
        },
        child: SafeArea(
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/onboarding');
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        const Flexible(child: ScholarisLogo(compact: true)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AppleBouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: KeyedSubtree(
                        key: const ValueKey('login-form-entrance'),
                        child: entranceItem(
                          index: 0,
                          interval: const Interval(
                            0,
                            1,
                            curve: Curves.easeOutCubic,
                          ),
                          offset: const Offset(0, 0.012),
                          child: AutofillGroup(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: MascotWelcomePair(
                                      key: const ValueKey('login-mascot-pair'),
                                      height:
                                          MediaQuery.sizeOf(context).height <
                                              650
                                          ? 120
                                          : 168,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Welcome back',
                                    style: geist(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                      letterSpacing: -.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Sign in to continue your scholarship journey.',
                                    style: geist(
                                      fontSize: 14,
                                      height: 1.45,
                                      color: kTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  _buildLockoutBanner(),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                      AutofillHints.email,
                                    ],
                                    autocorrect: false,
                                    textCapitalization: TextCapitalization.none,
                                    validator: _validateEmail,
                                    style: geist(fontSize: 14),
                                    decoration: _fieldDecoration(
                                      'Email',
                                      'you@example.com',
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _passwordController,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    textInputAction: TextInputAction.done,
                                    obscureText: _obscurePassword,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    onFieldSubmitted: (_) =>
                                        (_isLoading || locked)
                                        ? null
                                        : _onLogin(),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Enter your password.'
                                        : null,
                                    style: geist(fontSize: 14),
                                    decoration: _fieldDecoration(
                                      'Password',
                                      'Enter your password',
                                      suffix: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                          color: kTextSecondary,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _onForgotPassword,
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(44, 44),
                                        foregroundColor: kPrimary,
                                      ),
                                      child: Text(
                                        'Forgot password?',
                                        style: geist(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        key: const ValueKey(
                                          'remember-me-checkbox',
                                        ),
                                        value: _rememberMe,
                                        activeColor: kPrimary,
                                        onChanged: (val) => setState(
                                          () => _rememberMe = val ?? true,
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setState(
                                            () => _rememberMe = !_rememberMe,
                                          ),
                                          child: Container(
                                            constraints: const BoxConstraints(
                                              minHeight: 44,
                                            ),
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              'Remember me for 30 days',
                                              style: geist(
                                                fontSize: 13,
                                                color: kTextSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: (_isLoading || locked)
                                        ? null
                                        : _onLogin,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(
                                        double.infinity,
                                        48,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      backgroundColor: locked
                                          ? const Color(0xFFBA1A1A)
                                          : kPrimary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: locked
                                          ? const Color(0xFFE2A0A0)
                                          : _isLoading
                                          ? kPrimary
                                          : null,
                                      disabledForegroundColor: locked
                                          ? Colors.white.withValues(alpha: .8)
                                          : null,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
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
                                        : Text(
                                            locked
                                                ? 'Account Locked'
                                                : 'Sign in',
                                            textAlign: TextAlign.center,
                                            style: geist(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
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
                                        "Don't have an account?",
                                        style: geist(
                                          fontSize: 13,
                                          color: kTextSecondary,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => context.go('/signup'),
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(44, 44),
                                          foregroundColor: kPrimary,
                                        ),
                                        child: Text(
                                          'Sign up',
                                          style: geist(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_shouldShowProviderCta) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: _openProviderPortal,
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(44, 44),
                                        foregroundColor: kPrimary,
                                      ),
                                      child: Text(
                                        'Become a scholarship provider',
                                        textAlign: TextAlign.center,
                                        style: geist(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
      ),
    );
  }
}
