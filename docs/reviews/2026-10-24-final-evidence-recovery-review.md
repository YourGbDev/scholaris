# Independent final evidence-recovery review — October 24, 2026

## Decision

Prior five corrections are substantially implemented, but remote green remains withheld for evidence recovery/data-integrity defects below. These are a focused continuation of the evidence workflow, not a request to restart or broaden the project.

## Confirmed improvements

- Private storage policies now require an active student and actual owned open report for uploads; providers/unlinked objects denied in the repeated local probe.
- Evidence RPC checks object existence and duplicate path; previous nonexistent-object probe now rejected.
- Report ID is retained across attachment failures; first/second upload-failure regressions pass.
- Provider correction dialog now uploads replacement org/individual documents into resubmission payload.
- Browser helper now sends one click and favors leaf controls; however destination assertions still permit sidebar/ancestor substring matches, and role='tab' assumptions need verification against real button roles.

## Remaining focused findings

1. **P2 — Same-name attachments silently lost (independently reproduced).** `lib/features/safety/presentation/student_safety_report.dart:196` skips completed files by name (`Set<String>`), so two different selected image.png files yield one attachEvidence call and a success state. Independent test expected two calls, observed one: `scratch/codex-final-same-name-probe.txt`; reproduction `scratch/codex_same_filename_evidence_probe_test.dart`. Use stable per-attachment identity rather than filename. Include both same-name initial upload and failed-file retry tests.
2. **P1 — Ambiguous successful registration is not recoverable (source-confirmed, not executed).** Repository lines 101–128 creates a new timestamp/path per retry. If evidence registration commits but its response is lost, cleanup is correctly denied for the attached object, but the dialog treats that file as failed. Retrying creates a second object/registration and consumes another slot; a three-file report can become capped before all distinct files complete. Preserve a stable upload/registration identity and reconcile existing successful registration after an ambiguous response. Test server-commit/client-response-loss, not only a fake exception before persistence.
3. **P2 — Delete/register race (source-confirmed, separate-session reproduction pending).** 0032 attach function reads storage.objects without locking the object; DELETE policy checks only snapshot-visible absence of evidence. Concurrent delete and registration can both pass and leave a registered missing file. Coordinate object deletion/registration with shared server serialization, and prove with independent sessions. Do not describe new unattached-file cleanup as guaranteeing immutable evidence until tested.
4. **P2 — Partial success history can remain cached empty.** Student dialog invalidates history only after all files attach (line 207). Report persistence followed by upload failure leaves previously cached history stale when the user chooses report history. Invalidate immediately on acknowledged report creation as well as attachment changes; test preloaded-empty history plus failed attachment.

## Verification actually performed

- Supplied provider security suite rerun: **11 passed**, exit 0 (`scratch/codex-final-provider-recheck.txt`).
- Supplied safety security suite rerun: **10 passed**, exit 0 (`scratch/codex-final-safety-recheck.txt`).
- Updated prior independent storage probe rerun: blocked provider upload/read and missing-object registration, exit 0 (`scratch/codex-final-storage-recheck.txt`). Archi edited the prior probe to assert rejection; Codex inspected its actual assertions before execution.
- Focused workflows: **18 passed**, exit 0 (`scratch/codex-final-backend-workflows.txt`).
- Scoped safety/resubmission/admin analysis: **No issues found**, exit 0 (`scratch/codex-backend-final-analysis.txt`).
- New same-name attachment regression: **failed as expected**, one attachment call instead of two. Test-only probe outside production suite.
- Independent complete Flutter suite result recorded after completion below. Supplied saved admin-ui-suite-verified.txt still contains earlier 963 result; do not cite it as a 980 run.
- Browser attempted http://127.0.0.1:5027/: connection refused. No fresh browser interaction pass or current whole-matrix acceptance. No Codex real concurrency rerun in this round; preserve those prior logs as supplied evidence with exact tested source versions.

## Process and boundaries

Superpowers verification/review and separate read-only evidence reviewer applied. Product/SQL source unchanged by Codex; only scratch probes/evidence/docs. No remote operation, commit/push, deployment or IPA build. Archi should fix the four bounded evidence findings, add the listed adversarial regressions, restart local previews and provide genuine state-asserted browser evidence, then return for recheck.

Independent complete suite: **980 passed / 9 skipped / zero failures**, exit 0 (scratch/codex-backend-final-full.txt). The separate adversarial scratch test still fails and is outside that suite; green suite does not cover this new defect.

