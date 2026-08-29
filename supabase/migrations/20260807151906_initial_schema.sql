-- Family Tap initial schema
-- Spec sections 22-30. RLS is enabled on every table here (secure-by-default:
-- no policies yet means no access at all), but policies themselves are added
-- in the Phase 4 migration ("RLS作成"), not this one.

-- ============================================================
-- profiles — supplements auth.users (spec section 23)
-- ============================================================
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'One row per auth.users, holds the family-facing display name (spec section 20/23).';

-- ============================================================
-- families (spec section 24)
-- ============================================================
create table public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text not null unique,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

-- ============================================================
-- family_members — join table between profiles and families (spec section 25)
-- ============================================================
create table public.family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  unique (family_id, user_id)
);

-- ============================================================
-- report_buttons — user-defined report buttons (spec section 26)
-- ============================================================
create table public.report_buttons (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  label text not null,
  icon text,
  type text not null check (type in ('normal', 'daily')),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- reports — actual report events (spec section 27)
-- ============================================================
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  button_id uuid not null references public.report_buttons (id) on delete cascade,
  user_id uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

-- Speeds up the DAILY "already reported today?" lookup (spec section 31:
-- WHERE button_id = ? AND created_at >= start_of_today) and the history feed
-- (spec section 15: family-wide list ordered by created_at desc).
create index reports_button_created_at_idx on public.reports (button_id, created_at desc);
create index reports_family_created_at_idx on public.reports (family_id, created_at desc);

-- ============================================================
-- device_tokens — push notification targets (spec section 28)
-- ============================================================
create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  token text not null unique,
  platform text not null default 'ios',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- updated_at auto-maintenance
-- ============================================================
create function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger set_updated_at
  before update on public.report_buttons
  for each row execute function public.set_updated_at();

create trigger set_updated_at
  before update on public.device_tokens
  for each row execute function public.set_updated_at();

-- ============================================================
-- Enable RLS (policies added in the next migration — Phase 4)
-- ============================================================
alter table public.profiles enable row level security;
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.report_buttons enable row level security;
alter table public.reports enable row level security;
alter table public.device_tokens enable row level security;
