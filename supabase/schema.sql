-- NEPCOLLAB production schema: run once in Supabase SQL Editor.
-- Launch model: zero publishing fee; manual creator payout.
create extension if not exists pgcrypto;

create table if not exists profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 role text not null default 'creator' check(role in ('creator','brand','admin')),
 full_name text not null default 'New user', username text unique, avatar_url text, bio text,
 location text default 'Pokhara, Nepal', verified boolean default false,
 verification_status text not null default 'unverified' check(verification_status in ('unverified','pending','verified','rejected')),
 rating numeric(3,2) not null default 0, review_count int not null default 0,
 completion_rate numeric(5,2) not null default 100, response_rate numeric(5,2) not null default 100,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists creator_profiles (
 user_id uuid primary key references profiles(id) on delete cascade,
 niches text[] not null default '{}', platforms text[] not null default '{Instagram}', followers int not null default 0,
 engagement_rate numeric(6,2) not null default 0, average_views int not null default 0, starting_rate int not null default 0,
 languages text[] not null default '{Nepali,English}', portfolio_urls text[] not null default '{}', availability text not null default 'available',
 media_kit_url text, social_verified boolean not null default false, updated_at timestamptz not null default now()
);
create table if not exists brand_profiles (
 user_id uuid primary key references profiles(id) on delete cascade,
 business_name text not null, category text, website text, social_url text, registration_number text,
 payment_reliability numeric(5,2) not null default 100, team_size int not null default 1, updated_at timestamptz not null default now()
);
create table if not exists social_accounts (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id) on delete cascade,
 platform text not null, handle text not null, profile_url text, followers int not null default 0, engagement_rate numeric(6,2) not null default 0,
 verified boolean not null default false, access_token_encrypted text, created_at timestamptz not null default now(), unique(user_id,platform,handle)
);

