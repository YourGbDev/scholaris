-- RLS does not protect TRUNCATE. Client roles must not mutate existing audit rows
-- or manage table triggers/references. Keep ingestion and admin SELECT policies
-- unchanged; trusted database/service-role maintenance remains privileged.
revoke update, delete, truncate, references, trigger
on table public.audit_logs
from public, anon, authenticated;
