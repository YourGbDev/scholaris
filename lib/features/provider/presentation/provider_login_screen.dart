// lib/features/provider/presentation/provider_login_screen.dart
//
// Scholaris Provider Portal Login Screen.
// Designed with 100% fidelity to the Stitch Apple Sequoia Provider Console mockups:
// - scholaris_institutional_provider_portal_apple_design
// - scholaris_individual_provider_portal_apple_design
//
// TODO(LGU-pitch): Replace placeholder content before final LGU presentation:
// - Trust & personal impact stats bar ("₱185M+ Disbursed", "1,240+ Active Providers", "14,200+ Screened", "₱0 platform fee")
// - Testimonials (Engr. Jerome P., A Partner Foundation Inc.)
// - SEC registration number (SEC CS202109844)
// - Security and encryption claims ("Tier-3 Hardware Encrypted", "256-bit Bank-Grade Encryption", "Smart Escrow Vault")
// - "2FA Hardware & Passkey Supported"
// - Placeholder email domains (@ayalafoundation.org.ph, @privatefamilytrust.ph)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/core/security/login_lockout_service.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';
import '../providers/provider_type_provider.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

enum ProviderPortalTab { organization, individual }

class ProviderLoginScreen extends ConsumerStatefulWidget {
  const ProviderLoginScreen({super.key, this.initialType});

  final String? initialType;

  @override
  ConsumerState<ProviderLoginScreen> createState() =>
      _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends ConsumerState<ProviderLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late ProviderPortalTab _activeTab;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _accordionExpanded = false;