create table if not exists campaigns (
 id uuid primary key default gen_random_uuid(), brand_id uuid not null references profiles(id) on delete cascade,
 title text not null, objective text, category text not null, type text not null check(type in ('paid','gift')),
 budget int not null default 0 check(budget>=0), creator_reward int not null default 0 check(creator_reward>=0), currency text not null default 'NPR',
 location text, platforms text[] not null default '{Instagram}', deliverables text[] not null default '{1 Reel}', requirements jsonb not null default '{}'::jsonb,
 usage_rights text, exclusivity_days int not null default 0, revision_limit int not null default 1 check(revision_limit>=0), brief text,
 reference_urls text[] not null default '{}', image_url text, min_followers int not null default 0, deadline date,
 status text not null default 'draft' check(status in ('draft','pending_payment','active','paused','closed','completed','cancelled')),
 visibility text not null default 'public' check(visibility in ('public','invite_only')), views int not null default 0, saves int not null default 0,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists campaign_invites (
 id uuid primary key default gen_random_uuid(), campaign_id uuid not null references campaigns(id) on delete cascade,
 creator_id uuid not null references profiles(id) on delete cascade, status text not null default 'sent' check(status in ('sent','viewed','accepted','declined','expired')),
 created_at timestamptz not null default now(), unique(campaign_id,creator_id)
);
create table if not exists applications (
 id uuid primary key default gen_random_uuid(), campaign_id uuid not null references campaigns(id) on delete cascade,
 creator_id uuid not null references profiles(id) on delete cascade, message text, proposed_rate int,
 status text not null default 'pending' check(status in ('pending','accepted','rejected','withdrawn','active','submitted','revision','completed','cancelled')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(campaign_id,creator_id)
);
create table if not exists deliverables (
 id uuid primary key default gen_random_uuid(), application_id uuid not null references applications(id) on delete cascade,
 title text not null, kind text not null default 'reel', due_at timestamptz,
 status text not null default 'pending' check(status in ('pending','submitted','revision','approved','paid')), created_at timestamptz not null default now()
);
create table if not exists submissions (
 id uuid primary key default gen_random_uuid(), deliverable_id uuid references deliverables(id) on delete cascade,
 application_id uuid not null references applications(id) on delete cascade, creator_id uuid not null references profiles(id) on delete cascade,
 url text not null, caption text, analytics jsonb not null default '{}'::jsonb,
 status text not null default 'submitted' check(status in ('submitted','revision','approved','rejected')),
 feedback text, revision_number int not null default 0, created_at timestamptz not null default now()
);
create table if not exists conversations (
 id uuid primary key default gen_random_uuid(), campaign_id uuid references campaigns(id) on delete cascade,
 application_id uuid references applications(id) on delete cascade, created_at timestamptz not null default now()
);
create table if not exists conversation_members (
 conversation_id uuid not null references conversations(id) on delete cascade, user_id uuid not null references profiles(id) on delete cascade,
 last_read_at timestamptz, primary key(conversation_id,user_id)
);
create table if not exists messages (
 id uuid primary key default gen_random_uuid(), conversation_id uuid not null references conversations(id) on delete cascade,
 sender_id uuid not null references profiles(id) on delete cascade, body text not null check(length(trim(body))>0 and length(body)<=5000), attachment_url text,
 created_at timestamptz not null default now()
);
create table if not exists saved_campaigns (user_id uuid references profiles(id) on delete cascade,campaign_id uuid references campaigns(id) on delete cascade,created_at timestamptz default now(),primary key(user_id,campaign_id));
create table if not exists reviews (
 id uuid primary key default gen_random_uuid(), campaign_id uuid not null references campaigns(id) on delete cascade,
 application_id uuid not null references applications(id) on delete cascade, reviewer_id uuid not null references profiles(id) on delete cascade,
 reviewee_id uuid not null references profiles(id) on delete cascade, rating int not null check(rating between 1 and 5), comment text,
 created_at timestamptz not null default now(), unique(application_id,reviewer_id)
);
create table if not exists wallets (user_id uuid primary key references profiles(id) on delete cascade,available int not null default 0 check(available>=0),pending int not null default 0 check(pending>=0),lifetime_earned int not null default 0,lifetime_spent int not null default 0,updated_at timestamptz default now());

create table if not exists transactions (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id) on delete cascade,
 campaign_id uuid references campaigns(id) on delete set null, application_id uuid references applications(id) on delete set null,
 type text not null check(type in ('creator_payout','brand_funding','refund','platform_fee','adjustment')), amount int not null,
 provider text, provider_reference text, status text not null default 'pending' check(status in ('pending','processing','paid','failed','refunded','cancelled')),
 metadata jsonb not null default '{}', created_at timestamptz not null default now(), paid_at timestamptz
);

create unique index if not exists creator_payout_once_idx on transactions(application_id) where type='creator_payout';
create table if not exists payout_methods (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id) on delete cascade,
 method text not null check(method in ('esewa','khalti','bank')), account_name text, account_identifier text, verified boolean not null default false, created_at timestamptz default now()
);
create table if not exists disputes (
 id uuid primary key default gen_random_uuid(), campaign_id uuid not null references campaigns(id) on delete cascade, application_id uuid not null references applications(id) on delete cascade,
 opened_by uuid not null references profiles(id) on delete cascade, reason text not null, evidence_urls text[] default '{}',
 status text not null default 'open' check(status in ('open','investigating','resolved_creator','resolved_brand','closed')), resolution text, created_at timestamptz default now(), resolved_at timestamptz
);
create table if not exists reports (
 id uuid primary key default gen_random_uuid(), reporter_id uuid not null references profiles(id) on delete cascade, target_type text not null, target_id uuid not null,
 reason text not null, details text, status text not null default 'open' check(status in ('open','reviewing','resolved','dismissed')), created_at timestamptz default now()
);
create table if not exists verification_requests (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id) on delete cascade, type text not null check(type in ('creator','brand','social')),
 documents jsonb default '[]', status text not null default 'pending' check(status in ('pending','approved','rejected')), notes text,
 reviewed_by uuid references profiles(id), created_at timestamptz default now(), reviewed_at timestamptz
);
create table if not exists notifications (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id) on delete cascade,
 type text not null default 'system', title text not null, body text not null, data jsonb not null default '{}', read_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists referrals (
 id uuid primary key default gen_random_uuid(), referrer_id uuid not null references profiles(id) on delete cascade, referred_id uuid references profiles(id) on delete set null,
 code text not null, status text not null default 'pending', created_at timestamptz default now()
);
create table if not exists audit_logs (
 id uuid primary key default gen_random_uuid(), actor_id uuid references profiles(id) on delete set null, action text not null, entity_type text not null, entity_id uuid, metadata jsonb default '{}', created_at timestamptz default now()
);
create table if not exists platform_settings (key text primary key,value text not null,updated_at timestamptz default now());
insert into platform_settings(key,value) values ('monetization','0'),('marketplace_status','launch'),('social_verification_admin','@nepcollab.app') on conflict(key) do nothing;

