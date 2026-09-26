-- Migration 0016: Disbursements table
-- Tracks actual fund releases separate from application approval.
-- Approval (applications.status = 'approved') means eligibility confirmed.
-- Disbursement means money was actually sent. These are intentionally separate events.

CREATE TABLE public.disbursements (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id    uuid        NOT NULL REFERENCES public.applications(id) ON DELETE RESTRICT,
  scholarship_id    uuid        NOT NULL REFERENCES public.scholarships(id) ON DELETE RESTRICT,
  recipient_id      uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  amount            numeric     NOT NULL CHECK (amount > 0),
  status            text        NOT NULL DEFAULT 'pending'
                                CHECK (status IN ('pending', 'released', 'failed', 'cancelled')),
  payment_method    text,
  reference_number  text,
  released_at       timestamptz,
  released_by       uuid        REFERENCES public.profiles(id) ON DELETE SET NULL,
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_disbursements_application  ON public.disbursements(application_id);
CREATE INDEX idx_disbursements_recipient    ON public.disbursements(recipient_id);
CREATE INDEX idx_disbursements_status       ON public.disbursements(status);
CREATE INDEX idx_disbursements_created_at   ON public.disbursements(created_at DESC);

-- Auto-update updated_at
CREATE TRIGGER trg_disbursements_updated_at
  BEFORE UPDATE ON public.disbursements
  FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);

-- RLS
ALTER TABLE public.disbursements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admins_full_access_disbursements"
  ON public.disbursements
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "recipients_read_own_disbursements"
  ON public.disbursements
  FOR SELECT
  TO authenticated
  USING (recipient_id = auth.uid());

-- Audit trigger: log all disbursement state changes
CREATE OR REPLACE FUNCTION log_disbursement_audit()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.audit_logs (
    actor_id,
    actor_email,
    actor_role,
    action,
    target_type,
    target_id,
    details,
    ip_address
  )
  SELECT
    auth.uid(),
    p.email,
    p.role,
    CASE
      WHEN TG_OP = 'INSERT' THEN 'disbursement_created'
      WHEN TG_OP = 'UPDATE' AND NEW.status = 'released' THEN 'disbursement_released'
      WHEN TG_OP = 'UPDATE' AND NEW.status = 'failed'   THEN 'disbursement_failed'
      WHEN TG_OP = 'UPDATE' AND NEW.status = 'cancelled' THEN 'disbursement_cancelled'
      ELSE 'disbursement_updated'
    END,
    'disbursement',
    NEW.id::text,
    jsonb_build_object(
      'application_id',   NEW.application_id,
      'scholarship_id',   NEW.scholarship_id,
      'recipient_id',     NEW.recipient_id,
      'amount',           NEW.amount,
      'status',           NEW.status,
      'payment_method',   NEW.payment_method,
      'reference_number', NEW.reference_number,
      'released_at',      NEW.released_at,
      'released_by',      NEW.released_by
    ),
    NULL
  FROM public.profiles p
  WHERE p.id = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_disbursements_audit
  AFTER INSERT OR UPDATE ON public.disbursements
  FOR EACH ROW EXECUTE FUNCTION log_disbursement_audit();
