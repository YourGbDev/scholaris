-- =============================================================================
-- Scholaris — 0015: Scholarship Funding Columns (Amount, Coverage, Frequency)
--
-- 1. Schema Expansion: Add amount, coverage, and frequency columns to scholarships
-- 2. Constraints: Enforce non-negative amounts and valid frequency enum values
-- 3. Data Backfill: Populate realistic, authoritative grant amounts for existing scholarships
-- 4. Housekeeping: Remove obsolete verification test artifacts
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Schema Expansion: Add real funding attributes
-- -----------------------------------------------------------------------------
ALTER TABLE public.scholarships
  ADD COLUMN IF NOT EXISTS amount numeric NOT NULL DEFAULT 50000.00,
  ADD COLUMN IF NOT EXISTS coverage text NOT NULL DEFAULT 'Tuition + Allowance',
  ADD COLUMN IF NOT EXISTS frequency text NOT NULL DEFAULT 'annual';

-- -----------------------------------------------------------------------------
-- 2. Constraints
-- -----------------------------------------------------------------------------
ALTER TABLE public.scholarships
  DROP CONSTRAINT IF EXISTS chk_scholarships_amount_non_negative,
  ADD CONSTRAINT chk_scholarships_amount_non_negative CHECK (amount >= 0);

ALTER TABLE public.scholarships
  DROP CONSTRAINT IF EXISTS chk_scholarships_frequency_valid,
  ADD CONSTRAINT chk_scholarships_frequency_valid CHECK (frequency IN ('annual', 'per_semester', 'one_time'));

-- -----------------------------------------------------------------------------
-- 3. Authoritative Data Backfill
-- -----------------------------------------------------------------------------
-- 3a. Ayala Future Leaders Grant 2026 (The Provider's Active Endowment Grant)
UPDATE public.scholarships
SET 
  amount = 50000.00,
  coverage = 'Tuition + Allowance',
  frequency = 'annual'
WHERE id = 'aec8aea6-8930-47da-93d0-1b24b9ececdd'
   OR title ILIKE '%Ayala Future Leaders Grant 2026%';

-- 3b. Ayala Future Leaders STEM Grant 2026
UPDATE public.scholarships
SET 
  amount = 60000.00,
  coverage = 'Tuition + Allowance',
  frequency = 'annual'
WHERE id = '5842c47e-d813-4603-999d-3287d68a7201'
   OR title ILIKE '%Ayala Future Leaders STEM Grant 2026%';

-- 3c. DOST-SEI Undergraduate Scholarship
UPDATE public.scholarships
SET 
  amount = 40000.00,
  coverage = 'Tuition + Allowance',
  frequency = 'per_semester'
WHERE id = 'ff0922be-e3ca-4276-b341-92707c5c03b2'
   OR title ILIKE '%DOST-SEI Undergraduate Scholarship%';

-- 3d. CHED Merit Scholarship (MSRS)
UPDATE public.scholarships
SET 
  amount = 60000.00,
  coverage = 'Full Tuition + Stipend',
  frequency = 'annual'
WHERE id = '9966e678-a439-496f-beb9-c1c6c7cd4e53'
   OR title ILIKE '%CHED Merit Scholarship%';

-- 3e. CHED Tulong Dunong Program
UPDATE public.scholarships
SET 
  amount = 60000.00,
  coverage = 'Tuition Subsidy',
  frequency = 'annual'
WHERE id = 'aeb9eb80-5001-4e55-9aa7-c52517285063'
   OR title ILIKE '%CHED Tulong Dunong%';

-- 3f. SM Foundation College Scholarship
UPDATE public.scholarships
SET 
  amount = 120000.00,
  coverage = 'Full Tuition + Book Allowance',
  frequency = 'annual'
WHERE id = 'f8940e50-40e6-43c1-a6aa-724e1b671eb6'
   OR title ILIKE '%SM Foundation College Scholarship%';

-- 3g. Zobel de Ayala Scholars Program
UPDATE public.scholarships
SET 
  amount = 100000.00,
  coverage = 'Full Tuition + Leadership Grant',
  frequency = 'annual'
WHERE id = 'a2dccd58-753e-452a-9f55-6606821fd7e6'
   OR title ILIKE '%Zobel de Ayala Scholars Program%';

-- 3h. Presidential Scholarship for Academic Excellence
UPDATE public.scholarships
SET 
  amount = 100000.00,
  coverage = 'Full Tuition + Stipend',
  frequency = 'annual'
WHERE id = 'ea2a10d6-c07e-4aa5-b5a5-be3c136ca599'
   OR title ILIKE '%Presidential Scholarship%';

-- 3i. Engineering Excellence Grant
UPDATE public.scholarships
SET 
  amount = 100000.00,
  coverage = 'Full Tuition',
  frequency = 'annual'
WHERE id = 'f4510b52-17f5-462b-a57c-1be7c8c7020c'
   OR title ILIKE '%Engineering Excellence Grant%';

-- 3j. Women in Technology Grant
UPDATE public.scholarships
SET 
  amount = 60000.00,
  coverage = 'Tech Mentorship + Allowance',
  frequency = 'annual'
WHERE id = '7e66cdc4-d3c7-4209-995f-ab755a35727e'
   OR title ILIKE '%Women in Technology%';

-- -----------------------------------------------------------------------------
-- 4. Housekeeping: Remove obsolete verification test artifacts
-- -----------------------------------------------------------------------------
DELETE FROM public.provider_verifications
WHERE org_name = 'Test Foundation Obsolete';

-- Force schema reload for PostgREST
NOTIFY pgrst, 'reload schema';