create or replace function public.is_admin() returns boolean language sql security definer set search_path=public stable as $$ select exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin') $$;
create or replace function public.is_campaign_brand(cid uuid) returns boolean language sql security definer set search_path=public stable as $$ select exists(select 1 from public.campaigns c where c.id=cid and c.brand_id=auth.uid()) $$;
create or replace function public.is_application_participant(aid uuid) returns boolean language sql security definer set search_path=public stable as $$ select exists(select 1 from public.applications a join public.campaigns c on c.id=a.campaign_id where a.id=aid and (a.creator_id=auth.uid() or c.brand_id=auth.uid())) $$;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,full_name,role) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',split_part(coalesce(new.email,''),'@',1),'New user'),case when new.raw_user_meta_data->>'role'='brand' then 'brand' else 'creator' end) on conflict(id) do nothing;
 insert into public.creator_profiles(user_id) values(new.id) on conflict do nothing;
 insert into public.wallets(user_id) values(new.id) on conflict do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();



create or replace function public.notify_collaboration_events() returns trigger language plpgsql security definer set search_path=public as $$
declare brand_id uuid; campaign_title text;
begin
 if TG_TABLE_NAME='applications' then
  select c.brand_id,c.title into brand_id,campaign_title from campaigns c where c.id=new.campaign_id;
  if TG_OP='INSERT' then insert into notifications(user_id,type,title,body,data) values(brand_id,'application','New creator application',format('%s applied to %s.',(select full_name from profiles where id=new.creator_id),campaign_title),jsonb_build_object('application_id',new.id));
  elsif new.status='accepted' and old.status is distinct from 'accepted' then insert into notifications(user_id,type,title,body,data) values(new.creator_id,'application','Application accepted',format('Your application for %s was accepted.',campaign_title),jsonb_build_object('application_id',new.id)); end if;
 elsif TG_TABLE_NAME='submissions' then
  select c.brand_id,c.title into brand_id,campaign_title from applications a join campaigns c on c.id=a.campaign_id where a.id=new.application_id;
  if TG_OP='INSERT' then insert into notifications(user_id,type,title,body,data) values(brand_id,'submission','New content submitted',format('%s submitted content for %s.',(select full_name from profiles where id=new.creator_id),campaign_title),jsonb_build_object('submission_id',new.id)); end if;
 end if; return new; end; $$;
drop trigger if exists application_notifications on applications;
create trigger application_notifications after insert or update of status on applications for each row execute function public.notify_collaboration_events();
drop trigger if exists submission_notifications on submissions;
create trigger submission_notifications after insert on submissions for each row execute function public.notify_collaboration_events();


create or replace function public.prevent_admin_escalation() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if old.role <> 'admin' and new.role='admin' then raise exception 'Only a protected admin SQL session can grant admin role'; end if;
 return new;
end; $$;
drop trigger if exists prevent_admin_escalation_trigger on profiles;
create trigger prevent_admin_escalation_trigger before update on profiles for each row execute function public.prevent_admin_escalation();

create or replace function public.apply_creator_payout_to_wallet() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.type='creator_payout' and new.status='paid' and (TG_OP='INSERT' or old.status is distinct from 'paid') then update wallets set available=available+new.amount,lifetime_earned=lifetime_earned+new.amount,updated_at=now() where user_id=new.user_id; end if; return new; end; $$;
drop trigger if exists creator_payout_wallet_trigger on transactions;
create trigger creator_payout_wallet_trigger after update or insert on transactions for each row execute function public.apply_creator_payout_to_wallet();
create or replace function public.update_review_stats() returns trigger language plpgsql security definer set search_path=public as $$
begin update profiles set rating=(select round(avg(rating)::numeric,2) from reviews where reviewee_id=new.reviewee_id),review_count=(select count(*) from reviews where reviewee_id=new.reviewee_id),updated_at=now() where id=new.reviewee_id; return new; end; $$;
drop trigger if exists review_stats_trigger on reviews; create trigger review_stats_trigger after insert on reviews for each row execute function public.update_review_stats();

