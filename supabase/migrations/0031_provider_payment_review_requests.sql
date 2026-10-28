begin;
alter table public.support_concerns drop constraint support_concerns_category_check;
alter table public.support_concerns add constraint support_concerns_category_check check(category in ('payment_not_received','unsafe_request','release_fee','other','payment_record_correction'));
alter table public.support_concerns add column payment_id uuid references public.individual_support_payments(id) on delete restrict;
alter table public.support_concerns add constraint provider_correction_requires_payment check(category <> 'payment_record_correction' or payment_id is not null);
create function public.request_support_payment_review(p_payment uuid,p_description text) returns uuid
language plpgsql security definer set search_path='' as $$
declare p public.individual_support_payments; c public.individual_support_commitments; v_id uuid;
begin
 select * into p from public.individual_support_payments where id=p_payment;
 select * into c from public.individual_support_commitments where application_id=p.application_id;
 if not public.owns_individual_support(c.scholarship_id) then raise exception 'Payment unavailable' using errcode='42501'; end if;
 if p.received_at is null or p.voided_at is not null then raise exception 'Only confirmed records need platform correction review'; end if;
 insert into public.support_concerns(application_id,reporter_id,category,description,payment_id) values(c.application_id,auth.uid(),'payment_record_correction',trim(p_description),p.id) returning id into v_id;
 insert into public.notifications(user_id,title,message,target_id,type) select id,'Payment correction requested','A provider requested review of a student-confirmed payment record.',v_id::text,'application_update' from public.profiles where role='admin' and status='active';
 return v_id;
end; $$;
revoke all on function public.request_support_payment_review(uuid,text) from public,anon;
grant execute on function public.request_support_payment_review(uuid,text) to authenticated;
commit;

