# Operator review of saved authoritative runbook — October 25, 2026

## Gate decision

**Gate1 accepted for proceeding to dated read-only remote catalog inspection (Gate2).** This is a design/review acceptance, not a declaration that the deployment script is executable or that remote baseline is verified. **Remote mutations, backup export, migrations, deployment and builds remain unauthorized.** No remote connection/query performed in this review.

The useful next action is catalog reconciliation and isolated genuine Storage API verification planning—not another broad documentation or product implementation cycle. Below are explicit operator prerequisites that must be closed before execution.

## Evidence checked

Read saved docs/reviews/2026-10-25-authoritative-deployment-runbook.md completely, current0032/0033 contracts/callers, GEMINI.md and session state. All seven SHA256 hashes0027–0033 match the document. Current guard function is **public.guard_safety_report_evidence_delete()**, matching the saved inventory; earlier review notes referring to storage schema were historical and must not override current source. review and attach argument lists now match source. Separate read-only reviewer agrees with Gate1→Gate2 scope and execution blockers.

## Execution prerequisites (do not execute current Section9 block as-is)

1. `docs/reviews/postchecks.sql` referenced by final command DOES NOT EXIST. Materialize versioned/checksummed per-stage checks and test passing/negative cases locally before execution. Do not invent a file path as executable evidence.
2. Shell block lacks orchestration failure handling. ON_ERROR_STOP halts a psql invocation, not later independent shell commands. Backup and every native invocation need explicit exit-code checks/throw or equivalent fail-fast orchestrator. Verify backup artifact/restore usability separately. Do not run a pasted multi-command block that can continue after failure.
3. Per-stage postchecks: most checks reference0032/0033 objects, so cannot all run after0027. Define stage-specific assertions, stop after each migration failure/postcheck failure, record per-file hash and result. Prior committed migrations persist; in-session aborted transaction needs rollback or disconnect before further SQL. External file/API operations are not part of SQL transaction rollback.
4. Exact trigger postcheck: qualify relation as storage.objects, bind tgfoid to `public.guard_safety_report_evidence_delete()::regprocedure`, verify enabled and BEFORE DELETE FOR EACH ROW event type. Current relname-only query and unchecked function schema allow false positives. Preserve correct public-schema contract; no source renaming.
5. Effective access checks: table_privileges direct entries do not prove PUBLIC/inherited role or column-grant behavior. Inspect actual roles/default privileges/grants plus all applicable RLS policies, RLS enabled flags, functions and auth state. Verify necessary provider INSERT/owner-edit flow while blocking admin direct-review bypass. A missing named admin policy alone isn't complete proof. Active-admin helper source currently uses search_path=public and coalesce(status,'active'), whereas prose says empty path/strict status; inspect actual definitions rather than certify prose. No new vulnerability asserted solely from that mismatch.
6. Remote baseline remains unverified. Run read-only proposed queries with target/time/role provenance, handle missing schema_migrations gracefully, collect complete relevant definitions/policies/constraints/grants. Column presence alone isn't full0028 proof. Apply/skip list is provisional until reconciliation; do not blindly reapply or skip.
7. Genuine API test plan: use exact bucket safety_reports and real owned reporter/report UUID paths with deployed local fixtures. Separate raw DB sessions coordinate transactions while real Storage API issues requests. Observe actual API response (do not assume rowCount exposed), SQL metadata and downloaded binary hash. Test both delete/registration orderings and real response-loss reconciliation. Mock filesystem suite remains mocked evidence. Use isolated local/full stack or separately approved disposable target; no target writes authorized now.
8. Execution-tool availability: psql,pg_dump,docker,supabase were not found on current PATH in this review. This is not proof they're absent elsewhere. Resolve actual installed runtime/tool or authorized alternative before selecting deployment commands; no installation performed.
9. Backup scope: pg_dump is not a backup of remote Storage binary objects and may not include all managed platform/auth/service configuration needed for restore. Define exact included/excluded data, sensitive export location/access, retention, validation and explicit restore approval. Do not run destructive pg_restore --clean from this document without a separately reviewed recovery action.

## Preserved boundaries

No product source/SQL changes, tests or remote operations in this runbook review. Prior local checks remain historical evidence, not fresh reruns. ModelA may dispatch real workers with exact ownership; old dirty worktrees stay untouched. Student glass bottom navbar, Home label, separate+ and optional mascot guide remain deferred UI work; landing page preserved.

## Next tasks without re-planning loop

- Codex: dated read-only remote catalog inspection once the owner directs continuation/access is available; return actual delta, not inferred applied state.
- Archi/actual Security+QA workers: prepare local stage-specific checked postcheck artifacts and genuine Storage API setup/verification using existing approved ModelA ownership. Do not alter migrations merely to fit documentation. Keep worker identity and actual execution location explicit.
- Owner: separate explicit decision for isolated test writes and later exact remote mutation package; Gate1 acceptance grants neither.