alter table profiles enable row level security;
alter table creator_profiles enable row level security; alter table brand_profiles enable row level security; alter table social_accounts enable row level security;
alter table campaigns enable row level security; alter table campaign_invites enable row level security; alter table applications enable row level security;
alter table deliverables enable row level security; alter table submissions enable row level security; alter table conversations enable row level security; alter table conversation_members enable row level security; alter table messages enable row level security;
alter table saved_campaigns enable row level security; alter table reviews enable row level security; alter table wallets enable row level security; alter table transactions enable row level security; alter table payout_methods enable row level security;
alter table disputes enable row level security; alter table reports enable row level security; alter table verification_requests enable row level security; alter table notifications enable row level security; alter table referrals enable row level security; alter table audit_logs enable row level security; alter table platform_settings enable row level security;

drop policy if exists "profiles_read" on profiles;
drop policy if exists "profiles_insert" on profiles;
drop policy if exists "profiles_update" on profiles;
drop policy if exists "creator_profile_read" on creator_profiles;
drop policy if exists "creator_profile_write" on creator_profiles;
drop policy if exists "brand_profile_read" on brand_profiles;
drop policy if exists "brand_profile_write" on brand_profiles;
drop policy if exists "social_read" on social_accounts;
drop policy if exists "social_write" on social_accounts;
drop policy if exists "campaign_read" on campaigns;
drop policy if exists "campaign_insert" on campaigns;
drop policy if exists "campaign_update" on campaigns;
drop policy if exists "campaign_delete" on campaigns;
drop policy if exists "invite_read" on campaign_invites;
drop policy if exists "invite_write" on campaign_invites;
drop policy if exists "app_read" on applications;
drop policy if exists "app_insert" on applications;
drop policy if exists "app_update" on applications;
drop policy if exists "deliverable_read" on deliverables;
drop policy if exists "deliverable_write" on deliverables;
drop policy if exists "submission_read" on submissions;
drop policy if exists "submission_write" on submissions;
drop policy if exists "submission_update" on submissions;
drop policy if exists "conv_read" on conversations;
drop policy if exists "conv_write" on conversations;
drop policy if exists "conv_member_read" on conversation_members;
drop policy if exists "conv_member_write" on conversation_members;
drop policy if exists "message_read" on messages;
drop policy if exists "message_insert" on messages;
drop policy if exists "saved_all" on saved_campaigns;
drop policy if exists "review_read" on reviews;
drop policy if exists "review_insert" on reviews;
drop policy if exists "wallet_read" on wallets;
drop policy if exists "tx_read" on transactions;
drop policy if exists "payout_read" on payout_methods;
drop policy if exists "payout_write" on payout_methods;
drop policy if exists "dispute_read" on disputes;
drop policy if exists "dispute_insert" on disputes;
drop policy if exists "dispute_update" on disputes;
drop policy if exists "report_read" on reports;
drop policy if exists "report_insert" on reports;
drop policy if exists "report_update" on reports;
drop policy if exists "verify_read" on verification_requests;
drop policy if exists "verify_insert" on verification_requests;
drop policy if exists "verify_update" on verification_requests;
drop policy if exists "notif_read" on notifications;
drop policy if exists "notif_update" on notifications;
drop policy if exists "referral_read" on referrals;
drop policy if exists "referral_insert" on referrals;
drop policy if exists "audit_admin" on audit_logs;
drop policy if exists "settings_read" on platform_settings;
drop policy if exists "settings_write" on platform_settings;
drop policy if exists profiles_read on profiles; create policy profiles_read on profiles for select using (true);
drop policy if exists profiles_insert on profiles; create policy profiles_insert on profiles for insert with check(auth.uid()=id);
drop policy if exists profiles_update on profiles; create policy profiles_update on profiles for update using(auth.uid()=id or public.is_admin()) with check(auth.uid()=id or public.is_admin());
create policy creator_profile_read on creator_profiles for select using(true); create policy creator_profile_write on creator_profiles for all using(auth.uid()=user_id or public.is_admin()) with check(auth.uid()=user_id or public.is_admin());
create policy brand_profile_read on brand_profiles for select using(auth.uid()=user_id or public.is_admin()); create policy brand_profile_write on brand_profiles for all using(auth.uid()=user_id or public.is_admin()) with check(auth.uid()=user_id or public.is_admin());
create policy social_read on social_accounts for select using(auth.uid()=user_id or public.is_admin()); create policy social_write on social_accounts for all using(auth.uid()=user_id or public.is_admin()) with check(auth.uid()=user_id or public.is_admin());
create policy campaign_read on campaigns for select using((status='active' and visibility='public') or brand_id=auth.uid() or public.is_admin()); create policy campaign_insert on campaigns for insert with check(auth.uid()=brand_id); create policy campaign_update on campaigns for update using(brand_id=auth.uid() or public.is_admin()) with check(brand_id=auth.uid() or public.is_admin()); create policy campaign_delete on campaigns for delete using(brand_id=auth.uid() or public.is_admin());
create policy invite_read on campaign_invites for select using(creator_id=auth.uid() or public.is_campaign_brand(campaign_id) or public.is_admin()); create policy invite_write on campaign_invites for all using(creator_id=auth.uid() or public.is_campaign_brand(campaign_id) or public.is_admin()) with check(creator_id=auth.uid() or public.is_campaign_brand(campaign_id) or public.is_admin());
create policy app_read on applications for select using(creator_id=auth.uid() or public.is_campaign_brand(campaign_id) or public.is_admin()); create policy app_insert on applications for insert with check(auth.uid()=creator_id and exists(select 1 from campaigns c where c.id=campaign_id and c.status='active')); create policy app_update on applications for update using(creator_id=auth.uid() or public.is_campaign_brand(campaign_id) or public.is_admin()) with check(creator_id=auth.uid() or public.is_campaign_brand(campaign_id) or public.is_admin());
create policy deliverable_read on deliverables for select using(public.is_application_participant(application_id) or public.is_admin()); create policy deliverable_write on deliverables for all using(public.is_application_participant(application_id) or public.is_admin()) with check(public.is_application_participant(application_id) or public.is_admin());
create policy submission_read on submissions for select using(creator_id=auth.uid() or exists(select 1 from applications a join campaigns c on c.id=a.campaign_id where a.id=submissions.application_id and c.brand_id=auth.uid()) or public.is_admin()); create policy submission_write on submissions for insert with check(auth.uid()=creator_id and exists(select 1 from applications a where a.id=application_id and a.creator_id=auth.uid() and a.status in ('accepted','active','revision'))); create policy submission_update on submissions for update using(creator_id=auth.uid() or public.is_campaign_brand((select a.campaign_id from applications a where a.id=application_id)) or public.is_admin()) with check(creator_id=auth.uid() or public.is_campaign_brand((select a.campaign_id from applications a where a.id=application_id)) or public.is_admin());
create policy conv_read on conversations for select using(exists(select 1 from conversation_members m where m.conversation_id=id and m.user_id=auth.uid()) or public.is_admin()); create policy conv_write on conversations for all using(public.is_admin() or exists(select 1 from conversation_members m where m.conversation_id=id and m.user_id=auth.uid())) with check(public.is_admin() or campaign_id is null or public.is_campaign_brand(campaign_id) or exists(select 1 from applications a where a.campaign_id=campaign_id and a.creator_id=auth.uid()));
create policy conv_member_read on conversation_members for select using(user_id=auth.uid() or public.is_admin()); create policy conv_member_write on conversation_members for all using(user_id=auth.uid() or public.is_admin()) with check(user_id=auth.uid() or public.is_admin());
create policy message_read on messages for select using(exists(select 1 from conversation_members m where m.conversation_id=messages.conversation_id and m.user_id=auth.uid()) or public.is_admin()); create policy message_insert on messages for insert with check(auth.uid()=sender_id and exists(select 1 from conversation_members m where m.conversation_id=messages.conversation_id and m.user_id=auth.uid()));
create policy saved_all on saved_campaigns for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy review_read on reviews for select using(true); create policy review_insert on reviews for insert with check(auth.uid()=reviewer_id and exists(select 1 from applications a where a.id=application_id and (a.creator_id=auth.uid() or exists(select 1 from campaigns c where c.id=a.campaign_id and c.brand_id=auth.uid()))));
create policy wallet_read on wallets for select using(user_id=auth.uid() or public.is_admin());
create policy tx_read on transactions for select using(user_id=auth.uid() or public.is_admin()); create policy tx_admin_insert on transactions for insert with check(public.is_admin()); create policy tx_admin_update on transactions for update using(public.is_admin()) with check(public.is_admin()); create policy payout_read on payout_methods for select using(user_id=auth.uid() or public.is_admin()); create policy payout_write on payout_methods for all using(user_id=auth.uid() or public.is_admin()) with check(user_id=auth.uid() or public.is_admin());
create policy dispute_read on disputes for select using(opened_by=auth.uid() or exists(select 1 from applications a join campaigns c on c.id=a.campaign_id where a.id=application_id and (a.creator_id=auth.uid() or c.brand_id=auth.uid())) or public.is_admin()); create policy dispute_insert on disputes for insert with check(auth.uid()=opened_by); create policy dispute_update on disputes for update using(public.is_admin());
create policy report_read on reports for select using(reporter_id=auth.uid() or public.is_admin()); create policy report_insert on reports for insert with check(auth.uid()=reporter_id); create policy report_update on reports for update using(public.is_admin());
create policy verify_read on verification_requests for select using(user_id=auth.uid() or public.is_admin()); create policy verify_insert on verification_requests for insert with check(user_id=auth.uid()); create policy verify_update on verification_requests for update using(public.is_admin());
create policy notif_read on notifications for select using(user_id=auth.uid()); create policy notif_update on notifications for update using(user_id=auth.uid());
create policy referral_read on referrals for select using(referrer_id=auth.uid() or referred_id=auth.uid() or public.is_admin()); create policy referral_insert on referrals for insert with check(referrer_id=auth.uid());
create policy audit_admin on audit_logs for select using(public.is_admin()); create policy settings_read on platform_settings for select using(true); create policy settings_write on platform_settings for all using(public.is_admin()) with check(public.is_admin());

