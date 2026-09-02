// lib/features/scholarships/services/application_readiness.dart
//
// Pure application-readiness evaluation for the scholarship detail surface.
// Given the signed-in student's profile, a scholarship and an injectable
// reference time, it answers one question: may this student tap Apply right
// now? It performs no I/O, holds no state, never writes and never touches
// BuildContext — the actual application creation remains the exclusive
// responsibility of applicationsProvider → ApplicationRepository.
//
// Eligibility is NOT re-implemented here: the profile-vs-scholarship criteria
// come from MatchingEngine.failedCriteria (the exact code the discovery engine
// runs), so readiness and matching can never disagree. This file therefore
// adds only the availability (active/deadline) and profile-completeness
// layers on top.
//
// Precedence — deliberate, deterministic, and documented:
//   1. inactive          — a deactivated listing is never applicable,
//                          regardless of its deadline.
//   2. closed            — the deadline has passed; a closed scholarship is
//                          never presented as currently applicable.
//   3. profileIncomplete — a missing/unfinished profile is NOT an eligibility
//                          verdict; it must never be shown as "not eligible".
//   4. notEligible       — profile complete but one or more deterministic
//                          criteria fail (exposed with value-bearing reasons).
//   5. eligible          — everything passes.

import '../../profile/models/student_profile.dart';
import '../models/scholarship.dart';
import 'matching_engine.dart';

/// The outcome of evaluating whether a student may apply to a scholarship.
enum ApplicationReadinessState {
  /// Active, deadline open, profile complete, all criteria met.
  eligible,

  /// Profile complete but one or more criteria fail; see
  /// [ApplicationReadiness.missingCriteria] / [ApplicationReadiness.reasons].
  notEligible,

  /// No profile yet, or the profile has not completed setup. Distinct from
  /// [notEligible]: an absent profile is not an eligibility verdict.
  profileIncomplete,

  /// The deadline has passed.
  closed,

  /// The scholarship is not active.
  inactive,
}

/// The immutable readiness result for one (profile, scholarship, reference
/// time) evaluation.
class ApplicationReadiness {
  const ApplicationReadiness._(
    this.state, {
    this.missingCriteria = const [],
    this.reasons = const [],
  });

  final ApplicationReadinessState state;

  /// The eligibility criteria the profile fails, in the engine's canonical
  /// order. Always empty unless [state] is [ApplicationReadinessState.notEligible].
  final List<EligibilityCriterion> missingCriteria;

  /// Concise, value-bearing explanations for [missingCriteria] (e.g.
  /// "Minimum GPA 3.50 — your GPA is 3.20"). Always empty unless [state] is
  /// [ApplicationReadinessState.notEligible].
  final List<String> reasons;

  /// Only [eligible] may lead to an application write.
  bool get canApply => state == ApplicationReadinessState.eligible;
}

/// Evaluates whether [profile] may apply to [scholarship] as of
/// [referenceNow]. Pure and deterministic: the same inputs always produce the
/// same result, and [referenceNow] keeps deadline math out of the wall clock.
ApplicationReadiness evaluateApplicationReadiness({
  required StudentProfile? profile,
  required Scholarship scholarship,
  required DateTime referenceNow,
}) {
  // 1. A deactivated listing is never applicable, whatever its deadline says.
  if (!scholarship.isActive) {
    return const ApplicationReadiness._(ApplicationReadinessState.inactive);
  }

  // 2. Same expiry comparison the MatchingEngine applies.
  if (!scholarship.deadline.isAfter(referenceNow)) {
    return const ApplicationReadiness._(ApplicationReadinessState.closed);
  }

  // 3. Reuse the app's single profile-completeness definition (the
  // `setup_complete` flag the router already gates on). A missing profile is
  // never misreported as an eligibility failure.
  if (profile == null || !profile.setupComplete) {
    return const ApplicationReadiness._(
      ApplicationReadinessState.profileIncomplete,
    );
  }

  // 4/5. Eligibility comes from the MatchingEngine's own criteria code.
  final missing = MatchingEngine.failedCriteria(profile, scholarship);
  if (missing.isNotEmpty) {
    return ApplicationReadiness._(
      ApplicationReadinessState.notEligible,
      missingCriteria: missing,
      reasons: [
        for (final criterion in missing)
          _reasonFor(criterion, profile, scholarship),
      ],
    );
  }
  return const ApplicationReadiness._(ApplicationReadinessState.eligible);
}

/// Formats one failed criterion as a concise line using the actual model
/// values. Priority flags (PWD / working student) are intentionally absent —
/// the engine does not treat them as eligibility requirements.
String _reasonFor(
  EligibilityCriterion criterion,
  StudentProfile profile,
  Scholarship scholarship,
) {
  switch (criterion) {
    case EligibilityCriterion.gpa:
      return 'Minimum GPA ${scholarship.minGpa.toStringAsFixed(2)} — '
          'your GPA is ${profile.gpa.toStringAsFixed(2)}';
    case EligibilityCriterion.yearLevel:
      return 'Open to year ${scholarship.yearLevels.join(', ')} — '
          'you are in year ${profile.yearLevel}';
    case EligibilityCriterion.course:
      return '${profile.course} is not among the eligible courses';
    case EligibilityCriterion.citizenship:
      return 'Requires ${scholarship.citizenshipRequired} nationality — '
          'your nationality is ${profile.nationality}';
    case EligibilityCriterion.region:
      final regions = scholarship.regionsEligible;
      final openTo = regions.length <= 3
          ? regions.join(', ')
          : '${regions.length} selected regions';
      return 'Open to $openTo — your region is ${profile.region}';
    case EligibilityCriterion.income:
      final bracket = profile.incomeBracket;
      return bracket == null
          ? 'Income requirement not met — your household income is undisclosed'
          : 'Your income bracket ($bracket) is above the limit '
              '(${scholarship.maxIncomeBracket})';
  }
}
