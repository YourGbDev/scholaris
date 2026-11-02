# Student companion and profile roadmap

User-approved November 3, 2026.

## In this change

- Quiet student surfaces from the preceding polish remain.
- Fix reproduced bookmark layout flicker and pending/error/concurrent-save state.
- Repair existing Profile Edit routing rather than shipping a visible dead action. Existing validated personal, academic and financial forms now support save/cancel and return to Profile; initial setup stays a separate flow. Formal increment-four requirement is unconfirmed without the official rubric.
- Three short skippable chat introduction screens shown on EVERY Chat opening (latest November 3 user instruction), replay from help, new transparent chest-up welcome/explain/tools poses for both companions. Skip/Start dismiss only for that visit; ignore old completion preferences.
- Explicit identity exception: boys see Ari in chat after Ariel's Home/tour; girls see Ariel in chat after Ari's Home/tour. Do not change the Home companion.
- QR, upload and Find scholarships remain visible shortcuts with concise explanations and existing functional destinations. No duplicate full tutorial on every tool tap. AI replies are not connected and Send remains unavailable.

## Follow-up implementation

- [ ] Verify profile edit/save/cancel against the real backend and physical iOS build, including validation failures, refresh, interrupted saves and changed matching results. Local widget/repository tests do not replace this.
- [ ] Connect companion to a real AI service with per-user access control, useful error/retry and honest sources for scholarship answers.
- [ ] Return QR lookup results to conversation with actual provider, deadline, requirements and deterministic eligibility checks. No guaranteed acceptance claims.
- [ ] Add document extraction with a review of proposed profile/application changes; apply only after confirmation, never silently overwrite data.
- [ ] Draft application assistance from verified stored data, clearly separated from submitting an application.
- [ ] Review the legacy internal demo percentage cutoff for quick apply and hidden high-fit filter state separately from the current visual cleanup.

Four-worktree test and release contract: `2026-11-03-pre-checking-test-contract.md`. No real AI/backend integration, commit, push or IPA is implied by this roadmap.
