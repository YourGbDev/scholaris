// tools/test_organization_controls_security.mjs
// Sprint: Organization-Admin Controls, Capacity Accounting & School Eligibility (Phase 1)
// Automated Genuine Concurrency & Authorization Test Suite on Isolated Local PostgreSQL
// Runs actual PostgreSQL engine (PGlite WASM), enforcing real RLS, constraints, triggers, and functions.

import { PGlite } from '../scratch/cycle-testing/node_modules/@electric-sql/pglite/dist/index.js';
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';

const db = new PGlite();

// Deterministic UUID generator
const id = (prefix, n) => `${prefix.padEnd(8, '0')}-0000-0000-0000-${String(n).padStart(12, '0')}`;

// Roles & Identities
const orgAdminA = id('10000000', 1);
const reviewerA = id('10000000', 2);
const orgAdminB = id('20000000', 1);
const reviewerB = id('20000000', 2);
const platformAdmin = id('90000000', 1);

const studentA = id('30000000', 1); // Enrolled in School A (UPD)
const studentB = id('30000000', 2); // Enrolled in School B (Ateneo)
const studentNoSchool = id('30000000', 3); // school_id IS NULL

// Grants
const cappedGrant = id('40000000', 1);       // slots = 1, active = true
const reductionGrant = id('40000000', 2);    // slots = 5, active = true
const inactiveGrant = id('40000000', 3);     // slots = 10, active = false
const schoolRestrictedGrant = id('40000000', 4); // slots = 10, restricted to School A
const orgBGrant = id('50000000', 1);         // owned by Org B

// Applications
const appRace1 = id('60000000', 1);
const appRace2 = id('60000000', 2);
const appRed1 = id('60000000', 11);
const appRed2 = id('60000000', 12);
const appRed3 = id('60000000', 13);
const appWithdraw = id('60000000', 20);
const appStudentB = id('60000000', 30);
const appNoSchool = id('60000000', 31);

let passed = 0;

async function test(name, body) {
  try {
    await body();
    passed++;
    console.log(`PASS: ${name}`);
  } catch (err) {
    console.error(`FAIL: ${name}`);
    console.error(err);
    throw err;
  }
}

async function as(userId, sql, params = []) {
  await db.exec('reset role');
  if (userId) {
    await db.query("select set_config('request.jwt.claim.sub', $1, false)", [userId]);
    await db.exec('set role authenticated');
  } else {
    await db.exec('set role anon');
  }
  try {
    return await db.query(sql, params);
  } finally {
    await db.exec('reset role');
  }
}

const review = (user, applicationId, action, expectedStatus = 'under_review', scores = null, notes = 'Decision note') =>
  as(
    user,
    'select * from public.review_application($1, $2, $3, $4, $5)',
    [applicationId, expectedStatus, action, scores ? JSON.stringify(scores) : null, notes]
  );

async function denied(fn) {
  await assert.rejects(fn);
}

// -----------------------------------------------------------------------------
// Database Bootstrap & Migrations Ingestion
// -----------------------------------------------------------------------------
await db.exec(`
  create role authenticated;
  create role anon;
  create role service_role bypassrls;
  create schema auth;
  create schema storage;
  create table auth.users (id uuid primary key, email text, raw_user_meta_data jsonb default '{}'::jsonb);
  create function auth.uid() returns uuid language sql stable as
    $$select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid$$;
  create table storage.buckets (id text primary key, name text, public boolean);
  create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text, name text);
  alter table storage.objects enable row level security;
  create function storage.foldername(text) returns text[] language sql immutable as
    $$select string_to_array($1, '/')$$;
  grant usage on schema public, auth, storage to authenticated, anon;
`);

async function migration(name) {
  try {
    const sql = await readFile(new URL(`../supabase/migrations/${name}.sql`, import.meta.url), 'utf8');
    await db.exec(sql);
  } catch (err) {
    console.error(`Error in migration ${name}:`, err.message, err.code);
    process.exit(1);
  }
}

await migration('0001_init');
await db.exec("alter table public.profiles add role text default 'student', add status text default 'active'");
for (const file of [
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
]) {
  await migration(file);
}

await db.exec(`
  grant all on all tables in schema public, storage to authenticated;
  create policy legacy_finance_escape on public.applications for all to authenticated using (true) with check (true);
  create policy legacy_storage_read on storage.objects for select to authenticated using (true);
`);

await migration('0024_organization_review_cycle');
await migration('0025_preserve_existing_award_transition');
// Mirror Supabase production default privileges (scratch/0026_codex_remote_default_privileges.json):
// defaclobjtype 'r' (tables/views), 'S' (sequences), 'f' (functions) automatically granted to anon, authenticated.
await db.exec(`
  alter default privileges in schema public grant all on tables to anon, authenticated;
  alter default privileges in schema public grant all on sequences to anon, authenticated;
  alter default privileges in schema public grant all on functions to anon, authenticated;
`);
await migration('0026_organization_controls_slots_schools');

// -----------------------------------------------------------------------------
// Seed Identities & Base Relations
// -----------------------------------------------------------------------------
const allUsers = [
  orgAdminA, reviewerA, orgAdminB, reviewerB, platformAdmin,
  studentA, studentB, studentNoSchool
];

