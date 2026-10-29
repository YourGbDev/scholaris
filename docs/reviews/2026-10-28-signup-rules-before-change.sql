-- Read from project yqwbarzxpduzmtrxnrbm immediately before migration 0034.
-- This preserves the previous definitions only, not a data backup.
-- WARNING: Restoring these definitions reintroduces the signup privilege flaw.
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 insert into public.profiles (id, email, full_name, role, status)
 values (
 new.id,
 new.email,
 new.raw_user_meta_data->>'full_name',
 coalesce(new.raw_user_meta_data->>'role', 'student'),
 'active'
 );
 return new;
end;
$function$;

-- Previous sole INSERT policy: permissive, role PUBLIC, check (auth.uid() = id).
-- It can be recreated with the following only if rollback is explicitly required.
-- DROP POLICY IF EXISTS "Profiles are insertable by owner" ON public.profiles;
-- CREATE POLICY "Profiles are insertable by owner" ON public.profiles
--   AS PERMISSIVE FOR INSERT TO PUBLIC WITH CHECK (auth.uid() = id);
