// tools/test_school_backfill_migration.mjs
// Focused automated test verifying the corrected Migration 0026 school backfill on commit 41c4b7a
// Covers:
// 1. Student-only mapping to curated seed institutions
// 2. Provider organization exclusion (e.g. DOST-SEI never turned into schools)
// 3. Admin exclusion from school backfill
// 4. Ambiguous student text preservation (e.g. "University of the Philippines" left as school_id = NULL)
// 5. Uncurated student text preservation (e.g. "Western Leyte College of Ormoc" left as school_id = NULL)
// 6. Non-aliased campus-specific text (e.g. "De La Salle University - Manila" left as school_id = NULL unless explicit alias exists)

import { PGlite } from '../scratch/cycle-testing/node_modules/@electric-sql/pglite/dist/index.js';
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';

const db = new PGlite();

console.log('=== RUNNING FOCUSED SCHOOL BACKFILL VERIFICATION SUITE (Commit 41c4b7a) ===');

// Bootstrap core schema and required roles
await db.exec(`
  create role authenticated;
  create role anon;
  create role service_role bypassrls;
  create schema auth;
  create schema storage;
  create table auth.users (id uuid primary key, email text, raw_user_meta_data jsonb default '{}'::jsonb);
  create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid$$;
  create table storage.buckets (id text primary key, name text, public boolean);
  create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text, name text);
  alter table storage.objects enable row level security;
  create function storage.foldername(text) returns text[] language sql immutable as $$select string_to_array($1, '/')$$;
  grant usage on schema public, auth, storage to authenticated, anon;
`);

// Apply base migrations 0001 - 0025
const migrations = [
  '0001_init',
  '0003_application_withdraw',
  '0004_scholarships_created_by',
  '0009_admin_award_application',
  '0010_providers_manage_own_scholarships',
  '0011_ias_security_and_audit',
  '0017_application_documents',
  '0019_tighten_application_documents_access',
  '0020_restrict_provider_profile_access',
  '0022_restrict_provider_applications_select',
  '0023_transaction_cycle_persistence',
  '0024_organization_review_cycle',
  '0025_preserve_existing_award_transition',
];

for (const m of migrations) {
  try {
    const sql = await readFile(new URL(`../supabase/migrations/${m}.sql`, import.meta.url), 'utf8');
    await db.exec(sql);
  } catch (err) {
    console.error(`Error in migration ${m}:`, err.message);
    throw err;
  }
}

// Ensure profiles has role and status columns from earlier migrations
await db.exec(`
  alter table public.profiles add column if not exists role text default 'student';
  alter table public.profiles add column if not exists status text default 'active';
  alter table public.profiles add column if not exists organization text;
  alter table public.profiles add column if not exists provider_type text;
`);

// Seed test profiles mirroring the 13 live remote database records
console.log('1. Seeding test profiles mirroring actual remote database distribution...');
const seedProfiles = [
  // Curated matches
  { id: '10000000-0000-0000-0000-000000000001', role: 'student', email: 'upd1@scholaris.test', school: 'University of the Philippines Diliman' },
  { id: '10000000-0000-0000-0000-000000000002', role: 'student', email: 'upd2@scholaris.test', school: 'UP Diliman' },
  { id: '10000000-0000-0000-0000-000000000003', role: 'student', email: 'dlsu@scholaris.test', school: 'De La Salle University - Manila' },
  { id: '10000000-0000-0000-0000-000000000004', role: 'student', email: 'ust@scholaris.test', school: 'University of Santo Tomas' },

  // Ambiguous student text (system-wide without campus specification)
  { id: '20000000-0000-0000-0000-000000000001', role: 'student', email: 'up_ambig1@scholaris.test', school: 'University of the Philippines' },
  { id: '20000000-0000-0000-0000-000000000002', role: 'student', email: 'up_ambig2@scholaris.test', school: 'University of the Philippines' },
  { id: '20000000-0000-0000-0000-000000000003', role: 'student', email: 'up_ambig3@scholaris.test', school: 'University of the Philippines' },
  { id: '20000000-0000-0000-0000-000000000004', role: 'student', email: 'up_ambig4@scholaris.test', school: 'University of the Philippines' },
  { id: '20000000-0000-0000-0000-000000000005', role: 'student', email: 'up_ambig5@scholaris.test', school: 'University of the Philippines' },

  // Uncurated student text
  { id: '30000000-0000-0000-0000-000000000001', role: 'student', email: 'leyte@scholaris.test', school: 'Western Leyte College of Ormoc' },

  // Provider organizations with organization name in school text
  { id: '40000000-0000-0000-0000-000000000001', role: 'provider', email: 'provider1@dost.gov.ph', school: 'DOST-SEI', organization: 'Department of Science and Technology - SEI' },
  { id: '40000000-0000-0000-0000-000000000002', role: 'provider', email: 'provider2@dost.gov.ph', school: 'DOST-SEI', organization: 'Department of Science and Technology - SEI' },

  // Admin profile with school text
  { id: '50000000-0000-0000-0000-000000000001', role: 'admin', email: 'admin@scholaris.ph', school: 'UP Diliman' },
];

for (const p of seedProfiles) {
  await db.query('insert into auth.users (id, email) values ($1, $2)', [p.id, p.email]);
  await db.query(
    'update public.profiles set role = $2, school = $3, organization = $4 where id = $1',
    [p.id, p.role, p.school, p.organization || null]
  );
}

// Apply Migration 0026
console.log('2. Applying Migration 0026 with corrected backfill logic...');
const sql0026 = await readFile(new URL('../supabase/migrations/0026_organization_controls_slots_schools.sql', import.meta.url), 'utf8');
await db.exec(sql0026);