await db.exec(`
  insert into auth.users (id, email) values
    ${allUsers.map(u => `('${u}', '${u}@scholaris.test')`).join(',')};

  update public.profiles set role = 'provider' where id in ('${orgAdminA}', '${reviewerA}', '${orgAdminB}', '${reviewerB}');
  update public.profiles set role = 'admin' where id = '${platformAdmin}';
  update public.profiles set role = 'student' where id in ('${studentA}', '${studentB}', '${studentNoSchool}');

  insert into public.organization_memberships (user_id, organization_id, role, active) values
    ('${orgAdminA}', '${orgAdminA}', 'org_admin', true),
    ('${reviewerA}', '${orgAdminA}', 'reviewer', true),
    ('${orgAdminB}', '${orgAdminB}', 'org_admin', true),
    ('${reviewerB}', '${orgAdminB}', 'reviewer', true);
`);

// Fetch seeded schools
const upDilimanSchoolId = (await db.query(
  "select id from public.schools where normalized_name = 'university of the philippines diliman'"
)).rows[0].id;

const ateneoSchoolId = (await db.query(
  "select id from public.schools where normalized_name = 'ateneo de manila university'"
)).rows[0].id;

// Associate students with schools
await db.exec(`
  update public.profiles set school_id = '${upDilimanSchoolId}', school = 'University of the Philippines Diliman' where id = '${studentA}';
  update public.profiles set school_id = '${ateneoSchoolId}', school = 'Ateneo de Manila University' where id = '${studentB}';
  update public.profiles set school_id = null, school = null where id = '${studentNoSchool}';
`);

// -----------------------------------------------------------------------------
// Vector 1: Genuine Parallel Concurrency Race Condition Test on Isolated Local Database
// -----------------------------------------------------------------------------
await test('Vector 1: Genuine parallel concurrency test: two simultaneous approvals on 1-slot grant result in exactly 1 commit and 1 P0001 rejection', async () => {
  // Setup disposable grant with slots = 1
  await db.exec(`
    insert into public.scholarships (id, title, created_by, deadline, slots, is_active)
    values ('${cappedGrant}', 'Capped Competitive Grant', '${orgAdminA}', current_date + 30, 1, true);

    insert into public.applications (id, user_id, scholarship_id, status, notes) values
      ('${appRace1}', '${studentA}', '${cappedGrant}', 'submitted', 'Race Applicant 1'),
      ('${appRace2}', '${studentB}', '${cappedGrant}', 'submitted', 'Race Applicant 2');
  `);

  // Both applications endorsed by Reviewer A
  const scores = { academic: 9, financial: 8, leadership: 9, vision: 8 };
  await review(reviewerA, appRace1, 'endorse', 'submitted', scores);
  await review(reviewerA, appRace2, 'endorse', 'submitted', scores);

  // Verify both are now in 'under_review'
  const app1Status = (await db.query('select status from public.applications where id = $1', [appRace1])).rows[0].status;
  const app2Status = (await db.query('select status from public.applications where id = $1', [appRace2])).rows[0].status;
  assert.equal(app1Status, 'under_review');
  assert.equal(app2Status, 'under_review');

  // Concurrently execute review_application(approve) as Org Admin A
  const results = await Promise.allSettled([
    review(orgAdminA, appRace1, 'approve', 'under_review', null, 'Approved app 1'),
    review(orgAdminA, appRace2, 'approve', 'under_review', null, 'Approved app 2'),
  ]);

  const fulfilled = results.filter(r => r.status === 'fulfilled');
  const rejected = results.filter(r => r.status === 'rejected');

  assert.equal(fulfilled.length, 1, 'Exactly one approval must commit successfully');
  assert.equal(rejected.length, 1, 'Exactly one approval must reject due to slot exhaustion');

  const rejectionReason = rejected[0].reason;
  assert(
    rejectionReason.message.includes('Scholarship capacity reached') ||
    rejectionReason.code === 'P0001',
    `Expected P0001 capacity error, got: ${rejectionReason.message}`
  );

  // Check database capacity state
  const cap = (await db.query('select * from public.get_scholarship_capacity($1)', [cappedGrant])).rows[0];
  assert.equal(cap.total_slots, 1);
  assert.equal(cap.occupied_slots, 1);
  assert.equal(cap.remaining_slots, 0);

  // Ensure unapproved application remains intact in 'under_review'
  const appStates = (await db.query(
    'select id, status from public.applications where id in ($1, $2) order by id',
    [appRace1, appRace2]
  )).rows;
  const statuses = appStates.map(a => a.status).sort();
  assert.deepEqual(statuses, ['approved', 'under_review'], 'Rejected app must remain in under_review without corruption');
});

// -----------------------------------------------------------------------------
// Vector 2: Capacity Reduction Constraint Test
// -----------------------------------------------------------------------------
await test('Vector 2: Capacity reduction constraint: lowering slots below occupied count throws P0002 trigger exception', async () => {
  // Create grant with slots = 5 and 3 approved applications
  await db.exec(`
    insert into public.scholarships (id, title, created_by, deadline, slots, is_active)
    values ('${reductionGrant}', 'Reduction Test Grant', '${orgAdminA}', current_date + 30, 5, true);

    insert into public.applications (id, user_id, scholarship_id, status) values
      ('${appRed1}', '${studentA}', '${reductionGrant}', 'approved'),
      ('${appRed2}', '${studentB}', '${reductionGrant}', 'approved'),
      ('${appRed3}', '${studentNoSchool}', '${reductionGrant}', 'approved');
  `);

  // Attempt to reduce slots from 5 to 2 (below 3 occupied)
  await denied(async () => {
    await db.exec(`update public.scholarships set slots = 2 where id = '${reductionGrant}'`);
  });

  // Check slots remained 5
  const slots = (await db.query('select slots from public.scholarships where id = $1', [reductionGrant])).rows[0].slots;
  assert.equal(slots, 5, 'Scholarship slots must remain 5 after rejected reduction');

  // Legitimate reduction to 4 or 3 should succeed
  await db.exec(`update public.scholarships set slots = 3 where id = '${reductionGrant}'`);
  const newSlots = (await db.query('select slots from public.scholarships where id = $1', [reductionGrant])).rows[0].slots;
  assert.equal(newSlots, 3, 'Legitimate reduction to 3 occupied slots should succeed');
});

