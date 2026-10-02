# Manual verification for migration 0020 (provider_applicant_profiles)

Run ONLY in a staging copy or after a backup of the policies. Read each query before running it. Nothing here is executed automatically.

## Setup
You need 4 test users: Provider A (owns scholarship SA), Provider B, Student S1 (submitted to SA), Student S2 (draft application to SA), Student S3 (withdrawn application to SA), Student S4 (no application to SA).

To act as a user in the Supabase SQL editor:

    set local role authenticated;
    select set_config('request.jwt.claims', '{"sub":"<USER_UUID>","role":"authenticated"}', true);

## Checks (act as Provider A)
1. Submitted applicant is visible
   select id, full_name from public.provider_applicant_profiles where id = '<S1_UUID>';
   Expected: 1 row.
2. Draft applicant is hidden
   select id from public.provider_applicant_profiles where id = '<S2_UUID>';
   Expected: 0 rows.
3. Withdrawn applicant is hidden
   select id from public.provider_applicant_profiles where id = '<S3_UUID>';
   Expected: 0 rows.
4. Unrelated student is hidden
   select id from public.provider_applicant_profiles where id = '<S4_UUID>';
   Expected: 0 rows.
5. No sensitive columns
   select * from public.provider_applicant_profiles limit 1;
   Expected: no birth_date, phone, email, gender, has_disability, is_indigenous columns.
6. RPC matches the view
   select * from public.get_applicant_profile('<S1_UUID>');   Expected: 1 row.
   select * from public.get_applicant_profile('<S2_UUID>');   Expected: 0 rows.
   select * from public.get_applicant_profile('<S3_UUID>');   Expected: 0 rows.

## Checks (act as Provider B)
7. Provider B cannot see S1: repeat check 1 with Provider B's UUID. Expected: 0 rows.

## Check (anon)
8. Switch role: set local role anon;
   select * from public.provider_applicant_profiles;   Expected: permission denied or 0 rows.
   select * from public.get_applicant_profile('<S1_UUID>');   Expected: permission denied.

## After 0021 is applied
9. As Provider A, select * from public.profiles where id = '<S1_UUID>';
   Expected: 0 rows (the legacy policy is gone). The provider screens must still show applicant names via the view.
10. As Student S1, select * from public.profiles where id = '<S1_UUID>';
    Expected: 1 row (own-profile policy still works).
