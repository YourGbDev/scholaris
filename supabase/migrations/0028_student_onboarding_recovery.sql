-- Independent of 0027. Preserve existing grades and the provider view's exact access.
begin;
set local lock_timeout = '5s';

-- PostgreSQL cannot widen a column while a view depends on it.
create temporary table onboarding_saved_views on commit drop as
select distinct c.oid, n.nspname, c.relname, c.relowner, c.relacl,
       c.reloptions, pg_get_viewdef(c.oid, true) as definition,
       obj_description(c.oid) as description
from pg_depend d
join pg_rewrite r on r.oid = d.objid
join pg_class c on c.oid = r.ev_class
join pg_namespace n on n.oid = c.relnamespace
where d.refobjid = 'public.profiles'::regclass
  and d.refobjsubid = (select attnum from pg_attribute
    where attrelid = 'public.profiles'::regclass and attname = 'gpa');

do $$
declare v record;
begin
  for v in select * from onboarding_saved_views loop
    if v.nspname <> 'public' or v.relname <> 'provider_applicant_profiles'
       or exists(select 1 from pg_attribute where attrelid=v.oid and attnum>0
         and (attacl is not null or col_description(attrelid,attnum) is not null))
       or exists(select 1 from aclexplode(coalesce(v.relacl,acldefault('r',v.relowner)))
         where grantor<>v.relowner) then
      raise exception 'Unexpected dependent view metadata; migration requires review';
    end if;
    -- No CASCADE: unexpected downstream dependencies safely abort the transaction.
    execute format('drop view %I.%I', v.nspname,v.relname);
  end loop;
end $$;

alter table public.profiles alter column gpa type numeric(5,2);
alter table public.profiles add column if not exists gpa_scale text;
alter table public.profiles add column if not exists profile_setup_step smallint not null default 1;
alter table public.profiles add constraint profiles_gpa_scale_valid
  check (gpa_scale is null or gpa_scale in ('four_point','five_point','percentage'));
alter table public.profiles add constraint profiles_setup_step_valid
  check (profile_setup_step between 1 and 3);

do $$
declare v record; a record; role_name text; new_acl aclitem[];
begin
  for v in select * from onboarding_saved_views loop
    execute format('create view %I.%I %s as %s',v.nspname,v.relname,
      case when v.reloptions is null then '' else
        'with ('||array_to_string(v.reloptions,',')||')' end,v.definition);
    execute format('alter view %I.%I owner to %I',v.nspname,v.relname,pg_get_userbyid(v.relowner));
    -- Remove CREATE-time default grants before restoring the original ACL.
    select relacl into new_acl from pg_class where oid=format('%I.%I',v.nspname,v.relname)::regclass;
    for a in select distinct grantee from aclexplode(new_acl) loop
      role_name := case when a.grantee=0 then 'PUBLIC' else quote_ident(pg_get_userbyid(a.grantee)) end;
      execute format('revoke all on %I.%I from %s',v.nspname,v.relname,role_name);
    end loop;
    for a in select * from aclexplode(coalesce(v.relacl,acldefault('r',v.relowner))) loop
      role_name := case when a.grantee=0 then 'PUBLIC' else quote_ident(pg_get_userbyid(a.grantee)) end;
      execute format('grant %s on %I.%I to %s%s',a.privilege_type,v.nspname,v.relname,
        role_name,case when a.is_grantable then ' with grant option' else '' end);
    end loop;
    execute format('comment on view %I.%I is %L',v.nspname,v.relname,v.description);
    if exists(
      (select * from aclexplode(coalesce(v.relacl,acldefault('r',v.relowner)))
       except select * from aclexplode((select relacl from pg_class where oid=format('%I.%I',v.nspname,v.relname)::regclass)))
      union all
      (select * from aclexplode((select relacl from pg_class where oid=format('%I.%I',v.nspname,v.relname)::regclass))
       except select * from aclexplode(coalesce(v.relacl,acldefault('r',v.relowner))))
    ) then raise exception 'View ACL mismatch; rolling back'; end if;
  end loop;
end $$;
commit;
