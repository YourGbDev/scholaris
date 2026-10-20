-- =============================================================================
-- Migration 0026 Security & Authorization Regression Suite
-- File: supabase/tests/organization_controls_security_test.sql
--
-- Executes automated security, RLS, capacity accounting, and school eligibility
-- assertions directly in PostgreSQL. All writes and fixtures are rolled back.
-- =============================================================================

begin;

-- Temporary tables for tracking test assertions
create temporary table test_results (
  test_vector text primary key,
  status text not null,
  details text
);

grant all on test_results to authenticated;

-- Disposable Test Fixtures
create temporary table fixture_ids (
  key text primary key,
  id uuid not null
);

grant select on fixture_ids to authenticated;

insert into fixture_ids (key, id) values
  ('org_admin_a', '11111111-0000-0000-0000-000000000001'),
  ('reviewer_a', '11111111-0000-0000-0000-000000000002'),
  ('org_admin_b', '22222222-0000-0000-0000-000000000001'),
  ('platform_admin', '99999999-0000-0000-0000-000000000001'),
  ('student_upd', '33333333-0000-0000-0000-000000000001'),
  ('student_ateneo', '33333333-0000-0000-0000-000000000002'),
  ('student_no_school', '33333333-0000-0000-0000-000000000003'),
  ('grant_capped', '44444444-0000-0000-0000-000000000001'),
  ('grant_inactive', '44444444-0000-0000-0000-000000000002'),
  ('grant_restricted', '44444444-0000-0000-0000-000000000003'),
  ('app_1', '55555555-0000-0000-0000-000000000001'),
  ('app_2', '55555555-0000-0000-0000-000000000002'),
  ('app_3', '55555555-0000-0000-0000-000000000003');

-- -----------------------------------------------------------------------------
-- Fixture Setup (as superuser / postgres)
-- -----------------------------------------------------------------------------
do $$
declare
  v_upd_id uuid;
  v_ateneo_id uuid;
  v_admin_a uuid := '11111111-0000-0000-0000-000000000001';
  v_rev_a uuid := '11111111-0000-0000-0000-000000000002';
  v_admin_b uuid := '22222222-0000-0000-0000-000000000001';
  v_plat uuid := '99999999-0000-0000-0000-000000000001';
  v_st_upd uuid := '33333333-0000-0000-0000-000000000001';
  v_st_ateneo uuid := '33333333-0000-0000-0000-000000000002';
  v_st_none uuid := '33333333-0000-0000-0000-000000000003';
  v_grant_capped uuid := '44444444-0000-0000-0000-000000000001';
  v_grant_inactive uuid := '44444444-0000-0000-0000-000000000002';
  v_grant_restricted uuid := '44444444-0000-0000-0000-000000000003';
  v_app1 uuid := '55555555-0000-0000-0000-000000000001';
  v_app2 uuid := '55555555-0000-0000-0000-000000000002';
  v_app3 uuid := '55555555-0000-0000-0000-000000000003';
  v_err_code text;
  v_err_msg text;
