-- =============================================================================
-- Scholaris — 0002: Scholarship discovery contract
--
-- Reconciles public.scholarships with the domain model in
-- lib/features/scholarships/models/scholarship.dart and seeds realistic
-- Philippine scholarships so the discovery/matching experience has data.
--
-- The table is rebuilt (drop + recreate) because this is a development-stage
-- project with no production data and the old columns were incompatible with
-- the matching engine (which consumes max_income_bracket, regions_eligible,
-- citizenship_required, amount, coverage_type and tags).
-- =============================================================================

drop table if exists public.scholarships cascade;

create table public.scholarships (
  id                           uuid primary key default gen_random_uuid(),
  name                         text not null,
  provider                     text,
  description                  text,
  min_gpa                      numeric(3, 2) not null default 0,
  year_levels                  int[] not null default '{1,2,3,4,5}',
  eligible_courses             text[] not null default '{}',
  citizenship_required         text not null default 'any',
  regions_eligible             text[] not null default '{}',
  max_income_bracket           text not null default 'any'
                               check (max_income_bracket in ('low', 'mid', 'high', 'any')),
  is_pwd_priority              boolean not null default false,
  is_working_student_priority  boolean not null default false,
  slots_available              int,
  deadline                     date not null,
  amount                       numeric not null default 0,
  coverage_type                text,
  tags                         text[] not null default '{}',
  is_active                    boolean not null default true,
  created_at                   timestamptz not null default now()
);

alter table public.scholarships enable row level security;

-- RLS: any authenticated user may read; only service_role may write.
create policy "Scholarships are readable by authenticated users"
  on public.scholarships for select
  to authenticated
  using (true);

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

-- Restore the foreign keys from bookmarks/applications that the cascade drop
-- removed. The scholarships table keeps its uuid PK so the constraints are
-- recreated unchanged.
alter table public.bookmarks
  add constraint bookmarks_scholarship_id_fkey
  foreign key (scholarship_id) references public.scholarships (id) on delete cascade;

alter table public.applications
  add constraint applications_scholarship_id_fkey
  foreign key (scholarship_id) references public.scholarships (id) on delete cascade;

-- -----------------------------------------------------------------------------
-- Seed data — realistic Philippine scholarships (deadlines in the future).
-- -----------------------------------------------------------------------------

insert into public.scholarships
  (name, provider, description, min_gpa, year_levels, eligible_courses,
   citizenship_required, regions_eligible, max_income_bracket,
   is_pwd_priority, is_working_student_priority, slots_available, deadline,
   amount, coverage_type, tags, is_active)
