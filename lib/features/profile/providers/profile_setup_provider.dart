// lib/features/profile/providers/profile_setup_provider.dart
//
// Multi-step profile-setup state. Raw form input lives here so nothing is lost
// when the user moves between /profile-setup/personal, /academic and
// /financial. Domain validation is delegated to ProfileValidator; persistence
// is delegated to ProfileRepository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../models/profile_validator.dart';
import '../models/student_profile.dart';
import '../repositories/profile_repository.dart';

/// Holds every field across the 3 profile-setup steps plus submission state.
class ProfileSetupState {
  const ProfileSetupState({
    this.fullName = '',
    this.nationality = 'Filipino',
    this.birthDate,
    this.yearLevel = 1,
    this.course = '',
    this.school = '',
    this.gpa = '',
    this.monthlyFamilyIncome = '',
    this.incomeUndisclosed = false,
    this.region,
    this.province = '',
    this.cityMunicipality = '',
    this.hasDisability = false,
    this.isIndigenous = false,
    this.fieldErrors,
    this.attempted = false,
    this.isSubmitting = false,
    this.error,
    this.hydrated = false,
  });

  // Step 1 — personal
  final String fullName;
  final String nationality;
  final DateTime? birthDate;

  // Step 2 — academic
  final int yearLevel;
  final String course;
  final String school;
  final String gpa;

  // Step 3 — financial & location
  final String monthlyFamilyIncome;
  final bool incomeUndisclosed;
  final String? region;
  final String province;
  final String cityMunicipality;
  final bool hasDisability;
  final bool isIndigenous;

  // Validation & submit state
  final ProfileFieldErrors? fieldErrors;
  final bool attempted;
  final bool isSubmitting;
  final String? error;

  /// True once the draft has been populated from the signed-in user's persisted
  /// profile. Lets the UI sync its field controllers when hydration lands after
  /// the screen mounts.
  final bool hydrated;

  ProfileSetupState copyWith({
    String? fullName,
    String? nationality,
    DateTime? birthDate,
    int? yearLevel,
    String? course,
    String? school,
    String? gpa,
    String? monthlyFamilyIncome,
    bool? incomeUndisclosed,
    String? region,
    String? province,
    String? cityMunicipality,
    bool? hasDisability,
    bool? isIndigenous,
    ProfileFieldErrors? fieldErrors,
    bool clearFieldErrors = false,
    bool? attempted,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool? hydrated,
  }) {
    return ProfileSetupState(
      fullName: fullName ?? this.fullName,
      nationality: nationality ?? this.nationality,
      birthDate: birthDate ?? this.birthDate,
      yearLevel: yearLevel ?? this.yearLevel,
      course: course ?? this.course,
      school: school ?? this.school,
      gpa: gpa ?? this.gpa,
      monthlyFamilyIncome: monthlyFamilyIncome ?? this.monthlyFamilyIncome,
      incomeUndisclosed: incomeUndisclosed ?? this.incomeUndisclosed,
      region: region ?? this.region,
      province: province ?? this.province,
      cityMunicipality: cityMunicipality ?? this.cityMunicipality,
      hasDisability: hasDisability ?? this.hasDisability,
      isIndigenous: isIndigenous ?? this.isIndigenous,
      fieldErrors: clearFieldErrors ? null : (fieldErrors ?? this.fieldErrors),
      attempted: attempted ?? this.attempted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      hydrated: hydrated ?? this.hydrated,
    );
  }
}

class ProfileSetupNotifier extends StateNotifier<ProfileSetupState> {
  ProfileSetupNotifier(this._repository) : super(const ProfileSetupState()) {
    _hydration = _hydrate();
  }

  final ProfileRepository _repository;

  /// The single in-flight hydration attempt. Completed (awaited) by tests so
  /// they observe the post-hydration state deterministically.
  late final Future<void> _hydration;

  /// Completes once the initial hydration attempt has settled, whether or not
  /// a persisted profile was found and applied.
  Future<void> get hydrationComplete => _hydration;