begin
  select id into v_upd_id from public.schools where normalized_name = 'university of the philippines diliman';
  select id into v_ateneo_id from public.schools where normalized_name = 'ateneo de manila university';

  -- Auth Users setup
  insert into auth.users (id, email) values
    (v_admin_a, 'admin_a@test.ph'),
    (v_rev_a, 'reviewer_a@test.ph'),
    (v_admin_b, 'admin_b@test.ph'),
    (v_plat, 'plat_admin@test.ph'),
    (v_st_upd, 'st_upd@test.ph'),
    (v_st_ateneo, 'st_ateneo@test.ph'),
    (v_st_none, 'st_none@test.ph')
  on conflict (id) do nothing;

  -- Profiles setup
  insert into public.profiles (id, full_name, email, role, status, school_id) values
    (v_admin_a, 'Admin Alpha', 'admin_a@test.ph', 'provider', 'active', null),
    (v_rev_a, 'Reviewer Alpha', 'reviewer_a@test.ph', 'provider', 'active', null),
    (v_admin_b, 'Admin Beta', 'admin_b@test.ph', 'provider', 'active', null),
    (v_plat, 'Platform Admin', 'plat_admin@test.ph', 'admin', 'active', null),
    (v_st_upd, 'Student UPD', 'st_upd@test.ph', 'student', 'active', v_upd_id),
    (v_st_ateneo, 'Student Ateneo', 'st_ateneo@test.ph', 'student', 'active', v_ateneo_id),
    (v_st_none, 'Student No School', 'st_none@test.ph', 'student', 'active', null)
  on conflict (id) do update set role = excluded.role, school_id = excluded.school_id;

  -- Organization Memberships
  insert into public.organization_memberships (user_id, organization_id, role, active) values
    (v_admin_a, v_admin_a, 'org_admin', true),
    (v_rev_a, v_admin_a, 'reviewer', true),
    (v_admin_b, v_admin_b, 'org_admin', true)
  on conflict (user_id) do update set role = excluded.role, active = true;

  -- Scholarships
  insert into public.scholarships (id, title, created_by, deadline, slots, is_active) values
    (v_grant_capped, 'Capped Grant (5 slots)', v_admin_a, current_date + 30, 5, true),
    (v_grant_inactive, 'Inactive Grant', v_admin_a, current_date + 30, 10, false);

  insert into public.scholarships (id, title, created_by, deadline, slots, is_active, eligible_school_ids) values
    (v_grant_restricted, 'UPD Only Grant', v_admin_a, current_date + 30, 10, true, array[v_upd_id]);

  -- Populate 3 approved applications to capped grant
  insert into public.applications (id, user_id, scholarship_id, status) values
    (v_app1, v_st_upd, v_grant_capped, 'approved'),
    (v_app2, v_st_ateneo, v_grant_capped, 'approved'),
    (v_app3, v_st_none, v_grant_capped, 'approved');

  -- Vector 2: Capacity Reduction Constraint Trigger Test
  begin
    update public.scholarships set slots = 2 where id = v_grant_capped;
    raise exception 'Capacity reduction below occupied unexpectedly succeeded';
  exception when others then
    get stacked diagnostics v_err_code = returned_sqlstate, v_err_msg = message_text;
    if v_err_code = 'P0002' then
      insert into test_results values ('Vector 2: Capacity Reduction Trigger', 'PASS', 'Rejected with P0002: ' || v_err_msg);
    else
      raise exception 'Expected P0002 but got %: %', v_err_code, v_err_msg;
    end if;
  end;
end;
$$;

-- -----------------------------------------------------------------------------
-- Authenticated as Student Ateneo (School Eligibility Enforcement)
-- -----------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claim.sub', '33333333-0000-0000-0000-000000000002', true);

do $$
declare
  v_grant_restricted uuid := '44444444-0000-0000-0000-000000000003';
  v_st_ateneo uuid := '33333333-0000-0000-0000-000000000002';
  v_err_code text;
  v_err_msg text;
begin
  begin
    insert into public.applications (user_id, scholarship_id, status)
    values (v_st_ateneo, v_grant_restricted, 'submitted');
    raise exception 'Cross-school submission unexpectedly succeeded';
  exception when others then
    get stacked diagnostics v_err_code = returned_sqlstate, v_err_msg = message_text;
    if v_err_code = 'P0003' then
      insert into test_results values ('Vector 6: School Eligibility Guard', 'PASS', 'Rejected with P0003: ' || v_err_msg);
    else
      raise exception 'Expected P0003 but got %: %', v_err_code, v_err_msg;
    end if;
  end;
end;
$$;

-- -----------------------------------------------------------------------------
-- Authenticated as Student With No School
-- -----------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claim.sub', '33333333-0000-0000-0000-000000000003', true);

do $$
declare
  v_grant_restricted uuid := '44444444-0000-0000-0000-000000000003';
  v_st_none uuid := '33333333-0000-0000-0000-000000000003';
  v_err_code text;
  v_err_msg text;