-- Storage: create these buckets in Supabase Storage: avatars (public), campaign-media (public), submissions (private), verification-docs (private).
drop policy if exists tx_admin_insert on transactions; drop policy if exists tx_admin_update on transactions;

-- Storage buckets (safe to run in SQL Editor if storage schema is available).
insert into storage.buckets(id,name,public) values
 ('payment-proofs','payment-proofs',false),('avatars','avatars',true),('campaign-media','campaign-media',true),('submissions','submissions',false),('verification-docs','verification-docs',false)
on conflict(id) do update set public=excluded.public;

-- NepCollab launch additions: free marketplace, manual social verification, brand remarks, final admin work verification.
alter table applications add column if not exists brand_remarks text;
alter table submissions add column if not exists admin_verified boolean not null default false;
alter table submissions add column if not exists admin_verified_at timestamptz;
alter table submissions add column if not exists admin_verified_by uuid references profiles(id) on delete set null;

create index if not exists verification_requests_status_idx on verification_requests(status, created_at desc);
create index if not exists submissions_admin_review_idx on submissions(status, admin_verified, created_at desc);

create or replace function public.notify_admins_verification() returns trigger language plpgsql security definer set search_path=public as $$
declare doc jsonb;
begin
 doc := coalesce(new.documents->0, '{}'::jsonb);
 insert into notifications(user_id,type,title,body,data)
 select id,'verification','New social verification request',format('%s submitted %s verification for @%s. Code: %s', (select full_name from profiles where id=new.user_id), coalesce(doc->>'platform','social'), coalesce(doc->>'handle',''), coalesce(doc->>'verification_code','')),
 jsonb_build_object('verification_id',new.id,'user_id',new.user_id,'platform',doc->>'platform')
 from profiles where role='admin';
 return new;
