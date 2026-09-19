-- ============================================================
--  Облік Панелей — схема бази даних для Supabase
--  Встав увесь цей текст у Supabase → SQL Editor → RUN (один раз).
-- ============================================================

-- ---------- Партії закупівель ----------
create table if not exists public.batches (
  id                 text primary key,
  user_id            uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date               timestamptz,
  price_usd          numeric,
  rate               numeric,
  delivery_uah       numeric,
  delivery_usd       numeric,
  qty                integer,
  cost_per_panel_usd numeric,
  created_at         timestamptz default now()
);

-- ---------- Панелі ----------
create table if not exists public.panels (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null default auth.uid() references auth.users(id) on delete cascade,
  code                text not null,
  batch_id            text,
  cost_usd            numeric,
  price_usd           numeric,
  delivery_share_usd  numeric,
  rate_at_purchase    numeric,
  purchase_date       timestamptz,
  status              text default 'stock',   -- 'stock' | 'sold'
  sale                jsonb,                   -- {amount,currency,priceUsd,rate,buyer,date,profitUsd}
  created_at          timestamptz default now(),
  unique (user_id, code)                       -- один код на акаунт (нема дублів)
);

-- ---------- Налаштування (курс, націнка) ----------
create table if not exists public.settings (
  user_id       uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  rate_usd      numeric default 0,
  rate_eur      numeric default 0,
  rate_updated  timestamptz,
  margin        numeric default 15
);

-- ---------- Витрати на рекламу (окремо від панелей) ----------
create table if not exists public.ad_expenses (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date        timestamptz,
  amount      numeric,
  currency    text,        -- 'usd' | 'uah'
  amount_usd  numeric,     -- сума, зведена в долар
  rate        numeric,
  note        text,
  created_at  timestamptz default now()
);

-- ============================================================
--  Захист: кожен бачить і змінює ТІЛЬКИ свої дані
-- ============================================================
alter table public.batches     enable row level security;
alter table public.panels      enable row level security;
alter table public.settings    enable row level security;
alter table public.ad_expenses enable row level security;

drop policy if exists "own batches"  on public.batches;
drop policy if exists "own panels"   on public.panels;
drop policy if exists "own settings" on public.settings;
drop policy if exists "own ads"      on public.ad_expenses;

create policy "own batches"  on public.batches
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own panels"   on public.panels
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own settings" on public.settings
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own ads"      on public.ad_expenses
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ============================================================
--  Синхронізація в реальному часі між пристроями
--  (безпечно запускати повторно — дублі ігноруються)
-- ============================================================
do $$ begin alter publication supabase_realtime add table public.panels;      exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.batches;     exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.settings;    exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.ad_expenses; exception when duplicate_object then null; end $$;