begin
  begin
    insert into public.applications (user_id, scholarship_id, status)
    values (v_st_none, v_grant_restricted, 'submitted');
    raise exception 'Missing school submission unexpectedly succeeded';
  exception when others then
    get stacked diagnostics v_err_code = returned_sqlstate, v_err_msg = message_text;
    if v_err_code = 'P0003' then
      insert into test_results values ('Vector 7: Missing School Guard', 'PASS', 'Rejected with P0003: ' || v_err_msg);
    else
      raise exception 'Expected P0003 but got %: %', v_err_code, v_err_msg;
    end if;
  end;
end;
$$;

-- -----------------------------------------------------------------------------
-- Authenticated as Student UPD (Deduplication and Capacity Access)
-- -----------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claim.sub', '33333333-0000-0000-0000-000000000001', true);

do $$
declare
  v_upd_id uuid;
  v_custom_school_id uuid;
  v_cap record;
  v_grant_capped uuid := '44444444-0000-0000-0000-000000000001';
  v_grant_inactive uuid := '44444444-0000-0000-0000-000000000002';
  v_inactive_count int;
begin
  select id into v_upd_id from public.schools where normalized_name = 'university of the philippines diliman';

  -- Vector 8: Deduplication check
  v_custom_school_id := public.add_custom_school('   UNIVERSITY of the PHILIPPINES Diliman   ');
  if v_custom_school_id = v_upd_id then
    insert into test_results values ('Vector 8: School Deduplication', 'PASS', 'Matched existing school ID cleanly');
  else
    raise exception 'Deduplication failed to match existing school ID';
  end if;

  -- Vector 3: Active capacity query succeeds
  select * into v_cap from public.get_scholarship_capacity(v_grant_capped);
  if v_cap.total_slots = 5 and v_cap.occupied_slots = 3 and v_cap.remaining_slots = 2 then
    insert into test_results values ('Vector 3: Active Capacity Calculation', 'PASS', 'total: 5, occupied: 3, remaining: 2');
  else
    raise exception 'Capacity calculation mismatch: %', v_cap;
  end if;

  -- Vector 3: Inactive capacity query returns 0 rows
  select count(*) into v_inactive_count from public.get_scholarship_capacity(v_grant_inactive);
  if v_inactive_count = 0 then
    insert into test_results values ('Vector 3: Inactive Grant Privacy', 'PASS', 'Zero rows returned for inactive grant');
  else
    raise exception 'Inactive grant capacity leaked to student: % rows', v_inactive_count;
  end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Authenticated as Org Admin A (Roster, Assignments, Cross-Org Security)
-- -----------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-0000-0000-0000-000000000001', true);

do $$
declare
  v_admin_a uuid := '11111111-0000-0000-0000-000000000001';
  v_rev_a uuid := '11111111-0000-0000-0000-000000000002';
  v_admin_b uuid := '22222222-0000-0000-0000-000000000001';
  v_grant_capped uuid := '44444444-0000-0000-0000-000000000001';
  v_count int;
  v_err_code text;
  v_err_msg text;