end; $$;
drop trigger if exists verification_admin_notification on verification_requests;
create trigger verification_admin_notification after insert on verification_requests for each row execute function public.notify_admins_verification();

create or replace function public.notify_submission_admin_review() returns trigger language plpgsql security definer set search_path=public as $$
declare brand_id uuid; campaign_title text;
begin
 if new.status='approved' and old.status is distinct from 'approved' then
  select c.brand_id,c.title into brand_id,campaign_title from applications a join campaigns c on c.id=a.campaign_id where a.id=new.application_id;
  insert into notifications(user_id,type,title,body,data)
  select id,'submission','Work ready for final verification',format('Brand approved work for %s. Please verify and release the creator reward.',campaign_title),jsonb_build_object('submission_id',new.id,'application_id',new.application_id)
  from profiles where role='admin';
 end if;
 return new;
end; $$;
drop trigger if exists submission_admin_review_notification on submissions;
create trigger submission_admin_review_notification after update of status on submissions for each row execute function public.notify_submission_admin_review();

-- Social verification remains private to the owner/admin. Reviews are visible publicly.

-- Final launch hardening: safe admin bootstrap and transaction/reward writes.
drop trigger if exists prevent_admin_escalation_trigger on profiles;
drop function if exists public.prevent_admin_escalation();

