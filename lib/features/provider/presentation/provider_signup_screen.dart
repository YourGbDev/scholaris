// lib/features/provider/presentation/provider_signup_screen.dart
//
// Provider account creation flow. Collects organization/contact details,
// creates a Supabase auth account, tags the resulting profile row with
// role='provider', then shows the success overlay and navigates to the
// provider review screen.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/entrance.dart';
import 'package:scholaris/shared/widgets/success_overlay.dart';

const _inputRadius = 12.0;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool get _isWidgetTestBinding {
  final type = WidgetsBinding.instance.runtimeType.toString();
  return type == 'AutomatedTestWidgetsFlutterBinding' ||
      type == 'LiveTestWidgetsFlutterBinding';
}

const int kProviderEntranceTotalMs = 2200;

Interval _providerInterval(int beginMs, int endMs) =>
    EntranceMotion.intervalFrom(
      beginMs,
      endMs,
      kProviderEntranceTotalMs,
      curve: Curves.easeOutCubic,
    );

class ProviderSignupScreen extends StatefulWidget {
  const ProviderSignupScreen({super.key});

  @override
  State<ProviderSignupScreen> createState() => _ProviderSignupScreenState();
}

class _ProviderSignupScreenState extends State<ProviderSignupScreen>
    with
        TickerProviderStateMixin<ProviderSignupScreen>,
        EntranceMotionMixin<ProviderSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  Duration get entranceDuration =>
      const Duration(milliseconds: kProviderEntranceTotalMs);

  @override
  void dispose() {
    _orgController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _nameController.text.trim(),
          'organization': _orgController.text.trim(),
        },
        emailRedirectTo: null,
      );

      if (!mounted) return;

      try {
        if (response.user != null) {
          await Supabase.instance.client.from('profiles').update({
            'role': 'provider',
          }).eq('id', response.user!.id);
        }
      } on Exception catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar(
            'Account created, but we couldn\'t tag your profile. '
            'Our team will review your signup manually.',
          ),
        );
      }

      if (!mounted) return;
      await SuccessOverlay.show(context);
      if (!mounted) return;

      context.go('/provider-review');
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

  String? _validateOrg(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your organization name.';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter the contact person name.';
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

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    if (value != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  SnackBar _snackBar(String message) => SnackBar(
        content: Text(message, style: openSans()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final heroHeight = (viewport.maxHeight * 0.40)
                .clamp(180.0, viewport.maxHeight - 400);
            return Column(
              children: [
                SizedBox(
                  height: heroHeight,
                  width: double.infinity,
                  child: entranceItem(
                    index: 0,
                    offset: const Offset(0, 0.08),
                    interval: _providerInterval(200, 1000),
                    child: Lottie.asset(
                      'assets/animations/Business Team.json',
                      fit: BoxFit.contain,
                      animate:
                          !(MediaQuery.maybeOf(context)
                                  ?.disableAnimations ??
                              false) &&
                          !_isWidgetTestBinding,
                    ),
                  ),
                ),

                Expanded(
                  child: entranceItem(
                    index: 1,
                    offset: const Offset(0, 0.25),
                    interval: _providerInterval(200, 1000),
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
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
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
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Become a Scholarship Provider',
                                          textAlign: TextAlign.center,
                                          style: poppins(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: kPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Help students reach their dreams by '
                                          'offering scholarships on Scholaris.',
                                          textAlign: TextAlign.center,
                                          style: openSans(
                                            fontSize: 15,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _textField(
                                          controller: _orgController,
                                          label: 'Organization Name',
                                          validator: _validateOrg,
                                        ),
                                        const SizedBox(height: 12),
                                        _textField(
                                          controller: _nameController,
                                          label: 'Contact Person Name',
                                          validator: _validateName,
                                        ),
                                        const SizedBox(height: 12),
                                        _textField(
                                          controller: _emailController,
                                          label: 'Email',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          validator: _validateEmail,
                                        ),
                                        const SizedBox(height: 12),
                                        _textField(
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
                                        const SizedBox(height: 12),
                                        _textField(
                                          controller:
                                              _confirmPasswordController,
                                          label: 'Confirm Password',
                                          obscureText: _obscureConfirm,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) =>
                                              _onSubmit(),
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
                                          validator: _validateConfirm,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
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
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _onSubmit,
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
                                              'Apply to become a provider',
                                              style: poppins(
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextButton(
                                      onPressed: () => context.pop(),
                                      child: Text(
                                        'Back to login',
                                        style: poppins(
                                          color: kPrimary,
                                          fontWeight: FontWeight.w600,
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
      style: openSans(),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: openSans(color: Colors.black54),
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
