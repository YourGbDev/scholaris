-- =============================================================================
-- Scholaris — 0010: Providers manage own scholarships (RLS policies)
--
-- Grants authenticated users with role = 'provider' permission to insert,
-- update, and delete scholarships where created_by equals their own auth.uid().
--
-- Combined with 0004 (which added scholarships.created_by), this gives
-- providers full self-service lifecycle ownership of their scholarship listings.
-- =============================================================================

-- 1. Insert policy: Provider can only insert records where created_by = auth.uid()
create policy "Providers can insert own scholarships"
  on public.scholarships for insert
  to authenticated
  with check (
    created_by = auth.uid()
    and exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'provider'
    )
  );

-- 2. Update policy: Provider can only update their own records
create policy "Providers can update own scholarships"
  on public.scholarships for update
  to authenticated
  using (
    created_by = auth.uid()
    and exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'provider'
    )
  )
  with check (
    created_by = auth.uid()
  );

-- 3. Delete policy: Provider can only delete their own records
create policy "Providers can delete own scholarships"
  on public.scholarships for delete
  to authenticated
  using (
    created_by = auth.uid()
    and exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'provider'
    )
  );
