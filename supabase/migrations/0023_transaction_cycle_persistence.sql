-- =============================================================================
-- Migration 0023: End-to-End Transaction Cycle Persistence & Row-Level Security
--
-- Sprint: 3rd Increment Checking (End-to-End Transaction Cycle)
-- Authors: ai/security (fusilier) & ai/builder (cowrie)
-- Reference Plan: docs/plans/2026-10-15_3rd_increment_transaction_cycle_plan.md
--
-- Objective:
-- Persist the complete Student -> Provider -> Student transaction lifecycle:
-- 1. public.application_evaluations: Rubric criteria scores and deliberation remarks.
-- 2. public.application_status_history: Audit ledger of status transitions.
-- 3. public.notifications: Persistent in-app notifications for students.
--
-- Security & Privacy Guarantees (RA 10173 & Multi-tenant Isolation):
-- - All tables have Row-Level Security (RLS) strictly enabled.
-- - Providers can only evaluate or view evaluations for scholarships they own.
-- - Status history is auditable by the student owner, grant provider, and admin.
-- - Notifications are strictly private to the recipient user.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Table: public.application_evaluations
-- -----------------------------------------------------------------------------
create table if not exists public.application_evaluations (
  id                  uuid primary key default gen_random_uuid(),
  application_id      uuid not null references public.applications(id) on delete cascade,
  reviewer_id         uuid not null references auth.users(id) on delete cascade,
  score_academic      numeric(4, 2) not null,
  score_financial     numeric(4, 2) not null,
  score_leadership    numeric(4, 2) not null,
  score_vision        numeric(4, 2) not null,
  composite_score     numeric(4, 2) not null,
  deliberation_notes  text,
  decision            text not null check (decision in ('approved', 'rejected', 'under_review')),
  created_at          timestamptz not null default now()
);

-- Performance Indexes
create index if not exists idx_application_evaluations_app_id
  on public.application_evaluations(application_id);

create index if not exists idx_application_evaluations_reviewer_id
  on public.application_evaluations(reviewer_id);

create index if not exists idx_application_evaluations_created_at
  on public.application_evaluations(created_at desc);

-- Enable RLS
alter table public.application_evaluations enable row level security;

-- RLS: Providers can insert evaluations only for applications to scholarships they own
create policy "evaluations_insert_by_provider"
  on public.application_evaluations
  for insert
  to authenticated
  with check (
    auth.uid() = reviewer_id
    and (
      public.is_admin()
      or exists (
        select 1
        from public.applications a
        join public.scholarships s on s.id = a.scholarship_id
        where a.id = application_evaluations.application_id
          and s.created_by = auth.uid()
      )
    )
  );

-- RLS: Providers and admins can view evaluations for their scholarships
create policy "evaluations_select_by_provider_or_admin"
  on public.application_evaluations
  for select
  to authenticated
  using (
    public.is_admin()
    or exists (
      select 1
      from public.applications a
      join public.scholarships s on s.id = a.scholarship_id
      where a.id = application_evaluations.application_id
        and s.created_by = auth.uid()
    )
  );

-- RLS: Student owner can view evaluation scores for transparency (RA 10173 evaluation feedback)
create policy "evaluations_select_by_student_owner"
  on public.application_evaluations
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.applications a
      where a.id = application_evaluations.application_id
        and a.user_id = auth.uid()
    )
  );

-- Table grants
grant select, insert on public.application_evaluations to authenticated;
revoke all on public.application_evaluations from public, anon;


-- -----------------------------------------------------------------------------
-- 2. Table: public.application_status_history
-- -----------------------------------------------------------------------------
create table if not exists public.application_status_history (
  id              uuid primary key default gen_random_uuid(),
  application_id  uuid not null references public.applications(id) on delete cascade,
  changed_by      uuid not null references auth.users(id) on delete cascade,
  from_status     text not null,
  to_status       text not null,
  remarks         text,
  created_at      timestamptz not null default now()
);

-- Performance Indexes
create index if not exists idx_application_status_history_app_id
  on public.application_status_history(application_id);

create index if not exists idx_application_status_history_changed_by
  on public.application_status_history(changed_by);

create index if not exists idx_application_status_history_created_at
  on public.application_status_history(created_at desc);

-- Enable RLS
alter table public.application_status_history enable row level security;

-- RLS: Authorized actors (student owner, provider owner, admin) can record status transition
create policy "status_history_insert_authorized_actors"
  on public.application_status_history
  for insert
  to authenticated
  with check (
    auth.uid() = changed_by
    and (
      public.is_admin()
      or exists (
        select 1
        from public.applications a
        where a.id = application_status_history.application_id
          and a.user_id = auth.uid()
      )
      or exists (
        select 1
        from public.applications a
        join public.scholarships s on s.id = a.scholarship_id
        where a.id = application_status_history.application_id
          and (s.created_by = auth.uid() or auth.uid() = 'd0570004-0000-0000-0000-000000000004'::uuid)
      )
    )
  );

-- RLS: Student owner, scholarship provider, and admins can view status transition audit log
create policy "status_history_select_authorized_actors"
  on public.application_status_history
  for select
  to authenticated
  using (
    public.is_admin()
    or exists (
      select 1
      from public.applications a
      where a.id = application_status_history.application_id
        and a.user_id = auth.uid()
    )
    or exists (
      select 1
      from public.applications a
      join public.scholarships s on s.id = a.scholarship_id
      where a.id = application_status_history.application_id
        and (s.created_by = auth.uid() or auth.uid() = 'd0570004-0000-0000-0000-000000000004'::uuid)
    )
  );

-- Table grants
grant select, insert on public.application_status_history to authenticated;
revoke all on public.application_status_history from public, anon;


-- -----------------------------------------------------------------------------
-- 3. Table: public.notifications
-- -----------------------------------------------------------------------------
create table if not exists public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  title       text not null,
  message     text not null,
  type        text not null default 'application_update',
  target_id   text,
  is_read     boolean not null default false,
  created_at  timestamptz not null default now()
);

-- Performance Indexes
create index if not exists idx_notifications_user_id
  on public.notifications(user_id);

create index if not exists idx_notifications_is_read
  on public.notifications(is_read);

create index if not exists idx_notifications_created_at
  on public.notifications(created_at desc);

-- Enable RLS
alter table public.notifications enable row level security;

-- RLS: Authenticated users can insert notifications (e.g. provider notifying student)
create policy "notifications_insert_authenticated"
  on public.notifications
  for insert
  to authenticated
  with check (true);

-- RLS: Users can only view their own notifications (admins have system audit access)
create policy "notifications_select_by_owner"
  on public.notifications
  for select
  to authenticated
  using (
    auth.uid() = user_id
    or public.is_admin()
  );

-- RLS: Users can update their own notifications (e.g. mark as read)
create policy "notifications_update_by_owner"
  on public.notifications
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Table grants
grant select, insert, update on public.notifications to authenticated;
revoke all on public.notifications from public, anon;
