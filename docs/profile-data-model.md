# Scholaris Profile Data Model — Day 3

This document is the canonical reference for the student profile domain: why
each field exists, which fields feed deterministic eligibility, which are
personalization, which are required vs optional, and how the profile connects
to the future scholarship domain.

Source of truth: `lib/features/profile/models/student_profile.dart` (domain
model), `lib/features/profile/models/profile_validator.dart` (validation),
`lib/features/profile/repositories/profile_repository.dart` (persistence),
and the `public.profiles` table in `supabase/migrations/0001_init.sql`.

---

## 1. Field-by-field classification

| Dart field | DB column | Type | Classification | Required | Notes |
|---|---|---|---|---|---|
| `id` | `id` | String | System | — | Auth user PK; never chosen by the app. |
| `fullName` | `full_name` | String | Personalization | required | Display name. |
| `nationality` | `nationality` | String | **Eligibility** | required (default `Filipino`) | Citizenship-based matching. |
| `region` | `region` | String | **Eligibility — Location** | required | Matched against scholarship `regions_eligible`. |
| `province` | `province` | String? | Personalization (location) | optional | Refinement only. |
| `cityMunicipality` | `city_municipality` | String? | Personalization (location) | optional | Refinement only. |
| `gpa` | `gpa` | double | **Eligibility — GPA** | required | Range 1.0–4.0 (higher is better). |
| `yearLevel` | `year_level` | int | **Eligibility — Year Level** | required | 1–5. |
| `course` | `course` | String | **Eligibility — Course** | required | Matched against `eligible_courses`. |
| `school` | `school` | String? | Personalization | optional | Future institution-specific scholarships. |
| `monthlyFamilyIncome` | `monthly_family_income` | double? | **Eligibility — Income** | required-or-undisclosed | `null` = "Prefer not to say". |
| `hasDisability` | `has_disability` | bool | Eligibility modifier | optional (default false) | PWD-priority scholarships. |
| `isIndigenous` | `is_indigenous` | bool | Eligibility modifier | optional (default false) | Indigenous-specific scholarships. |
| `birthDate` | `birth_date` | DateTime? | Personalization | optional | Future age-based scholarships. |
| `gender` | `gender` | String? | Personalization | optional | Not collected in the Day 3 UI (deferred). |
| `setupComplete` | `setup_complete` | bool | System | — | Drives the post-auth redirect. |
| `createdAt` / `updatedAt` | `created_at` / `updated_at` | DateTime? | System | — | DB-managed. |

### Derived (never stored)

- `incomeBracket` getter — `'low'` / `'mid'` / `'high'` / `null`, derived from
  `monthlyFamilyIncome` with thresholds `< ₱25,000`, `≤ ₱70,000`, `> ₱70,000`.
  Used only by the matching engine.

---

## 2. Deterministic eligibility inputs

The five primary inputs the future Eligibility Engine will consume:

1. **GPA** (`gpa`) — scholarships declare a minimum GPA.
2. **Year Level** (`yearLevel`) — scholarships restrict eligible year levels.
3. **Course** (`course`) — some scholarships target specific programs.
4. **Household/Family Income** (`monthlyFamilyIncome`) — income-constrained
   (need-based) scholarships. An undisclosed income is treated conservatively:
   income-constrained scholarships do **not** match an undisclosed profile.
5. **Location** (`region`) — location-restricted scholarships.

Plus citizenship (`nationality`) and the two eligibility modifiers
(`hasDisability`, `isIndigenous`) which participate in eligibility rules.

The profile models these cleanly and validates them in the domain layer
(`ProfileValidator`), not only in the UI. Validation rules:

| Field | Rule |
|---|---|
| `gpa` | parseable, `1.0 ≤ gpa ≤ 4.0` |
| `yearLevel` | `1 ≤ level ≤ 5` |
| `course` | non-empty |
| `monthlyFamilyIncome` | if not undisclosed → non-negative number |
| `region` | selected (non-empty) |
| `nationality` | non-empty |
| `fullName` | non-empty |

---

## 3. Personalization inputs

- `fullName`, `birthDate`, `gender`, `school`, `province`, `cityMunicipality`.

These do **not** participate in deterministic eligibility. They personalize
the experience (display name, institution context) or prepare for features
added later (age-based scholarships). They are kept optional and minimal to
avoid collecting unnecessary personal information. `gender` is modeled for
schema completeness but deliberately **not** collected in the Day 3 setup UI.

