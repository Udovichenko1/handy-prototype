-- Handy: схема базы данных для Supabase
-- Выполнить целиком в Supabase Dashboard → SQL Editor → New query → Run

create extension if not exists pgcrypto;

-- Профили пользователей (и клиенты, и мастера)
create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  role text not null check (role in ('client','worker')),
  name text,
  email text,
  category text,              -- ключ категории, только для role='worker'
  rating numeric default 5.0, -- только для role='worker'
  price_hour numeric,         -- только для role='worker'
  lat double precision,
  lng double precision,
  created_at timestamptz not null default now()
);

-- Задания
create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  category text not null,
  district text,
  address text,
  lat double precision,
  lng double precision,
  price numeric not null,
  scheduled_date text,
  scheduled_time text,
  description text,
  status text not null default 'open' check (status in ('open','taken','done')),
  worker_id uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;
alter table tasks enable row level security;

-- Профили читают все авторизованные (нужно для списка мастеров на радаре)
create policy "profiles readable by authenticated"
  on profiles for select
  to authenticated
  using (true);

create policy "users create own profile"
  on profiles for insert
  to authenticated
  with check (auth.uid() = id);

create policy "users update own profile"
  on profiles for update
  to authenticated
  using (auth.uid() = id);

-- Задания читают все авторизованные (нужно для радара)
create policy "tasks readable by authenticated"
  on tasks for select
  to authenticated
  using (true);

create policy "clients create own tasks"
  on tasks for insert
  to authenticated
  with check (auth.uid() = client_id);

-- владелец задания может менять его; открытое задание может "забрать" любой авторизованный (упрощение для прототипа)
create policy "owner or open task updatable"
  on tasks for update
  to authenticated
  using (auth.uid() = client_id or status = 'open');
