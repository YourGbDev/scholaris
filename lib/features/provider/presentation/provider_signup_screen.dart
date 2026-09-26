// lib/features/provider/presentation/provider_signup_screen.dart
//
// End-to-end Provider Signup & Accreditation Flow:
// - Individual Provider Signup (2 focused steps + confirmation)
// - Organization Provider Signup (4 focused steps + review + confirmation)
// - Styled with the Apple Sequoia Stitch portal DNA
// - Client-side file picking (PDF/JPG/PNG, max 5MB) and Supabase storage upload
// - Masked ID display and RA 10173 data privacy consent
//
// TODO(SMS-OTP): Integrate Telco SMS Gateway (e.g. Semaphore/Twilio) for live OTP verification.
// TODO(LGU-pitch): Replace placeholder partner accreditation claims before the formal presentation.

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/core/security/password_validator.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';
import '../data/provider_verification_repository.dart';
import '../models/provider_verification.dart';
import '../providers/provider_type_provider.dart';
import '../providers/provider_verification_provider.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _phPhonePattern = RegExp(r'^(09|\+639|639)\d{9}$');

class ProviderSignupScreen extends ConsumerStatefulWidget {
  const ProviderSignupScreen({super.key, this.initialType});

  final String? initialType;

  @override
  ConsumerState<ProviderSignupScreen> createState() =>
      _ProviderSignupScreenState();
}

class _ProviderSignupScreenState extends ConsumerState<ProviderSignupScreen> {
  // Mode: 'organization' | 'individual'
  late String _providerType;

  // Individual Form Controllers & State
  int _indivCurrentStep = 1; // 1: Account, 2: Verification, 3: Confirmation
  final _indivLegalNameCtrl = TextEditingController();
  final _indivEmailCtrl = TextEditingController();
  final _indivPhoneCtrl = TextEditingController();
  final _indivPasswordCtrl = TextEditingController();
  final _indivConfirmCtrl = TextEditingController();
  String _indivIdType = 'PhilSys National ID';
  final _indivIdNumberCtrl = TextEditingController();
  String _indivSourceOfFunds = 'Employment Income';
  String _indivGivingBudget = '₱2k-10k';
  final _indivTinCtrl = TextEditingController();
  bool _indivConsent = false;
  Uint8List? _indivIdFrontBytes;
  String? _indivIdFrontFileName;
  Uint8List? _indivSelfieBytes;
  String? _indivSelfieFileName;

  // Organization Form Controllers & State
  int _orgCurrentStep = 1; // 1: Org Details, 2: Rep Details, 3: Docs, 4: Review, 5: Confirmation
  final _orgNameCtrl = TextEditingController();
  String _orgType = 'Foundation';
  final _orgRegNumberCtrl = TextEditingController();
  final _orgRepNameCtrl = TextEditingController();
  final _orgRepPositionCtrl = TextEditingController();
  final _orgRepEmailCtrl = TextEditingController();
  final _orgRepPhoneCtrl = TextEditingController();
  final _orgPasswordCtrl = TextEditingController();
  final _orgConfirmCtrl = TextEditingController();
  Uint8List? _orgSecBytes;
  String? _orgSecFileName;
  Uint8List? _orgBirBytes;
  String? _orgBirFileName;
  Uint8List? _orgBoardBytes;
  String? _orgBoardFileName;
  bool _orgConsent = false;

  // UI State
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  bool _emailConfirmationPending = false;
  String? _pendingConfirmationEmail;
  String? _errorMessage;