---

## 4. Required vs optional

- **Required:** `fullName`, `nationality`, `region`, `gpa`, `yearLevel`,
  `course`, and `monthlyFamilyIncome` **unless** the student explicitly chooses
  "Prefer not to say" (then `null`, still valid).
- **Optional:** `province`, `cityMunicipality`, `school`, `birthDate`,
  `gender`, `hasDisability`, `isIndigenous`.
- **System:** `id`, `setupComplete`, `createdAt`, `updatedAt`.

The UI marks required fields with `*` and optional fields with `(optional)`.

---

## 5. Serialization / Supabase mapping

Dart model fields use `@JsonKey(name: 'snake_case')` everywhere the Dart name
differs from the `profiles` column. `fromJson`/`toJson` therefore round-trip a
real Supabase row exactly — no camelCase keys are ever written to the database.
`toDbRow()` produces only the user-writable snake_case columns; system columns
(`id`, `created_at`, `updated_at`) are managed by the database.

Dates are written as `yyyy-MM-dd` (`formatDate`), matching the `date` column
type.

---

## 6. Repository & security

`ProfileRepository` (`profile_repository.dart`) is the only gateway to the
`profiles` table:

- `fetchCurrent()` — reads the signed-in user's **own** row.
- `saveCurrent(profile:)` — upserts the signed-in user's **own** row; throws
  `ProfileOwnershipException` if `profile.id != authenticatedUserId`.

The target user id is always derived from the authenticated session — never
from caller input — so another student's profile can never be read or written
through this API. Row-level security in the DB enforces the same rule as
defense in depth. Profile contents are never logged.

`ProfileDataSource` (interface) + `SupabaseProfileDataSource` keeps the
repository testable with an in-memory fake.

---

## 7. Connection to the Scholarship domain

The `StudentProfile` object is the canonical domain object the matching system
consumes. The Day 2 `MatchingEngine` reads `gpa`, `yearLevel`, `course`,
`nationality`, `region` and the derived `incomeBracket` to determine eligibility.

**Day 4 resolved the `scholarships` table ↔ `Scholarship` model reconciliation**
that was deferred in Day 3. See `docs/scholarship-discovery.md` for the
contract, the data layer, and the personalized matching UX.

---

## 8. Future Eligibility Engine & why deterministic before AI ranking

The roadmap is: **deterministic eligibility → deterministic ranking → (later)
AI-assisted personalization**.

1. The Eligibility Engine applies hard, objective rules against the profile:
   minimum GPA, eligible year levels, course restrictions, citizenship,
   region, income bracket, deadline and active status. This is binary and
   verifiable — a scholarship is either eligible or not.
2. Ranking orders the eligible set deterministically (soonest deadline, then
   highest amount).
3. Only after a correct, explainable shortlist exists should AI/LLM ranking
   personalize ordering, summarize, or explain matches.

Deterministic eligibility runs **before** any AI ranking because:
- **Correctness:** eligibility is an objective gate; ranking is subjective.
  Getting the gate wrong misleads the student.
- **Explainability:** the student must be able to see *why* they are (or are
  not) eligible for each result.
- **Cost & privacy:** hard filtering minimizes the number of student profiles
  and scholarships passed to any future LLM call.

Day 3 intentionally does **not** implement AI ranking, LLM integration,
embeddings, vector databases, scholarship scraping, notifications, or
analytics.

---

## 9. Intentionally deferred

| Item | Reason |
|---|---|
| `scholarships` table ↔ `Scholarship` model reconciliation | Scholarship domain is a later phase. |
| Eligibility Engine (deterministic) | Later phase; the profile already models its inputs. |
| AI ranking / LLM / embeddings / vector DB | Explicitly out of scope. |
| Scholarship scraping, notifications, analytics | Explicitly out of scope. |
| `is_working_student` | Not in the DB schema; no current eligibility rule requires it. |
| `email` on the profile | Lives in `auth.users`; no duplication needed. |
| `incomeBracket` as a stored column | Derived value; never persisted. |
| `gender` collection in the UI | Sensitive, unnecessary for Day 3 eligibility. |
| Dead TODO screen stubs | Broad cleanup deferred; only the broken test was fixed. |
