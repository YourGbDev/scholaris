// lib/features/profile/presentation/profile_setup_screen.dart
//
// Multi-step profile setup wizard. Rebuilt to match the Stitch design
// system with Philippine context (segmented micro-bar step tracker,
// 740+ Active Philippine Grants insight banner, UniFAST / SUC / DOST-SEI
// guidance, and Peso formatting).
//
// Preserves domain validation (ProfileValidator), profileSetupProvider state,
// and all test contracts.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/models/avatar_item.dart';
import 'package:scholaris/features/profile/models/profile_validator.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/presentation/widgets/avatar_display.dart';
import 'package:scholaris/features/profile/providers/avatar_provider.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';
import 'package:scholaris/shared/widgets/success_overlay.dart';

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
        'personal' => 'Basic details so we can personalize your experience and match grants.',
        'academic' => 'We use this to match scholarships for your university and major program.',
        _ => 'Helps us find need-based scholarships and subsidies. This stays private.',
      };

  @override
  void initState() {
    super.initState();
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

  void _syncHydration(ProfileSetupState? previous, ProfileSetupState next) {
    if (next.hydrated && !(previous?.hydrated ?? false)) {
      if (next.attempted) return;
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
      return const Scaffold(body: SizedBox.shrink());
    }

    final state = ref.watch(profileSetupProvider(userId));
    final notifier = ref.read(profileSetupProvider(userId).notifier);
    ref.listen(profileSetupProvider(userId), _syncHydration);

    final pct = switch (_stepIndex) {
      1 => '33%',
      2 => '66%',
      _ => '100%',
    };

    return Scaffold(
      backgroundColor: kSurfaceWarm,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: widget.step != 'personal'
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: kTextPrimary),
                onPressed: () {
                  final backRoute = widget.step == 'academic'
                      ? ProfileSetupRoute.personal
                      : ProfileSetupRoute.academic;
                  context.go(backRoute);
                },
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ScholarisLogo(compact: true),
            const SizedBox(width: 8),
            Text(
              'Profile Setup',
              style: poppins(
                color: kPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Segmented Micro-Bar & Step Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step $_stepIndex of 3',
                          style: poppins(
                            color: kPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kPrimaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pct Complete',
                            style: poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 3-segment micro-bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: _stepIndex >= 2 ? kPrimary : const Color(0xFFDDE2F3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: _stepIndex >= 3 ? kPrimary : const Color(0xFFDDE2F3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Step Header Titles
                    Text(
                      _stepTitle,
                      style: poppins(
                        color: kTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepSubtitle,
                      style: openSans(
                        color: kTextSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Philippine Grant Match Insight Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDDE2F3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD2E4FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF1B3A5C),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '740+ Active Philippine Grants',
                                  style: poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kTextPrimary,
                                  ),
                                ),
                                Text(
                                  'DOST-SEI, CHED UniFAST, LGU subsidies, & private foundations open.',
                                  style: openSans(
                                    fontSize: 11,
                                    color: kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Fields
                    ..._buildStepFields(context, notifier, state),

                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(state.error!),
                    ],
                    const SizedBox(height: 28),

                    // Action Buttons
                    _buildButtons(context, state),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
          _buildAvatarSetupCard(context),
          const SizedBox(height: 20),
          _textField(
            label: 'Full Name',
            controller: _fullNameController,
            onChanged: notifier.setFullName,
            required: true,
            hintText: 'e.g. Maya Santos Dela Cruz',
            prefixIcon: Icons.badge_outlined,
            helperText: 'Matches PSA birth certificate and official enrollment records.',
            validator: (_) => _fieldError((e) => e.fullName),
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'Nationality',
            controller: _nationalityController,
            onChanged: notifier.setNationality,
            required: true,
            hintText: 'e.g. Filipino',
            prefixIcon: Icons.flag_outlined,
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
            prefixIcon: Icons.calendar_today_rounded,
            items: List.generate(5, (index) {
              final level = index + 1;
              return DropdownMenuItem(
                value: level,
                child: Text(
                  '$level${_ordinal(level)} Year',
                  style: openSans(),
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
            hintText: 'e.g. BS Computer Science, BA Communication',
            prefixIcon: Icons.school_outlined,
            validator: (_) => _fieldError((e) => e.course),
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'School',
            controller: _schoolController,
            onChanged: notifier.setSchool,
            optional: true,
            hintText: 'e.g. UP Diliman, PUP Manila, UST, DLSU, or SUC',
            prefixIcon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'GPA',
            controller: _gpaController,
            onChanged: notifier.setGpa,
            required: true,
            helperText: 'Range: 1.0 - 4.0 (GWA or cumulative GPA)',
            hintText: 'e.g. 3.50 or 1.75',
            prefixIcon: Icons.grade_outlined,
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
            helperText: 'e.g. 20,000 · used for need-based grant filtering',
            hintText: '20,000',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            enabled: !state.incomeUndisclosed,
            prefixText: '₱ ',
            prefixIcon: Icons.payments_outlined,
            validator: (_) => _fieldError((e) => e.monthlyFamilyIncome),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: kBorderLight),
            ),
            child: CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: kPrimary,
              title: Text(
                'Prefer not to say',
                style: openSans(fontSize: 13, color: kTextPrimary),
              ),
              value: state.incomeUndisclosed,
              onChanged: (value) {
                final checked = value ?? false;
                if (checked) _incomeController.clear();
                notifier.setIncomeUndisclosed(checked);
              },
            ),
          ),
          const SizedBox(height: 14),
          _dropdown<String>(
            label: 'Region',
            required: true,
            value: state.region,
            hint: 'Select your Philippine region',
            prefixIcon: Icons.map_outlined,
            items: kPhilippineRegions
                .map(
                  (region) => DropdownMenuItem(
                    value: region,
                    child: Text(region, style: openSans()),
                  ),
                )
                .toList(),
            validator: (_) => _fieldError((e) => e.region),
            onChanged: (value) {
              if (value != null) notifier.setRegion(value);
            },
          ),
          const SizedBox(height: 14),
          _textField(
            label: 'Province',
            controller: _provinceController,
            onChanged: notifier.setProvince,
            optional: true,
            hintText: 'e.g. Metro Manila, Cebu, Davao del Sur',
            prefixIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 14),
          _textField(
            label: 'City / Municipality',
            controller: _cityController,
            onChanged: notifier.setCityMunicipality,
            optional: true,
            hintText: 'e.g. Quezon City, Manila, Cebu City',
            prefixIcon: Icons.location_city_outlined,
          ),
          const SizedBox(height: 12),
          _optionalSwitch(
            title: 'Has a disability',
            subtitle: 'PWD-priority scholarships & DOST assistance may apply',
            value: state.hasDisability,
            onChanged: notifier.setHasDisability,
          ),
          const SizedBox(height: 8),
          _optionalSwitch(
            title: 'Indigenous person',
            subtitle: 'NCIP & Indigenous-specific educational funds may apply',
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
          initialDate: birthDate ?? DateTime(2003, 10, 14),
          firstDate: DateTime(1970),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          notifier.setBirthDate(picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _fieldDecoration(
          label: 'Birth Date',
          optional: true,
          prefixIcon: Icons.cake_outlined,
          helperText: 'Youth grants and fellowships filter by age eligibility (18–25).',
        ),
        child: Text(
          birthDate == null ? 'Select date' : formatDate(birthDate),
          style: openSans(
            fontSize: 14,
            color: birthDate == null ? Colors.black38 : kTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSetupCard(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider) ?? 'anonymous';
    final avatarState = ref.watch(avatarProvider(userId));
    final notifier = ref.read(avatarProvider(userId).notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderLight),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Avatar',
                      style: poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kNavyTrust,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pick a doodle or set up later',
                      style: openSans(
                        fontSize: 11,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey('avatar-setup-later'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  await notifier.skipToDefault();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Default doodle avatar assigned. You can change this anytime in your profile.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text(
                  'Set up later',
                  style: openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AvatarDisplay(
                avatarId: avatarState.avatarId,
                isRealPhoto: avatarState.isRealPhoto,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AvatarItem.presets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final preset = AvatarItem.presets[index];
                      final isSelected = !avatarState.isRealPhoto && avatarState.avatarId == preset.id;
                      return GestureDetector(
                        key: ValueKey('avatar-setup-option-${preset.id}'),
                        onTap: () => notifier.selectDoodle(preset.id),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? kPrimary : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: Center(
                            child: AvatarDisplay(
                              avatarId: preset.id,
                              isRealPhoto: false,
                              size: 44,
                              showVerifiedBadge: false,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
    String? hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    FormFieldValidator<String>? validator,
    bool enabled = true,
    String? prefixText,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: openSans(fontSize: 14, color: kTextPrimary),
      decoration: _fieldDecoration(
        label: label,
        required: required,
        optional: optional,
        helperText: helperText,
        hintText: hintText,
        prefixText: prefixText,
        prefixIcon: prefixIcon,
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
    IconData? prefixIcon,
  }) {
    return DropdownButtonFormField<T>(
      key: ValueKey(value),
      initialValue: value,
      hint: hint == null
          ? null
          : Text(hint, style: openSans(color: Colors.black38, fontSize: 13)),
      onChanged: onChanged,
      items: items,
      validator: validator,
      style: openSans(fontSize: 14, color: kTextPrimary),
      decoration: _fieldDecoration(
        label: label,
        required: required,
        prefixIcon: prefixIcon,
      ),
    );
  }

  Widget _optionalSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title, style: poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary)),
          subtitle: Text(
            subtitle,
            style: openSans(color: kTextSecondary, fontSize: 11),
          ),
          value: value,
          activeTrackColor: kPrimary,
          onChanged: onChanged,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    bool required = false,
    bool optional = false,
    String? helperText,
    String? hintText,
    String? prefixText,
    IconData? prefixIcon,
  }) {
    final labelText = required
        ? '$label *'
        : optional
            ? '$label (optional)'
            : label;
    return InputDecoration(
      labelText: labelText,
      labelStyle: openSans(color: kTextSecondary, fontSize: 13),
      hintText: hintText,
      hintStyle: openSans(color: Colors.black38, fontSize: 13),
      helperText: helperText,
      helperStyle: openSans(color: kTextSecondary, fontSize: 11),
      prefixText: prefixText,
      prefixStyle: poppins(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: kTextSecondary) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 1.5),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kErrorSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kError.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: kError, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: openSans(color: kError, fontSize: 13),
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
                foregroundColor: kPrimary,
                side: const BorderSide(color: kPrimary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Back',
                    style: poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: widget.step == 'personal' ? 1 : 2,
          child: ElevatedButton(
            onPressed: state.isSubmitting
                ? null
                : () => _handleNextOrSubmit(isLastStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.isSubmitting
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
                        isLastStep ? 'Complete Profile' : 'Continue',
                        style: poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleNextOrSubmit(bool isLastStep) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final notifier = ref.read(profileSetupProvider(userId).notifier);

    notifier.validateStep(widget.step);
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (isLastStep) {
      final success = await notifier.submit();
      if (!mounted) return;
      if (success) {
        await SuccessOverlay.show(context);
        if (!mounted) return;
        ref.invalidate(profileCompleteProvider);
        ref.invalidate(currentProfileProvider);
        try {
          await ref.read(profileCompleteProvider.future);
        } catch (_) {}
        if (!mounted) return;
        context.go('/home');
      }
    } else {
      final nextRoute = widget.step == 'academic'
          ? ProfileSetupRoute.financial
          : ProfileSetupRoute.academic;
      context.go(nextRoute);
    }
  }

  String _ordinal(int n) => switch (n) {
        1 => 'st',
        2 => 'nd',
        3 => 'rd',
        _ => 'th',
      };
}
