-- Payment corrections and private student support concerns. No funds are moved.
begin;
create function public.is_support_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=auth.uid() and role='admin' and status='active');
$$;
revoke all on function public.is_support_admin() from public,anon;
grant execute on function public.is_support_admin() to authenticated;

alter table public.individual_support_payments add column voided_at timestamptz,add column void_reason text,add column voided_by uuid references public.profiles(id);
alter table public.individual_support_payments add constraint valid_support_correction check((voided_at is null and void_reason is null and voided_by is null) or (voided_at is not null and length(trim(void_reason)) between 5 and 500 and voided_by is not null));
create policy support_payment_admin_read on public.individual_support_payments for select to authenticated using(public.is_support_admin());
create policy support_commitment_admin_read on public.individual_support_commitments for select to authenticated using(public.is_support_admin());

create function public.void_individual_support_payment(p_payment uuid,p_reason text) returns void
language plpgsql security definer set search_path='' as $$
declare p public.individual_support_payments; c public.individual_support_commitments;
begin
 select * into p from public.individual_support_payments where id=p_payment for update;
 if not found then raise exception 'Payment unavailable' using errcode='42501'; end if;
 select * into c from public.individual_support_commitments where application_id=p.application_id for update;
 if not public.owns_individual_support(c.scholarship_id) and not public.is_support_admin() then raise exception 'Payment unavailable' using errcode='42501'; end if;
 if p.voided_at is not null then return; end if;
 if p.received_at is not null and not public.is_support_admin() then raise exception 'Student-confirmed records require platform review'; end if;
 if p_reason is null or length(trim(p_reason)) not between 5 and 500 then raise exception 'A correction reason is required'; end if;
 update public.individual_support_payments set voided_at=now(),void_reason=trim(p_reason),voided_by=auth.uid() where id=p_payment;
 insert into public.notifications(user_id,title,message,target_id,type) values(c.student_id,'Support record corrected','A payment record was marked as entered in error. Its history remains available. This does not mean a refund or transfer occurred.',p.application_id::text,'application_update');
end; $$;

create or replace function public.confirm_individual_support_receipt(p_payment uuid) returns void
language plpgsql security definer set search_path='' as $$
declare p public.individual_support_payments; v_student uuid;
begin
 select * into p from public.individual_support_payments where id=p_payment for update;
 select student_id into v_student from public.individual_support_commitments where application_id=p.application_id;
 if v_student is distinct from auth.uid() or auth.uid() is null then raise exception 'Payment unavailable' using errcode='42501'; end if;
 if p.voided_at is not null then raise exception 'This payment record has been corrected'; end if;
 update public.individual_support_payments set received_at=now() where id=p_payment and received_at is null;
end; $$;

create or replace function public.record_individual_support_payment(p_application uuid,p_cents bigint,p_method text,p_reference text) returns void
language plpgsql security definer set search_path='' as $$
declare c public.individual_support_commitments; v_sent bigint;
begin
 select * into c from public.individual_support_commitments where application_id=p_application for update;
 if not found or not public.owns_individual_support(c.scholarship_id) then raise exception 'Support record unavailable' using errcode='42501'; end if;
 select coalesce(sum(amount_cents),0) into v_sent from public.individual_support_payments where application_id=p_application and voided_at is null;
 if p_cents is null or p_cents<=0 or v_sent+p_cents>c.amount_cents then raise exception 'Amount exceeds outstanding support'; end if;
 insert into public.individual_support_payments(application_id,amount_cents,method,reference,recorded_by) values(p_application,p_cents,p_method,trim(p_reference),auth.uid());
 insert into public.notifications(user_id,title,message,target_id,type) values(c.student_id,'Support marked as sent','Your provider recorded a payment. Confirm receipt only after checking your own account or school receipt.',p_application::text,'application_update');
end; $$;

