import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {readFile} from 'node:fs/promises';
const require=createRequire('C:/scholaris/scratch/cycle-testing/dummy.js');
const {PGlite}=require('@electric-sql/pglite');
const db=new PGlite();
const admin='10000000-0000-0000-0000-000000000001';
const student='10000000-0000-0000-0000-000000000002';
const inactive='10000000-0000-0000-0000-000000000003';
const scholarship='20000000-0000-0000-0000-000000000001';
async function asRole(role,id,action){
 await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id || '']);
 await db.exec('set role '+role);
 try{return await action();}finally{await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub','',false)");}
}
const total=async()=>Number((await db.query('select count(*) n from audit_logs')).rows[0].n);
const rpc=(action='scholarship_flagged',details={reason:'Needs review'})=>db.query('select public.log_audit_event($1,$2,$3,$4::jsonb) id',[action,'scholarship',scholarship,JSON.stringify(details)]);
try{
 await db.exec(`
  create role anon;create role authenticated;create role service_role;create role supabase_auth_admin;
  create schema auth;
  create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
  create table auth.users(id uuid primary key,email text);
  create table auth.audit_log_entries(id uuid primary key default gen_random_uuid(),payload json,created_at timestamptz default now(),ip_address varchar);
  create table profiles(id uuid primary key references auth.users,full_name text,email text,role text,status text,provider_type text);
  create table scholarships(id uuid primary key,title text,provider text,is_active boolean,created_by uuid);
  create table audit_logs(id uuid primary key default gen_random_uuid(),actor_id uuid references auth.users on delete set null,actor_email text,actor_role text not null default 'unknown',action text not null,target_type text not null,target_id text,details jsonb default '{}',ip_address text,created_at timestamptz not null default now());
  insert into auth.users values('${admin}','admin@example.test'),('${student}','student@example.test'),('${inactive}','inactive@example.test');
  insert into profiles values('${admin}','Admin','forged-admin-email@example.test','admin','active',null),('${student}','Student','student@example.test','student','active',null),('${inactive}','Inactive','inactive@example.test','admin','deactivated',null);
  insert into scholarships values('${scholarship}','Server title','Server provider',false,'${admin}');
  grant usage on schema public,auth to anon,authenticated,service_role,supabase_auth_admin;
  grant select,insert,update,delete on profiles,scholarships to authenticated;
  grant select,insert on audit_logs to anon,authenticated;
  grant insert(actor_id,actor_email,actor_role,action,target_type,target_id,details,ip_address,created_at) on audit_logs to public,anon,authenticated;
  grant insert on auth.audit_log_entries to supabase_auth_admin;
  alter table audit_logs enable row level security;
  create policy admin_read on audit_logs for select to authenticated using (auth.uid()='${admin}');
  create policy "Authenticated users can record audit actions" on audit_logs for insert to authenticated with check(true);
 `);
 for(const name of ['0035_guard_profile_status.sql','0037_admin_profile_audit.sql','0038_audit_log_mutation_privileges.sql'])await db.exec(await readFile(new URL('../supabase/migrations/'+name,import.meta.url),'utf8'));
 await db.exec('create trigger trg_guard_profiles_role_change before update on profiles for each row execute function guard_profiles_role_change()');
 const old=await readFile(new URL('../supabase/migrations/0011_ias_security_and_audit.sql',import.meta.url),'utf8');
 await db.exec(old.slice(old.indexOf('create or replace function public.log_audit_event('),old.indexOf('-- 4. Server-side lockout')));
 if(process.argv.includes('--with-fix'))await db.exec(await readFile(new URL('../supabase/migrations/0039_trusted_audit_events.sql',import.meta.url),'utf8'));
 await asRole('authenticated',student,async()=>{
  await assert.rejects(()=>db.query("insert into audit_logs(actor_id,actor_role,action,target_type) values($1,'admin','user_deleted','user')",[student]),/permission denied/i);
  await assert.rejects(()=>rpc(),/administrator/i);
  await assert.rejects(()=>db.query('select public.set_admin_scholarship_active($1,true)',[scholarship]),/administrator/i);
 });
 await asRole('anon',null,()=>assert.rejects(()=>rpc(),/permission denied/i));
 await asRole('authenticated',inactive,()=>assert.rejects(()=>rpc(),/administrator/i));
 for(const role of ['anon','authenticated']){
  const {rows}=await db.query("select has_any_column_privilege($1,'public.audit_logs','INSERT') allowed",[role]);assert.equal(rows[0].allowed,false);
 }
 await asRole('authenticated',admin,async()=>{
  let before=await total();await rpc('user_deleted');assert.equal(await total(),before,'Deprecated success report must not create a row');
  await assert.rejects(()=>rpc('login'),/supported/i);
  await assert.rejects(()=>rpc('scholarship_flagged',{reason:'ok',password:'secret'}),/details/i);
  await assert.rejects(()=>rpc('scholarship_flagged',{reason:' '}),/reason/i);
  await assert.rejects(()=>rpc('scholarship_flagged',{reason:{password:'secret'}}),/reason/i);
  await assert.rejects(()=>rpc('scholarship_flagged',{reason:'x'.repeat(501)}),/reason/i);
  const result=await rpc('scholarship_flagged',{reason:'Needs review',title:'Spoofed title',provider:'Spoofed provider'});assert.ok(result.rows[0].id);
 });
 let row=(await db.query("select * from audit_logs where action='scholarship_flagged'")).rows[0];
 assert.equal(row.actor_id,admin);assert.equal(row.actor_email,'admin@example.test');assert.equal(row.details.title,'Server title');assert.equal(row.details.source,'database_rpc');
 let before=await total();
 await asRole('authenticated',admin,()=>db.query('select public.set_admin_scholarship_active($1,true)',[scholarship]));
 assert.equal(await total(),before+1);
 row=(await db.query("select * from audit_logs where action='scholarship_activated'")).rows[0];assert.equal(row.actor_id,admin);
 const created='10000000-0000-0000-0000-000000000004';
 await db.query('insert into auth.users values($1,$2)',[created,'new@example.test']);
 await db.query("insert into profiles(id,role,status) values($1,'student','active')",[created]);
 row=(await db.query("select * from audit_logs where action='user_created' and target_id=$1",[created])).rows[0];assert.equal(row.actor_id,null);assert.equal(row.actor_role,'system');
 await asRole('authenticated',admin,()=>db.query('delete from profiles where id=$1',[created]));
 row=(await db.query("select * from audit_logs where action='user_deleted' and target_id=$1",[created])).rows[0];assert.equal(row.actor_id,admin);
 await asRole('authenticated',admin,()=>db.query("update profiles set full_name='PRIVATE CHANGED NAME' where id=$1",[student]));
 row=(await db.query("select * from audit_logs where action='user_updated' order by created_at desc limit 1")).rows[0];assert.equal(row.actor_email,'admin@example.test');assert.ok(!JSON.stringify(row.details).includes('PRIVATE CHANGED NAME'));
 for(const actor of [student,'not-a-uuid','90000000-0000-0000-0000-000000000099',null]){
  await asRole('supabase_auth_admin',null,()=>db.query('insert into auth.audit_log_entries(payload,ip_address) values($1::json,$2)',[JSON.stringify({action:'login',actor_id:actor,actor_username:'spoof@example.test',password:'SECRET',token:'SECRET',traits:{password:'SECRET'}}),'203.0.113.4']));
 }
 const mirrored=(await db.query("select * from audit_logs where action='auth_login' order by created_at")).rows;
 assert.equal(mirrored.length,4);assert.equal(mirrored.filter(r=>r.actor_id===student).length,1);assert.equal(mirrored.filter(r=>r.actor_id===null).length,3);
 assert.ok(mirrored.every(r=>r.details.source==='supabase_auth' && r.details.outcome==='recorded' && r.ip_address==='203.0.113.4'));
 assert.ok(!JSON.stringify(mirrored).includes('SECRET'));assert.ok(!JSON.stringify(mirrored).includes('spoof@example.test'));
 before=await total();await asRole('supabase_auth_admin',null,()=>db.query('insert into auth.audit_log_entries(payload) values($1::json)',[JSON.stringify({action:'user_deleted_fake',actor_id:admin})]));assert.equal(await total(),before);
 await db.exec("alter table audit_logs add constraint test_fail_audit check(action <> 'auth_login') not valid");
 const authBefore=Number((await db.query('select count(*) n from auth.audit_log_entries')).rows[0].n);
 await assert.rejects(()=>asRole('supabase_auth_admin',null,()=>db.query('insert into auth.audit_log_entries(payload) values($1::json)',[JSON.stringify({action:'login',actor_id:student})])),/test_fail_audit/i);
 assert.equal(Number((await db.query('select count(*) n from auth.audit_log_entries')).rows[0].n),authBefore);
 console.log('PASS: trusted audit ingestion, lifecycle/activation events, sanitized Auth capture and atomic failure');
}finally{await db.close();}