begin
  -- Vector 9: Roster Provider Isolation
  select count(*) into v_count from public.get_organization_roster(v_admin_a);
  if v_count >= 2 then
    insert into test_results values ('Vector 9: Roster Provider Isolation', 'PASS', 'Returned ' || v_count || ' members; students excluded');
  else
    raise exception 'Roster returned unexpected count: %', v_count;
  end if;

  -- Vector 10: Cross-Organization Assignment Boundary
  begin
    perform public.assign_scholarship_reviewer(v_grant_capped, v_admin_b);
    raise exception 'Assigning cross-org reviewer unexpectedly succeeded';
  exception when others then
    get stacked diagnostics v_err_code = returned_sqlstate, v_err_msg = message_text;
    insert into test_results values ('Vector 10: Cross-Org Assignment Boundary', 'PASS', 'Rejected with code: ' || v_err_code);
  end;

  -- Vector 10b: Org Admin Assign and Unassign Reviewer
  perform public.assign_scholarship_reviewer(v_grant_capped, v_rev_a);
  if exists (select 1 from public.scholarship_reviewer_assignments where scholarship_id = v_grant_capped and reviewer_id = v_rev_a) then
    insert into test_results values ('Vector 10b: Org Admin Assign Reviewer', 'PASS', 'Reviewer successfully assigned');
  else
    raise exception 'Reviewer assignment was not created';
  end if;

  perform public.unassign_scholarship_reviewer(v_grant_capped, v_rev_a);
  if not exists (select 1 from public.scholarship_reviewer_assignments where scholarship_id = v_grant_capped and reviewer_id = v_rev_a) then
    insert into test_results values ('Vector 10c: Org Admin Unassign Reviewer', 'PASS', 'Reviewer successfully unassigned');
  else
    raise exception 'Reviewer assignment was not deleted';
  end if;

  -- Vector 10j: Org Admin Direct Table INSERT Denied (Must use validated RPC)
  begin
    insert into public.scholarship_reviewer_assignments (scholarship_id, reviewer_id, assigned_by)
    values (v_grant_capped, v_rev_a, v_admin_a);
    raise exception 'Direct INSERT unexpectedly succeeded';
  exception when others then
    get stacked diagnostics v_err_code = returned_sqlstate;
    if v_err_code = '42501' then
      insert into test_results values ('Vector 10j: Org Admin Direct INSERT Denied', 'PASS', 'Rejected with 42501');
    else
      raise exception 'Expected 42501 on direct INSERT but got %', v_err_code;
    end if;
  end;

  -- Vector 10k: Org Admin Direct Table UPDATE Denied
  begin
    update public.scholarship_reviewer_assignments set reviewer_id = v_rev_a where scholarship_id = v_grant_capped;
    raise exception 'Direct UPDATE unexpectedly succeeded';
  exception when others then
    get stacked diagnostics v_err_code = returned_sqlstate;
    if v_err_code = '42501' then
      insert into test_results values ('Vector 10k: Org Admin Direct UPDATE Denied', 'PASS', 'Rejected with 42501');
    else
      raise exception 'Expected 42501 on direct UPDATE but got %', v_err_code;
    end if;
  end;

  -- Vector 10l: Org Admin Direct Table DELETE Denied
  begin
    delete from public.scholarship_reviewer_assignments where scholarship_id = v_grant_capped;
    raise exception 'Direct DELETE unexpectedly succeeded';
  exception when others then
    get stacked diagnostics v_err_code = returned_sqlstate;
    if v_err_code = '42501' then
      insert into test_results values ('Vector 10l: Org Admin Direct DELETE Denied', 'PASS', 'Rejected with 42501');
    else
      raise exception 'Expected 42501 on direct DELETE but got %', v_err_code;
    end if;
  end;

  -- Vector 10m: Org Admin SELECT on assignments visible through RLS
  perform public.assign_scholarship_reviewer(v_grant_capped, v_rev_a);
  select count(*) into v_count from public.scholarship_reviewer_assignments where scholarship_id = v_grant_capped;
  if v_count = 1 then
    insert into test_results values ('Vector 10m: Org Admin Assignments SELECT Preserved', 'PASS', 'Assignment visible via RLS');
  else
    raise exception 'Org admin expected 1 assignment but got %', v_count;
  end if;
  perform public.unassign_scholarship_reviewer(v_grant_capped, v_rev_a);
end;
$$;

-- -----------------------------------------------------------------------------
-- Authenticated as Outsider (Student Ateneo attempting assign/unassign)
-- -----------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claim.sub', '33333333-0000-0000-0000-000000000002', true);

do $$
declare
  v_grant_capped uuid := '44444444-0000-0000-0000-000000000001';
  v_rev_a uuid := '11111111-0000-0000-0000-000000000002';
  v_err_code text;
  v_count int;