create table public.support_concerns (
 id uuid primary key default gen_random_uuid(),
 application_id uuid not null references public.applications(id) on delete restrict,
 reporter_id uuid not null references public.profiles(id) on delete restrict,
 category text not null check(category in ('payment_not_received','unsafe_request','release_fee','other')),
 description text not null check(length(trim(description)) between 10 and 2000),
 status text not null default 'open' check(status in ('open','under_review','resolved','dismissed')),
 resolution_note text,
 reviewed_by uuid references public.profiles(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create unique index one_open_support_concern on public.support_concerns(application_id,reporter_id,category) where status in ('open','under_review');
alter table public.support_concerns enable row level security;
revoke all on public.support_concerns from anon,authenticated;
grant select on public.support_concerns to authenticated;
create policy private_support_concern_read on public.support_concerns for select to authenticated using(reporter_id=auth.uid() or public.is_support_admin());

create function public.report_support_concern(p_application uuid,p_category text,p_description text) returns uuid
language plpgsql security definer set search_path='' as $$
declare a public.applications; v_id uuid;
begin
 select * into a from public.applications where id=p_application for update;
 if not found or auth.uid() is null or a.user_id is distinct from auth.uid() or a.status='draft' then raise exception 'Application unavailable' using errcode='42501'; end if;
 insert into public.support_concerns(application_id,reporter_id,category,description) values(a.id,auth.uid(),p_category,trim(p_description)) returning id into v_id;
 insert into public.notifications(user_id,title,message,target_id,type)
 select id,'Student support concern','A private student concern is waiting in the Support concerns queue.',v_id::text,'application_update' from public.profiles where role='admin' and status='active';
 return v_id;
end; $$;

create function public.review_support_concern(p_concern uuid,p_status text,p_note text) returns void
language plpgsql security definer set search_path='' as $$
declare c public.support_concerns;
begin
 if not public.is_support_admin() then raise exception 'Admin access required' using errcode='42501'; end if;
 select * into c from public.support_concerns where id=p_concern for update;
 if not found then raise exception 'Concern unavailable'; end if;
 if p_status is null or p_status not in ('under_review','resolved','dismissed') then raise exception 'Invalid review status'; end if;
 if p_note is null or length(trim(p_note)) not between 10 and 1000 then raise exception 'A clear update for the student is required'; end if;
 if c.status in ('resolved','dismissed') then raise exception 'This concern is already closed'; end if;
 update public.support_concerns set status=p_status,resolution_note=trim(p_note),reviewed_by=auth.uid(),updated_at=now() where id=p_concern;
 insert into public.notifications(user_id,title,message,target_id,type) values(c.reporter_id,'Support concern updated','An administrator updated your support concern. Open the application to read their update.',c.application_id::text,'application_update');
end; $$;
revoke all on function public.void_individual_support_payment(uuid,text),public.report_support_concern(uuid,text,text),public.review_support_concern(uuid,text,text) from public,anon;
grant execute on function public.void_individual_support_payment(uuid,text),public.report_support_concern(uuid,text,text),public.review_support_concern(uuid,text,text) to authenticated;
create table public.support_concern_history (
 id bigint generated always as identity primary key,
 concern_id uuid not null references public.support_concerns(id) on delete restrict,
 status text not null,
 note text,
 actor_id uuid references public.profiles(id),
 created_at timestamptz not null default now()
);
alter table public.support_concern_history enable row level security;
revoke all on public.support_concern_history from anon,authenticated;
grant select on public.support_concern_history to authenticated;
create policy private_support_history_read on public.support_concern_history for select to authenticated using(exists(select 1 from public.support_concerns c where c.id=concern_id and (c.reporter_id=auth.uid() or public.is_support_admin())));
create function public.audit_support_concern() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.support_concern_history(concern_id,status,note,actor_id) values(new.id,new.status,new.resolution_note,auth.uid());
 return new;
end; $$;
revoke all on function public.audit_support_concern() from public,anon,authenticated;
create trigger private_support_concern_audit after insert or update on public.support_concerns for each row execute function public.audit_support_concern();
commit;

