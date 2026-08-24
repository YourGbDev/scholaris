// lib/features/profile/presentation/profile_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';

// Scholaris brand palette.
const _primary = Color(0xFF0F4D2E);
const _accent = Color(0xFFF1B41E);
const _background = Color(0xFFFAFAF8);

const _inputRadius = 12.0;

/// Multi-step profile setup wizard. The active step is given by [step]
/// ('personal' | 'academic' | 'financial'); all field values live in
/// [profileSetupProvider] so nothing is lost between steps.
class ProfileSetupScreen extends ConsumerWidget {
  const ProfileSetupScreen({super.key, required this.step});

  final String step;

  int get _stepIndex => switch (step) {
        'personal' => 1,
        'academic' => 2,
        _ => 3,
      };

  String get _stepTitle => switch (step) {
        'personal' => 'Personal Information',
        'academic' => 'Academic Information',
        _ => 'Financial Information',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileSetupProvider);

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
              const SizedBox(height: 16),
              ..._buildStepFields(context, ref, state),
              if (state.error != null) ...[
                const SizedBox(height: 16),
                _buildErrorBanner(state.error!),
              ],
              const SizedBox(height: 24),
              _buildButtons(context, ref, state),
            ],
          ),
        ),
      ),
    );
  }

  // --- Shared progress indicator --------------------------------------------

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
    WidgetRef ref,
    ProfileSetupState state,
  ) {
    final notifier = ref.read(profileSetupProvider.notifier);

    return switch (step) {
      'personal' => [
          _textField(
            label: 'Full Name',
            value: state.fullName,
            onChanged: notifier.setFullName,
          ),
          const SizedBox(height: 16),
          _birthDateField(context, ref, state),
          const SizedBox(height: 16),
          _dropdown<String>(
            label: 'Gender',
            value: state.gender,
            items: const ['Male', 'Female', 'Prefer not to say']
                .map(
                  (gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender, style: GoogleFonts.openSans()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) notifier.setGender(value);
            },
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'Nationality',
            value: state.nationality,
            onChanged: notifier.setNationality,
          ),
        ],
      'academic' => [
          _dropdown<int>(
            label: 'Year Level',
            value: state.yearLevel,
            items: List.generate(4, (index) {
              final level = index + 1;
              return DropdownMenuItem(
                value: level,
                child: Text(
                  '$level${_ordinal(level)} Year',
                  style: GoogleFonts.openSans(),
                ),
              );
            }),
            onChanged: (value) {
              if (value != null) notifier.setYearLevel(value);
            },
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'Course',
            value: state.course,
            onChanged: notifier.setCourse,
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'School',
            value: state.school,
            onChanged: notifier.setSchool,
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'GPA (1.0 - 4.0)',
            value: state.gpa,
            onChanged: notifier.setGpa,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),
        ],
      _ => [
          _textField(
            label: 'Monthly Family Income',
            value: state.monthlyFamilyIncome,
            onChanged: notifier.setMonthlyFamilyIncome,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'Region',
            value: state.region,
            onChanged: notifier.setRegion,
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'Province',
            value: state.province,
            onChanged: notifier.setProvince,
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'City / Municipality',
            value: state.cityMunicipality,
            onChanged: notifier.setCityMunicipality,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Has a disability', style: GoogleFonts.openSans()),
            value: state.hasDisability,
            activeThumbColor: _primary,
            onChanged: notifier.setHasDisability,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Indigenous person', style: GoogleFonts.openSans()),
            value: state.isIndigenous,
            activeThumbColor: _primary,
            onChanged: notifier.setIsIndigenous,
          ),
        ],
    };
  }

  Widget _birthDateField(
    BuildContext context,
    WidgetRef ref,
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
          ref.read(profileSetupProvider.notifier).setBirthDate(picked);
        }
      },
      borderRadius: BorderRadius.circular(_inputRadius),
      child: InputDecorator(
        decoration: _fieldDecoration(label: 'Birth Date'),
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

  Widget _textField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.openSans(),
      decoration: _fieldDecoration(label: label),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      onChanged: onChanged,
      items: items,
      style: GoogleFonts.openSans(),
      decoration: _fieldDecoration(label: label),
    );
  }

  InputDecoration _fieldDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.openSans(color: Colors.black54),
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
          const Icon(Icons.error_outline, color: Color(0xFFB3261E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.openSans(color: const Color(0xFFB3261E)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Buttons --------------------------------------------------------------

  Widget _buildButtons(
    BuildContext context,
    WidgetRef ref,
    ProfileSetupState state,
  ) {
    final isLastStep = step == 'financial';
    final backRoute = step == 'academic'
        ? ProfileSetupRoute.personal
        : ProfileSetupRoute.academic;

    return Row(
      children: [
        if (step != 'personal') ...[
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
            onPressed: isLastStep
                ? (state.isSubmitting ? null : () => _onSubmit(context, ref))
                : () => _onNext(context, ref),
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
                    isLastStep ? 'Submit' : 'Next',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  // --- Navigation -----------------------------------------------------------

  void _onNext(BuildContext context, WidgetRef ref) {
    if (step == 'academic') {
      final state = ref.read(profileSetupProvider);
      final gpa = double.tryParse(state.gpa);
      if (gpa == null || gpa < 1.0 || gpa > 4.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'GPA must be a number between 1.0 and 4.0.',
              style: GoogleFonts.openSans(),
            ),
          ),
        );
        return;
      }
      context.go(ProfileSetupRoute.financial);
      return;
    }
    context.go(ProfileSetupRoute.academic);
  }

  Future<void> _onSubmit(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(profileSetupProvider.notifier).submit();
    if (!ok) return;

    // Re-check setup_complete so the router's redirect lets us through to /home.
    ref.invalidate(profileCompleteProvider);
    await ref.read(profileCompleteProvider.future);

    if (context.mounted) {
      context.go('/home');
    }
  }

  String _ordinal(int n) {
    if (n == 1) return 'st';
    if (n == 2) return 'nd';
    if (n == 3) return 'rd';
    return 'th';
  }
}