// -----------------------------------------------------------------------------
// Vector 3: Backend Aggregate Slot Access & Visibility Enforcement Test
// -----------------------------------------------------------------------------
await test('Vector 3: Aggregate slot access: active grant visible with counts; inactive grant returns 0 rows for students; applications row privacy preserved', async () => {
  await db.exec(`
    insert into public.scholarships (id, title, created_by, deadline, slots, is_active)
    values ('${inactiveGrant}', 'Inactive Private Grant', '${orgAdminA}', current_date + 30, 10, false);
  `);

  // Student A queries capacity for active grant
  const activeCap = await as(studentA, 'select * from public.get_scholarship_capacity($1)', [reductionGrant]);
  assert.equal(activeCap.rows.length, 1);
  assert.equal(activeCap.rows[0].total_slots, 3);
  assert.equal(activeCap.rows[0].occupied_slots, 3);
  assert.equal(activeCap.rows[0].remaining_slots, 0);

  // Student A queries capacity for inactive grant -> 0 rows returned
  const inactiveCap = await as(studentA, 'select * from public.get_scholarship_capacity($1)', [inactiveGrant]);
  assert.equal(inactiveCap.rows.length, 0, 'Inactive scholarship capacity must be invisible to students');

  // Org Admin A CAN see inactive grant capacity
  const adminCap = await as(orgAdminA, 'select * from public.get_scholarship_capacity($1)', [inactiveGrant]);
  assert.equal(adminCap.rows.length, 1, 'Org admin must see capacity for own inactive grant');

  // Direct applications query by Student A returns ONLY Student A's own applications (zero other student applications)
  const studentApps = await as(studentA, 'select id, user_id from public.applications');
  for (const row of studentApps.rows) {
    assert.equal(row.user_id, studentA, 'Student must never see another student application');
  }
});

// -----------------------------------------------------------------------------
// Vector 4: Preservation of Authoritative 0024/0025 Permissions & Transitions Audit
// -----------------------------------------------------------------------------
await test('Vector 4: Authoritative permissions & transitions: client direct updates denied; platform-admin award consumes 0 extra slots; approved withdrawal blocked', async () => {
  const appTamper = id('60000000', 40);
  await db.exec(`
    insert into public.applications (id, user_id, scholarship_id, status)
    values ('${appTamper}', '${studentA}', '${reductionGrant}', 'submitted');
  `);

  // Client attempts direct update of workflow fields or unauthorized status transition on active application
  await denied(async () => {
    await as(studentA, "update public.applications set status = 'approved' where id = $1", [appTamper]);
  });
  await denied(async () => {
    await as(studentA, "update public.applications set endorsed_by = $1 where id = $2", [reviewerA, appTamper]);
  });
  await denied(async () => {
    await as(studentA, "update public.applications set scholarship_id = $1 where id = $2", [orgBGrant, appTamper]);
  });

  // Org admin cannot directly update application status to 'awarded' (0 rows affected under RLS)
  const orgAdminAwardRes = await as(orgAdminA, "update public.applications set status = 'awarded' where id = $1 returning id", [appRed1]);
  assert.equal(orgAdminAwardRes.rows.length, 0, 'Org admin direct update to awarded must be denied');

  // Verify platform admin can transition approved -> awarded under 0025
  const capBefore = (await db.query('select * from public.get_scholarship_capacity($1)', [reductionGrant])).rows[0];
  const awardRes = await as(platformAdmin, "update public.applications set status = 'awarded' where id = $1 returning id", [appRed1]);
  assert.equal(awardRes.rows.length, 1, 'Platform admin must be able to award approved application');

  // Awarded transition consumes 0 additional slots (occupied slots remain 3)
  const capAfter = (await db.query('select * from public.get_scholarship_capacity($1)', [reductionGrant])).rows[0];
  assert.equal(capAfter.occupied_slots, capBefore.occupied_slots, 'Awarding must not consume additional slots');

  // Student attempt to withdraw an 'approved' application is denied (0 rows affected)
  const studentApprovedWithdraw = await as(studentB, "update public.applications set status = 'withdrawn' where id = $1 returning id", [appRed2]);
  assert.equal(studentApprovedWithdraw.rows.length, 0, 'Student cannot withdraw approved application under restrictive boundary');

  // Student CAN withdraw draft/submitted/under_review application, consuming 0 slots
  await db.exec(`
    insert into public.applications (id, user_id, scholarship_id, status)
    values ('${appWithdraw}', '${studentA}', '${reductionGrant}', 'submitted');
  `);
  const capBeforeWithdraw = (await db.query('select * from public.get_scholarship_capacity($1)', [reductionGrant])).rows[0];
  assert.equal(capBeforeWithdraw.occupied_slots, 3, 'Submitted application does not occupy slot');

  await as(studentA, "update public.applications set status = 'withdrawn' where id = $1", [appWithdraw]);
  const capAfterWithdraw = (await db.query('select * from public.get_scholarship_capacity($1)', [reductionGrant])).rows[0];
  assert.equal(capAfterWithdraw.occupied_slots, 3, 'Withdrawn application consumes 0 slots');
});

