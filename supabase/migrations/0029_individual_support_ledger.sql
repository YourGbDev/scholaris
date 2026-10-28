-- Individual support records. No bank transfer or bank verification is performed.
-- Depends on 0027; execute through the normal reviewed migration process.
begin;
create function public.owns_individual_support(p_scholarship uuid) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.scholarships s join public.profiles p on p.id=s.created_by
 where s.id=p_scholarship and s.created_by=auth.uid() and p.role='provider'
 and p.provider_type='individual' and p.status='active' and exists(select 1 from public.provider_verifications v where v.user_id=p.id and v.provider_type='individual' and v.status='approved')) and public.can_review_scholarship(p_scholarship);
$$;
revoke all on function public.owns_individual_support(uuid) from public,anon;
grant execute on function public.owns_individual_support(uuid) to authenticated;

create table public.individual_support_budgets (
 scholarship_id uuid primary key references public.scholarships(id) on delete restrict,
 cycle_label text not null check(length(trim(cycle_label)) between 1 and 80),
 budget_cents bigint not null check(budget_cents between 1 and 100000000000),
 updated_at timestamptz not null default now()
);
create table public.individual_support_commitments (
 application_id uuid primary key references public.applications(id) on delete restrict,
 scholarship_id uuid not null references public.scholarships(id) on delete restrict,
 student_id uuid not null references public.profiles(id) on delete restrict,
 amount_cents bigint not null check(amount_cents between 1 and 100000000000),
 next_due_on date,
 recorded_by uuid not null references public.profiles(id),
 recorded_at timestamptz not null default now()
);
create table public.individual_support_payments (
 id uuid primary key default gen_random_uuid(),
 application_id uuid not null references public.individual_support_commitments(application_id) on delete restrict,
 amount_cents bigint not null check(amount_cents between 1 and 100000000000),
 method text not null check(method in ('bank','gcash','maya','school','official_venue')),
 reference text not null check(length(trim(reference)) between 1 and 100),
 sent_at timestamptz not null default now(),
 recorded_by uuid not null references public.profiles(id),
 received_at timestamptz,
 unique(application_id,reference)
);
alter table public.individual_support_budgets enable row level security;
alter table public.individual_support_commitments enable row level security;
alter table public.individual_support_payments enable row level security;
revoke all on public.individual_support_budgets,public.individual_support_commitments,public.individual_support_payments from anon,authenticated;
grant select on public.individual_support_budgets,public.individual_support_commitments,public.individual_support_payments to authenticated;
create policy support_budget_owner_read on public.individual_support_budgets for select to authenticated using(public.owns_individual_support(scholarship_id));
create policy support_commitment_read on public.individual_support_commitments for select to authenticated using(student_id=auth.uid() or public.owns_individual_support(scholarship_id));
create policy support_payment_read on public.individual_support_payments for select to authenticated using(exists(select 1 from public.individual_support_commitments c where c.application_id=individual_support_payments.application_id and (c.student_id=auth.uid() or public.owns_individual_support(c.scholarship_id))));

create function public.save_individual_support_budget(p_scholarship uuid,p_label text,p_cents bigint) returns void
language plpgsql security definer set search_path='' as $$
begin
 if not public.owns_individual_support(p_scholarship) then raise exception 'Support workspace unavailable' using errcode='42501'; end if;
 -- Lock the same parent used by approval and commitment writes.
 perform 1 from public.scholarships where id=p_scholarship for update;
 insert into public.individual_support_budgets(scholarship_id,cycle_label,budget_cents) values(p_scholarship,trim(p_label),p_cents)
 on conflict(scholarship_id) do update set cycle_label=excluded.cycle_label,budget_cents=excluded.budget_cents,updated_at=now();
end; $$;

create function public.record_individual_support_commitment(p_application uuid,p_cents bigint) returns void
language plpgsql security definer set search_path='' as $$
declare a public.applications;
begin
 select * into a from public.applications where id=p_application for update;
 if not found or not public.owns_individual_support(a.scholarship_id) then raise exception 'Application unavailable' using errcode='42501'; end if;
 perform 1 from public.scholarships where id=a.scholarship_id for update;
 if a.status not in ('approved','awarded') then raise exception 'Only approved support can be recorded'; end if;
 insert into public.individual_support_commitments(application_id,scholarship_id,student_id,amount_cents,recorded_by)
 values(a.id,a.scholarship_id,a.user_id,p_cents,auth.uid());
end; $$;

