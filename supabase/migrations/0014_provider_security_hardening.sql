-- =============================================================================
-- Scholaris — 0014: Provider Security Hardening & Server-Side Triggers
--
-- 1. Anti-Privilege Escalation: Guard trigger on public.profiles
-- 2. Profile Sync Trigger: Automatically set role='provider' upon verification insert/resubmit
-- 3. Audit Logging Trigger: Server-side audit log generation upon admin decision
-- 4. RLS Re-submission Policy: Allow rejected providers to update row back to 'pending'
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Guard Trigger: Prevent non-admins from altering role or provider_type
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_profiles_role_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- If role or provider_type is changing
  IF (NEW.role IS DISTINCT FROM OLD.role OR NEW.provider_type IS DISTINCT FROM OLD.provider_type) THEN
    -- Allow if current session is an admin or called from an internal server trigger (e.g. provider verification sync)
    IF NOT (public.is_admin() OR pg_trigger_depth() > 1) THEN
      RAISE EXCEPTION 'Unauthorized: only administrators can modify role or provider_type directly.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_profiles_role_change ON public.profiles;
CREATE TRIGGER trg_guard_profiles_role_change
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_profiles_role_change();

-- -----------------------------------------------------------------------------
-- 2. Profile Sync Trigger: Sync provider_verifications to public.profiles
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_provider_verification_sync_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Enforce that clients cannot insert status other than 'pending'
  IF (TG_OP = 'INSERT' AND NEW.status != 'pending') THEN
    RAISE EXCEPTION 'New verification submissions must have status = pending.';
  END IF;

  -- Sync attributes to profiles
  UPDATE public.profiles
  SET
    role = 'provider',
    provider_type = NEW.provider_type,
    full_name = COALESCE(NEW.full_name, NEW.org_name, profiles.full_name),
    phone = COALESCE(NEW.phone, NEW.rep_phone, profiles.phone),
    organization = COALESCE(NEW.org_name, profiles.organization),
    updated_at = now()
  WHERE id = NEW.user_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_provider_verification_sync_profile ON public.provider_verifications;
CREATE TRIGGER trg_provider_verification_sync_profile
  AFTER INSERT OR UPDATE ON public.provider_verifications
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_provider_verification_sync_profile();

-- -----------------------------------------------------------------------------
-- 3. Review & Audit Trigger: Server-side reviewer stamping and audit_logs entry
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_provider_verification_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_email text;
  v_admin_role text;
BEGIN
  -- Trigger on status change to 'approved' or 'rejected'
  IF (NEW.status IN ('approved', 'rejected') AND (OLD.status IS DISTINCT FROM NEW.status)) THEN
    -- Prevent non-admins from reviewing
    IF NOT public.is_admin() THEN
      RAISE EXCEPTION 'Unauthorized: only administrators can approve or reject provider verifications.';
    END IF;

    -- Enforce server-side reviewer assignment
    NEW.reviewed_by := auth.uid();
    NEW.reviewed_at := now();

    -- Fetch admin profile metadata
    SELECT email, role INTO v_admin_email, v_admin_role
    FROM public.profiles
    WHERE id = auth.uid();

    -- Write immutable audit log row
    INSERT INTO public.audit_logs (
      actor_id,
      actor_email,
      actor_role,
      action,
      target_type,
      target_id,
      details,
      created_at
    ) VALUES (
      auth.uid(),
      COALESCE(v_admin_email, (auth.jwt() ->> 'email')),
      COALESCE(v_admin_role, 'admin'),
      CASE 
        WHEN NEW.status = 'approved' THEN 'provider_verification_approved'
        ELSE 'provider_verification_rejected'
      END,
      'provider_verification',
      NEW.user_id::text,
      jsonb_build_object(
        'provider_type', NEW.provider_type,
        'previous_status', OLD.status,
        'new_status', NEW.status,
        'review_note', COALESCE(NEW.review_note, '')
      ),
      now()
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_provider_verification_review ON public.provider_verifications;
CREATE TRIGGER trg_provider_verification_review
  BEFORE UPDATE ON public.provider_verifications
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_provider_verification_review();

-- -----------------------------------------------------------------------------
-- 4. RLS Re-submission Policy: Enable rejected providers to update back to pending
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can update own pending verification" ON public.provider_verifications;
CREATE POLICY "Users can update own pending verification"
  ON public.provider_verifications FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id AND status IN ('pending', 'rejected'))
  WITH CHECK (auth.uid() = user_id AND status = 'pending');

-- Force schema reload
NOTIFY pgrst, 'reload schema';