  /// Fetches the signed-in user's persisted profile exactly once and, when one
  /// exists and the form is still untouched, populates the draft. Safe even if
  /// the shared `currentProfileProvider` is still loading: this notifier reads
  /// the repository directly. Never clobbers an in-progress draft, and never
  /// re-runs for this notifier's lifetime (it runs from the constructor only).
  Future<void> _hydrate() async {
    final StudentProfile? profile;
    try {
      profile = await _repository.fetchCurrent();
    } catch (_) {
      // A failed hydration must not block or break the wizard; leave the empty
      // form and let the user continue.
      return;
    }
    if (profile == null || !_isPristine()) return;

    state = state.copyWith(
      fullName: profile.fullName,
      nationality: profile.nationality,
      birthDate: profile.birthDate,
      yearLevel: profile.yearLevel,
      course: profile.course,
      school: profile.school ?? '',
      gpa: profile.gpa.toStringAsFixed(2),
      monthlyFamilyIncome: _formatIncome(profile.monthlyFamilyIncome),
      incomeUndisclosed: profile.monthlyFamilyIncome == null,
      region: profile.region,
      province: profile.province ?? '',
      cityMunicipality: profile.cityMunicipality ?? '',
      hasDisability: profile.hasDisability,
      isIndigenous: profile.isIndigenous,
      hydrated: true,
    );
  }

  /// True when the form still holds its initial empty/default values — i.e. the
  /// user has not started editing. Hydration only applies to such a pristine
  /// form so it can never overwrite an actively edited draft.
  bool _isPristine() {
    final s = state;
    return !s.attempted &&
        !s.isSubmitting &&
        s.error == null &&
        s.fullName.isEmpty &&
        s.nationality == 'Filipino' &&
        s.birthDate == null &&
        s.yearLevel == 1 &&
        s.course.isEmpty &&
        s.school.isEmpty &&
        s.gpa.isEmpty &&
        s.monthlyFamilyIncome.isEmpty &&
        !s.incomeUndisclosed &&
        s.region == null &&
        s.province.isEmpty &&
        s.cityMunicipality.isEmpty &&
        !s.hasDisability &&
        !s.isIndigenous;
  }

  static String _formatIncome(double? income) {
    if (income == null) return '';
    return income == income.roundToDouble()
        ? income.toStringAsFixed(0)
        : income.toString();
  }

  static const ProfileValidator _validator = ProfileValidator();

  // --- Step 1 — personal ----------------------------------------------------

  void setFullName(String value) {
    state = state.copyWith(fullName: value);
    _refreshErrors();
  }

  void setNationality(String value) {
    state = state.copyWith(nationality: value);
    _refreshErrors();
  }

  void setBirthDate(DateTime? value) {
    state = state.copyWith(birthDate: value);
    _refreshErrors();
  }

  // --- Step 2 — academic ----------------------------------------------------

  void setYearLevel(int value) {
    state = state.copyWith(yearLevel: value);
    _refreshErrors();
  }

  void setCourse(String value) {
    state = state.copyWith(course: value);
    _refreshErrors();
  }

  void setSchool(String value) => state = state.copyWith(school: value);

  void setGpa(String value) {
    state = state.copyWith(gpa: value);
    _refreshErrors();
  }

  // --- Step 3 — financial & location ---------------------------------------

  void setMonthlyFamilyIncome(String value) {
    state = state.copyWith(monthlyFamilyIncome: value);
    _refreshErrors();
  }

  void setIncomeUndisclosed(bool value) {
    state = state.copyWith(incomeUndisclosed: value, monthlyFamilyIncome: '');
    _refreshErrors();
  }

  void setRegion(String value) {
    state = state.copyWith(region: value);
    _refreshErrors();
  }

  void setProvince(String value) => state = state.copyWith(province: value);

  void setCityMunicipality(String value) =>
      state = state.copyWith(cityMunicipality: value);

  void setHasDisability(bool value) =>
      state = state.copyWith(hasDisability: value);

  void setIsIndigenous(bool value) => state = state.copyWith(isIndigenous: value);

