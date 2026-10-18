// npm install --prefix scratch/cycle-testing @electric-sql/pglite --no-audit --no-fund
// node tools/test_organization_review_cycle.mjs
// Runs actual PostgreSQL RLS/functions, not a mock of authorization logic.
import { PGlite } from '../scratch/cycle-testing/node_modules/@electric-sql/pglite/dist/index.js';
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
const db = new PGlite();
const id = n => `00000000-0000-0000-0000-${String(n).padStart(12, '0')}`;
const [admin, reviewer, student, outsider, otherStudent, finance, platformAdmin] = [1,2,3,4,5,6,7].map(id);
const [grant, otherGrant, app, rejectedApp, draft, withdrawn, otherApp] = [11,12,21,22,23,24,25].map(id);
let passed = 0;
async function test(name, body) { await body(); passed++; console.log(`PASS ${name}`); }
async function as(user, sql, params=[]) {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub', $1, false)", [user]);
  await db.exec('set role authenticated');
  try { return await db.query(sql, params); } finally { await db.exec('reset role'); }
}
const review = (user, application, action, status='submitted', scores={academic:8,financial:7,leadership:9,vision:8}) =>
  as(user, 'select * from public.review_application($1,$2,$3,$4,$5)', [application,status,action,JSON.stringify(scores),'Demo evaluation']);
async function denied(fn) { await assert.rejects(fn); }
await db.exec(`
  create role authenticated; create role anon; create role service_role bypassrls;
  create schema auth; create schema storage;
  create table auth.users(id uuid primary key);
  create function auth.uid() returns uuid language sql stable as
    $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
  create table storage.buckets(id text primary key, name text, public boolean);
  create table storage.objects(id uuid primary key default gen_random_uuid(), bucket_id text, name text);
  alter table storage.objects enable row level security;
  create function storage.foldername(text) returns text[] language sql immutable as
    $$select string_to_array($1,'/')$$;
  grant usage on schema public,auth,storage to authenticated,anon;
`);
async function migration(name) { await db.exec(await readFile(new URL(`../supabase/migrations/${name}.sql`, import.meta.url), 'utf8')); }
await migration('0001_init');
await db.exec("alter table public.profiles add role text default 'student', add status text default 'active'");
for(const file of ['0003_application_withdraw','0004_scholarships_created_by','0009_admin_award_application',
  '0010_providers_manage_own_scholarships','0017_application_documents','0019_tighten_application_documents_access',
  '0020_restrict_provider_profile_access','0022_restrict_provider_applications_select','0023_transaction_cycle_persistence']) await migration(file);