  final _formKeyIndivStep1 = GlobalKey<FormState>();
  final _formKeyIndivStep2 = GlobalKey<FormState>();
  final _formKeyOrgStep1 = GlobalKey<FormState>();
  final _formKeyOrgStep2 = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final param = widget.initialType?.toLowerCase();
    _providerType = (param == 'individual') ? 'individual' : 'organization';
  }

  @override
  void dispose() {
    _indivLegalNameCtrl.dispose();
    _indivEmailCtrl.dispose();
    _indivPhoneCtrl.dispose();
    _indivPasswordCtrl.dispose();
    _indivConfirmCtrl.dispose();
    _indivIdNumberCtrl.dispose();
    _indivTinCtrl.dispose();

    _orgNameCtrl.dispose();
    _orgRegNumberCtrl.dispose();
    _orgRepNameCtrl.dispose();
    _orgRepPositionCtrl.dispose();
    _orgRepEmailCtrl.dispose();
    _orgRepPhoneCtrl.dispose();
    _orgPasswordCtrl.dispose();
    _orgConfirmCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation Helpers
  // ---------------------------------------------------------------------------

  String? _validatePhone(String? val) {
    final clean = val?.trim().replaceAll(RegExp(r'[\s\-]'), '') ?? '';
    if (clean.isEmpty) return 'Enter a Philippine mobile number.';
    if (!_phPhonePattern.hasMatch(clean)) {
      return 'Enter a valid PH mobile number (e.g. 09171234567 or +639171234567).';
    }
    return null;
  }

  String? _validateEmail(String? val) {
    final clean = val?.trim() ?? '';
    if (clean.isEmpty) return 'Enter an email address.';
    if (!_emailPattern.hasMatch(clean)) return 'Enter a valid email address.';
    return null;
  }

  // ---------------------------------------------------------------------------
  // File Picking
  // ---------------------------------------------------------------------------

  Future<void> _pickFile({
    required Function(Uint8List bytes, String name) onPicked,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
          _showError('Could not read file data. Please try another file.');
          return;
        }

        final err = ProviderVerificationRepository.validateFile(
          fileName: file.name,
          byteLength: file.bytes!.length,
        );

        if (err != null) {
          _showError(err);
          return;
        }

        setState(() {
          onPicked(file.bytes!, file.name);
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('[PROVIDER SIGNUP FILE PICKER] $e');
      _showError('File selection cancelled or failed. Please select a valid document.');
    }
  }

  void _showError(String msg) {
    setState(() => _errorMessage = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: const Color(0xFFBA1A1A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Submission Handlers
  // ---------------------------------------------------------------------------

  Future<void> _submitIndividual() async {
    if (!_indivConsent) {
      _showError('Please consent to RA 10173 data processing to continue.');
      return;
    }
    if (_indivIdFrontBytes == null) {
      _showError('Please upload a photo of your Government ID.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final repo = ref.read(providerVerificationRepositoryProvider);
      final currentUser = client.auth.currentUser;

      String userId;
      final email = _indivEmailCtrl.text.trim();
      final password = _indivPasswordCtrl.text;
      final fullName = _indivLegalNameCtrl.text.trim();
      final phone = _indivPhoneCtrl.text.trim();

      if (currentUser != null) {
        userId = currentUser.id;
      } else {
        try {
          final authRes = await client.auth.signUp(
            email: email,
            password: password,
            data: {
              'full_name': fullName,
              'role': 'provider',
              'provider_type': 'individual',
              'phone': phone,
            },
          );
          if (authRes.session == null && authRes.user != null) {
            setState(() {
              _emailConfirmationPending = true;
              _pendingConfirmationEmail = email;
              _isSubmitting = false;
            });
            return;
          }
          final user = authRes.user;
          if (user == null) {
            throw const AuthException('Could not create provider account. Please verify credentials.');
          }
          userId = user.id;
        } on AuthException catch (e) {
          if (e.message.toLowerCase().contains('already registered')) {
            throw const AuthException(
                'This email is already registered. Please sign in or use another email.');
          }
          rethrow;
        }
      }

      // 2. Upload ID front
      String idFrontPath = '';
      if (_indivIdFrontBytes != null) {
        idFrontPath = await repo.uploadDocument(
          userId: userId,
          docType: 'gov_id_front',
          bytes: _indivIdFrontBytes!,
          fileName: _indivIdFrontFileName ?? 'gov_id.jpg',
        );
      }

      // 3. Upload Selfie (optional)
      String? selfiePath;
      if (_indivSelfieBytes != null) {
        selfiePath = await repo.uploadDocument(
          userId: userId,
          docType: 'selfie_with_id',
          bytes: _indivSelfieBytes!,
          fileName: _indivSelfieFileName ?? 'selfie.jpg',
        );
      }

      // 4. Save Verification Record
      final verification = ProviderVerification(
        userId: userId,
        providerType: 'individual',
        status: 'pending',
        fullName: fullName,
        email: email,
        phone: phone,
        govIdType: _indivIdType,
        govIdNumber: _indivIdNumberCtrl.text.trim(),
        govIdFrontPath: idFrontPath,
        selfieIdPath: selfiePath,
        sourceOfFunds: _indivSourceOfFunds,
        monthlyGivingBudget: _indivGivingBudget,
        tin: _indivTinCtrl.text.trim().isNotEmpty
            ? _indivTinCtrl.text.trim()
            : null,
        dataConsent: _indivConsent,
      );

      await repo.submitVerification(verification);
      ref.invalidate(currentUserVerificationProvider);
      ref.invalidate(activeProviderTypeProvider);

      setState(() {
        _indivCurrentStep = 3; // Confirmation
        _isSubmitting = false;
      });
    } on AuthException catch (e) {
      setState(() => _isSubmitting = false);
      debugPrint('[PROVIDER SIGNUP AUTH EXCEPTION] ${e.message}');
      _showError(e.message);
    } catch (e) {
      setState(() => _isSubmitting = false);
      debugPrint('[PROVIDER SIGNUP EXCEPTION] Type: ${e.runtimeType}');
      _showError('Submission could not be completed. Please verify your information and retry.');
    }
  }

  Future<void> _submitOrganization() async {
    if (!_orgConsent) {
      _showError('Please consent to RA 10173 data processing to continue.');
      return;
    }
    if (_orgSecBytes == null || _orgBirBytes == null) {
      _showError('Please upload both your SEC Certificate and BIR 2303.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final repo = ref.read(providerVerificationRepositoryProvider);
      final currentUser = client.auth.currentUser;

      String userId;
      final email = _orgRepEmailCtrl.text.trim();
      final password = _orgPasswordCtrl.text;
      final orgName = _orgNameCtrl.text.trim();
      final repName = _orgRepNameCtrl.text.trim();
      final repPhone = _orgRepPhoneCtrl.text.trim();

      if (currentUser != null) {
        userId = currentUser.id;
      } else {
        try {
          final authRes = await client.auth.signUp(
            email: email,
            password: password,
            data: {
              'full_name': orgName,
              'role': 'provider',
              'provider_type': 'organization',
              'organization': orgName,
              'phone': repPhone,
            },
          );
          if (authRes.session == null && authRes.user != null) {
            setState(() {
              _emailConfirmationPending = true;
              _pendingConfirmationEmail = email;
              _isSubmitting = false;
            });
            return;
          }
          final user = authRes.user;
          if (user == null) {
            throw const AuthException('Could not create provider account. Please verify credentials.');
          }
          userId = user.id;
        } on AuthException catch (e) {
          if (e.message.toLowerCase().contains('already registered')) {
            throw const AuthException(
                'This representative email is already registered. Please sign in or use another email.');
          }
          rethrow;
        }
      }

      // 2. Upload SEC Certificate
      String secPath = '';
      if (_orgSecBytes != null) {
        secPath = await repo.uploadDocument(
          userId: userId,
          docType: 'sec_certificate',
          bytes: _orgSecBytes!,
          fileName: _orgSecFileName ?? 'sec_cert.pdf',
        );
      }

      // 3. Upload BIR 2303
      String birPath = '';
      if (_orgBirBytes != null) {
        birPath = await repo.uploadDocument(
          userId: userId,
          docType: 'bir_2303',
          bytes: _orgBirBytes!,
          fileName: _orgBirFileName ?? 'bir_2303.pdf',
        );
      }

      // 4. Upload Board Resolution (if provided)
      String? boardPath;
      if (_orgBoardBytes != null) {
        boardPath = await repo.uploadDocument(
          userId: userId,
          docType: 'board_resolution',
          bytes: _orgBoardBytes!,
          fileName: _orgBoardFileName ?? 'board_resolution.pdf',
        );
      }

      // 5. Submit Verification Record
      final verification = ProviderVerification(
        userId: userId,
        providerType: 'organization',
        status: 'pending',
        orgName: orgName,
        orgType: _orgType,
        regNumber: _orgRegNumberCtrl.text.trim(),
        repName: repName,
        repPosition: _orgRepPositionCtrl.text.trim(),
        repEmail: email,
        repPhone: repPhone,
        secCertPath: secPath,
        bir2303Path: birPath,
        boardResolutionPath: boardPath,
        dataConsent: _orgConsent,
      );

      await repo.submitVerification(verification);
      ref.invalidate(currentUserVerificationProvider);
      ref.invalidate(activeProviderTypeProvider);

      setState(() {
        _orgCurrentStep = 5; // Confirmation
        _isSubmitting = false;
      });
    } on AuthException catch (e) {
      setState(() => _isSubmitting = false);
      debugPrint('[PROVIDER ORG SIGNUP AUTH EXCEPTION] ${e.message}');
      _showError(e.message);
    } catch (e) {
      setState(() => _isSubmitting = false);
      debugPrint('[PROVIDER ORG SIGNUP EXCEPTION] Type: ${e.runtimeType}');
      _showError('Submission could not be completed. Please verify your information and retry.');
    }
  }

  // ---------------------------------------------------------------------------
  // Main Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isOrg = _providerType == 'organization';
    final isIndividual = _providerType == 'individual';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header branding & back to login
                  _buildTopNav(),
                  const SizedBox(height: 20),

                  // Mode Switcher (if not on confirmation)
                  if ((isIndividual && _indivCurrentStep < 3) ||
                      (isOrg && _orgCurrentStep < 5)) ...[
                    _buildModeToggle(),
                    const SizedBox(height: 20),
                  ],

                  // Card container
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
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDAD6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFBA1A1A)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: Color(0xFFBA1A1A), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF410002),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_emailConfirmationPending)
                          _buildEmailConfirmationScreen()
                        else if (isIndividual)
                          _buildIndividualFlow()
                        else
                          _buildOrganizationFlow(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Compliance Footer
                  _buildComplianceFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ScholarisLogo(badgeSize: 28, fontSize: 18, compact: true),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB3F1C6).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'PROVIDER REGISTRATION',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00351C),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => context.go('/provider/login'),
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: Text(
            'Login',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0F4D2E),
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    final isOrg = _providerType == 'organization';
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEDF3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isOrg) {
                  setState(() {
                    _providerType = 'organization';
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.apartment_rounded,
                      size: 15,
                      color: isOrg ? Colors.white : const Color(0xFF404942),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Organization Provider',
                          maxLines: 1,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isOrg ? FontWeight.w600 : FontWeight.w500,
                            color: isOrg ? Colors.white : const Color(0xFF404942),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isOrg) {
                  setState(() {
                    _providerType = 'individual';
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 15,
                      color: !isOrg ? Colors.white : const Color(0xFF404942),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Individual Provider',
                          maxLines: 1,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: !isOrg ? FontWeight.w600 : FontWeight.w500,
                            color: !isOrg ? Colors.white : const Color(0xFF404942),
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
      ),
    );
  }

  // ===========================================================================
  // PART 2: INDIVIDUAL PROVIDER FLOW (2 STEPS + CONFIRMATION)
  // ===========================================================================

  Widget _buildIndividualFlow() {
    if (_indivCurrentStep == 1) {
      return _buildIndivStep1AccountSetup();
    } else if (_indivCurrentStep == 2) {
      return _buildIndivStep2Verification();
    } else {
      return _buildIndivStep3Confirmation();
    }
  }

  Widget _buildIndivStep1AccountSetup() {
    final password = _indivPasswordCtrl.text;
    final passwordStrength = PasswordValidator.strengthScore(password);

    return Form(
      key: _formKeyIndivStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepProgressHeader(
            currentStep: 1,
            totalSteps: 2,
            stepTitle: 'Step 1 — Account Setup',
            subtitle:
                'Set up your personal benefactor credentials. You will use this email to sign in.',
          ),
          const SizedBox(height: 20),

          // Legal Name
          _buildFieldLabel('Full Legal Name', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _indivLegalNameCtrl,
            style: GoogleFonts.inter(fontSize: 14),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter your full legal name.' : null,
            decoration: _inputDecoration(
              hint: 'e.g. Juan P. Dela Cruz',
              prefixIcon: Icons.badge_outlined,
            ),
          ),
          const SizedBox(height: 16),

          // Email
          _buildFieldLabel('Personal Email', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _indivEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(fontSize: 14),
            validator: _validateEmail,
            decoration: _inputDecoration(
              hint: 'sponsor@gmail.com',
              prefixIcon: Icons.mail_outline_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // PH Mobile Phone
          _buildFieldLabel('Philippine Mobile Number', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _indivPhoneCtrl,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.inter(fontSize: 14),
            validator: _validatePhone,
            decoration: _inputDecoration(
              hint: '0917 123 4567 or +639171234567',
              prefixIcon: Icons.phone_android_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // Password
          _buildFieldLabel('Password', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _indivPasswordCtrl,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(fontSize: 14),
            onChanged: (val) => setState(() {}),
            validator: (v) => PasswordValidator.validatePassword(v),
            decoration: _inputDecoration(
              hint: '••••••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 18,
                  color: const Color(0xFF707971),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Password Complexity Criteria
          _buildPasswordComplexityWidget(password, passwordStrength),
          const SizedBox(height: 14),

          // Confirm Password
          _buildFieldLabel('Confirm Password', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _indivConfirmCtrl,
            obscureText: _obscureConfirm,
            style: GoogleFonts.inter(fontSize: 14),
            validator: (v) => PasswordValidator.validateConfirmPassword(
              v,
              _indivPasswordCtrl.text,
            ),
            decoration: _inputDecoration(
              hint: '••••••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 18,
                  color: const Color(0xFF707971),
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_formKeyIndivStep1.currentState!.validate()) {
                  setState(() => _indivCurrentStep = 2);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4D2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Proceed to Identity & Verification',
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndivStep2Verification() {
    return Form(
      key: _formKeyIndivStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepProgressHeader(
            currentStep: 2,
            totalSteps: 2,
            stepTitle: 'Step 2 — Identity & Financial Verification',
            subtitle:
                'Complies with Philippine AMLC & Data Privacy regulations (RA 10173).',
          ),
          const SizedBox(height: 20),

          // ID Type Dropdown
          _buildFieldLabel('Government ID Type', isRequired: true),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _indivIdType,
            decoration: _inputDecoration(prefixIcon: Icons.badge_outlined),
            items: const [
              DropdownMenuItem(
                  value: 'PhilSys National ID',
                  child: Text('PhilSys National ID')),
              DropdownMenuItem(
                  value: 'Philippine Passport',
                  child: Text('Philippine Passport')),
              DropdownMenuItem(
                  value: "Driver's License",
                  child: Text("Driver's License (LTO)")),
              DropdownMenuItem(
                  value: 'UMID',
                  child: Text('UMID (Unified Multi-Purpose ID)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _indivIdType = val);
            },
          ),
          const SizedBox(height: 16),

          // ID Number
          _buildFieldLabel('Government ID Number', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _indivIdNumberCtrl,
            style: GoogleFonts.inter(fontSize: 14),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Enter your government ID number.'
                : null,
            decoration: _inputDecoration(
              hint: 'e.g. 1234-5678-9012-3456',
              prefixIcon: Icons.numbers_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // ID Photo Upload (Front)
          _buildFieldLabel('Government ID Photo (Front)', isRequired: true),
          const SizedBox(height: 6),
          _buildFileUploadBox(
            title: _indivIdFrontFileName ?? 'Click to select ID photo (JPG, PNG, PDF)',
            isUploaded: _indivIdFrontBytes != null,
            onTap: () => _pickFile(
              onPicked: (bytes, name) {
                _indivIdFrontBytes = bytes;
                _indivIdFrontFileName = name;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Selfie with ID (Optional)
          _buildFieldLabel('Selfie with ID (Optional)', isRequired: false),
          const SizedBox(height: 6),
          _buildFileUploadBox(
            title: _indivSelfieFileName ??
                'Click to select selfie with ID (Optional, speeds up review)',
            isUploaded: _indivSelfieBytes != null,
            onTap: () => _pickFile(
              onPicked: (bytes, name) {
                _indivSelfieBytes = bytes;
                _indivSelfieFileName = name;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Source of Funds Dropdown
          _buildFieldLabel('Source of Funds', isRequired: true),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _indivSourceOfFunds,
            decoration:
                _inputDecoration(prefixIcon: Icons.account_balance_wallet_outlined),
            items: const [
              DropdownMenuItem(
                  value: 'Employment Income', child: Text('Employment Income')),
              DropdownMenuItem(
                  value: 'Business Income', child: Text('Business Income')),
              DropdownMenuItem(
                  value: 'Personal Savings', child: Text('Personal Savings')),
              DropdownMenuItem(
                  value: 'Inheritance', child: Text('Inheritance')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _indivSourceOfFunds = val);
            },
          ),
          const SizedBox(height: 16),

          // Monthly Giving Budget Bracket
          _buildFieldLabel('Monthly Giving Budget Bracket', isRequired: true),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _indivGivingBudget,
            decoration: _inputDecoration(prefixIcon: Icons.payments_outlined),
            items: const [
              DropdownMenuItem(
                  value: '₱500-2k', child: Text('₱500 – ₱2,000 / month')),
              DropdownMenuItem(
                  value: '₱2k-10k', child: Text('₱2,000 – ₱10,000 / month')),
              DropdownMenuItem(
                  value: '₱10k+', child: Text('₱10,000+ / month')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _indivGivingBudget = val);
            },
          ),
          const SizedBox(height: 16),

          // TIN (Optional)
          _buildFieldLabel('Tax Identification Number (TIN, Optional)',
              isRequired: false),
          const SizedBox(height: 6),
          TextFormField(
            controller: _indivTinCtrl,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: _inputDecoration(
              hint: '000-000-000-000',
              prefixIcon: Icons.receipt_long_outlined,
            ),
          ),
          const SizedBox(height: 20),

          // Consent Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _indivConsent,
                  activeColor: const Color(0xFF0F4D2E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  onChanged: (v) => setState(() => _indivConsent = v ?? false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'I consent to the collection and secure processing of my personal and financial information under RA 10173 (Philippine Data Privacy Act) for identity verification and direct grant administration.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF404942),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() => _indivCurrentStep = 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF404942),
                  side: const BorderSide(color: Color(0xFFC0C9C0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                child: const Text('← Back'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (_formKeyIndivStep2.currentState!.validate()) {
                            _submitIndividual();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4D2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Verification',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndivStep3Confirmation() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFB3F1C6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 38,
            color: Color(0xFF0F4D2E),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Application submitted.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1B1F),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Text(
            'Verification status: Pending',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF92400E),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Thank you, ${_indivLegalNameCtrl.text.trim()}. Your individual benefactor account has been registered. You can immediately access your Benefactor Console while our compliance committee reviews your submitted PhilSys/Government credentials.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF404942),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              context.go('/provider-home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4D2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Access Individual Provider Console',
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
        ),
      ],
    );
  }

  // ===========================================================================
  // PART 3: ORGANIZATION PROVIDER FLOW (4 STEPS + CONFIRMATION)
  // ===========================================================================

  Widget _buildOrganizationFlow() {
    switch (_orgCurrentStep) {
      case 1:
        return _buildOrgStep1Details();
      case 2:
        return _buildOrgStep2Representative();
      case 3:
        return _buildOrgStep3Uploads();
      case 4:
        return _buildOrgStep4Review();
      default:
        return _buildOrgStep5Confirmation();
    }
  }

  Widget _buildOrgStep1Details() {
    return Form(
      key: _formKeyOrgStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepProgressHeader(
            currentStep: 1,
            totalSteps: 4,
            stepTitle: 'Step 1 — Organization Details',
            subtitle:
                'Institutional identity and Philippine regulatory registration numbers.',
          ),
          const SizedBox(height: 20),

          // Org Name
          _buildFieldLabel('Organization Name', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _orgNameCtrl,
            style: GoogleFonts.inter(fontSize: 14),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Enter your organization name.'
                : null,
            decoration: _inputDecoration(
              hint: 'e.g. Hope Education Foundation, Inc.',
              prefixIcon: Icons.apartment_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // Org Type Dropdown
          _buildFieldLabel('Organization Type', isRequired: true),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _orgType,
            decoration: _inputDecoration(prefixIcon: Icons.category_outlined),
            items: const [
              DropdownMenuItem(
                  value: 'Foundation',
                  child: Text('Foundation (Non-Stock Non-Profit)')),
              DropdownMenuItem(
                  value: 'Corporate',
                  child: Text('Corporate (CSR / Endowment)')),
              DropdownMenuItem(
                  value: 'SUC/State College',
                  child: Text('SUC / State College')),
              DropdownMenuItem(
                  value: 'LGU',
                  child: Text('LGU (Local Government Unit)')),
              DropdownMenuItem(
                  value: 'NGO',
                  child: Text('NGO (Non-Governmental Organization)')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _orgType = val);
            },
          ),
          const SizedBox(height: 16),

          // SEC / BIR Registration Number
          _buildFieldLabel('SEC / BIR Registration Number', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _orgRegNumberCtrl,
            style: GoogleFonts.inter(fontSize: 14),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Enter SEC or BIR registration number.'
                : null,
            decoration: _inputDecoration(
              hint: 'e.g. CS202109844 or 000-000-000-000',
              prefixIcon: Icons.assured_workload_outlined,
            ),
          ),
          const SizedBox(height: 24),

          // Action
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_formKeyOrgStep1.currentState!.validate()) {
                  setState(() => _orgCurrentStep = 2);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4D2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Proceed to Representative Details',
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgStep2Representative() {
    final password = _orgPasswordCtrl.text;
    final passwordStrength = PasswordValidator.strengthScore(password);

    return Form(
      key: _formKeyOrgStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepProgressHeader(
            currentStep: 2,
            totalSteps: 4,
            stepTitle: 'Step 2 — Authorized Representative',
            subtitle:
                'The representative work email and password will be used to log in to the workstation.',
          ),
          const SizedBox(height: 20),

          // Full Name
          _buildFieldLabel('Representative Full Name', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _orgRepNameCtrl,
            style: GoogleFonts.inter(fontSize: 14),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Enter representative full name.'
                : null,
            decoration: _inputDecoration(
              hint: 'Maria Santos',
              prefixIcon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // Position / Title
          _buildFieldLabel('Position / Title', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _orgRepPositionCtrl,
            style: GoogleFonts.inter(fontSize: 14),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Enter official position.'
                : null,
            decoration: _inputDecoration(
              hint: 'Grants Director / Program Lead',
              prefixIcon: Icons.work_outline_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // Work Email
          _buildFieldLabel('Official Work Email', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _orgRepEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(fontSize: 14),
            validator: _validateEmail,
            decoration: _inputDecoration(
              hint: 'msantos@ayalafoundation.org.ph',
              prefixIcon: Icons.mail_outline_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // Phone
          _buildFieldLabel('Contact Phone Number', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _orgRepPhoneCtrl,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.inter(fontSize: 14),
            validator: _validatePhone,
            decoration: _inputDecoration(
              hint: '0917 123 4567 or +639171234567',
              prefixIcon: Icons.phone_android_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // Password
          _buildFieldLabel('Workstation Password', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _orgPasswordCtrl,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(fontSize: 14),
            onChanged: (val) => setState(() {}),
            validator: (v) => PasswordValidator.validatePassword(v),
            decoration: _inputDecoration(
              hint: '••••••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 18,
                  color: const Color(0xFF707971),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Password Complexity Widget
          _buildPasswordComplexityWidget(password, passwordStrength),
          const SizedBox(height: 14),

          // Confirm Password
          _buildFieldLabel('Confirm Password', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _orgConfirmCtrl,
            obscureText: _obscureConfirm,
            style: GoogleFonts.inter(fontSize: 14),
            validator: (v) => PasswordValidator.validateConfirmPassword(
              v,
              _orgPasswordCtrl.text,
            ),
            decoration: _inputDecoration(
              hint: '••••••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 18,
                  color: const Color(0xFF707971),
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _orgCurrentStep = 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF404942),
                  side: const BorderSide(color: Color(0xFFC0C9C0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                child: const Text('← Back'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKeyOrgStep2.currentState!.validate()) {
                      setState(() => _orgCurrentStep = 3);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4D2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Proceed to Document Uploads',
                            maxLines: 1,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrgStep3Uploads() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepProgressHeader(
          currentStep: 3,
          totalSteps: 4,
          stepTitle: 'Step 3 — Document Uploads',
          subtitle:
              'Upload SEC Registration, BIR 2303, and Board Resolution (PDF, JPG, PNG up to 5 MB).',
        ),
        const SizedBox(height: 20),

        // SEC Certificate
        _buildFieldLabel('SEC Certificate of Registration', isRequired: true),
        const SizedBox(height: 6),
        _buildFileUploadBox(
          title: _orgSecFileName ?? 'Select SEC Certificate (PDF/JPG/PNG)',
          isUploaded: _orgSecBytes != null,
          onTap: () => _pickFile(
            onPicked: (bytes, name) {
              _orgSecBytes = bytes;
              _orgSecFileName = name;
            },
          ),
        ),
        const SizedBox(height: 16),

        // BIR 2303
        _buildFieldLabel('BIR Certificate of Registration (Form 2303)',
            isRequired: true),
        const SizedBox(height: 6),
        _buildFileUploadBox(
          title: _orgBirFileName ?? 'Select BIR 2303 (PDF/JPG/PNG)',
          isUploaded: _orgBirBytes != null,
          onTap: () => _pickFile(
            onPicked: (bytes, name) {
              _orgBirBytes = bytes;
              _orgBirFileName = name;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Board Resolution
        _buildFieldLabel(
            'Board Resolution / Secretary Certificate (Authorized Signatory)',
            isRequired: false),
        const SizedBox(height: 6),
        _buildFileUploadBox(
          title: _orgBoardFileName ??
              'Select Board Resolution (Optional, speeds up review)',
          isUploaded: _orgBoardBytes != null,
          onTap: () => _pickFile(
            onPicked: (bytes, name) {
              _orgBoardBytes = bytes;
              _orgBoardFileName = name;
            },
          ),
        ),
        const SizedBox(height: 24),

        // Actions
        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _orgCurrentStep = 2),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF404942),
                side: const BorderSide(color: Color(0xFFC0C9C0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('← Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_orgSecBytes == null || _orgBirBytes == null) {
                    _showError(
                        'Please upload both your SEC Certificate and BIR 2303 before continuing.');
                    return;
                  }
                  setState(() => _orgCurrentStep = 4);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4D2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Review Application Dossier',
                          maxLines: 1,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrgStep4Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepProgressHeader(
          currentStep: 4,
          totalSteps: 4,
          stepTitle: 'Step 4 — Review & Accreditation Submission',
          subtitle:
              'Verify all institutional details. You may edit any section before final submission.',
        ),
        const SizedBox(height: 20),

        // Section 1: Org Details
        _buildReviewSection(
          title: 'Organization Details',
          onEdit: () => setState(() => _orgCurrentStep = 1),
          items: [
            MapEntry('Legal Entity Name', _orgNameCtrl.text.trim()),
            MapEntry('Entity Type', _orgType),
            MapEntry('Registration No.', _maskValue(_orgRegNumberCtrl.text.trim())),
          ],
        ),
        const SizedBox(height: 14),

        // Section 2: Authorized Representative
        _buildReviewSection(
          title: 'Authorized Representative',
          onEdit: () => setState(() => _orgCurrentStep = 2),
          items: [
            MapEntry('Representative Name', _orgRepNameCtrl.text.trim()),
            MapEntry('Position / Title', _orgRepPositionCtrl.text.trim()),
            MapEntry('Account Email', _orgRepEmailCtrl.text.trim()),
            MapEntry('Contact Phone', _orgRepPhoneCtrl.text.trim()),
          ],
        ),
        const SizedBox(height: 14),

        // Section 3: Uploaded Documents
        _buildReviewSection(
          title: 'Accreditation Documents',
          onEdit: () => setState(() => _orgCurrentStep = 3),
          items: [
            MapEntry('SEC Certificate', _orgSecFileName ?? 'None'),
            MapEntry('BIR 2303', _orgBirFileName ?? 'None'),
            MapEntry('Board Resolution', _orgBoardFileName ?? 'Not provided'),
          ],
        ),
        const SizedBox(height: 20),

        // Consent Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _orgConsent,
                activeColor: const Color(0xFF0F4D2E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                onChanged: (v) => setState(() => _orgConsent = v ?? false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'I confirm that I am an authorized representative of the entity with full authority to register and disburse educational aid under RA 10173 and applicable Philippine foundation governance regulations.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF404942),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Actions
        Row(
          children: [
            OutlinedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _orgCurrentStep = 3),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF404942),
                side: const BorderSide(color: Color(0xFFC0C9C0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('← Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrganization,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4D2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Submit for Accreditation',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrgStep5Confirmation() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFB3F1C6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.domain_verification_rounded,
            size: 38,
            color: Color(0xFF0F4D2E),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Submitted for accreditation.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1B1F),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Text(
            'Status: Pending review',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF92400E),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Your institutional dossier for ${_orgNameCtrl.text.trim()} has been dispatched to the Scholaris accreditation engine. You may immediately explore the Provider Console while our clearance auditors review your SEC & BIR documents.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF404942),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              context.go('/provider-home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4D2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Access Organization Console',
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
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable Step & UI Widgets
  // ---------------------------------------------------------------------------

  Widget _buildStepProgressHeader({
    required int currentStep,
    required int totalSteps,
    required String stepTitle,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP $currentStep OF $totalSteps',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F4D2E),
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${((currentStep / totalSteps) * 100).toInt()}% COMPLETED',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF707971),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: currentStep / totalSteps,
            minHeight: 5,
            backgroundColor: const Color(0xFFEEEDF3),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F4D2E)),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          stepTitle,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1B1F),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0xFF404942),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1B1F),
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFBA1A1A),
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 13,
        color: const Color(0xFF707971).withValues(alpha: 0.6),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: const Color(0xFF707971))
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF4F3F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0F4D2E), width: 1.5),
      ),
    );
  }

  Widget _buildFileUploadBox({
    required String title,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUploaded
              ? const Color(0xFFB3F1C6).withValues(alpha: 0.2)
              : const Color(0xFFF4F3F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded
                ? const Color(0xFF0F4D2E)
                : const Color(0xFFC0C9C0),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isUploaded
                  ? Icons.check_circle_rounded
                  : Icons.cloud_upload_outlined,
              size: 22,
              color: isUploaded
                  ? const Color(0xFF0F4D2E)
                  : const Color(0xFF707971),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isUploaded ? FontWeight.w600 : FontWeight.w400,
                  color: isUploaded
                      ? const Color(0xFF0F4D2E)
                      : const Color(0xFF404942),
                ),
              ),
            ),
            Text(
              isUploaded ? 'Change' : 'Browse',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F4D2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordComplexityWidget(String password, int passwordStrength) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final active = index < passwordStrength;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 4,
                decoration: BoxDecoration(
                  color: active
                      ? (passwordStrength >= 3
                          ? const Color(0xFF0F4D2E)
                          : const Color(0xFFF99A00))
                      : const Color(0xFFEEEDF3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Complexity',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF707971),
              ),
            ),
            Text(
              PasswordValidator.strengthLabel(passwordStrength),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: passwordStrength >= 3
                    ? const Color(0xFF0F4D2E)
                    : (passwordStrength >= 2
                        ? const Color(0xFFF99A00)
                        : const Color(0xFFBA1A1A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F3F8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _complexityRow(
                'At least 8 characters long',
                PasswordValidator.hasMinLength(password),
              ),
              _complexityRow(
                'Uppercase & lowercase letters',
                PasswordValidator.hasUppercase(password) &&
                    PasswordValidator.hasLowercase(password),
              ),
              _complexityRow(
                'At least one number (0-9)',
                PasswordValidator.hasDigit(password),
              ),
              _complexityRow(
                'Special character (!@#\$%^&*)',
                PasswordValidator.hasSpecialChar(password),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _complexityRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 13,
            color: met ? const Color(0xFF0F4D2E) : const Color(0xFF707971),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: met
                  ? const Color(0xFF1A1B1F)
                  : const Color(0xFF707971),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection({
    required String title,
    required VoidCallback onEdit,
    required List<MapEntry<String, String>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1B1F),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F4D2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF707971),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      e.value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1B1F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskValue(String raw) {
    if (raw.isEmpty) return '—';
    if (raw.length <= 4) return '•••• $raw';
    return '•••• •••• ${raw.substring(raw.length - 4)}';
  }

  Widget _buildEmailConfirmationScreen() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF1A1B1F).withValues(alpha: 0.08),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFB3F1C6).withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: Color(0xFF0F4D2E),
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Confirm Your Email Address',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1B1F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We have sent an accreditation confirmation link to:\n${_pendingConfirmationEmail ?? 'your registered email'}\n\nPlease check your inbox, confirm your email address, and then sign in to finish your provider verification.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF707971),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                context.go('/provider/login?type=$_providerType');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4D2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Proceed to Provider Sign In',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceFooter() {
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
        const SizedBox(height: 4),
        Text(
          '© 2026 Scholaris Philippines • Provider Accreditation Framework',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF707971),
          ),
        ),
      ],
    );
  }
}
