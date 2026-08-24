-- =============================================================================
-- Scholaris — initial schema
-- Scholarship-matching app: profiles, scholarships, bookmarks, applications.
-- Run in the Supabase SQL editor (or as a migration).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Helper: touch updated_at on UPDATE
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 1. profiles
-- -----------------------------------------------------------------------------
create table public.profiles (
  id                    uuid primary key references auth.users (id) on delete cascade,
  full_name             text,
  birth_date            date,
  gender                text,
  nationality           text default 'Filipino',
  region                text,
  province              text,
  city_municipality     text,
  gpa                   numeric(3, 2),
  year_level            int,
  course                text,
  school                text,
  monthly_family_income numeric,
  has_disability        boolean not null default false,
  is_indigenous         boolean not null default false,
  setup_complete        boolean not null default false,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Auto-create a blank profile when a user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id)
  values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Keep updated_at fresh.
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

-- RLS: a user may only read/update their own row, and only their own row may
-- be inserted (e.g. by the sign-up trigger / client after auth).
create policy "Profiles are selectable by owner"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Profiles are insertable by owner"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Profiles are updatable by owner"
  on public.profiles for update
  using (auth.uid() = id);

-- -----------------------------------------------------------------------------
-- 2. scholarships
-- -----------------------------------------------------------------------------
create table public.scholarships (
  id                  uuid primary key default gen_random_uuid(),
  title               text not null,
  provider            text,
  description         text,
  min_gpa             numeric,
  max_monthly_income  numeric,
  required_year_levels int[],
  required_courses    text[],
  location_restriction text,
  for_indigenous      boolean not null default false,
  for_pwd             boolean not null default false,
  slots               int,
  deadline            date,
  application_url     text,
  is_active           boolean not null default true,
  created_at          timestamptz not null default now()
);

alter table public.scholarships enable row level security;

-- RLS: any authenticated user may read; only service_role may write.
create policy "Scholarships are readable by authenticated users"
  on public.scholarships for select
  to authenticated
  using (true);

-- The service_role bypasses RLS by default; these policies make the intent
-- explicit for any connection that presents the service role.
create policy "Scholarships are insertable by service_role only"
  on public.scholarships for insert
  to service_role
  with check (true);

create policy "Scholarships are updatable by service_role only"
  on public.scholarships for update
  to service_role
  using (true);

create policy "Scholarships are deletable by service_role only"
  on public.scholarships for delete
  to service_role
  using (true);

-- -----------------------------------------------------------------------------
-- 3. bookmarks
-- -----------------------------------------------------------------------------
create table public.bookmarks (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users (id) on delete cascade,
  scholarship_id uuid not null references public.scholarships (id) on delete cascade,
  created_at     timestamptz not null default now(),
  unique (user_id, scholarship_id)
);

alter table public.bookmarks enable row level security;

-- RLS: users may fully manage their own bookmarks only.
create policy "Bookmarks are selectable by owner"
  on public.bookmarks for select
  using (auth.uid() = user_id);

create policy "Bookmarks are insertable by owner"
  on public.bookmarks for insert
  with check (auth.uid() = user_id);

create policy "Bookmarks are updatable by owner"
  on public.bookmarks for update
  using (auth.uid() = user_id);

create policy "Bookmarks are deletable by owner"
  on public.bookmarks for delete
  using (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 4. applications
-- -----------------------------------------------------------------------------
create table public.applications (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users (id) on delete cascade,
  scholarship_id uuid not null references public.scholarships (id) on delete cascade,
  status         text not null default 'draft'
                 check (status in ('draft', 'submitted', 'under_review', 'approved', 'rejected')),
  notes          text,
  applied_at     timestamptz,
  updated_at     timestamptz not null default now()
);

alter table public.applications enable row level security;

create trigger applications_set_updated_at
  before update on public.applications
  for each row execute procedure public.set_updated_at();

-- RLS: users may read/insert/update their own applications only.
create policy "Applications are selectable by owner"
  on public.applications for select
  using (auth.uid() = user_id);

create policy "Applications are insertable by owner"
  on public.applications for insert
  with check (auth.uid() = user_id);

create policy "Applications are updatable by owner"
  on public.applications for update
  using (auth.uid() = user_id);
