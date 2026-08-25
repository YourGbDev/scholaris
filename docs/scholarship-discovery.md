# Scholaris Scholarship Discovery — Day 4

This document is the canonical reference for the scholarship discovery
experience: the reconciled `scholarships` table contract, the data layer, the
personalized matching UX, and the bookmarks/saved flow.

Source of truth: `lib/features/scholarships/` (models, repositories, providers,
services), `lib/features/bookmarks/`, `lib/features/home/presentation/home_screen.dart`,
and `supabase/migrations/0002_scholarship_discovery.sql`.

---

## 1. The database ↔ model contract

Day 3 deferred the reconciliation between `public.scholarships` and the
`Scholarship` domain model. Day 4 resolved it. The table was rebuilt
(`0002_scholarship_discovery.sql`) so the columns match exactly what the
matching engine and UI consume:

| Dart field | DB column | Notes |
|---|---|---|
| `id` | `id` | uuid PK |
| `name` | `name` | previously `title` |
| `provider` | `provider` | nullable |
| `description` | `description` | nullable |
| `minGpa` | `min_gpa` | numeric(3,2) |
| `yearLevels` | `year_levels` | int[], default `{1..5}` |
| `eligibleCourses` | `eligible_courses` | text[], empty = any course |
| `citizenshipRequired` | `citizenship_required` | default `'any'` |
| `regionsEligible` | `regions_eligible` | text[], empty = any region |
| `maxIncomeBracket` | `max_income_bracket` | `'low'/'mid'/'high'/'any'` |
| `isPwdPriority` | `is_pwd_priority` | default false |
| `isWorkingStudentPriority` | `is_working_student_priority` | default false |
| `slotsAvailable` | `slots_available` | int, nullable |
| `deadline` | `deadline` | date, not null |
| `amount` | `amount` | numeric |
| `coverageType` | `coverage_type` | `'full'/'partial'/'stipend'` |
| `tags` | `tags` | text[] |
| `isActive` | `is_active` | default true |

Every Dart field uses an explicit `@JsonKey(name: 'snake_case')` (or a safe
`@Default`) so `fromJson`/`toJson` round-trip a real Supabase row and partial
rows still parse defensively. The model and the migration must stay in sync.

The migration also re-establishes the `bookmarks`/`applications` foreign keys
that the rebuild dropped and seeds 12 realistic Philippine scholarships with
deadlines in the future.

---

## 2. Data layer

Mirrors the profile feature:

- `ScholarshipDataSource` (interface) + `SupabaseScholarshipDataSource`
  (reads active rows ordered by deadline).
- `ScholarshipRepository.fetchActive()` — filters `isActive`, orders by
  soonest deadline, maps snake_case rows → `Scholarship`.
- `ScholarshipRepository` is overridable in tests with an in-memory fake
  (`test/helpers/fake_scholarship_data_source.dart`).

Providers (`scholarships_provider.dart`):

- `scholarshipsProvider` — all active scholarships.
- `scholarshipByIdProvider(id)` — single item for the detail screen.
- `matchesProvider` — the personalized result: fetches the current profile
  (`currentProfileProvider`) + catalog, then applies the deterministic
  `MatchingEngine` (eligible → ranked).

---

## 3. The personalized matching UX

Matching is the primary experience, not a sub-feature of a catalog:

- The **Discover tab** greets the student by first name, then leads with
  **"Your Matches"** — the ranked eligible list.
- Every matched card shows **explainability chips** (`matchReasonsFor` in
  `services/match_reasons.dart`): *GPA requirement*, *Year level*, *Your
  course*, *In your region*, *Income eligible*, etc. Students see *why* they
  match, which is the explainability principle from `profile-data-model.md`.
- Matches that are eligible are removed from the "Browse all scholarships"
  section below, so matched scholarships are never duplicated.
- Full **loading / empty / error** states with retry (`state_views.dart`).
- Deadline urgency: cards and the detail screen render a gold "closing soon"
  chip within 14 days of the deadline.

## 4. Saved (bookmarks)

- `BookmarkDataSource` + `BookmarkRepository` scoped to the authenticated
  user (session-derived id only).
- `bookmarksProvider` (AsyncNotifier) holds the set of saved scholarship ids
  and exposes `toggle(id)`; the detail screen and app bar keep it in sync.
- The **Saved tab** maps saved ids → scholarship cards, with an empty state.

## 5. Shell & navigation

`HomeScreen` is a Material 3 shell with a bottom `NavigationBar`:

- **Discover** — matches + browse
- **Saved** — bookmarks
- **Profile** — summary card + "Update profile" + "Sign out"

The branded `SplashScreen` (wordmark + tagline fade) replaces the old spinner.
No multi-page intro — intentionally deferred (see plan).

## 6. Testing

- `scholarship_model_test.dart` — snake_case ↔ camelCase round-trip + defaults.
- `scholarship_repository_test.dart` — mapping, active filter, ordering.
- `matches_provider_test.dart` — profile + catalog → ranked eligible set.
- `bookmarks_test.dart` — repository scoping, idempotent remove, notifier toggle.
- `discovery_widget_test.dart` — shell tabs, Discover matches + chips,
  Saved states, detail facts, bookmark action.

## 7. Intentionally deferred

| Item | Reason |
|---|---|
| Apply / application tracking UI | Applications table exists; UI is a later phase. |
| Deadline reminders / notifications | Out of scope for Day 4. |
| Intro / multi-page onboarding | Deferred; branded splash covers first impression. |
| AI/LLM ranking | Deterministic engine first (see profile-data-model.md). |