  LockoutStatus? _lockoutStatus;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    // Default to organization unless explicitly requested as individual
    final typeParam = widget.initialType?.toLowerCase();
    _activeTab = (typeParam == 'individual')
        ? ProviderPortalTab.individual
        : ProviderPortalTab.organization;

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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final lockoutCheck = LoginLockoutService.instance.checkLockout(email);
    if (lockoutCheck.isLocked) {
      _startLockoutCountdown(lockoutCheck);
      _showSnackBar(lockoutCheck.lockoutMessage, isError: true);
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

      // 1. Role verification check
      final profileRes = await client
          .from('profiles')
          .select('role, provider_type')
          .eq('id', user.id)
          .maybeSingle();

      final role = (profileRes?['role'] as String?)?.toLowerCase() ?? 'student';

      if (role == 'student') {
        // Disallow student login on provider portal
        await client.auth.signOut();
        LoginLockoutService.instance.recordFailedAttempt(email);

        if (!mounted) return;
        _showStudentRoleGateDialog();
        return;
      }

      // Successful login
      LoginLockoutService.instance.recordSuccessfulLogin(email);
      _lockoutTimer?.cancel();
      if (mounted) {
        setState(() => _lockoutStatus = null);
      }

      // Refresh provider type state
      ref.invalidate(activeProviderTypeProvider);

      if (!mounted) return;
      if (role == 'admin') {
        context.go('/admin-home');
      } else {
        context.go('/provider-home');
      }
    } on AuthException catch (error) {
      final newStatus = LoginLockoutService.instance.recordFailedAttempt(email);
      if (newStatus.isLocked) {
        _startLockoutCountdown(newStatus);
      } else {
        if (mounted) setState(() => _lockoutStatus = newStatus);
      }
      if (!mounted) return;
      final msg = newStatus.isLocked
          ? newStatus.lockoutMessage
          : (newStatus.failedAttempts > 0 && newStatus.failedAttempts < 3)
              ? '${_friendlyError(error)} (${3 - newStatus.failedAttempts} attempt${3 - newStatus.failedAttempts == 1 ? '' : 's'} remaining)'
              : _friendlyError(error);
      _showSnackBar(msg, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('An unexpected error occurred. Please try again.',
          isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showStudentRoleGateDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.school_rounded, color: Color(0xFF0F4D2E), size: 24),
            const SizedBox(width: 8),
            Text(
              'Provider Portal',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'This portal is for providers. Use the Scholaris app.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1A1B1F),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Dismiss',
              style: GoogleFonts.inter(
                color: const Color(0xFF707971),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4D2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Go to Student Login',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyError(AuthException error) {
    if (error.message.contains('Invalid login credentials')) {
      return 'Incorrect email or password. Please verify your credentials.';
    }
    if (error.message.contains('Email not confirmed') ||
        error.message.contains('email_not_confirmed')) {
      return 'Your provider email is pending verification. Please check your inbox.';
    }
    return error.message;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
        ),
        backgroundColor:
            isError ? const Color(0xFFBA1A1A) : const Color(0xFF1A1B1F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOrg = _activeTab == ProviderPortalTab.organization;
    final isLocked = _lockoutStatus?.isLocked ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FE),
      body: SafeArea(
        child: Stack(
          children: [
            // Spatial ambience glow
            Positioned(
              top: -120,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 720,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0F4D2E).withValues(alpha: 0.12),
                        const Color(0xFF0F4D2E).withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main scrollable canvas
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Topbar Chrome
                      _buildTopChrome(isOrg),
                      const SizedBox(height: 20),

                      // Main Workstation Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF1A1B1F).withValues(alpha: 0.06),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Role Switcher Tabs
                              _buildRoleSwitcher(isOrg),
                              const SizedBox(height: 20),

                              // 2. Header & Badges
                              _buildCardHeader(isOrg),
                              const SizedBox(height: 24),

                              // 3. Lockout Banner (if triggered)
                              if (isLocked) ...[
                                _buildLockoutBanner(),
                                const SizedBox(height: 16),
                              ],

                              // 4. Email Field
                              _buildEmailField(isOrg),
                              const SizedBox(height: 16),

                              // 5. Password Field
                              _buildPasswordField(),
                              const SizedBox(height: 14),

                              // 6. Remember Me & Security Pill
                              _buildKeepSignedInRow(isOrg),
                              const SizedBox(height: 20),

                              // 7. Submit Button CTA
                              _buildSubmitButton(isOrg, isLocked),
                              const SizedBox(height: 24),

                              // 8. Onboarding Trigger (Accordion or Callout)
                              if (isOrg)
                                _buildOrgAccreditationCallout()
                              else
                                _buildIndividualOnboardingAccordion(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 9. Trust & Metrics Bar
                      _buildMetricsBar(isOrg),
                      const SizedBox(height: 16),

                      // 10. Testimonial Card
                      _buildTestimonialCard(isOrg),
                      const SizedBox(height: 16),

                      // 11. Individual Extra: Remittance Rails & Escrow Vault
                      if (!isOrg) ...[
                        _buildRemittanceRails(),
                        const SizedBox(height: 16),
                        _buildSmartEscrowVaultCard(),
                        const SizedBox(height: 20),
                      ],

                      // 12. Footer
                      _buildFooter(isOrg),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopChrome(bool isOrg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1A1B1F).withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const ScholarisLogo(badgeSize: 28, fontSize: 17, compact: true),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFB3F1C6).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isOrg ? 'ORGANIZATION PORTAL' : 'INDIVIDUAL PROVIDER PORTAL',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00351C),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F4D2E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isOrg
                        ? 'AY 2026–2027 • Clearance Engine'
                        : 'Direct Disbursement Rail',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF404942),
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

  Widget _buildRoleSwitcher(bool isOrg) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEDF3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Organization Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isOrg) {
                      setState(() {
                        _activeTab = ProviderPortalTab.organization;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isOrg ? const Color(0xFF0F4D2E) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isOrg
                          ? [
                              const BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apartment_rounded,
                          size: 15,
                          color: isOrg ? Colors.white : const Color(0xFF404942),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Organization',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight:
                                isOrg ? FontWeight.w600 : FontWeight.w500,
                            color: isOrg ? Colors.white : const Color(0xFF404942),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Individual Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isOrg) {
                      setState(() {
                        _activeTab = ProviderPortalTab.individual;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !isOrg ? const Color(0xFF0F4D2E) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !isOrg
                          ? [
                              const BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 15,
                          color: !isOrg ? Colors.white : const Color(0xFF404942),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Individual',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight:
                                !isOrg ? FontWeight.w600 : FontWeight.w500,
                            color: !isOrg ? Colors.white : const Color(0xFF404942),
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
        const SizedBox(height: 6),
        Text(
          isOrg
              ? 'For foundations, corporate endowments, SUCs & LGUs'
              : 'For private philanthropists, alumni sponsors & independent grant providers',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF404942),
          ),
        ),
      ],
    );
  }

  Widget _buildCardHeader(bool isOrg) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFB3F1C6).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOrg ? Icons.security_rounded : Icons.assured_workload_rounded,
                size: 13,
                color: const Color(0xFF00351C),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  isOrg
                      ? 'AUTHORIZED PHILANTHROPIC & CORPORATE PARTNERS ONLY'
                      : 'DIRECT SCHOLAR GRANT FUNDING · FULL 100% TRANCHE TRANSPARENCY',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00351C),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isOrg ? 'Organization Provider Portal' : 'Individual Provider Portal',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1B1F),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isOrg
              ? 'Sign in to manage institutional endowments, verify applicant LRNs, and disburse education grants via automated clearing rails.'
              : 'Fund a student directly. As an individual provider, you choose who you support and see every single peso reach their tuition and living allowance.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF404942),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildLockoutBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded,
              color: Color(0xFFBA1A1A), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lockoutStatus!.lockoutMessage,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF93000A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(bool isOrg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isOrg ? 'ORGANIZATION EMAIL' : 'PROVIDER EMAIL',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF404942),
                letterSpacing: 0.8,
              ),
            ),
            if (isOrg)
              Text(
                'Gov / Org domain',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: const Color(0xFF707971),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: const ValueKey('provider-login-email-field'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1A1B1F),
          ),
          validator: (val) {
            final email = val?.trim() ?? '';
            if (email.isEmpty) return 'Enter your provider email.';
            if (!_emailPattern.hasMatch(email)) {
              return 'Enter a valid email address.';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: isOrg
                ? 'endowments@partnerfoundation.org.ph'
                : 'provider@example.com or sponsor@gmail.com',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF707971).withValues(alpha: 0.6),
            ),
            prefixIcon: const Icon(
              Icons.mail_outline_rounded,
              size: 18,
              color: Color(0xFF707971),
            ),
            filled: true,
            fillColor: const Color(0xFFF4F3F8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0F4D2E), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PASSWORD',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF404942),
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/forgot-password'),
              child: Text(
                'Forgot password?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F4D2E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: const ValueKey('provider-login-password-field'),
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1A1B1F),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Enter your password.';
            return null;
          },
          decoration: InputDecoration(
            hintText: '••••••••••••',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF707971).withValues(alpha: 0.6),
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: Color(0xFF707971),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 18,
                color: const Color(0xFF707971),
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            filled: true,
            fillColor: const Color(0xFFF4F3F8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0F4D2E), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeepSignedInRow(bool isOrg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                activeColor: const Color(0xFF0F4D2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isOrg ? 'Remember this workstation' : 'Keep me signed in',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF404942),
              ),
            ),
          ],
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOrg ? Icons.key_rounded : Icons.verified_user_rounded,
                size: 13,
                color: const Color(0xFF0F4D2E),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isOrg
                      ? '2FA Hardware Supported'
                      : 'Bank-Grade Encryption',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF707971),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isOrg, bool isLocked) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        key: const ValueKey('provider-login-submit-button'),
        onPressed: (isLocked || _isLoading) ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F4D2E),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFDAD9DF),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                    isOrg
                        ? 'Access Provider Console'
                        : 'Access Individual Provider Console',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
      ),
    );
  }

  Widget _buildOrgAccreditationCallout() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New endowment partner or educational foundation?',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1B1F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SEC & BIR-verified institutional clearing status.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF404942),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.go('/become-provider?type=organization'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F4D2E),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Accreditation Fast Track →',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualOnboardingAccordion() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F8),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() => _accordionExpanded = !_accordionExpanded);
            },
            borderRadius: BorderRadius.circular(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Want to sponsor a scholar independently?',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF404942),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Register as an Individual Provider (2-Step Quick Setup)',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F4D2E),
                              ),
                            ),
                          ),
                          Icon(
                            _accordionExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 18,
                            color: const Color(0xFF0F4D2E),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB3F1C6).withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    size: 17,
                    color: Color(0xFF0F4D2E),
                  ),
                ),
              ],
            ),
          ),
          if (_accordionExpanded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F4D2E),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '1',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Profile & Verification',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1B1F),
                          ),
                        ),
                        Text(
                          'Instant PhilSys National ID, passport, or alumni credential check with e-KYC instant validation.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF404942),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F4D2E),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '2',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giving Preferences & Scholar Match',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1B1F),
                          ),
                        ),
                        Text(
                          'Select STEM, Agriculture, or State University criteria, set recurring tranche amounts, and link instant wallets.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF404942),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    context.go('/become-provider?type=individual'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE3E2E7),
                  foregroundColor: const Color(0xFF0F4D2E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Begin 2-Minute Onboarding Now →',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsBar(bool isOrg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1A1B1F).withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _metricCol(
              value: isOrg ? '₱185M+' : '1,240+',
              label: isOrg ? 'Disbursed • 82 Provinces' : 'Active Providers',
              isGreen: false,
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFFEEEDF3)),
          Expanded(
            child: _metricCol(
              value: isOrg ? '14,200+' : '100%',
              label: isOrg ? 'Scholars Screened' : 'Traceable Tranches',
              isGreen: !isOrg,
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFFEEEDF3)),
          Expanded(
            child: _metricCol(
              value: isOrg ? '99.4%' : '₱0',
              label: isOrg ? 'Stipend Reliability' : 'Platform Fee',
              isGreen: isOrg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCol({
    required String value,
    required String label,
    required bool isGreen,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isGreen ? const Color(0xFF0F4D2E) : const Color(0xFF1A1B1F),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF707971),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialCard(bool isOrg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1A1B1F).withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Color(0xFFF99A00),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isOrg
                      ? const Color(0xFFEEEDF3)
                      : const Color(0xFFB3F1C6).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isOrg
                      ? 'Institutional Reviewer Feedback'
                      : 'Verified Provider Story',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isOrg
                        ? const Color(0xFF404942)
                        : const Color(0xFF0F4D2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isOrg
                ? '“Scholaris replaced manual endorsements with automated LRN deduplication and verifiable BIR tranche schedules. Our cycle went from 14 weeks to 8 days.”'
                : '“I wanted to sponsor an engineering student at a State University without going through a complex foundation process. Scholaris verified enrollment and lets me disburse directly with real-time tuition clearance.”',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF1A1B1F),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isOrg)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD8E2FF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'AF',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF004493),
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 34,
                    height: 34,
                    color: const Color(0xFFEEEDF3),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF0F4D2E),
                      size: 20,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOrg ? 'A Partner Foundation Inc.' : 'Engr. J. P.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1B1F),
                    ),
                  ),
                  Text(
                    isOrg
                        ? 'Higher Education Grant Committee • Metro Manila'
                        : 'A Private Donor · Independent University Alumni Sponsor',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: const Color(0xFF707971),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemittanceRails() {
    return Column(
      children: [
        Text(
          'SUPPORTED INSTANT REMITTANCE RAILS',
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF707971),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _railChip('GCash Verified', const Color(0xFF0058BC)),
            _railChip('LandBank Direct', const Color(0xFF0F4D2E)),
            _railChip('Maya', const Color(0xFF0D9488)),
            _railChip('InstaPay / PESONet', const Color(0xFF623A00)),
          ],
        ),
      ],
    );
  }

  Widget _railChip(String label, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF1A1B1F).withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1B1F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartEscrowVaultCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1A1B1F).withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFB3F1C6).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFF0F4D2E),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Escrow Vault',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1B1F),
                  ),
                ),
                Text(
                  'Funds release automatically upon verified university grade submission.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF707971),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0F4D2E), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              '100%',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F4D2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isOrg) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined,
                size: 13, color: Color(0xFF0F4D2E)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'RA 10173 Philippine Data Privacy Act Compliant · Encrypted Identity Verification',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF707971),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            Text(
              '© 2026 Scholaris Philippines',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: const Color(0xFF707971),
              ),
            ),
            const Text('•',
                style: TextStyle(fontSize: 10, color: Color(0xFF707971))),
            Text(
              'Privacy Charter',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: const Color(0xFF707971),
              ),
            ),
            const Text('•',
                style: TextStyle(fontSize: 10, color: Color(0xFF707971))),
            Text(
              'Legal Terms',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: const Color(0xFF707971),
              ),
            ),
            const Text('•',
                style: TextStyle(fontSize: 10, color: Color(0xFF707971))),
            Text(
              isOrg ? 'Security Disclosure' : 'Escrow Terms',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: const Color(0xFF707971),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Compliance Rails: RA 10173 • SEC CS202109844',
              style: GoogleFonts.inter(
                fontSize: 9.5,
                color: const Color(0xFF707971),
              ),
            ),
            Text(
              isOrg
                  ? 'Scholaris Institutional Security Architecture'
                  : 'Scholaris Individual Provider Portal',
              style: GoogleFonts.inter(
                fontSize: 9.5,
                color: const Color(0xFF707971),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