values
  -- 1. Merit / national need-based
  ('CHED Merit Scholarship (MSRS)',
   'Commission on Higher Education',
   'A national merit scholarship for academically strong students. Covers tuition and a monthly stipend for the duration of the degree.',
   3.0, '{1,2,3,4,5}', '{}',
   'Filipino', '{NCR,CAR,Region I,Region II,Region III,Region IV-A (CALABARZON),MIMAROPA,Region V,Region VI,Region VII,Region VIII,Region IX,Region X,Region XI,Region XII,Region XIII (Caraga),BARMM}',
   'low', false, false, 2000, '2026-11-30', 50000, 'full', '{merit,stipend,undergraduate}', true),

  ('DOST-SEI Undergraduate Scholarship',
   'Department of Science and Technology',
   'Supports students pursuing priority STEM programs. Includes tuition subsidy, monthly stipend and learning materials allowance.',
   2.0, '{1,2,3,4,5}', '{}',
   'Filipino', '{NCR,CAR,Region I,Region II,Region III,Region IV-A (CALABARZON),MIMAROPA,Region V,Region VI,Region VII,Region VIII,Region IX,Region X,Region XI,Region XII,Region XIII (Caraga),BARMM}',
   'any', false, false, 8000, '2026-10-15', 70000, 'full', '{stem,stipend,priority-program}', true),

  ('CHED Tulong Dunong Program',
   'Commission on Higher Education',
   'Need-based financial assistance for students whose families earn below the poverty threshold. Priority is given to academically struggling students in good standing.',
   2.0, '{1,2,3,4,5}', '{}',
   'Filipino', '{}',
   'low', false, false, null, '2026-12-10', 30000, 'partial', '{need-based,undergraduate}', true),

  -- 2. Region-specific
  ('Maynila Education Grant',
   'City Government of Manila',
   'City scholarship for Manila residents in good academic standing. Covers tuition and partial allowance for one school year.',
   2.5, '{1,2,3,4}', '{}',
   'Filipino', '{NCR}',
   'low', false, false, 500, '2026-09-30', 25000, 'partial', '{city,local}', true),

  ('Visayas Regional Scholars Program',
   'Regional Development Council',
   'Encourages students from the Visayas to pursue higher education within their region through tuition support and mentorship.',
   2.75, '{1,2,3,4,5}', '{}',
   'Filipino', '{Region VI,Region VII,Region VIII}',
   'mid', false, false, 300, '2026-11-20', 20000, 'partial', '{regional,mentorship}', true),

  -- 3. Course-specific
  ('Women in Technology Grant',
   'Philippine Women''s Technology Alliance',
   'Supports female students pursuing computer science and information technology degrees with tuition coverage and a laptop allowance.',
   3.0, '{2,3,4}', '{BS Computer Science,BS Information Technology,BS Computer Engineering}',
   'Filipino', '{NCR,Region IV-A (CALABARZON),Region VII}',
   'any', false, false, 60, '2026-10-31', 45000, 'full', '{women-in-tech,laptop,stem}', true),

  ('Engineering Excellence Grant',
   'San Miguel Corporation Foundation',
   'For top-performing engineering students who can demonstrate financial need. Includes internship placement after graduation.',
   3.5, '{1,2,3,4,5}', '{}',
   'Filipino', '{NCR,Region III,Region IV-A (CALABARZON),Region VII,Region X}',
   'mid', false, false, 40, '2026-12-01', 60000, 'full', '{engineering,internship,high-gpa}', true),

  ('Nursing Leadership Scholarship',
   'Philippine Nurses Association',
   'Develops future nurse leaders from all regions. Covers tuition, board review and licensure exam fees.',
   3.0, '{1,2,3,4}', '{}',
   'Filipino', '{}',
   'any', false, false, 150, '2026-11-10', 55000, 'full', '{nursing,board-review}', true),

  -- 4. PWD / working-student priority
  ('Inclusive Education Grant',
   'National Commission on Disability',
   'Tuition support for students with disabilities in accredited higher education institutions.',
   2.0, '{1,2,3,4,5}', '{}',
   'Filipino', '{}',
   'mid', true, false, 100, '2026-10-25', 40000, 'full', '{pwd,inclusive}', true),

  ('Working Student Support Grant',
   'Aboitiz Foundation',
   'Flexible scholarship for students who work part-time while studying. Provides financial aid plus academic mentoring.',
   2.25, '{2,3,4}', '{}',
   'Filipino', '{NCR,Region VII,Region XI,Region XIII (Caraga)}',
   'mid', false, true, 200, '2026-12-05', 35000, 'partial', '{working-student,mentoring}', true),

  -- 5. Private / foundation
  ('Zobel de Ayala Scholars Program',
   'Ayala Foundation',
   'Holistic scholarship supporting students from public high schools in select cities. Covers tuition, stipend and leadership training.',
   2.75, '{1,2,3,4,5}', '{}',
   'Filipino', '{NCR,Region IV-A (CALABARZON),Region VII,Region XI}',
   'low', false, false, 80, '2026-11-05', 50000, 'full', '{leadership,holistic}', true),

  ('Ramon Aboitiz Foundation Grant',
   'Ramon Aboitiz Foundation Inc.',
   'Need-based grant for students in the Visayas committed to community development.',
   2.5, '{1,2,3,4,5}', '{}',
   'Filipino', '{Region VI,Region VII,Region VIII}',
   'low', false, false, 120, '2026-10-20', 28000, 'partial', '{community,visayas}', true);
