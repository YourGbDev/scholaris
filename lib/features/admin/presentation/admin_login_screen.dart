// lib/features/admin/presentation/admin_login_screen.dart
//
// Dedicated Super Admin Login Portal for Scholaris.
// Institutional Governance & Disbursement Console aesthetic:
// - Command-center aesthetic with deep emerald (#0B291A) & dark slate (#0F172A)
// - Strictly internal: no social logins, no student signups, no provider marketing
// - Direct authentication & role-gated access to Admin HomeScreen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/core/security/login_lockout_service.dart';
import 'package:scholaris/shared/theme/app_motion.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
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
  void dispose() {
    _lockoutTimer?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final lockoutCheck = LoginLockoutService.instance.checkLockout(email);
    if (lockoutCheck.isLocked) {
      _startLockoutCountdown(lockoutCheck);
      _showErrorSnackBar(lockoutCheck.lockoutMessage);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;
      final authResponse = await client.auth.signInWithPassword(
        email: email,
        password: _passwordController.text,
      );

      final user = authResponse.user;
      if (user == null) {
        throw const AuthException('Authentication failed. User not found.');
      }

      // Verify admin role in public.profiles
      final profileRes = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final role = (profileRes?['role'] as String?)?.toLowerCase();

      if (role != 'admin') {
        // Sign out unauthorized non-admin attempts
        await client.auth.signOut();
        LoginLockoutService.instance.recordFailedAttempt(email);

        if (!mounted) return;
        _showAccessDeniedDialog();
        return;
      }

      // Success
      LoginLockoutService.instance.recordSuccessfulLogin(email);
      _lockoutTimer?.cancel();
      if (mounted) {
        setState(() => _lockoutStatus = null);
        context.go('/admin-home');
      }
    } on AuthException catch (e) {
      LoginLockoutService.instance.recordFailedAttempt(email);
      final updatedStatus = LoginLockoutService.instance.checkLockout(email);
      if (updatedStatus.isLocked) {
        _startLockoutCountdown(updatedStatus);
      }
      if (mounted) {
        _showErrorSnackBar(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.openSans(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAccessDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.gpp_bad_rounded, color: Color(0xFFFF6F59), size: 24),
            const SizedBox(width: 10),
            Text(
              'Access Restricted',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'This account does not have Special Disbursing or Governance privileges.\n\nOnly authorized institutional comptrollers and governance officers can sign in to the DOST-SEI Grant Finance Console.',
          style: GoogleFonts.openSans(color: const Color(0xFF94A3B8), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Acknowledge',
              style: GoogleFonts.outfit(color: const Color(0xFF34D399), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _lockoutStatus?.isLocked ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate Governance Background
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0F4D2E).withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 550,
              height: 550,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E3A5F).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Center Console Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Elevated Command Surface
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF334155),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(36),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Restricted Access Badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF064E3B).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF059669).withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 13,
                                  color: Color(0xFF34D399),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'DOST-SEI COMPTROLLER • SPECIAL DISBURSING AUTHORITY',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: const Color(0xFF34D399),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title & Shield Icon
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4D2E),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F4D2E).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DOST-SEI Grant Finance Console',
                                    style: GoogleFonts.outfit(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Institutional Grant Disbursement & Award Conferral',
                                    style: GoogleFonts.openSans(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          'Sign in to verify DOST-SEI grant committee evaluations, authorize official award status, and release scholarship fund disbursements.',
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            height: 1.5,
                            color: const Color(0xFFCBD5E1),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Lockout Alert Banner
                        if (isLocked) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEF4444)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: Color(0xFFFCA5A5), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _lockoutStatus?.lockoutMessage ?? 'Too many attempts.',
                                    style: GoogleFonts.openSans(
                                      color: const Color(0xFFFCA5A5),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Email Field
                        Text(
                          'COMPTROLLER EMAIL',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isLoading && !isLocked,
                          style: GoogleFonts.openSans(color: Colors.white, fontSize: 14),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'e.g. finance.dost@scholaris.gov.ph or admin@scholaris.edu.ph',
                            hintStyle: GoogleFonts.openSans(color: const Color(0xFF64748B), fontSize: 13),
                            prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF94A3B8), size: 19),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Admin email is required';
                            }
                            if (!val.contains('@')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Password Field
                        Text(
                          'SECURITY CREDENTIAL',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isLoading && !isLocked,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.openSans(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '••••••••••••',
                            hintStyle: GoogleFonts.openSans(color: const Color(0xFF64748B), fontSize: 13),
                            prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF94A3B8), size: 19),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 19,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Security password is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 28),

                        // Authorize & Sign In Button
                        PressableScale(
                          onTap: (_isLoading || isLocked) ? null : _handleAdminLogin,
                          enabled: !_isLoading && !isLocked,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF059669),
                                  Color(0xFF0F4D2E),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Authorize & Sign In',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Security Audit Footer
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Protected by Row-Level Security & Immutable Audit Logging (RA 10173).',
                                  style: GoogleFonts.openSans(
                                    fontSize: 10.5,
                                    color: const Color(0xFF64748B),
                                    height: 1.3,
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
          ),
        ],
      ),
    );
  }
}