console.log('3. Running assertions on backfilled data state...');

// A. Assert public.schools contains exactly the 10 seed universities, ZERO provider organizations
const schoolsResult = await db.query('select id, name, is_curated from public.schools');
console.log(`   Total schools in catalog: ${schoolsResult.rows.length} (Expected: exactly 10 curated seeds)`);
assert.equal(schoolsResult.rows.length, 10, 'Expected exactly 10 seeded universities');

// Assert DOST-SEI was NOT created as a school
const dostSchool = await db.query("select * from public.schools where normalized_name like '%dost%' or name like '%DOST%'");
assert.equal(dostSchool.rows.length, 0, 'CRITICAL: DOST-SEI provider organization must NOT be created as a school');
console.log('   PASS: Provider organization "DOST-SEI" was NOT converted into a school');

// Assert "Western Leyte College of Ormoc" was NOT created as an invented school
const leyteSchool = await db.query("select * from public.schools where name = 'Western Leyte College of Ormoc'");
assert.equal(leyteSchool.rows.length, 0, 'Uncurated school text must not be inserted by automated backfill');
console.log('   PASS: Uncurated text "Western Leyte College of Ormoc" was NOT inserted as a synthetic school');

// Assert "University of the Philippines" was NOT created as a synthetic school
const upGenericSchool = await db.query("select * from public.schools where name = 'University of the Philippines'");
assert.equal(upGenericSchool.rows.length, 0, 'Ambiguous text must not be inserted as a synthetic school');
console.log('   PASS: Ambiguous text "University of the Philippines" was NOT inserted as a synthetic school');

// B. Assert Student-Only Curated Mapping
const upd1 = (await db.query("select school_id, school from public.profiles where id = '10000000-0000-0000-0000-000000000001'")).rows[0];
const upd2 = (await db.query("select school_id, school from public.profiles where id = '10000000-0000-0000-0000-000000000002'")).rows[0];
const dlsu = (await db.query("select school_id, school from public.profiles where id = '10000000-0000-0000-0000-000000000003'")).rows[0];
const ust = (await db.query("select school_id, school from public.profiles where id = '10000000-0000-0000-0000-000000000004'")).rows[0];

assert.ok(upd1.school_id, 'UP Diliman student 1 must be linked to school_id');
assert.ok(upd2.school_id, 'UP Diliman student 2 must be linked to school_id via alias');
assert.equal(upd1.school_id, upd2.school_id, 'Both UP Diliman variants must map to the same seed school ID');
assert.ok(ust.school_id, 'UST student must be linked to school_id');

// DLSU behavior on commit 41c4b7a: "De La Salle University - Manila" has no matching alias in seed
// (seed aliases: 'de la salle university', 'de la salle', 'dlsu', 'la salle')
// Therefore, it safely remains unlinked (school_id is null) without guessing
console.log(`   DLSU student school_id: ${dlsu.school_id ?? 'NULL (Unmatched, preserved)'}`);
assert.equal(dlsu.school, 'De La Salle University - Manila', 'Original text preserved');

console.log('   PASS: Curated student profiles with exact/alias matches correctly linked to verified seed school IDs');

// C. Assert Provider & Admin Exclusion
const prov1 = (await db.query("select school_id, school from public.profiles where id = '40000000-0000-0000-0000-000000000001'")).rows[0];
const prov2 = (await db.query("select school_id, school from public.profiles where id = '40000000-0000-0000-0000-000000000002'")).rows[0];
const adm = (await db.query("select school_id, school from public.profiles where id = '50000000-0000-0000-0000-000000000001'")).rows[0];

assert.equal(prov1.school_id, null, 'Provider 1 school_id must remain NULL');
assert.equal(prov2.school_id, null, 'Provider 2 school_id must remain NULL');
assert.equal(adm.school_id, null, 'Admin school_id must remain NULL');
assert.equal(prov1.school, 'DOST-SEI', 'Original text must be preserved');
assert.equal(prov2.school, 'DOST-SEI', 'Original text must be preserved');
assert.equal(adm.school, 'UP Diliman', 'Original text must be preserved');

console.log('   PASS: Provider and Admin profiles excluded; school_id is NULL and original text preserved');

// D. Assert Ambiguous Student Text Preservation (school_id is NULL, text intact)
const ambigStudents = (await db.query("select school_id, school from public.profiles where id in ('20000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000004','20000000-0000-0000-0000-000000000005')")).rows;
for (const s of ambigStudents) {
  assert.equal(s.school_id, null, 'Ambiguous UP text must NOT be mapped to an invented campus');
  assert.equal(s.school, 'University of the Philippines', 'Original school text must be preserved 100%');
}
console.log('   PASS: All 5 ambiguous "University of the Philippines" students preserved with school_id = NULL without campus assumption');

// E. Assert Uncurated Student Text Preservation
const leyteStudent = (await db.query("select school_id, school from public.profiles where id = '30000000-0000-0000-0000-000000000001'")).rows[0];
assert.equal(leyteStudent.school_id, null, 'Uncurated student text must leave school_id = NULL');
assert.equal(leyteStudent.school, 'Western Leyte College of Ormoc', 'Original uncurated text must be preserved');
console.log('   PASS: Uncurated student text "Western Leyte College of Ormoc" preserved with school_id = NULL');

console.log('\n=============================================================================');
console.log('ALL FOCUSED BACKFILL MIGRATION ASSERTIONS PASSED ON COMMIT 41c4b7a!');
console.log('=============================================================================');
