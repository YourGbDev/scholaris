-- =============================================================================
-- Scholaris — 0023: transaction_cycle_persistence.sql
--
-- Tables, constraints, indexes, and RLS policies supporting the end-to-end
-- transaction cycle:
-- 1. public.application_evaluations: persists rubric criteria scores, composite
--    score, deliberation notes, and decision made by committee reviewers.
-- 2. public.application_status_history: audit log tracking each status
--    transition (from_status -> to_status) with author and remarks.
-- 3. public.notifications: in-app notifications delivered to students when their
--    application status transitions.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. public.application_evaluations
-- -----------------------------------------------------------------------------
create table if not exists public.application_evaluations (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(id) on delete cascade,
  reviewer_id uuid not null references auth.users(id) on delete cascade,
  score_academic numeric(4,2) not null,
  score_financial numeric(4,2) not null,
  score_leadership numeric(4,2) not null,
  score_vision numeric(4,2) not null,
  composite_score numeric(4,2) not null,
  deliberation_notes text,
  decision text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_evaluations_application_id
  on public.application_evaluations(application_id);

create index if not exists idx_evaluations_reviewer_id
  on public.application_evaluations(reviewer_id);

alter table public.application_evaluations enable row level security;

-- Policy: Provider/Reviewer who owns the scholarship can insert evaluation
create policy "Reviewers can insert evaluations for applications to their scholarships"
  on public.application_evaluations for insert
  to authenticated
  with check (
    auth.uid() = reviewer_id
    and exists (
      select 1 from public.applications a
      join public.scholarships s on s.id = a.scholarship_id
      where a.id = application_evaluations.application_id
        and s.created_by = auth.uid()
    )
  );

-- Policy: Reviewer, scholarship owner, applicant student, or admin can select evaluation
create policy "Reviewers, admins, and applicant can select evaluations"
  on public.application_evaluations for select
  to authenticated
  using (
    auth.uid() = reviewer_id
    or exists (
      select 1 from public.applications a
      join public.scholarships s on s.id = a.scholarship_id
      where a.id = application_evaluations.application_id
        and (s.created_by = auth.uid() or a.user_id = auth.uid())
    )
    or (select coalesce((auth.jwt()->'app_metadata'->>'is_admin')::boolean, false))
  );

-- -----------------------------------------------------------------------------
-- 2. public.application_status_history
-- -----------------------------------------------------------------------------
create table if not exists public.application_status_history (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(id) on delete cascade,
  changed_by uuid not null references auth.users(id) on delete cascade,
  from_status text not null,
  to_status text not null,
  remarks text,
  created_at timestamptz not null default now()
);

create index if not exists idx_status_history_application_id
  on public.application_status_history(application_id);

create index if not exists idx_status_history_changed_by
  on public.application_status_history(changed_by);

alter table public.application_status_history enable row level security;

-- Policy: Authenticated users can insert transitions they perform
create policy "Authenticated users can insert status history"
  on public.application_status_history for insert
  to authenticated
  with check (
    auth.uid() = changed_by
  );

-- Policy: Applicant student, scholarship owner provider, or admin can view history
create policy "Applicant, reviewer, and admin can view status history"
  on public.application_status_history for select
  to authenticated
  using (
    exists (
      select 1 from public.applications a
      join public.scholarships s on s.id = a.scholarship_id
      where a.id = application_status_history.application_id
        and (a.user_id = auth.uid() or s.created_by = auth.uid())
    )
    or (select coalesce((auth.jwt()->'app_metadata'->>'is_admin')::boolean, false))
  );

-- -----------------------------------------------------------------------------
-- 3. public.notifications
-- -----------------------------------------------------------------------------
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  message text not null,
  type text not null default 'application_update',
  target_id text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user_id
  on public.notifications(user_id);

create index if not exists idx_notifications_user_unread
  on public.notifications(user_id) where is_read = false;

alter table public.notifications enable row level security;

-- Policy: Authenticated users can create notifications (e.g. system/provider notifying applicant)
create policy "Authenticated users can create notifications"
  on public.notifications for insert
  to authenticated
  with check (true);

-- Policy: Users can only select their own notifications
create policy "Users can view their own notifications"
  on public.notifications for select
  to authenticated
  using (auth.uid() = user_id);

-- Policy: Users can update their own notifications (e.g. mark as read)
create policy "Users can update their own notifications"
  on public.notifications for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
