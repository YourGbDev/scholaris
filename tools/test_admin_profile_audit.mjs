import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { readFile } from 'node:fs/promises';

const require = createRequire('C:/scholaris/scratch/cycle-testing/dummy.js');
const { PGlite } = require('@electric-sql/pglite');
const db = new PGlite();
const admin = '10000000-0000-0000-0000-000000000001';
const user = '10000000-0000-0000-0000-000000000002';
try {
  await db.exec(`
    create role authenticated; create role anon;
    create schema auth;
    create function auth.uid() returns uuid language sql stable as
      $$select nullif(current_setting('request.jwt.claim.sub', true),'')::uuid$$;
    create table profiles (id uuid primary key, role text, status text, full_name text, email text);
    create table audit_logs (actor_id uuid, actor_email text, actor_role text, action text, target_type text, target_id text, details jsonb);
    create function is_admin() returns boolean language sql stable security definer set search_path=public as
      $$select exists(select 1 from profiles where id=auth.uid() and role='admin' and status='active')$$;
    grant usage on schema auth, public to authenticated;
    grant select, update on profiles to authenticated;
    insert into profiles values ('${admin}','admin','active','Admin','admin@example.test'), ('${user}','student','active','User','user@example.test');
  `);
  await db.exec(await readFile(new URL('../supabase/migrations/0037_admin_profile_audit.sql', import.meta.url), 'utf8'));
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [admin]);
  await db.exec('set role authenticated');
  await db.query('update profiles set role=$1, status=$2, full_name=$3 where id=$4', ['provider','deactivated','Changed',user]);
  await db.exec('reset role');
  const { rows } = await db.query('select actor_id, action, target_id, details from audit_logs order by action');
  assert.deepEqual(rows.map(r => r.action), ['user_role_changed','user_status_changed','user_updated']);
  assert.ok(rows.every(r => r.actor_id === admin && r.target_id === user));
  assert.ok(!JSON.stringify(rows).includes('Changed'));
  await db.query('update profiles set full_name=full_name where id=$1', [user]);
  assert.equal((await db.query('select count(*)::int as n from audit_logs')).rows[0].n, 3);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [user]);
  await db.query('update profiles set full_name=$1 where id=$2', ['Self edit',user]);
  assert.equal((await db.query('select count(*)::int as n from audit_logs')).rows[0].n, 3);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [admin]);
  await db.exec("alter table audit_logs add constraint reject_new_updates check (action <> 'user_updated') not valid");
  await assert.rejects(() => db.query('update profiles set full_name=$1 where id=$2', ['Must roll back', user]));
  assert.equal((await db.query('select full_name from profiles where id=$1', [user])).rows[0].full_name, 'Self edit');
  await db.exec('set role authenticated');
  await assert.rejects(() => db.query('select public.audit_admin_profile_update()'), /permission denied/i);
  console.log('PASS: admin profile changes produce actor-bound audit events without profile contents');
} finally { await db.close(); }
