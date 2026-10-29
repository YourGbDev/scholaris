import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { readFile } from 'node:fs/promises';

const require = createRequire('C:/scholaris/scratch/cycle-testing/dummy.js');
const { PGlite } = require('@electric-sql/pglite');
const db = new PGlite();
try {
  await db.exec(`
    create role anon; create role authenticated; create role service_role;
    create table public.audit_logs (id int primary key, action text not null);
    insert into public.audit_logs values (1,'baseline');
    grant all on public.audit_logs to public, anon, authenticated, service_role;
    create function public.record_server_audit() returns void language sql security definer set search_path='' as
      $$insert into public.audit_logs values (2,'server-trigger')$$;
    grant execute on function public.record_server_audit() to authenticated;
  `);
  if (process.argv.includes('--with-fix')) {
    await db.exec(await readFile(new URL('../supabase/migrations/0038_audit_log_mutation_privileges.sql',import.meta.url),'utf8'));
  }
  for (const role of ['anon','authenticated']) {
    for (const privilege of ['UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER']) {
      const {rows}=await db.query('select has_table_privilege($1,$2,$3) allowed',[role,'public.audit_logs',privilege]);
      assert.equal(rows[0].allowed,false,`${role} must not retain ${privilege}, including via PUBLIC`);
    }
  }
  await db.exec('set role authenticated');
  await assert.rejects(()=>db.exec('truncate public.audit_logs'),/permission denied/i);
  await assert.rejects(()=>db.exec("update public.audit_logs set action='changed'"),/permission denied/i);
  await assert.rejects(()=>db.exec('delete from public.audit_logs'),/permission denied/i);
  await db.exec('select public.record_server_audit()');
  await db.exec('reset role');
  const {rows}=await db.query('select action from public.audit_logs order by id');
  assert.deepEqual(rows,[{action:'baseline'},{action:'server-trigger'}]);
  const retained=await db.query("select has_table_privilege('authenticated','public.audit_logs','INSERT') ins,has_table_privilege('authenticated','public.audit_logs','SELECT') sel,has_table_privilege('service_role','public.audit_logs','TRUNCATE') service_maintenance");
  assert.deepEqual(retained.rows,[{ins:true,sel:true,service_maintenance:true}]);
  console.log('PASS: client audit-table mutation privileges removed, server logging and maintenance preserved');
} finally { await db.close(); }