  /// Validates only the fields of the current [step] and exposes the errors so
  /// the form can surface them per-input. Returns the (possibly empty) errors.
  ProfileFieldErrors? validateStep(String step) {
    final all = _validateAll();
    final errors = switch (step) {
      'personal' => ProfileFieldErrors(
          fullName: all.fullName,
          nationality: all.nationality,
        ),
      'academic' => ProfileFieldErrors(
          gpa: all.gpa,
          yearLevel: all.yearLevel,
          course: all.course,
        ),
      _ => ProfileFieldErrors(
          monthlyFamilyIncome: all.monthlyFamilyIncome,
          region: all.region,
        ),
    };
    final result = errors.isValid ? null : errors;
    state = state.copyWith(attempted: true, fieldErrors: result);
    return result;
  }

  /// Persists the completed profile via the repository. Returns true on
  /// success; on failure the error is exposed via [ProfileSetupState.error].
  Future<bool> submit() async {
    final current = state;
    final all = _validateAll();
    state = state.copyWith(attempted: true, fieldErrors: all);
    if (!all.isValid) {
      state = state.copyWith(
        error: 'Please review the highlighted fields and try again.',
      );
      return false;
    }

    final userId = _repository.currentUserId;
    if (userId == null) {
      state = state.copyWith(
        error: 'You must be signed in to save your profile.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final profile = StudentProfile(
        id: userId,
        fullName: current.fullName.trim(),
        nationality: current.nationality.trim(),
        birthDate: current.birthDate,
        region: current.region!.trim(),
        province: _blankToNull(current.province),
        cityMunicipality: _blankToNull(current.cityMunicipality),
        gpa: double.parse(current.gpa),
        yearLevel: current.yearLevel,
        course: current.course.trim(),
        school: _blankToNull(current.school),
        monthlyFamilyIncome: current.incomeUndisclosed
            ? null
            : double.parse(current.monthlyFamilyIncome.trim()),
        hasDisability: current.hasDisability,
        isIndigenous: current.isIndigenous,
        setupComplete: true,
      );
      await _repository.saveCurrent(profile: profile);

      state = state.copyWith(isSubmitting: false, error: null);
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to save your profile. Please try again.',
      );
      return false;
    }
  }

  // --- Internals ------------------------------------------------------------

  ProfileFieldErrors _validateAll() {
    return _validator.validate(
      fullName: state.fullName,
      nationality: state.nationality,
      gpa: double.tryParse(state.gpa),
      yearLevel: state.yearLevel,
      course: state.course,
      monthlyFamilyIncome: state.monthlyFamilyIncome,
      incomeUndisclosed: state.incomeUndisclosed,
      region: state.region,
    );
  }

  void _refreshErrors() {
    if (!state.attempted) return;
    final all = _validateAll();
    state = state.copyWith(fieldErrors: all.isValid ? null : all);
  }

  static String? _blankToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

/// The multi-step profile-setup draft, isolated per authenticated user.
///
/// Keyed on the authenticated user's id and autoDisposed: when a session ends,
/// that user's notifier (and its in-progress draft) is dropped, and the next
/// user gets a fresh notifier that hydrates from their own profile. User A's
/// draft can therefore never surface in User B's session.
final profileSetupProvider = StateNotifierProvider.family.autoDispose<
    ProfileSetupNotifier,
    ProfileSetupState,
    String>(
  (ref, userId) => ProfileSetupNotifier(ref.watch(profileRepositoryProvider)),
);

/// The signed-in user's full profile, or null when signed out / not built yet.
/// Consumed by the matches provider and the profile tab.
///
/// Watches [currentUserIdProvider] so it is recomputed for every auth
/// transition: logging out yields null and logging in as another user fetches
/// that user's own profile instead of serving the previous user's cache.
final currentProfileProvider = FutureProvider<StudentProfile?>(
  (ref) {
    ref.watch(currentUserIdProvider);
    return ref.watch(profileRepositoryProvider).fetchCurrent();
  },
);