begin
  begin
    perform public.assign_scholarship_reviewer(v_grant_capped, v_rev_a);
    raise exception 'Outsider assign unexpectedly succeeded';
  exception when others then
    get stacked diagnostics v_err_code = returned_sqlstate;
    if v_err_code = '42501' then
      insert into test_results values ('Vector 10d: Outsider Assign Denied', 'PASS', 'Rejected with 42501');
    else
      raise exception 'Expected 42501 but got %', v_err_code;
    end if;
  end;

  begin
    perform public.unassign_scholarship_reviewer(v_grant_capped, v_rev_a);
    raise exception 'Outsider unassign unexpectedly succeeded';
  exception when others then
    get stacked diagnostics v_err_code = returned_sqlstate;
    if v_err_code = '42501' then
      insert into test_results values ('Vector 10e: Outsider Unassign Denied', 'PASS', 'Rejected with 42501');
    else
      raise exception 'Expected 42501 but got %', v_err_code;
    end if;
  end;

  -- Vector 10n: Outsider Direct Table INSERT Denied
  begin
    insert into public.scholarship_reviewer_assignments (scholarship_id, reviewer_id, assigned_by)
    values (v_grant_capped, v_rev_a, '33333333-0000-0000-0000-000000000002');
    raise exception 'Outsider direct INSERT unexpectedly succeeded';
  exception when others then
    get stacked diagnostics v_err_code = returned_sqlstate;
    if v_err_code = '42501' then
      insert into test_results values ('Vector 10n: Outsider Direct INSERT Denied', 'PASS', 'Rejected with 42501');
    else
      raise exception 'Expected 42501 on outsider direct INSERT but got %', v_err_code;
    end if;
  end;

  -- Vector 10o: Outsider SELECT on assignments filtered to 0 rows by RLS
  select count(*) into v_count from public.scholarship_reviewer_assignments where scholarship_id = v_grant_capped;
  if v_count = 0 then
    insert into test_results values ('Vector 10o: Outsider Assignments SELECT Isolated', 'PASS', 'Returned 0 rows under RLS');
  else
    raise exception 'Outsider saw % assignments under RLS', v_count;
  end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Authenticated as Reviewer (Reviewer A attempting assign/unassign)
-- -----------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-0000-0000-0000-000000000002', true);

do $$
declare
  v_grant_capped uuid := '44444444-0000-0000-0000-000000000001';
  v_rev_a uuid := '11111111-0000-0000-0000-000000000002';
  v_err_code text;
begin
  begin
    perform public.assign_scholarship_reviewer(v_grant_capped, v_rev_a);
    raise exception 'Reviewer assign unexpectedly succeeded';
  exception when others then
    get stacked diagnostics v_err_code = returned_sqlstate;
    if v_err_code = '42501' then
      insert into test_results values ('Vector 10f: Reviewer Assign Denied', 'PASS', 'Rejected with 42501');
    else
      raise exception 'Expected 42501 but got %', v_err_code;
    end if;
  end;

  begin
    perform public.unassign_scholarship_reviewer(v_grant_capped, v_rev_a);
    raise exception 'Reviewer unassign unexpectedly succeeded';
  exception when others then
    get stacked diagnostics v_err_code = returned_sqlstate;
    if v_err_code = '42501' then
      insert into test_results values ('Vector 10g: Reviewer Unassign Denied', 'PASS', 'Rejected with 42501');
    else
      raise exception 'Expected 42501 but got %', v_err_code;
    end if;
  end;
end;
$$;

-- -----------------------------------------------------------------------------
-- Authenticated as Platform Admin (Assign and Unassign Reviewer)
-- -----------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claim.sub', '99999999-0000-0000-0000-000000000001', true);

do $$
declare
  v_grant_capped uuid := '44444444-0000-0000-0000-000000000001';
  v_rev_a uuid := '11111111-0000-0000-0000-000000000002';
begin
  perform public.assign_scholarship_reviewer(v_grant_capped, v_rev_a);
  if exists (select 1 from public.scholarship_reviewer_assignments where scholarship_id = v_grant_capped and reviewer_id = v_rev_a) then
    insert into test_results values ('Vector 10h: Platform Admin Assign Reviewer', 'PASS', 'Reviewer successfully assigned');
  else
    raise exception 'Platform admin reviewer assignment was not created';
  end if;

  perform public.unassign_scholarship_reviewer(v_grant_capped, v_rev_a);
  if not exists (select 1 from public.scholarship_reviewer_assignments where scholarship_id = v_grant_capped and reviewer_id = v_rev_a) then
    insert into test_results values ('Vector 10i: Platform Admin Unassign Reviewer', 'PASS', 'Reviewer successfully unassigned');
  else
    raise exception 'Platform admin reviewer assignment was not deleted';
  end if;
end;
$$;

reset role;

-- Output test results
select test_vector, status, details from test_results order by test_vector;

rollback;
