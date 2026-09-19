// lib/features/auth/presentation/signup_screen.dart
//
// Account creation against Supabase. Rebuilt to match the Stitch design
// system with Philippine context ("Iskolar ng Bayan", ₱480M+ active grants,
// RA 10173 compliance, University/School & PH phone inputs).
//
// Preserves local validation, Supabase sign up flow, and test suite contracts.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/app/confirmation_redirect.dart';
import 'package:scholaris/core/security/password_validator.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';
import 'package:scholaris/shared/widgets/success_overlay.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreedToPrivacy = true;
  int _selectedRoleIndex = 0; // 0: Student / Applicant, 1: Provider / LGU

  @override
  void dispose() {
    _fullNameController.dispose();
    _schoolController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _calculatePasswordStrength(String password) =>
      PasswordValidator.strengthScore(password);

  Future<void> _onSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar('Please agree to the Terms of Service & Privacy Policy.'),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final metadata = <String, dynamic>{
        'full_name': _fullNameController.text.trim(),
      };
      if (_schoolController.text.trim().isNotEmpty) {
        metadata['school'] = _schoolController.text.trim();
      }
      if (_phoneController.text.trim().isNotEmpty) {
        metadata['phone'] = '+63${_phoneController.text.trim()}';
      }

      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: metadata,
        emailRedirectTo: emailConfirmationRedirect,
      );

      if (!mounted) return;

      await SuccessOverlay.show(context);
      if (!mounted) return;

      if (response.session == null) {
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
    if (error.message.contains('already registered') ||
        error.message.toLowerCase().contains('already exists')) {
      return 'An account with this email already exists. Please log in instead.';
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

  String? _validatePassword(String? value) =>
      PasswordValidator.validatePassword(value);

  String? _validateConfirmPassword(String? value) =>
      PasswordValidator.validateConfirmPassword(value, _passwordController.text);

  Widget _requirementRow(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 13,
            color: met ? kPrimary : const Color(0xFF9E9E9E),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: openSans(
                fontSize: 11,
                color: met ? kPrimary : const Color(0xFF757575),
                fontWeight: met ? FontWeight.w600 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final passwordStrength = _calculatePasswordStrength(_passwordController.text);
    final passwordsMatch = _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;

    return Scaffold(
      backgroundColor: kSurfaceWarm,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: kTextPrimary),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/login');
                      }
                    },
                    tooltip: 'Go back',
                  ),
                  const SizedBox(width: 4),
                  const Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: ScholarisLogo(compact: true),
                    ),
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kSurfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.help_outline_rounded, size: 16, color: kTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Help',
                            style: openSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Iskolar ng Bayan Pill
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: kPrimaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: kPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ISKOLAR NG BAYAN',
                                    style: poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: kPrimary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Heading
                          Text(
                            'Create your account',
                            style: poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: kTextPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Access thousands of verified scholarships across the Philippines tailored to your background.',
                            style: openSans(
                              fontSize: 12,
                              color: kTextSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Motivational Grant Stat Banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kPrimary, Color(0xFF1B3A5C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.verified_rounded,
                                              size: 14,
                                              color: kAccent,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Free Forever For Students',
                                                overflow: TextOverflow.ellipsis,
                                                style: poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '100% Free',
                                      style: poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFB3F1C6),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₱480M+ Active Grants',
                                  style: poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Vetted opportunities spanning Luzon, Visayas & Mindanao',
                                  style: openSans(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Segmented Role Selector
                          Text(
                            'I am joining as:',
                            style: openSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EEFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedRoleIndex = 0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _selectedRoleIndex == 0 ? kPrimary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: _selectedRoleIndex == 0
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.08),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.school_rounded,
                                            size: 15,
                                            color: _selectedRoleIndex == 0 ? Colors.white : kTextSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Student',
                                              overflow: TextOverflow.ellipsis,
                                              style: poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _selectedRoleIndex == 0 ? Colors.white : kTextSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      context.push('/become-provider');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _selectedRoleIndex == 1 ? kPrimary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.account_balance_rounded,
                                            size: 15,
                                            color: _selectedRoleIndex == 1 ? Colors.white : kTextSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Provider',
                                              overflow: TextOverflow.ellipsis,
                                              style: poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _selectedRoleIndex == 1 ? Colors.white : kTextSecondary,
                                              ),
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
                          const SizedBox(height: 16),

                          // 1. Full Legal Name (TextFormField index 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Full Name',
                                style: poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kTextPrimary,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'As on PSA birth certificate',
                                  overflow: TextOverflow.ellipsis,
                                  style: openSans(
                                    fontSize: 11,
                                    color: kTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _formTextField(
                            controller: _fullNameController,
                            hintText: 'e.g. Maya Santos Dela Cruz',
                            prefixIcon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: _validateFullName,
                          ),
                          const SizedBox(height: 12),

                          // 2. University, College, or High School (TextField - preserves FormField indices)
                          Text(
                            'University, College, or High School',
                            style: poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _auxTextField(
                            controller: _schoolController,
                            hintText: 'e.g. UP Diliman, PUP, UST, DLSU, or High School',
                            prefixIcon: Icons.domain_rounded,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),

                          // 3. Email (TextFormField index 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Email',
                                style: poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kTextPrimary,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'School or personal',
                                  overflow: TextOverflow.ellipsis,
                                  style: openSans(
                                    fontSize: 11,
                                    color: kTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _formTextField(
                            controller: _emailController,
                            hintText: 'e.g. maya.santos@up.edu.ph or personal email',
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 12),

                          // 4. Philippine Mobile Number (TextField)
                          Text(
                            'Philippine Mobile Number',
                            style: poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                height: 46,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8EEFF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kBorderLight),
                                ),
                                child: Row(
                                  children: [
                                    const Text('🇵🇭', style: TextStyle(fontSize: 14)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+63',
                                      style: poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: kTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _auxTextField(
                                  controller: _phoneController,
                                  hintText: '917 890 1234',
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 5. Password (TextFormField index 2)
                          Text(
                            'Password',
                            style: poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _formTextField(
                            controller: _passwordController,
                            hintText: 'Minimum 8 characters',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            validator: _validatePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: kTextSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Password Strength Gauge
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: passwordStrength >= 1
                                        ? (passwordStrength == 1
                                            ? Colors.orange
                                            : kPrimary)
                                        : Colors.black12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: passwordStrength >= 2 ? kPrimary : Colors.black12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: passwordStrength >= 3 ? kPrimary : Colors.black12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Password Complexity',
                                style: openSans(fontSize: 11, color: kTextSecondary),
                              ),
                              Text(
                                PasswordValidator.strengthLabel(passwordStrength),
                                style: openSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: passwordStrength >= 3
                                      ? kPrimary
                                      : (passwordStrength == 2 ? Colors.orange : const Color(0xFFBA1A1A)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F8FA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8E5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _requirementRow('At least 8 characters', PasswordValidator.hasMinLength(_passwordController.text)),
                                _requirementRow('Uppercase & lowercase letters', PasswordValidator.hasUppercase(_passwordController.text) && PasswordValidator.hasLowercase(_passwordController.text)),
                                _requirementRow('At least one number (0-9)', PasswordValidator.hasDigit(_passwordController.text)),
                                _requirementRow('Special character (!@#\$%^&*)', PasswordValidator.hasSpecialChar(_passwordController.text)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 6. Confirm Password (TextFormField index 3)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Confirm Password',
                                style: poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kTextPrimary,
                                ),
                              ),
                              if (passwordsMatch)
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 14, color: kPrimary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Passwords match',
                                      style: openSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: kPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _formTextField(
                            controller: _confirmPasswordController,
                            hintText: 'Re-enter your password',
                            prefixIcon: Icons.lock_clock_outlined,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() {}),
                            onFieldSubmitted: (_) => _onSignUp(),
                            validator: _validateConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                color: kTextSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // RA 10173 Consent Checkbox
                          GestureDetector(
                            onTap: () => setState(() => _agreedToPrivacy = !_agreedToPrivacy),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _agreedToPrivacy,
                                    activeColor: kPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setState(() => _agreedToPrivacy = val ?? false);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'I agree to the Terms of Service and Data Privacy Policy in accordance with the Philippine Data Privacy Act of 2012 (RA 10173).',
                                    style: openSans(
                                      fontSize: 11,
                                      color: kTextSecondary,
                                      height: 1.4,
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

            // Pinned Bottom Action Cluster: guarantees visibility on all viewports
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _onSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sign up',
                                      style: poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      ' — Create Free Account',
                                      overflow: TextOverflow.ellipsis,
                                      style: poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),

                      // Already have an account? Log in
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: openSans(
                              fontSize: 12,
                              color: kTextSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Log in',
                                  style: poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: kPrimary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _formTextField({
    required TextEditingController controller,
    required String hintText,
    required FormFieldValidator<String> validator,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: openSans(fontSize: 14, color: kTextPrimary),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: openSans(fontSize: 13, color: Colors.black38),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: kTextSecondary) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _auxTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      style: openSans(fontSize: 14, color: kTextPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: openSans(fontSize: 13, color: Colors.black38),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: kTextSecondary) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }
}
