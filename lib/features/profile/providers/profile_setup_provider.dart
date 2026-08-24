// lib/features/profile/providers/profile_setup_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Holds every field across the 3 profile-setup steps so no data is lost when
/// the user moves between /profile-setup/personal, /academic and /financial.
class ProfileSetupState {
  const ProfileSetupState({
    this.fullName = '',
    this.birthDate,
    this.gender = 'Male',
    this.nationality = 'Filipino',
    this.yearLevel = 1,
    this.course = '',
    this.school = 'Western Leyte College of Ormoc',
    this.gpa = '',
    this.monthlyFamilyIncome = '',
    this.region = '',
    this.province = '',
    this.cityMunicipality = '',
    this.hasDisability = false,
    this.isIndigenous = false,
    this.isSubmitting = false,
    this.error,
  });

  // Step 1 — personal
  final String fullName;
  final DateTime? birthDate;
  final String gender;
  final String nationality;

  // Step 2 — academic
  final int yearLevel;
  final String course;
  final String school;
  final String gpa;

  // Step 3 — financial
  final String monthlyFamilyIncome;
  final String region;
  final String province;
  final String cityMunicipality;
  final bool hasDisability;
  final bool isIndigenous;

  // Submit state
  final bool isSubmitting;
  final String? error;

  ProfileSetupState copyWith({
    String? fullName,
    DateTime? birthDate,
    String? gender,
    String? nationality,
    int? yearLevel,
    String? course,
    String? school,
    String? gpa,
    String? monthlyFamilyIncome,
    String? region,
    String? province,
    String? cityMunicipality,
    bool? hasDisability,
    bool? isIndigenous,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return ProfileSetupState(
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      yearLevel: yearLevel ?? this.yearLevel,
      course: course ?? this.course,
      school: school ?? this.school,
      gpa: gpa ?? this.gpa,
      monthlyFamilyIncome: monthlyFamilyIncome ?? this.monthlyFamilyIncome,
      region: region ?? this.region,
      province: province ?? this.province,
      cityMunicipality: cityMunicipality ?? this.cityMunicipality,
      hasDisability: hasDisability ?? this.hasDisability,
      isIndigenous: isIndigenous ?? this.isIndigenous,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProfileSetupNotifier extends StateNotifier<ProfileSetupState> {
  ProfileSetupNotifier() : super(const ProfileSetupState());

  // Step 1 — personal
  void setFullName(String value) => state = state.copyWith(fullName: value);
  void setBirthDate(DateTime? value) => state = state.copyWith(birthDate: value);
  void setGender(String value) => state = state.copyWith(gender: value);
  void setNationality(String value) => state = state.copyWith(nationality: value);

  // Step 2 — academic
  void setYearLevel(int value) => state = state.copyWith(yearLevel: value);
  void setCourse(String value) => state = state.copyWith(course: value);
  void setSchool(String value) => state = state.copyWith(school: value);
  void setGpa(String value) => state = state.copyWith(gpa: value);

  // Step 3 — financial
  void setMonthlyFamilyIncome(String value) =>
      state = state.copyWith(monthlyFamilyIncome: value);
  void setRegion(String value) => state = state.copyWith(region: value);
  void setProvince(String value) => state = state.copyWith(province: value);
  void setCityMunicipality(String value) =>
      state = state.copyWith(cityMunicipality: value);
  void setHasDisability(bool value) => state = state.copyWith(hasDisability: value);
  void setIsIndigenous(bool value) => state = state.copyWith(isIndigenous: value);

  /// Upserts every collected field to the `profiles` table for the signed-in
  /// user and marks the profile as complete. Returns true on success; on
  /// failure the error is exposed via [ProfileSetupState.error].
  Future<bool> submit() async {
    final current = state;
    final gpa = double.tryParse(current.gpa);
    if (gpa == null || gpa < 1.0 || gpa > 4.0) {
      state = state.copyWith(
        error: 'GPA must be a number between 1.0 and 4.0.',
      );
      return false;
    }

    final income = double.tryParse(current.monthlyFamilyIncome) ?? 0.0;
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('You must be signed in to save your profile.');
      }

      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'full_name': current.fullName,
        'birth_date':
            current.birthDate == null ? null : formatDate(current.birthDate!),
        'gender': current.gender,
        'nationality': current.nationality,
        'year_level': current.yearLevel,
        'course': current.course,
        'school': current.school,
        'gpa': gpa,
        'monthly_family_income': income,
        'region': current.region,
        'province': current.province,
        'city_municipality': current.cityMunicipality,
        'has_disability': current.hasDisability,
        'is_indigenous': current.isIndigenous,
        'setup_complete': true,
      });

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to save your profile. Please try again.',
      );
      return false;
    }
  }
}

/// Formats a date as `yyyy-MM-dd` for storage in Supabase.
String formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

final profileSetupProvider =
    StateNotifierProvider<ProfileSetupNotifier, ProfileSetupState>(
  (ref) => ProfileSetupNotifier(),
);
