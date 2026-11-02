# Save, Profile Edit and Chat validation — November 3

Source: uncommitted changes on `codex/auth-tour-polish`, based on `b4b6e0d`, in the auth-tour-polish worktree. Includes preceding quiet-student UI polish. No commit, push or IPA was produced by this task. Record the actual committed source before distributing to Orca worktrees.

## Reproduced defects and fixes

1. Bookmark dependency updates temporarily rebuilt the dashboard summary as loading. Home discarded retained summary data, zeroed counts and removed Closing Soon, causing layout movement. Keep the retained summary only while its current profile/catalog/matches/applications/bookmarks sources remain ready; genuine refresh/auth loading still hides stale data. A widget regression proved the section existed before save and disappeared during recomputation before the fix.
2. The bookmark button ORed server state with local optimistic state, so pending unsave could remain filled. It also ignored asynchronous callback failures. Use an awaitable callback and a pending override, reject duplicate pending taps, roll back failed operations and show a retry message. Do not change unrelated reveal/count animations.
3. Simultaneous saves captured the same old set and overwrote each other locally. Apply each successful mutation to the latest set while retaining generation/user guards. Tests reproduce both IDs saved remotely but only one locally before the fix.
4. Completed students were redirected away from every profile setup route, even when launched by an Edit action. Allow the existing validated sections for editing, offer Save Changes/back, persist via the existing repository and return to Profile. Back discards the draft. Initial setup still completes on Dashboard. Hide setup progress during editing and remove an invented old academic-year label. The official increment rubric was not supplied; repository demo notes do not establish whether editing is required, so no scope exemption is claimed.

## Chat scope

Three white, minimal, skippable introduction screens with new transparent bust portraits: welcome, explanation and tools. Completion is per profile, recorded on skip/final start; leaving early does not complete it. Help replays the guide. Male/unset students meet Ari after Ariel's tour; female students meet Ariel after Ari's tour. Home/tour identity is unchanged.

Visible QR, upload and Find scholarships shortcuts explain their purpose and open the existing scanner/upload/Discover flows. AI replies are not connected; Send is unavailable. No simulated AI eligibility, automatic profile changes or fabricated conversations were added. Upload/scanner permissions and real backend document behavior still require device/live verification.

## Evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Integrated Flutter suite | 1,269 passed, 6 skipped, 0 failed | `build/nov03-final-integrated-tests.log` |
| Final larger chat artwork / 320px 200% / keyboard / first-use/replay tests | 9 passed | `build/nov03-chat-final-test.log` |
| Final edit-header/save/back/setup/signup tests | 14 passed | delegated focused run; `test/profile_edit_navigation_test.dart`, `test/student_signup_mobile_regression_test.dart` |
| Bookmark regressions + Home/Discover/Saved-related checks | 113 passed | focused run; new assertions in bookmark/card/dashboard tests |
| Full analyzer | 0 errors/warnings; 11 existing informational notices | `build/nov03-final-analyze.log` |
| Final affected source analysis | No issues in 8 source files | `build/nov03-final-source-analyze.log` |
| CAPTCHA build configuration and responsive challenge script | Both passed | existing Node harnesses run locally |
| Actual production tab-scoped authentication JS | 69/69 passed | `node tools/test_tab_scoped_auth.mjs` |
| Release web regression-preview compilation | Passed | `build/nov03-readiness-web-build.log`; preview entry point only |
| Actual rendered UI | Chat identities/slides/shortcuts, profile editor, 320px 200% text; bookmark frames | screenshots under `2026-11-03-save-profile-chat-evidence` |

The six skips are three opt-in live provider integration cases, two screenshot-generation fixtures, and one real-router provider-entry test with an existing auth-timer teardown issue. They are not live passes. One stale signup assertion initially failed because it expected completed students to be bounced out of editing; it now tests the correct completed-user exit from email verification. No auth guard was weakened to satisfy it.

## Remaining release gates

Local fixtures and tests do not establish live end-to-end readiness. Arki must coordinate the four-worktree contract in `docs/plans/2026-11-03-pre-checking-test-contract.md`, integrate reviewed findings into a committed source, and run real production-entry browser journeys with designated disposable accounts. Physical iOS CAPTCHA/login, bookmark motion, editing and camera/upload permissions remain pending. Never disable CAPTCHA or build from the regression-preview target.

Follow-up roadmap: `docs/plans/2026-11-03-student-companion-roadmap.md`. Prior quiet-surface evidence remains in `design-plans/2026-11-03-quiet-student-evidence`.
