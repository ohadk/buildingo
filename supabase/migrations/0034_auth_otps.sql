-- Login OTP store (WhatsApp / email). Firebase SMS stays on Firebase Phone Auth.
-- Rows are deleted on successful verify, expiry, or too many attempts.
-- TTL matches the WhatsApp Content Template copy (15 minutes).

create table if not exists public.auth_otps (
  phone_e164 text primary key,
  code_hash text not null,
  channel text not null check (channel in ('whatsapp', 'email')),
  expires_at timestamptz not null,
  attempts int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists auth_otps_expires_at_idx on public.auth_otps (expires_at);

alter table public.auth_otps enable row level security;
-- Service role only (API uses supabaseAdmin); no anon/authenticated policies.

-- Upsert a hashed OTP. Default TTL = 15 minutes (template copy).
create or replace function public.upsert_auth_otp(
  p_phone text,
  p_code_hash text,
  p_channel text,
  p_ttl_minutes int default 15
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_channel not in ('whatsapp', 'email') then
    raise exception 'invalid channel';
  end if;
  insert into public.auth_otps (
    phone_e164, code_hash, channel, expires_at, attempts, created_at
  ) values (
    p_phone,
    p_code_hash,
    p_channel,
    now() + make_interval(mins => greatest(p_ttl_minutes, 1)),
    0,
    now()
  )
  on conflict (phone_e164) do update set
    code_hash = excluded.code_hash,
    channel = excluded.channel,
    expires_at = excluded.expires_at,
    attempts = 0,
    created_at = excluded.created_at;
end;
$$;

-- Verify hash and delete the row on success / terminal failure.
-- Returns: ok | not_found | expired | invalid | too_many
create or replace function public.consume_auth_otp(
  p_phone text,
  p_code_hash text,
  p_max_attempts int default 5
) returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  row public.auth_otps%rowtype;
begin
  select * into row from public.auth_otps where phone_e164 = p_phone for update;
  if not found then
    return 'not_found';
  end if;

  if row.expires_at < now() then
    delete from public.auth_otps where phone_e164 = p_phone;
    return 'expired';
  end if;

  if row.attempts >= p_max_attempts then
    delete from public.auth_otps where phone_e164 = p_phone;
    return 'too_many';
  end if;

  if row.code_hash is distinct from p_code_hash then
    update public.auth_otps
      set attempts = attempts + 1
      where phone_e164 = p_phone;
    if row.attempts + 1 >= p_max_attempts then
      delete from public.auth_otps where phone_e164 = p_phone;
      return 'too_many';
    end if;
    return 'invalid';
  end if;

  delete from public.auth_otps where phone_e164 = p_phone;
  return 'ok';
end;
$$;

-- Drop stale rows (optional housekeeping; consume also deletes on expire).
create or replace function public.cleanup_expired_auth_otps()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted int;
begin
  delete from public.auth_otps where expires_at < now();
  get diagnostics deleted = row_count;
  return deleted;
end;
$$;

revoke all on function public.upsert_auth_otp(text, text, text, int) from public;
revoke all on function public.consume_auth_otp(text, text, int) from public;
revoke all on function public.cleanup_expired_auth_otps() from public;
grant execute on function public.upsert_auth_otp(text, text, text, int) to service_role;
grant execute on function public.consume_auth_otp(text, text, int) to service_role;
grant execute on function public.cleanup_expired_auth_otps() to service_role;