drop policy if exists profiles_update on profiles;
create policy profiles_update on profiles for update
using (auth.uid()=id or public.is_admin())
with check ((auth.uid()=id and role <> 'admin') or public.is_admin());

create or replace function public.grant_admin(target uuid) returns void
language plpgsql security definer set search_path=public as $$
begin
  update public.profiles set role='admin', verified=true, verification_status='verified', updated_at=now() where id=target;
end; $$;
revoke execute on function public.grant_admin(uuid) from public, anon, authenticated;

drop policy if exists tx_admin_insert on transactions;
drop policy if exists tx_admin_update on transactions;
create policy tx_admin_insert on transactions for insert to authenticated with check(public.is_admin());
create policy tx_admin_update on transactions for update to authenticated using(public.is_admin()) with check(public.is_admin());

-- No launch campaign should ever be held for a platform fee.
drop policy if exists campaign_insert on campaigns;
create policy campaign_insert on campaigns for insert to authenticated with check(auth.uid()=brand_id and status='active');

-- Optional manual QR payment infrastructure. Launch defaults to free (NPR 0), so this stays dormant until enabled by admin.
create table if not exists payment_submissions (
 id uuid primary key default gen_random_uuid(),
 campaign_id uuid not null references campaigns(id) on delete cascade,
 brand_id uuid not null references profiles(id) on delete cascade,
 amount int not null check(amount>0),
 transaction_reference text not null,
 proof_path text not null,
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 notes text,
 reviewed_by uuid references profiles(id) on delete set null,
 reviewed_at timestamptz,
 created_at timestamptz not null default now()
);
create index if not exists payment_submissions_status_idx on payment_submissions(status,created_at desc);
alter table payment_submissions enable row level security;
drop policy if exists payment_read on payment_submissions;
drop policy if exists payment_insert on payment_submissions;
drop policy if exists payment_update on payment_submissions;
create policy payment_read on payment_submissions for select using(brand_id=auth.uid() or public.is_admin());
create policy payment_insert on payment_submissions for insert with check(brand_id=auth.uid() and exists(select 1 from campaigns c where c.id=campaign_id and c.brand_id=auth.uid() and c.status='pending_payment'));
create policy payment_update on payment_submissions for update using(public.is_admin() or brand_id=auth.uid()) with check(public.is_admin() or brand_id=auth.uid());

insert into platform_settings(key,value) values
 ('payment_enabled','false'),('platform_fee_npr','0'),('payment_qr_url','')
on conflict(key) do nothing;

create or replace function public.notify_admins_payment() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into notifications(user_id,type,title,body,data)
 select id,'payment','New QR payment to verify',format('%s submitted a NPR %s payment for %s.',(select full_name from profiles where id=new.brand_id),new.amount,(select title from campaigns where id=new.campaign_id)),jsonb_build_object('payment_id',new.id,'campaign_id',new.campaign_id)
 from profiles where role='admin';
 return new;
end; $$;
drop trigger if exists payment_admin_notifications on payment_submissions;
create trigger payment_admin_notifications after insert on payment_submissions for each row execute function public.notify_admins_payment();

drop policy if exists payment_proof_read on storage.objects;
drop policy if exists payment_proof_insert on storage.objects;
create policy payment_proof_read on storage.objects for select using(bucket_id='payment-proofs' and (public.is_admin() or (storage.foldername(name))[1]=auth.uid()::text));
create policy payment_proof_insert on storage.objects for insert with check(bucket_id='payment-proofs' and (storage.foldername(name))[1]=auth.uid()::text);
