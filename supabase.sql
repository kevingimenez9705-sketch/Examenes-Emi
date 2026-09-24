-- Progreso por DNI (Entrenador -> Encargado -> Gerente).
-- La tabla queda cerrada: la página (anon key) solo puede usar las 2 funciones de abajo.
create table if not exists public.examen_resultados (
  id bigint generated always as identity primary key,
  marca text not null default 'sabores' check (marca in ('sabores','extremas')),
  dni text not null,
  nivel text not null check (nivel in ('entrenador','encargado','gerente')),
  porcentaje int,
  condicion text,
  nombre text,
  local text,
  payload jsonb,
  creado timestamptz not null default now()
);
alter table public.examen_resultados add column if not exists marca text not null default 'sabores';
create index if not exists examen_resultados_dni_idx on public.examen_resultados (marca, dni);

alter table public.examen_resultados enable row level security;
drop policy if exists "anon inserta resultados" on public.examen_resultados;
drop policy if exists "anon lee resultados" on public.examen_resultados;
revoke all on public.examen_resultados from anon, authenticated;

-- Devuelve solo los niveles aprobados de un DNI (sin nombres ni otros datos).
create or replace function public.niveles_aprobados(p_marca text, p_dni text)
returns text[] language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(distinct nivel), '{}')
  from examen_resultados where marca = p_marca and dni = p_dni and condicion = 'Aprobado';
$$;

-- Aprobados y fecha del último intento no aprobado por nivel (sin nombres ni otros datos).
create or replace function public.estado_dni(p_marca text, p_dni text)
returns json language sql stable security definer set search_path = public as $$
  select json_build_object(
    'aprobados', niveles_aprobados(p_marca, p_dni),
    'desaprobados', coalesce((
      select json_object_agg(nivel, ultimo) from (
        select nivel, max(creado) as ultimo from examen_resultados
        where marca = p_marca and dni = p_dni and condicion is distinct from 'Aprobado'
        group by nivel) t), '{}'::json));
$$;

-- Registra un resultado. Rechaza niveles no habilitados o dentro de las 48 hs de espera.
create or replace function public.registrar_resultado(
  p_marca text, p_dni text, p_nivel text, p_porcentaje int, p_condicion text,
  p_nombre text, p_local text, p_payload jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare
  orden text[] := array['entrenador','encargado','gerente'];
  pos int := array_position(orden, p_nivel);
  aprob text[] := niveles_aprobados(p_marca, p_dni);
begin
  if p_dni !~ '^\d{7,8}$' or pos is null or p_marca not in ('sabores','extremas') then
    raise exception 'datos inválidos';
  end if;
  if pos > 1 and not (orden[1:pos-1] <@ aprob) then
    raise exception 'nivel no habilitado';
  end if;
  if exists (select 1 from examen_resultados where marca = p_marca and dni = p_dni and nivel = p_nivel
             and condicion is distinct from 'Aprobado' and creado > now() - interval '48 hours') then
    raise exception 'debe esperar 48 hs para volver a rendir';
  end if;
  insert into examen_resultados (marca, dni, nivel, porcentaje, condicion, nombre, local, payload)
  values (p_marca, p_dni, p_nivel, p_porcentaje, p_condicion, p_nombre, p_local, p_payload);
end;
$$;

revoke all on function public.niveles_aprobados(text,text) from public;
revoke all on function public.estado_dni(text,text) from public;
grant execute on function public.estado_dni(text,text) to anon;
revoke all on function public.registrar_resultado(text,text,text,int,text,text,text,jsonb) from public;
grant execute on function public.niveles_aprobados(text,text) to anon;
grant execute on function public.registrar_resultado(text,text,text,int,text,text,text,jsonb) to anon;
