// lib/features/profile/presentation/profile_setup_screen.dart
//
// Multi-step profile setup wizard. The active step is given by [step]
// ('personal' | 'academic' | 'financial'); all field values live in
// [profileSetupProvider] so nothing is lost between steps.
//
// Validation is performed by the domain layer (ProfileValidator) through
// [profileSetupProvider]; this screen only surfaces the resulting per-field
// errors and guides the user. Required fields are marked with `*`, optional
// fields are labeled "(optional)".

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/models/profile_validator.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/shared/widgets/success_overlay.dart';

// Scholaris brand palette.
const _primary = Color(0xFF0F4D2E);
const _accent = Color(0xFFF1B41E);
const _background = Color(0xFFFAFAF8);
const _errorColor = Color(0xFFB3261E);

const _inputRadius = 12.0;

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, required this.step});

  final String step;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _nationalityController;
  late final TextEditingController _courseController;
  late final TextEditingController _schoolController;
  late final TextEditingController _gpaController;
  late final TextEditingController _incomeController;
  late final TextEditingController _provinceController;
  late final TextEditingController _cityController;

  int get _stepIndex => switch (widget.step) {
        'personal' => 1,
        'academic' => 2,
        _ => 3,
      };

  String get _stepTitle => switch (widget.step) {
        'personal' => 'Personal Information',
        'academic' => 'Academic Information',
        _ => 'Financial Information',
      };

  String get _stepSubtitle => switch (widget.step) {
        'personal' => 'Basic details so we can personalize your experience.',
        'academic' => 'We use this to match scholarships for your program.',
        _ => 'Helps us find need-based scholarships. This stays private.',
      };

  @override
  void initState() {
    super.initState();
    // The draft lives in profileSetupProvider, keyed by the authenticated user.
    // The router guards this route to signed-in users, so userId is present in
    // production; a null here only happens during a brief auth transition.
    final userId = ref.read(currentUserIdProvider);
    final state = userId == null
        ? const ProfileSetupState()
        : ref.read(profileSetupProvider(userId));
    _fullNameController = TextEditingController(text: state.fullName);
    _nationalityController = TextEditingController(text: state.nationality);
    _courseController = TextEditingController(text: state.course);
    _schoolController = TextEditingController(text: state.school);
    _gpaController = TextEditingController(text: state.gpa);
    _incomeController =
        TextEditingController(text: state.monthlyFamilyIncome);
    _provinceController = TextEditingController(text: state.province);
    _cityController = TextEditingController(text: state.cityMunicipality);
  }

  /// A returning user's persisted profile may finish loading after this screen
  /// mounted (the notifier hydrates asynchronously). When it lands, mirror the
  /// hydrated values into the controllers so the form is populated.
  void _syncHydration(ProfileSetupState? previous, ProfileSetupState next) {
    if (next.hydrated && !(previous?.hydrated ?? false)) {
      // TEMP DEBUG: log hydration event
      debugPrint('[ProfileSetup] hydration landed: attempted=${next.attempted}, fullName="${next.fullName}"');
      // If the user has already started interacting with the form, do NOT
      // overwrite their in-progress input with the persisted values.
      if (next.attempted) {
        debugPrint('[ProfileSetup] hydration skipped because form was already attempted');
        return;
      }
      _syncFromState(next);
    }
  }

  void _syncFromState(ProfileSetupState state) {
    _fullNameController.text = state.fullName;
    _nationalityController.text = state.nationality;
    _courseController.text = state.course;
    _schoolController.text = state.school;
    _gpaController.text = state.gpa;
    _incomeController.text = state.monthlyFamilyIncome;
    _provinceController.text = state.province;
    _cityController.text = state.cityMunicipality;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nationalityController.dispose();
    _courseController.dispose();
    _schoolController.dispose();
    _gpaController.dispose();
    _incomeController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      // The router only shows this screen to signed-in users; this guards the
      // brief transition between an auth change and the redirect.
      return const Scaffold(body: SizedBox.shrink());
    }

    final state = ref.watch(profileSetupProvider(userId));
    final notifier = ref.read(profileSetupProvider(userId).notifier);
    ref.listen(profileSetupProvider(userId), _syncHydration);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profile Setup',
          style: GoogleFonts.poppins(
            color: _primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgressHeader(),
                const SizedBox(height: 24),
                Text(
                  _stepTitle,
                  style: GoogleFonts.poppins(
                    color: _primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _stepSubtitle,
                  style: GoogleFonts.openSans(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                ..._buildStepFields(context, notifier, state),
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorBanner(state.error!),
                ],
                const SizedBox(height: 24),
                _buildButtons(context, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Progress header ------------------------------------------------------

  Widget _buildProgressHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $_stepIndex of 3',
          style: GoogleFonts.openSans(
            color: _primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _stepIndex / 3,
            minHeight: 6,
            backgroundColor: _primary.withValues(alpha: 0.12),
            color: _accent,
          ),
        ),
      ],
    );
  }

  // --- Step fields ----------------------------------------------------------

  List<Widget> _buildStepFields(
    BuildContext context,
    ProfileSetupNotifier notifier,
    ProfileSetupState state,
  ) {
    return switch (widget.step) {
      'personal' => [
          _textField(
            label: 'Full Name',
            controller: _fullNameController,
            onChanged: notifier.setFullName,
            required: true,
            validator: (_) => _fieldError((e) => e.fullName),
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'Nationality',
            controller: _nationalityController,
            onChanged: notifier.setNationality,
            required: true,
            validator: (_) => _fieldError((e) => e.nationality),
          ),
          const SizedBox(height: 16),
          _birthDateField(context, notifier, state),
        ],
      'academic' => [
          _dropdown<int>(
            label: 'Year Level',
            required: true,
            value: state.yearLevel,
            items: List.generate(5, (index) {
              final level = index + 1;
              return DropdownMenuItem(
                value: level,
                child: Text(
                  '$level${_ordinal(level)} Year',
                  style: GoogleFonts.openSans(),
                ),
              );
            }),
            validator: (_) => _fieldError((e) => e.yearLevel),
            onChanged: (value) {
              if (value != null) notifier.setYearLevel(value);
            },
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'Course',
            controller: _courseController,
            onChanged: notifier.setCourse,
            required: true,
            validator: (_) => _fieldError((e) => e.course),
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'School',
            controller: _schoolController,
            onChanged: notifier.setSchool,
            optional: true,
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'GPA',
            controller: _gpaController,
            onChanged: notifier.setGpa,
            required: true,
            helperText: 'Range: 1.0 - 4.0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            validator: (_) => _fieldError((e) => e.gpa),
          ),
        ],
      _ => [
          _textField(
            label: 'Monthly Family Income',
            controller: _incomeController,
            onChanged: notifier.setMonthlyFamilyIncome,
            required: !state.incomeUndisclosed,
            helperText: 'e.g. 20,000 · optional to share',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            enabled: !state.incomeUndisclosed,
            prefixText: '₱',
            validator: (_) => _fieldError((e) => e.monthlyFamilyIncome),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: _primary,
            title: Text(
              'Prefer not to say',
              style: GoogleFonts.openSans(),
            ),
            value: state.incomeUndisclosed,
            onChanged: (value) {
              final checked = value ?? false;
              if (checked) _incomeController.clear();
              notifier.setIncomeUndisclosed(checked);
            },
          ),
          const SizedBox(height: 8),
          _dropdown<String>(
            label: 'Region',
            required: true,
            value: state.region,
            hint: 'Select your region',
            items: kPhilippineRegions
                .map(
                  (region) => DropdownMenuItem(
                    value: region,
                    child: Text(region, style: GoogleFonts.openSans()),
                  ),
                )
                .toList(),
            validator: (_) => _fieldError((e) => e.region),
            onChanged: (value) {
              if (value != null) notifier.setRegion(value);
            },
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'Province',
            controller: _provinceController,
            onChanged: notifier.setProvince,
            optional: true,
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'City / Municipality',
            controller: _cityController,
            onChanged: notifier.setCityMunicipality,
            optional: true,
          ),
          const SizedBox(height: 8),
          _optionalSwitch(
            title: 'Has a disability',
            subtitle: 'PWD-priority scholarships may apply',
            value: state.hasDisability,
            onChanged: notifier.setHasDisability,
          ),
          _optionalSwitch(
            title: 'Indigenous person',
            subtitle: 'Indigenous-specific scholarships may apply',
            value: state.isIndigenous,
            onChanged: notifier.setIsIndigenous,
          ),
        ],
    };
  }

  Widget _birthDateField(
    BuildContext context,
    ProfileSetupNotifier notifier,
    ProfileSetupState state,
  ) {
    final birthDate = state.birthDate;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: birthDate ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          notifier.setBirthDate(picked);
        }
      },
      borderRadius: BorderRadius.circular(_inputRadius),
      child: InputDecorator(
        decoration: _fieldDecoration(label: 'Birth Date', optional: true),
        child: Text(
          birthDate == null ? 'Select date' : formatDate(birthDate),
          style: GoogleFonts.openSans(
            color: birthDate == null ? Colors.black54 : Colors.black,
          ),
        ),
      ),
    );
  }

  // --- Shared field widgets -------------------------------------------------

  /// Reads the latest per-field error from the domain validator.
  String? _fieldError(String? Function(ProfileFieldErrors) pick) {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;
    final errors = ref.read(profileSetupProvider(userId)).fieldErrors;
    return errors == null ? null : pick(errors);
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    bool required = false,
    bool optional = false,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    FormFieldValidator<String>? validator,
    bool enabled = true,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.openSans(),
      decoration: _fieldDecoration(
        label: label,
        required: required,
        optional: optional,
        helperText: helperText,
        prefixText: prefixText,
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool required = false,
    FormFieldValidator<T>? validator,
    String? hint,
  }) {
    return DropdownButtonFormField<T>(
      key: ValueKey(value),
      initialValue: value,
      hint: hint == null
          ? null
          : Text(hint, style: GoogleFonts.openSans(color: Colors.black54)),
      onChanged: onChanged,
      items: items,
      validator: validator,
      style: GoogleFonts.openSans(),
      decoration: _fieldDecoration(label: label, required: required),
    );
  }

  Widget _optionalSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.openSans(color: Colors.black54, fontSize: 12),
      ),
      value: value,
      activeThumbColor: _primary,
      onChanged: onChanged,
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    bool required = false,
    bool optional = false,
    String? helperText,
    String? prefixText,
  }) {
    final labelText = required
        ? '$label *'
        : optional
            ? '$label (optional)'
            : label;
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.openSans(color: Colors.black54),
      helperText: helperText,
      helperStyle: GoogleFonts.openSans(
        color: Colors.black45,
        fontSize: 12,
      ),
      prefixText: prefixText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputRadius),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputRadius),
        borderSide: const BorderSide(color: _errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputRadius),
        borderSide: const BorderSide(color: _errorColor, width: 1.5),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(_inputRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _errorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.openSans(color: _errorColor),
            ),
          ),
        ],
      ),
    );
  }

  // --- Buttons --------------------------------------------------------------

  Widget _buildButtons(BuildContext context, ProfileSetupState state) {
    final isLastStep = widget.step == 'financial';
    final backRoute = widget.step == 'academic'
        ? ProfileSetupRoute.personal
        : ProfileSetupRoute.academic;

    return Row(
      children: [
        if (widget.step != 'personal') ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.go(backRoute),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_inputRadius),
                ),
              ),
              child: Text(
                'Back',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: state.isSubmitting
                ? null
                : (isLastStep ? _onSubmit : _onNext),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_inputRadius),
              ),
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isLastStep ? 'Save Profile' : 'Next',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  // --- Navigation -----------------------------------------------------------

  /// The setup notifier for the currently signed-in user. Only reachable when
  /// signed in (the router guards this route and build guards null userId).
  ProfileSetupNotifier get _notifier =>
      ref.read(profileSetupProvider(ref.read(currentUserIdProvider)!).notifier);

  void _onNext() {
    final notifier = _notifier;
    notifier.validateStep(widget.step);

    final formState = _formKey.currentState;
    final isValid = formState?.validate() ?? false;

    // TEMP DEBUG: log validation result and field errors
    final userId = ref.read(currentUserIdProvider);
    final fieldErrors = userId == null
        ? null
        : ref.read(profileSetupProvider(userId)).fieldErrors;
    debugPrint('[ProfileSetup] _onNext step=$widget.step isValid=$isValid fieldErrors=$fieldErrors');

    if (!isValid) return;

    final nextRoute = widget.step == 'academic'
        ? ProfileSetupRoute.financial
        : ProfileSetupRoute.academic;
    context.go(nextRoute);
  }

  Future<void> _onSubmit() async {
    final notifier = _notifier;
    notifier.validateStep('financial');

    final userId = ref.read(currentUserIdProvider);
    final preValidateRegion = userId == null
        ? null
        : ref.read(profileSetupProvider(userId)).region;
    final preValidateErrors = userId == null
        ? null
        : ref.read(profileSetupProvider(userId)).fieldErrors;
    debugPrint(
      '[ProfileSetup] _onSubmit preValidate region=$preValidateRegion fieldErrors=$preValidateErrors',
    );

    final formState = _formKey.currentState;
    final isValid = formState?.validate() ?? false;
    debugPrint('[ProfileSetup] _onSubmit isValid=$isValid');

    if (!isValid) {
      final postErrors = userId == null
          ? null
          : ref.read(profileSetupProvider(userId)).fieldErrors;
      debugPrint('[ProfileSetup] _onSubmit blocked fieldErrors=$postErrors');
      return;
    }

    final ok = await notifier.submit();
    if (!ok) return;

    // Re-check setup_complete so the router's redirect lets us through to /home,
    // and refetch the shared current profile so tabs show the saved values.
    ref.invalidate(profileCompleteProvider);
    ref.invalidate(currentProfileProvider);
    await ref.read(profileCompleteProvider.future);

    if (mounted) {
      await SuccessOverlay.show(context);
      if (mounted) context.go('/home');
    }
  }

  String _ordinal(int n) {
    if (n == 1) return 'st';
    if (n == 2) return 'nd';
    if (n == 3) return 'rd';
    return 'th';
  }
}