// Supabase's default privileges, plus live legacy policies observed in dashboard.
await db.exec(`grant all on all tables in schema public,storage to authenticated;
  create policy legacy_finance_escape on public.applications for all to authenticated using (true) with check (true);
  create policy legacy_storage_read on storage.objects for select to authenticated using (true);
`);
await migration('0024_organization_review_cycle');
await migration('0025_preserve_existing_award_transition');
await db.exec(`insert into auth.users(id) values ${[admin,reviewer,student,outsider,otherStudent,finance,platformAdmin].map(x=>`('${x}')`).join(',')};
  update public.profiles set role='provider' where id in ('${admin}','${reviewer}','${outsider}','${finance}');
  update public.profiles set role='admin' where id='${platformAdmin}';
  insert into public.organization_memberships(user_id,organization_id,role) values
    ('${admin}','${admin}','org_admin'), ('${reviewer}','${admin}','reviewer'),
    ('${outsider}','${outsider}','org_admin'), ('${finance}','${admin}','finance');
  insert into public.scholarships(id,title,created_by,deadline) values
    ('${grant}','Demo grant','${admin}',current_date+30),('${otherGrant}','Other org','${outsider}',current_date+30);
  insert into public.applications(id,user_id,scholarship_id,status,notes) values
    ('${app}','${student}','${grant}','submitted','Student essay'),
    ('${rejectedApp}','${otherStudent}','${grant}','submitted','Other essay'),
    ('${draft}','${otherStudent}','${grant}','draft','Private draft'),
    ('${withdrawn}','${otherStudent}','${grant}','withdrawn','Private withdrawn'),
    ('${otherApp}','${student}','${otherGrant}','submitted','Other org essay');
  insert into storage.objects(bucket_id,name) values
    ('application_documents','${app}/transcript.pdf'),('application_documents','${draft}/private.pdf'),
    ('application_documents','${otherApp}/cross-org.pdf'),('application_documents','malformed/fail.pdf');
`);
await test('reviewer sees own org submissions; drafts/withdrawn/cross-org denied despite legacy policies', async()=> {
  const r=await as(reviewer,'select id from public.applications');
  assert.deepEqual(r.rows.map(x=>x.id).sort(),[app,rejectedApp].sort());
});
await test('reviewer document access excludes drafts and other organizations',async()=> {
  const r=await as(reviewer,"select name from storage.objects where bucket_id='application_documents'");
  assert.deepEqual(r.rows.map(x=>x.name),[`${app}/transcript.pdf`]);
});
await test('reviewer receives minimized academic profile; raw private profiles denied',async()=> {
  assert.equal((await as(reviewer,'select id from public.get_applicant_profile($1)',[student])).rows.length,1);
  assert.equal((await as(reviewer,'select id from public.profiles where id=$1',[student])).rows.length,0);
  const fields=Object.keys((await as(reviewer,'select * from public.get_applicant_profile($1)',[student])).rows[0]);
  for(const f of ['birth_date','gender','phone','email','has_disability','is_indigenous']) assert(!fields.includes(f));
});
await test('membership self-promotion and forged notifications denied', async()=> {
  await denied(()=>as(reviewer,"update public.organization_memberships set role='org_admin' where user_id=$1",[reviewer]));
  await denied(()=>as(reviewer,"insert into public.notifications(user_id,title,message) values ($1,'fake','fake')",[student]));
});
await test('reviewer cannot publish scholarships',()=>denied(()=>as(reviewer,"insert into public.scholarships(title,created_by,deadline) values ('Unauthorized',$1,current_date+30)",[reviewer])));
await test('admin can publish scholarships',async()=> {
  assert.equal((await as(admin,"insert into public.scholarships(title,created_by,deadline) values ('Published',$1,current_date+30) returning id",[admin])).rows.length,1);
});
await test('admin cannot decide without a separate endorsement',()=>denied(()=>review(admin,app,'approve')));
await test('reviewer approval and rejection RPCs denied',async()=>{
  await denied(()=>review(reviewer,app,'approve')); await denied(()=>review(reviewer,app,'reject'));
});
await test('direct reviewer/admin final PATCH affects zero rows',async()=>{
  for(const user of [reviewer,admin]) {
    const r=await as(user,"update public.applications set status='approved' where id=$1 returning id",[app]);
    assert.equal(r.rows.length,0);
  }
});
await test('cross-org endorsement, final decisions, and finance access denied',async()=>{
  await denied(()=>review(outsider,app,'endorse'));
  await denied(()=>review(outsider,app,'approve'));
  await denied(()=>review(reviewer,otherApp,'endorse'));
  assert.equal((await as(finance,'select id from public.applications')).rows.length,0);
});
await test('student cannot forge endorsement fields, final result, or reassign ownership',async()=>{
  await denied(()=>as(student,"update public.applications set endorsed_by=$1 where id=$2",[reviewer,app]));
  await denied(()=>as(student,"update public.applications set status='approved' where id=$1",[app]));
  await denied(()=>as(student,"update public.applications set scholarship_id=$1 where id=$2",[otherGrant,app]));
});
await test('invalid evaluation rolls back without history/status change',async()=>{
  await denied(()=>review(reviewer,app,'endorse','submitted',{academic:99,financial:7,leadership:8,vision:9}));
  assert.equal((await db.query('select status from applications where id=$1',[app])).rows[0].status,'submitted');
  assert.equal((await db.query('select * from application_evaluations')).rows.length,0);
});
await test('reviewer endorsement persists actor, timestamp, rubric and history without changing essay',async()=>{
  const r=await review(reviewer,app,'endorse');
  assert.equal(r.rows[0].status,'under_review'); assert.equal(r.rows[0].endorsed_by,reviewer);
  assert(r.rows[0].endorsed_at); assert.equal(r.rows[0].notes,'Student essay');
  const e=(await db.query('select * from application_evaluations where application_id=$1',[app])).rows[0];
  assert.equal(e.decision,'endorsed'); assert.equal(e.reviewer_id,reviewer); assert.equal(Number(e.composite_score),7.9);
  const h=(await db.query('select * from application_status_history where application_id=$1',[app])).rows;
  assert.equal(h.length,1); assert.equal(h[0].changed_by,reviewer); assert(h[0].remarks.includes('Endorsed'));
});
await test('duplicate/stale endorsement and reviewer final decision denied after endorsement',async()=>{
  await denied(()=>review(reviewer,app,'endorse')); await denied(()=>review(reviewer,app,'endorse','under_review'));
  await denied(()=>review(reviewer,app,'approve','under_review')); await denied(()=>review(reviewer,app,'reject','under_review'));
});
await test('notification failure rolls back final status, actor and history',async()=>{
  await db.exec("create function fail_notification() returns trigger language plpgsql as $$begin raise exception 'test notification failure'; end$$; create trigger test_notification_failure before insert on notifications for each row execute function fail_notification();");
  await denied(()=>review(admin,app,'approve','under_review'));
  const a=(await db.query('select * from applications where id=$1',[app])).rows[0];
  assert.equal(a.status,'under_review'); assert.equal(a.decided_by,null);
  assert.equal((await db.query('select * from application_status_history where application_id=$1',[app])).rows.length,1);
  await db.exec('drop trigger test_notification_failure on notifications');
});
await test('history failure rolls back final status AND notification',async()=>{
  await db.exec("create trigger test_history_failure before insert on application_status_history for each row execute function fail_notification();");
  await denied(()=>review(admin,app,'approve','under_review'));
  assert.equal((await db.query('select status from applications where id=$1',[app])).rows[0].status,'under_review');
  assert.equal((await db.query('select * from notifications')).rows.length,0);
  await db.exec('drop trigger test_history_failure on application_status_history');
});
await test('authorized admin approval persists final actor, history and private student notification',async()=>{
  const r=await review(admin,app,'approve','under_review');
  assert.equal(r.rows[0].status,'approved'); assert.equal(r.rows[0].decided_by,admin); assert(r.rows[0].decided_at);
  assert.equal((await as(student,'select * from notifications')).rows.length,1);
  assert.equal((await as(reviewer,'select * from notifications')).rows.length,0);
  assert.equal((await as(otherStudent,'select * from notifications')).rows.length,0);
});
await test('authorized admin rejection persists final result and recipient notification',async()=>{
  await review(reviewer,rejectedApp,'endorse');
  const r=await review(admin,rejectedApp,'reject','under_review'); assert.equal(r.rows[0].status,'rejected');
  assert.equal((await as(otherStudent,'select * from notifications')).rows[0].title,'Application Rejected');
});
await test('terminal decision replay and missing application fail',async()=>{
  await denied(()=>review(admin,app,'reject','approved')); await denied(()=>review(admin,id(999),'approve'));
});
await test('platform admin retains only the existing approved-to-awarded transition',async()=>{
  await denied(()=>review(platformAdmin,rejectedApp,'approve','rejected'));
  assert.equal((await as(platformAdmin,"update applications set status='approved' where id=$1 returning id",[rejectedApp])).rows.length,0);
  const r=await as(platformAdmin,"update applications set status='awarded' where id=$1 returning id",[app]);
  assert.equal(r.rows.length,1);
});
console.log(`${passed} PostgreSQL authorization/transaction tests passed`);
await db.close();
