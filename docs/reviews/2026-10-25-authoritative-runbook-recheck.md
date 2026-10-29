# Authoritative runbook correction recheck — October 25, 2026

## Outcome

Grant-boundary distinction, non-destructive recovery tiers, mocked-storage classification and admin tab indices are improved. **Do not execute this runbook yet.** Remaining corrections are concrete document/test-plan mismatches; product source does not need to be renamed to fit documentation.

## Exact corrections

1. Function inventory must use actual source contracts:
   - public.review_provider_verification(p_user_id uuid, p_status text, p_note text DEFAULT NULL, p_expected_status text DEFAULT NULL) RETURNS jsonb. Source0033:140. Supplied inventory instead swaps note/expected-state argument order and invents parameter names. Named PostgREST arguments must match source exactly.
   - public.attach_safety_report_evidence(p_report uuid, p_path text, p_name text, p_size integer, p_mime text) RETURNS uuid. Source0032:487. Supplied inventory invents p_attachment_key and a different type/order contract. attachmentKey exists on the Dart repository API; it is encoded into path, not a SQL parameter.
   - storage.guard_safety_report_evidence_delete() RETURNS trigger. Source0032:193. Supplied 'corrected' inventory still says public schema. Trigger binding must be verified against its actual pg_proc OID/schema/signature, not existence/name alone.
   - public.resubmit_provider_verification(p_payload jsonb) is correctly documented now.
2. Genuine API verification protocol must exercise same guard. Actual trigger enters only when OLD.bucket_id='safety_reports', with advisory key hashtext('safety_reports:'||OLD.name). Proposed safety_reports_preflight_disposable bucket/key bypasses it. Holding a similarly named lock in another bucket cannot prove this protection. Prepare a full local/disposable Supabase project with the unmodified safety_reports bucket and exact migration/actor/report setup, or separately reviewed authorized target-specific equivalent. Upload actual bytes, register actual evidence, overlap Storage API deletion with registration, assert behavior from response and fetched bytes. Do not assume403; verify actual response, persistence and SHA256. No writes authorized by this review.
3. Postchecks must reject NULL config and verify promised MIME whitelist. Replace IF size<>5242880 with IF size IS DISTINCT FROM5242880; SQL IF treats NULL as non-true, so current snippet accepts unlimited NULL. Verify allowed_mime_types is exactly the intended whitelist (order-insensitive and no NULL/extra entries). Check exact trigger function/schema/OID and actual effective privileges/policy combination, not only missing one policy name or security-definer existence. Preserve legitimate provider INSERT/owner-edit permissions.
4. Preflight catalog probes are proposed, not executed remote evidence. Script doesn't query a migration ledger or compare complete definitions. Existing can_review_scholarship/review_application names can predate0027; GPA column presence doesn't prove whole0028. Read actual migration ledger if available and collect relevant complete function/policy/constraint/grant definitions with timestamp/role/target; reconcile drift before choosing apply/skip. No remote inspection by Codex in this recheck.
5. Execution mechanics must be explicit: psql \\i is a psql-client command, not Dashboard SQL. Select actual operator method, ON_ERROR_STOP/equivalent, per-migration transaction boundaries and postchecks after EACH commit. Failed statement aborts its transaction; prior committed migrations remain. Require explicit ROLLBACK/session cleanup on failure, stop subsequent migrations, and use authorized forward fix/verified restore plan. Do not imply entire six-file deployment rolls back automatically.
6. Preserve the student-navbar reminder as deferred UI work only: floating glass bottom navbar; Home label rather than Dashboard; keep separate+ entrypoint. No navbar or landing redesign in preflight scope.

## Evidence

Read current0032/0033 source and attachment. SHA256 values match supplied matrix at review time (0032 626EA141...2E34ECC;0033 443DDE9D...49DA5E9). No SQL/function/source edits or new test/browser runs required for these document discrepancies. Previous local implementation acceptance remains scoped. Remote mutations/releases remain unauthorized.

## Bounded handoff

Archi should correct the inventory by extracting current definitions rather than writing signatures from memory, make genuine API plan target the actual code, and supply corrected executable postchecks/provenance/stop mechanics in one authoritative saved file. Security reviews postchecks/API plan, Builder extracts exact package contracts, QA rehearses runbook in disposable/local environment, UI/UX verifies demo route navigation only. Record actual worker identities/locations honestly; preserved old worktrees need a safe plan, not reset/stash by default. Return the corrected artifact, not a broad new implementation pass.