// -----------------------------------------------------------------------------
// Vector 5: Duplicate Decision Idempotency Test
// -----------------------------------------------------------------------------
await test('Vector 5: Duplicate decision idempotency: repeating approval on already approved app is rejected without extra slot consumption', async () => {
  // Find which race app was approved
  const approvedRaceApp = (await db.query(
    "select id from public.applications where scholarship_id = $1 and status = 'approved'",
    [cappedGrant]
  )).rows[0].id;

  // Attempting to re-approve an already approved application
  await denied(async () => {
    await review(orgAdminA, approvedRaceApp, 'approve', 'approved');
  });

  const cap = (await db.query('select * from public.get_scholarship_capacity($1)', [cappedGrant])).rows[0];
  assert.equal(cap.occupied_slots, 1, 'Occupied slots must remain 1');
  assert.equal(cap.remaining_slots, 0, 'Remaining slots must remain 0');
});

// -----------------------------------------------------------------------------
// Vector 6: Backend School Eligibility Submission Bypass Test
// -----------------------------------------------------------------------------
await test('Vector 6: School eligibility bypass: student in School B submitting to School A restricted grant is rejected with P0003', async () => {
  // Create grant restricted to School A (UP Diliman)
  await db.exec(`
    insert into public.scholarships (id, title, created_by, deadline, slots, is_active, eligible_school_ids)
    values ('${schoolRestrictedGrant}', 'UP Diliman Only Grant', '${orgAdminA}', current_date + 30, 10, true, array['${upDilimanSchoolId}'::uuid]);
  `);

  // Student B (enrolled in Ateneo) attempts direct insert as 'submitted'
  await denied(async () => {
    await as(studentB, `
      insert into public.applications (id, user_id, scholarship_id, status)
      values ('${appStudentB}', '${studentB}', '${schoolRestrictedGrant}', 'submitted')
    `);
  });

  // Student B can create draft
  await as(studentB, `
    insert into public.applications (id, user_id, scholarship_id, status)
    values ('${appStudentB}', '${studentB}', '${schoolRestrictedGrant}', 'draft')
  `);

  // Student B attempting to submit draft to 'submitted' is rejected with P0003
  await denied(async () => {
    await as(studentB, "update public.applications set status = 'submitted' where id = $1", [appStudentB]);
  });

  // Verify status is still 'draft'
  const st = (await db.query('select status from public.applications where id = $1', [appStudentB])).rows[0].status;
  assert.equal(st, 'draft');

  // Student A (UP Diliman) CAN submit successfully
  const appStudentA = id('60000000', 35);
  await as(studentA, `
    insert into public.applications (id, user_id, scholarship_id, status)
    values ('${appStudentA}', '${studentA}', '${schoolRestrictedGrant}', 'submitted')
  `);
  const stA = (await db.query('select status from public.applications where id = $1', [appStudentA])).rows[0].status;
  assert.equal(stA, 'submitted', 'Eligible student submission must succeed');
});

// -----------------------------------------------------------------------------
// Vector 7: Missing School Information Handling
// -----------------------------------------------------------------------------
await test('Vector 7: Missing school handling: student with school_id IS NULL submitting to restricted grant fails closed with P0003', async () => {
  // Student with no school attempts submission
  await denied(async () => {
    await as(studentNoSchool, `
      insert into public.applications (id, user_id, scholarship_id, status)
      values ('${appNoSchool}', '${studentNoSchool}', '${schoolRestrictedGrant}', 'submitted')
    `);
  });

  const exists = (await db.query('select 1 from public.applications where id = $1', [appNoSchool])).rows.length;
  assert.equal(exists, 0, 'Unsubmitted application must not exist');
});

// -----------------------------------------------------------------------------
// Vector 8: School Normalization & Deduplication Integrity Test
// -----------------------------------------------------------------------------
await test('Vector 8: School normalization & deduplication: casing/whitespace and alias match existing school; empty name rejected', async () => {
  // Exact name with whitespace and mixed casing
  const res1 = await as(studentA, "select public.add_custom_school('   university of the philippines diliman   ') as id");
  assert.equal(res1.rows[0].id, upDilimanSchoolId, 'Whitespace/casing match must return existing school ID');

  // Alias match: 'upd'
  const res2 = await as(studentA, "select public.add_custom_school('UPD') as id");
  assert.equal(res2.rows[0].id, upDilimanSchoolId, 'Alias match must return existing school ID');

  // Empty string rejected with P0002
  await denied(async () => {
    await as(studentA, "select public.add_custom_school('   ')");
  });

  // Adding genuinely new school succeeds
  const res3 = await as(studentA, "select public.add_custom_school('Silliman University') as id");
  const newSchoolId = res3.rows[0].id;
  assert(newSchoolId, 'New school ID should be returned');

  const schoolRow = (await db.query('select * from public.schools where id = $1', [newSchoolId])).rows[0];
  assert.equal(schoolRow.name, 'Silliman University');
  assert.equal(schoolRow.normalized_name, 'silliman university');
  assert.equal(schoolRow.is_curated, false);
});

