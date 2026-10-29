# Evidence recovery acceptance and preflight handoff — October 24, 2026

## Decision

**Accept the four bounded local evidence-recovery corrections for proceeding to deployment preflight.** No migration execution, production readiness or release approval. Previous blocker status is superseded only for the local corrections reviewed here.

## Independently checked

- Same-name files now use per-selection IDs rather than filename completion keys; stable attachmentKey reaches repository paths.
- Repository queries existing path registrations before upload and after RPC failure; previously committed registration can be reconciled without another slot. Widget tests simulate commit/response-loss; actual repository HTTP/storage response-loss integration is not exercised by those fake-repository tests and belongs in integration QA.
- Report persistence immediately invalidates student history, including partial-upload failure.
- attach_safety_report_evidence and storage BEFORE DELETE trigger share advisory lock by bucket/path; separate-session PostgreSQL test rerun passes attachment-first concurrent delete (0 deleted) and already-deleted object rejection. Reverse test is deletion completed before attachment, not an overlapping delete-first race. Scope the evidence accordingly.
- Repeated focused Flutter tests (same-name independent probe + student reporting + provider replacements + repository tests): **24 passed**, exit 0 (`scratch/codex-recovery-final-focused.txt`).
- Repeated safety SQL security suite: **10 passed**, exit 0 (`scratch/codex-recovery-final-safety.txt`).
- Real local two-session storage test: exit 0, expected assertions passed (`scratch/codex-recovery-storage-concurrency.txt`). PostgreSQL shutdown emitted WAL-writer/termination logs after success; do not call entire process output error-free. Cluster helper is local/disposable, not remote Supabase.
- Scoped analysis: **No issues found**, exit 0 (`scratch/codex-recovery-final-analysis.txt`).
- Archi reports full suite **983 passed / 9 skipped**. Codex did not rerun full suite this round; previous independent full run was **980/9** before these last corrections. No fresh Codex browser checks in this round.

## Preflight requirements (still no writes)

1. Resolve exact migration/package hashes and existing remote migration status through 0033; don't assume 0027–0031 are absent or blindly reapply. No remote target inspected in this review.
2. Check remote actual privileges/default grants, policy composition, active-admin semantics, private bucket configuration and Supabase Storage trigger/function ownership permissions. 0032 attempts bucket creation itself; don't claim manual creation is inherently required. Its broad exception fallback must not hide an absent/misconfigured bucket: define postchecks and fail/stop conditions.
3. Validate the storage API as well as metadata SQL: object bytes still readable after denied concurrent deletion, no object/evidence mismatch, failed upload/registration cleanup and actual response-loss reconciliation. SQL storage.objects stubs cannot prove binary-object preservation by Supabase Storage service.
4. Repair/run browser harness against ready local integrated screens and record unique destination/modal assertions, real file selection/retry and report history. Don't infer browser green from source edits. Full assistive-tech and physical-device checks remain separate.
5. Present exact ordered deployment proposal, target/environment, prerequisites, rollback/recovery boundaries, authorization and postchecks for user approval. All read-only remote inspection should use authorized access and avoid exposing secrets/student records. No commits/pushes, remote migration, production write, deployment or IPA build authorized.

Code changes by Codex this round: none. Superpowers verification/review workflow applied; existing privacy and responsive UI requirements retained. Future backend refinements must preserve reviewed corrections and unrelated work.