-- Capture new approval amounts once. Never recalculate them after listing edits.
create function public.capture_individual_support_commitment() returns trigger
language plpgsql security definer set search_path='' as $$
declare v_amount numeric; v_owner uuid;
begin
 if new.status='approved' and old.status is distinct from new.status then
  select s.amount,s.created_by into v_amount,v_owner from public.scholarships s join public.profiles p on p.id=s.created_by where s.id=new.scholarship_id and p.provider_type='individual' and p.role='provider';
  if v_amount>0 and v_amount*100<=100000000000 then
   insert into public.individual_support_commitments(application_id,scholarship_id,student_id,amount_cents,recorded_by)
   values(new.id,new.scholarship_id,new.user_id,round(v_amount*100)::bigint,coalesce(auth.uid(),v_owner)) on conflict do nothing;
  end if;
 end if;
 return new;
end; $$;
create trigger capture_individual_support_after_approval after update of status on public.applications for each row execute function public.capture_individual_support_commitment();

create function public.record_individual_support_payment(p_application uuid,p_cents bigint,p_method text,p_reference text) returns void
language plpgsql security definer set search_path='' as $$
declare c public.individual_support_commitments; v_sent bigint;
begin
 select * into c from public.individual_support_commitments where application_id=p_application for update;
 if not found or not public.owns_individual_support(c.scholarship_id) then raise exception 'Support record unavailable' using errcode='42501'; end if;
 select coalesce(sum(amount_cents),0) into v_sent from public.individual_support_payments where application_id=p_application;
 if p_cents is null or p_cents<=0 or v_sent+p_cents>c.amount_cents then raise exception 'Amount exceeds outstanding support'; end if;
 insert into public.individual_support_payments(application_id,amount_cents,method,reference,recorded_by) values(p_application,p_cents,p_method,trim(p_reference),auth.uid());
 insert into public.notifications(user_id,title,message,target_id,type) values(c.student_id,'Support marked as sent','Your provider recorded a payment. Confirm receipt only after checking your own account or school receipt.',p_application::text,'application_update');
end; $$;

create function public.schedule_individual_support(p_application uuid,p_due date) returns void
language plpgsql security definer set search_path='' as $$
declare c public.individual_support_commitments;
begin
 select * into c from public.individual_support_commitments where application_id=p_application for update;
 if not found or not public.owns_individual_support(c.scholarship_id) then raise exception 'Support record unavailable' using errcode='42501'; end if;
 update public.individual_support_commitments set next_due_on=p_due where application_id=p_application;
end; $$;
revoke all on function public.schedule_individual_support(uuid,date) from public,anon;
grant execute on function public.schedule_individual_support(uuid,date) to authenticated;

create function public.confirm_individual_support_receipt(p_payment uuid) returns void
language plpgsql security definer set search_path='' as $$
declare v_student uuid;
begin
 select c.student_id into v_student from public.individual_support_payments p join public.individual_support_commitments c on c.application_id=p.application_id where p.id=p_payment;
 if v_student is distinct from auth.uid() or auth.uid() is null then raise exception 'Payment unavailable' using errcode='42501'; end if;
 update public.individual_support_payments set received_at=now() where id=p_payment and received_at is null;
end; $$;

revoke all on function public.save_individual_support_budget(uuid,text,bigint), public.record_individual_support_commitment(uuid,bigint),public.record_individual_support_payment(uuid,bigint,text,text),public.confirm_individual_support_receipt(uuid),public.capture_individual_support_commitment() from public,anon;
grant execute on function public.save_individual_support_budget(uuid,text,bigint), public.record_individual_support_commitment(uuid,bigint),public.record_individual_support_payment(uuid,bigint,text,text),public.confirm_individual_support_receipt(uuid) to authenticated;
-- Append-only audit metadata; no account credentials or transaction references.
create table public.individual_support_events (
 id bigint generated always as identity primary key,
 scholarship_id uuid not null references public.scholarships(id),
 actor_id uuid references public.profiles(id),
 event_type text not null,
 recorded_at timestamptz not null default now()
);
alter table public.individual_support_events enable row level security;
revoke all on public.individual_support_events from anon,authenticated;
grant select on public.individual_support_events to authenticated;
create policy support_events_owner_read on public.individual_support_events for select to authenticated using(public.owns_individual_support(scholarship_id));
create function public.audit_individual_support() returns trigger language plpgsql security definer set search_path='' as $$
declare v_scholarship uuid;
begin
 if tg_table_name='individual_support_payments' then
  select scholarship_id into v_scholarship from public.individual_support_commitments where application_id=new.application_id;
 else v_scholarship:=new.scholarship_id; end if;
 insert into public.individual_support_events(scholarship_id,actor_id,event_type) values(v_scholarship,auth.uid(),tg_table_name || ':' || lower(tg_op));
 return new;
end; $$;
revoke all on function public.audit_individual_support() from public,anon,authenticated;
create trigger support_budget_audit after insert or update on public.individual_support_budgets for each row execute function public.audit_individual_support();
create trigger support_commitment_audit after insert or update on public.individual_support_commitments for each row execute function public.audit_individual_support();
create trigger support_payment_audit after insert or update on public.individual_support_payments for each row execute function public.audit_individual_support();
commit;