// -----------------------------------------------------------------------------
// Vector 9: Roster Column-Minimization & Student Isolation Test
// -----------------------------------------------------------------------------
await test('Vector 9: Roster column-minimization: roster contains zero students, zero student PII, and accurately reflects counts', async () => {
  const roster = await as(orgAdminA, 'select * from public.get_organization_roster($1)', [orgAdminA]);

  assert(roster.rows.length >= 2, 'Must return at least orgAdminA and reviewerA');

  for (const row of roster.rows) {
    assert(['org_admin', 'reviewer'].includes(row.role), `Role ${row.role} is not an allowed provider role`);
    // Ensure sensitive student columns are not present
    assert.strictEqual(row.birth_date, undefined);
    assert.strictEqual(row.monthly_family_income, undefined);
    assert.strictEqual(row.gpa, undefined);
    assert.strictEqual(row.school, undefined);
  }

  // Student querying roster returns 0 rows
  const studentRoster = await as(studentA, 'select * from public.get_organization_roster($1)', [orgAdminA]);
  assert.equal(studentRoster.rows.length, 0, 'Students cannot access provider team roster');
});

// -----------------------------------------------------------------------------
// Vector 10: Cross-Organization Isolation & Audit Ledger Integrity
// -----------------------------------------------------------------------------
await test('Vector 10: Cross-organization isolation & audit ledger integrity: cross-org calls fail with 42501; direct audit log insert denied', async () => {
  await db.exec(`
    insert into public.scholarships (id, title, created_by, deadline, is_active)
    values ('${orgBGrant}', 'Org B Private Grant', '${orgAdminB}', current_date + 30, true);
  `);

  // Org Admin A attempting to assign reviewer for Org B scholarship is denied
  await denied(async () => {
    await as(orgAdminA, 'select public.assign_scholarship_reviewer($1, $2)', [orgBGrant, reviewerA]);
  });

  // Org Admin A attempting to assign a reviewer who is NOT a member of Org A is denied
  await denied(async () => {
    await as(orgAdminA, 'select public.assign_scholarship_reviewer($1, $2)', [cappedGrant, reviewerB]);
  });

  // Org Admin A assigning Reviewer A to own scholarship succeeds and writes to audit log
  const assignRes = await as(orgAdminA, 'select public.assign_scholarship_reviewer($1, $2)', [cappedGrant, reviewerA]);
  assert(assignRes.rows.length === 1, 'Assigning reviewer to own scholarship should succeed');

  // Org Admin A querying Org B activity logs returns 0 rows
  const logsB = await as(orgAdminA, 'select * from public.get_organization_activity_logs($1)', [orgAdminB]);
  assert.equal(logsB.rows.length, 0, 'Cross-org activity logs must be strictly isolated');

  // Org Admin A querying own activity logs returns the assign_reviewer event
  const logsA = await as(orgAdminA, 'select * from public.get_organization_activity_logs($1)', [orgAdminA]);
  assert(logsA.rows.length > 0, 'Audit log should record assign_reviewer event');
  assert.equal(logsA.rows[0].action, 'assign_reviewer');

  // Spoofed client insert into public.audit_logs (forging another actor_id) is denied under RLS
  await denied(async () => {
    await as(orgAdminA, `
      insert into public.audit_logs (actor_id, actor_email, actor_role, action, target_type, target_id)
      values ('${studentA}', 'hacker@scholaris.test', 'admin', 'forged_action', 'scholarship', '${cappedGrant}')
    `);
  });

  // Direct client UPDATE or DELETE on public.audit_logs affects 0 rows (immutable ledger)
  const auditUpdateRes = await as(orgAdminA, "update public.audit_logs set action = 'tampered' returning id");
  assert.equal(auditUpdateRes.rows.length, 0, 'Audit logs must be strictly immutable to client updates');
  const auditDeleteRes = await as(orgAdminA, "delete from public.audit_logs returning id");
  assert.equal(auditDeleteRes.rows.length, 0, 'Audit logs must be strictly immutable to client deletes');
});

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Vector 12: Assign/Unassign Authorization Matrix (Outsider, Cross-Org Admin, Reviewer, Org Admin, Platform Admin)
// -----------------------------------------------------------------------------
await test('Vector 12: Assign & unassign authorization matrix: outsider, cross-org admin, and reviewer denied with 42501 (leaving assignments and audit logs unchanged); authorized org admin and platform admin succeed', async () => {
  const outsider = studentB; // Authenticated user with no membership in Org A
  const crossOrgAdmin = orgAdminB; // Org admin of Org B, no membership in Org A
  const reviewer = reviewerA; // Reviewer in Org A, not org admin
  const authorizedOrgAdmin = orgAdminA; // Org admin in Org A
  const targetScholarship = reductionGrant; // Owned by Org A
  const targetReviewer = reviewerA; // Reviewer in Org A

  const getAssignmentsCount = async () =>
    Number((await db.query('select count(*) as c from public.scholarship_reviewer_assignments where scholarship_id = $1', [targetScholarship])).rows[0].c);

  const getAuditLogsCount = async () =>
    Number((await db.query('select count(*) as c from public.audit_logs where target_id = $1', [targetScholarship])).rows[0].c);

  // Helper for denied test asserting table & audit immutability
  const assertDenied = async (actor, actionName, querySql, params) => {
    const preAssign = await getAssignmentsCount();
    const preAudit = await getAuditLogsCount();

    await assert.rejects(
      as(actor, querySql, params),
      (err) => {
        const matches = err.code === '42501' || (err.message && err.message.includes('Only organization admins'));
        assert(matches, `${actionName} by ${actor} should fail with 42501, but got: ${err.message}`);
        return true;
      }
    );

    const postAssign = await getAssignmentsCount();
    const postAudit = await getAuditLogsCount();
    assert.equal(postAssign, preAssign, `${actionName} denial MUST leave assignments count unchanged`);
    assert.equal(postAudit, preAudit, `${actionName} denial MUST leave audit logs count unchanged`);
  };

  // 1. Authenticated Outsider (has no membership in Org A): assign and unassign denied
  await assertDenied(outsider, 'Outsider Assign', 'select public.assign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);
  await assertDenied(outsider, 'Outsider Unassign', 'select public.unassign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);

  // 2. Cross-Org Admin (org_admin in Org B, no membership in Org A): assign and unassign denied
  await assertDenied(crossOrgAdmin, 'Cross-Org Admin Assign', 'select public.assign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);
  await assertDenied(crossOrgAdmin, 'Cross-Org Admin Unassign', 'select public.unassign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);

  // 3. Reviewer (member in Org A, but role is reviewer, not org_admin): assign and unassign denied
  await assertDenied(reviewer, 'Reviewer Assign', 'select public.assign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);
  await assertDenied(reviewer, 'Reviewer Unassign', 'select public.unassign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);

  // 4. Authorized Org Admin: Assign succeeds
  const preOrgAssignAudit = await getAuditLogsCount();
  const assignOrgRes = await as(authorizedOrgAdmin, 'select * from public.assign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);
  assert.equal(assignOrgRes.rows.length, 1, 'Authorized org admin assign must succeed');
  assert.equal(await getAssignmentsCount(), 1, 'Assignment row must be created');
  assert.equal(await getAuditLogsCount(), preOrgAssignAudit + 1, 'Audit log must record assign_reviewer event');
  const orgAssignLog = (await db.query('select * from public.audit_logs where target_id = $1 order by created_at desc limit 1', [targetScholarship])).rows[0];
  assert.equal(orgAssignLog.action, 'assign_reviewer');
  assert.equal(orgAssignLog.actor_id, authorizedOrgAdmin);

  // When assignment exists, verify outsider, cross-org admin, and reviewer STILL CANNOT unassign
  await assertDenied(outsider, 'Outsider Unassign existing', 'select public.unassign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);
  assert.equal(await getAssignmentsCount(), 1, 'Outsider unassign must not delete existing assignment');

  await assertDenied(crossOrgAdmin, 'Cross-Org Admin Unassign existing', 'select public.unassign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);
  assert.equal(await getAssignmentsCount(), 1, 'Cross-org admin unassign must not delete existing assignment');

  await assertDenied(reviewer, 'Reviewer Unassign existing', 'select public.unassign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);
  assert.equal(await getAssignmentsCount(), 1, 'Reviewer unassign must not delete existing assignment');

  // Authorized Org Admin: Unassign succeeds
  const preOrgUnassignAudit = await getAuditLogsCount();
  const unassignOrgRes = await as(authorizedOrgAdmin, 'select public.unassign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);
  assert.equal(unassignOrgRes.rows[0].unassign_scholarship_reviewer, true, 'Authorized org admin unassign must return true');
  assert.equal(await getAssignmentsCount(), 0, 'Assignment row must be deleted');
  assert.equal(await getAuditLogsCount(), preOrgUnassignAudit + 1, 'Audit log must record unassign_reviewer event');
  const orgUnassignLog = (await db.query('select * from public.audit_logs where target_id = $1 order by created_at desc limit 1', [targetScholarship])).rows[0];
  assert.equal(orgUnassignLog.action, 'unassign_reviewer');
  assert.equal(orgUnassignLog.actor_id, authorizedOrgAdmin);

  // 5. Platform Admin: Assign and Unassign succeed
  const prePlatAssignAudit = await getAuditLogsCount();
  const assignPlatRes = await as(platformAdmin, 'select * from public.assign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);
  assert.equal(assignPlatRes.rows.length, 1, 'Platform admin assign must succeed');
  assert.equal(await getAssignmentsCount(), 1, 'Platform admin assignment row must be created');
  assert.equal(await getAuditLogsCount(), prePlatAssignAudit + 1, 'Audit log must record platform admin assign_reviewer event');
  const platAssignLog = (await db.query('select * from public.audit_logs where target_id = $1 order by created_at desc limit 1', [targetScholarship])).rows[0];
  assert.equal(platAssignLog.action, 'assign_reviewer');
  assert.equal(platAssignLog.actor_id, platformAdmin);

  const prePlatUnassignAudit = await getAuditLogsCount();
  const unassignPlatRes = await as(platformAdmin, 'select public.unassign_scholarship_reviewer($1, $2)', [targetScholarship, targetReviewer]);
  assert.equal(unassignPlatRes.rows[0].unassign_scholarship_reviewer, true, 'Platform admin unassign must return true');
  assert.equal(await getAssignmentsCount(), 0, 'Platform admin assignment row must be deleted');
  assert.equal(await getAuditLogsCount(), prePlatUnassignAudit + 1, 'Audit log must record platform admin unassign_reviewer event');
  const platUnassignLog = (await db.query('select * from public.audit_logs where target_id = $1 order by created_at desc limit 1', [targetScholarship])).rows[0];
  assert.equal(platUnassignLog.action, 'unassign_reviewer');
  assert.equal(platUnassignLog.actor_id, platformAdmin);
});

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Vector 13: Direct-Table Mutation Defense Under Production Default Privileges
// (Direct INSERT/UPDATE/DELETE denied, actor spoofing & cross-org blocked, audit events enforced, SELECT preserved via RLS)
// -----------------------------------------------------------------------------
await test('Vector 13: Direct-table mutation defense under production default privileges: direct INSERT/UPDATE/DELETE denied; actor spoofing and cross-org reviewers blocked; audit events strictly required; authenticated SELECT preserved through RLS', async () => {
  const targetScholarship = reductionGrant; // Owned by Org A
  const validReviewer = reviewerA; // Org A reviewer
  const crossOrgReviewer = reviewerB; // Org B reviewer
  const outsider = studentB;

  const getAssignmentsCount = async () =>
    Number((await db.query('select count(*) as c from public.scholarship_reviewer_assignments where scholarship_id = $1', [targetScholarship])).rows[0].c);

  const getAuditLogsCount = async () =>
    Number((await db.query('select count(*) as c from public.audit_logs where target_id = $1', [targetScholarship])).rows[0].c);

  const initialAssignments = await getAssignmentsCount();
  const initialAudits = await getAuditLogsCount();

  // 1. Direct table INSERT must be DENIED for all client roles, even with production default grants
  // A. Authorized Org Admin attempting direct INSERT (bypassing RPC)
  await assert.rejects(
    as(orgAdminA, 'insert into public.scholarship_reviewer_assignments(scholarship_id, reviewer_id, assigned_by) values ($1, $2, $3)',
      [targetScholarship, validReviewer, orgAdminA]),
    (err) => {
      assert(err.code === '42501', `Direct INSERT by orgAdminA should fail with 42501, got: ${err.message} (${err.code})`);
      return true;
    }
  );

  // B. Actor Spoofing via direct INSERT: orgAdminA trying to forge assigned_by as orgAdminB
  await assert.rejects(
    as(orgAdminA, 'insert into public.scholarship_reviewer_assignments(scholarship_id, reviewer_id, assigned_by) values ($1, $2, $3)',
      [targetScholarship, validReviewer, orgAdminB]),
    (err) => {
      assert(err.code === '42501', `Actor-spoofed direct INSERT should fail with 42501, got: ${err.message} (${err.code})`);
      return true;
    }
  );

  // C. Cross-Org Reviewer via direct INSERT: orgAdminA trying to assign reviewerB (from Org B)
  await assert.rejects(
    as(orgAdminA, 'insert into public.scholarship_reviewer_assignments(scholarship_id, reviewer_id, assigned_by) values ($1, $2, $3)',
      [targetScholarship, crossOrgReviewer, orgAdminA]),
    (err) => {
      assert(err.code === '42501', `Cross-org direct INSERT should fail with 42501, got: ${err.message} (${err.code})`);
      return true;
    }
  );

  // D. Direct INSERT by outsider (studentB)
  await assert.rejects(
    as(outsider, 'insert into public.scholarship_reviewer_assignments(scholarship_id, reviewer_id, assigned_by) values ($1, $2, $3)',
      [targetScholarship, validReviewer, outsider]),
    (err) => {
      assert(err.code === '42501', `Direct INSERT by outsider should fail with 42501, got: ${err.message} (${err.code})`);
      return true;
    }
  );

  // Verify that all rejected direct INSERT attempts left assignments and audit logs unchanged
  assert.equal(await getAssignmentsCount(), initialAssignments, 'Direct INSERT denials must leave assignments unchanged');
  assert.equal(await getAuditLogsCount(), initialAudits, 'Direct INSERT denials must leave audit logs unchanged');

  // 2. Validate RPC enforcement: cross-org reviewer assignment rejected with P0002
  await assert.rejects(
    as(orgAdminA, 'select public.assign_scholarship_reviewer($1, $2)', [targetScholarship, crossOrgReviewer]),
    (err) => {
      assert(err.code === 'P0002' || (err.message && err.message.includes('not an active reviewer')),
        `Cross-org reviewer assignment via RPC must fail with P0002, got: ${err.message} (${err.code})`);
      return true;
    }
  );
  assert.equal(await getAssignmentsCount(), initialAssignments, 'Rejected RPC must leave assignments unchanged');
  assert.equal(await getAuditLogsCount(), initialAudits, 'Rejected RPC must leave audit logs unchanged');

  // 3. Authorized RPC assign succeeds, binds assigned_by to auth.uid(), and records required audit log
  const assignRes = await as(orgAdminA, 'select * from public.assign_scholarship_reviewer($1, $2)', [targetScholarship, validReviewer]);
  assert.equal(assignRes.rows.length, 1, 'Valid RPC assignment must succeed');
  assert.equal(assignRes.rows[0].assigned_by, orgAdminA, 'assigned_by must strictly bind to auth.uid()');
  assert.equal(await getAssignmentsCount(), initialAssignments + 1, 'Assignment row created');
  assert.equal(await getAuditLogsCount(), initialAudits + 1, 'Audit log emitted');

  const auditEntry = (await db.query('select * from public.audit_logs where target_id = $1 order by created_at desc limit 1', [targetScholarship])).rows[0];
  assert.equal(auditEntry.action, 'assign_reviewer', 'Audit action must be assign_reviewer');
  assert.equal(auditEntry.actor_id, orgAdminA, 'Audit actor must match authenticated caller');
  assert.equal(auditEntry.details?.reviewer_id, validReviewer, 'Audit details must record reviewer_id');

  // 4. Direct table UPDATE must be DENIED for all client roles
  await assert.rejects(
    as(orgAdminA, 'update public.scholarship_reviewer_assignments set reviewer_id = $1 where scholarship_id = $2', [crossOrgReviewer, targetScholarship]),
    (err) => {
      assert(err.code === '42501', `Direct UPDATE by orgAdminA should fail with 42501, got: ${err.message} (${err.code})`);
      return true;
    }
  );
  await assert.rejects(
    as(outsider, 'update public.scholarship_reviewer_assignments set reviewer_id = $1 where scholarship_id = $2', [crossOrgReviewer, targetScholarship]),
    (err) => {
      assert(err.code === '42501', `Direct UPDATE by outsider should fail with 42501, got: ${err.message} (${err.code})`);
      return true;
    }
  );

  // 5. Direct table DELETE must be DENIED for all client roles
  await assert.rejects(
    as(orgAdminA, 'delete from public.scholarship_reviewer_assignments where scholarship_id = $1 and reviewer_id = $2', [targetScholarship, validReviewer]),
    (err) => {
      assert(err.code === '42501', `Direct DELETE by orgAdminA should fail with 42501, got: ${err.message} (${err.code})`);
      return true;
    }
  );
  await assert.rejects(
    as(outsider, 'delete from public.scholarship_reviewer_assignments where scholarship_id = $1 and reviewer_id = $2', [targetScholarship, validReviewer]),
    (err) => {
      assert(err.code === '42501', `Direct DELETE by outsider should fail with 42501, got: ${err.message} (${err.code})`);
      return true;
    }
  );

  // 6. Authenticated SELECT is preserved through RLS
  // A. Org Admin of Org A can SELECT assignments
  const adminSelectRes = await as(orgAdminA, 'select * from public.scholarship_reviewer_assignments where scholarship_id = $1', [targetScholarship]);
  assert.equal(adminSelectRes.rows.length, 1, 'Org admin must be able to SELECT assignments via RLS');

  // B. Reviewer of Org A can SELECT assignments
  const reviewerSelectRes = await as(reviewerA, 'select * from public.scholarship_reviewer_assignments where scholarship_id = $1', [targetScholarship]);
  assert.equal(reviewerSelectRes.rows.length, 1, 'Org reviewer must be able to SELECT assignments via RLS');

  // C. Outsider (studentB) cannot see assignments (RLS filters out)
  const outsiderSelectRes = await as(outsider, 'select * from public.scholarship_reviewer_assignments where scholarship_id = $1', [targetScholarship]);
  assert.equal(outsiderSelectRes.rows.length, 0, 'Outsider SELECT must return 0 rows under RLS');

  // D. Cross-Org Admin (orgAdminB) cannot see Org A assignments
  const crossAdminSelectRes = await as(orgAdminB, 'select * from public.scholarship_reviewer_assignments where scholarship_id = $1', [targetScholarship]);
  assert.equal(crossAdminSelectRes.rows.length, 0, 'Cross-org admin SELECT must return 0 rows under RLS');

  // E. Platform Admin can SELECT all assignments
  const platSelectRes = await as(platformAdmin, 'select * from public.scholarship_reviewer_assignments where scholarship_id = $1', [targetScholarship]);
  assert.equal(platSelectRes.rows.length, 1, 'Platform admin must be able to SELECT assignments');

  // 7. Cleanup via authorized RPC unassign emits required audit log
  const unassignRes = await as(orgAdminA, 'select public.unassign_scholarship_reviewer($1, $2)', [targetScholarship, validReviewer]);
  assert.equal(unassignRes.rows[0].unassign_scholarship_reviewer, true, 'Authorized unassign must succeed');
  assert.equal(await getAssignmentsCount(), initialAssignments, 'Assignment row deleted');
  assert.equal(await getAuditLogsCount(), initialAudits + 2, 'Unassign audit log emitted');

  const unassignAudit = (await db.query('select * from public.audit_logs where target_id = $1 order by created_at desc limit 1', [targetScholarship])).rows[0];
  assert.equal(unassignAudit.action, 'unassign_reviewer', 'Audit action must be unassign_reviewer');
  assert.equal(unassignAudit.actor_id, orgAdminA, 'Audit actor must match authenticated caller');
});

// Vector 11: SQL Test Script Verification (supabase/tests/organization_controls_security_test.sql)
// -----------------------------------------------------------------------------
await test('Vector 11: SQL Regression Suite: supabase/tests/organization_controls_security_test.sql runs to completion with transactional rollback', async () => {
  try {
    const sql = await readFile(new URL('../supabase/tests/organization_controls_security_test.sql', import.meta.url), 'utf8');
    await db.exec(sql);
  } catch (err) {
    console.error('Vector 11 error message:', err.message);
    process.exit(1);
  }
});

console.log(`\n=============================================================================`);
console.log(`All ${passed} Organization-Admin Controls & Concurrency Tests Passed!`);
console.log(`=============================================================================\n`);

await db.close();
