-- Live regression rehearsal for the named demo identities, with no credentials.
-- All fixture writes and assertions are rolled back. Run the whole script.
begin;
create temporary table cycle_fixture (application_id uuid, scholarship_id uuid);
create temporary table cycle_results (test text, result text);
create temporary table cycle_foreign_fixture (application_id uuid);
grant select on cycle_fixture to authenticated;
grant select on cycle_foreign_fixture to authenticated;
grant insert, select on cycle_results to authenticated;
with s as (
  insert into public.scholarships(title,created_by,deadline,is_active)
  values ('Transactional RLS rehearsal (rolled back)',
    '0574ae43-93ca-4961-a90a-efba58f373ef',current_date+30,true) returning id
), a as (
  insert into public.applications(user_id,scholarship_id,status,notes)
  select 'b7aeaf4e-6907-4325-925f-18d59b761abc',id,'submitted','Student statement preserved' from s
  returning id,scholarship_id
) insert into cycle_fixture select id,scholarship_id from a;
-- A different organization principal. Scholarship ownership alone must not
-- grant this reviewer authority outside the explicitly assigned organization.
with s as (
  insert into public.scholarships(title,created_by,deadline,is_active)
  values ('Other organization test (rolled back)',
    '5caeaf69-fba0-441d-95b5-fb0e2762c23d',current_date+30,true) returning id
), a as (
  insert into public.applications(user_id,scholarship_id,status)
  select 'b7aeaf4e-6907-4325-925f-18d59b761abc',id,'submitted' from s returning id
) insert into cycle_foreign_fixture select id from a;

set local role authenticated;
select set_config('request.jwt.claim.sub','5caeaf69-fba0-441d-95b5-fb0e2762c23d',true);
do $$
declare a uuid; foreign_a uuid; n int;
begin
  select application_id into a from cycle_fixture;
  select application_id into foreign_a from cycle_foreign_fixture;
  if not exists (select 1 from public.applications where id=a) then raise exception 'Reviewer SELECT failed'; end if;
  insert into cycle_results values ('Authorized reviewer SELECT','PASS');
  begin
    perform public.review_application(a,'submitted','approve');
    raise exception 'Reviewer approval unexpectedly succeeded';
  exception when insufficient_privilege then null; end;
  begin
    perform public.review_application(a,'submitted','reject');
    raise exception 'Reviewer rejection unexpectedly succeeded';
  exception when insufficient_privilege then null; end;
  insert into cycle_results values ('Reviewer approval/rejection denied','PASS');
  if exists (select 1 from public.applications where id=foreign_a) then raise exception 'Cross-org SELECT leak'; end if;
  begin
    perform public.review_application(foreign_a,'submitted','endorse',
      '{"academic":8,"financial":7,"leadership":9,"vision":8}');
    raise exception 'Cross-org endorsement unexpectedly succeeded';
  exception when insufficient_privilege then null; end;
  insert into cycle_results values ('Cross-org reviewer SELECT and endorsement denied','PASS');
  if exists (select 1 from public.profiles where id='b7aeaf4e-6907-4325-925f-18d59b761abc') then
    raise exception 'Raw student profile leak'; end if;
  insert into cycle_results values ('Raw student profile denied to reviewer','PASS');
  update public.applications set status='approved' where id=a;
  get diagnostics n=row_count;
  if n<>0 then raise exception 'Direct final update affected rows'; end if;
  insert into cycle_results values ('Direct final update returns zero rows','PASS');
  perform public.review_application(a,'submitted','endorse',
    '{"academic":8,"financial":7,"leadership":9,"vision":8}', 'Live rollback evaluation');
  if not exists (select 1 from public.application_evaluations where application_id=a and decision='endorsed'
    and reviewer_id=auth.uid() and composite_score=7.90) then raise exception 'Evaluation not persisted'; end if;
  insert into cycle_results values ('Reviewer endorsement/evaluation persisted','PASS');
  if exists (select 1 from public.applications where id=a and notes<>'Student statement preserved') then
    raise exception 'Student essay overwritten'; end if;
end;
$$;
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','0574ae43-93ca-4961-a90a-efba58f373ef',true);
do $$
declare a uuid; foreign_a uuid;
begin
  select application_id into a from cycle_fixture;
  select application_id into foreign_a from cycle_foreign_fixture;
  begin
    perform public.review_application(foreign_a,'submitted','approve');
    raise exception 'Cross-org admin decision unexpectedly succeeded';
  exception when insufficient_privilege then null; end;
  insert into cycle_results values ('Cross-org admin decision denied','PASS');
  perform public.review_application(a,'under_review','approve',null,'Final demo decision');
  if not exists (select 1 from public.applications where id=a and status='approved'
    and decided_by=auth.uid() and decided_at is not null and endorsed_at is not null) then
    raise exception 'Admin decision not persisted'; end if;
  if (select count(*) from public.application_status_history where application_id=a) <> 2 then
    raise exception 'History not persisted'; end if;
  insert into cycle_results values ('Admin approval/actor/timestamp/history persisted','PASS');
end;
$$;
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','b7aeaf4e-6907-4325-925f-18d59b761abc',true);
do $$
declare a uuid;
begin
  select application_id into a from cycle_fixture;
  if not exists (select 1 from public.notifications where target_id=a::text and title='Application Approved') then
    raise exception 'Student notification not persisted'; end if;
  insert into cycle_results values ('Student reads committed final notification','PASS');
  begin
    insert into public.notifications(user_id,title,message) values (auth.uid(),'Forged','Forged');
    raise exception 'Forged notification succeeded';
  exception when insufficient_privilege then null; end;
  insert into cycle_results values ('Forged notification denied','PASS');
end;
$$;
reset role;
select * from cycle_results;
rollback;
