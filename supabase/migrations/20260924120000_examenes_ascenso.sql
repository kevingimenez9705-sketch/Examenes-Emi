-- ============================================================
-- Exámenes de ascenso — Supabase
-- Migración: la integración de Supabase con GitHub la aplica al mergear a main.
-- (También se puede correr a mano en Supabase > SQL Editor.)
-- Se puede volver a correr sin romper nada.
--
-- La tabla queda cerrada: con la anon key solo se pueden usar las
-- funciones de abajo, nunca leer ni escribir la tabla directo.
--   · estado_dni          -> examen (index.html): niveles aprobados y espera de 48 hs
--   · registrar_resultado -> examen (index.html): guarda un resultado
--   · examenes_campus     -> Campus de Ascensos: resultados sin DNI ni respuestas
-- ============================================================

create table if not exists public.examen_resultados (
  id bigint generated always as identity primary key,
  marca text not null check (marca in ('sabores','hex')),
  dni text not null,
  nivel text not null check (nivel in ('entrenador','encargado','gerente')),
  porcentaje int,
  condicion text,
  nombre text,
  apellido text,
  local text,
  payload jsonb,
  creado timestamptz not null default now()
);
create index if not exists examen_resultados_marca_dni_idx on public.examen_resultados (marca, dni);

alter table public.examen_resultados enable row level security;
revoke all on public.examen_resultados from anon, authenticated;

-- Niveles aprobados de un DNI en una marca.
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
  p_nombre text, p_apellido text, p_local text, p_payload jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare
  orden text[] := array['entrenador','encargado','gerente'];
  pos int := array_position(orden, p_nivel);
  aprob text[] := niveles_aprobados(p_marca, p_dni);
begin
  if p_dni !~ '^\d{7,8}$' or pos is null or p_marca not in ('sabores','hex') then
    raise exception 'datos inválidos';
  end if;
  if pos > 1 and not (orden[1:pos-1] <@ aprob) then
    raise exception 'nivel no habilitado';
  end if;
  if exists (select 1 from examen_resultados where marca = p_marca and dni = p_dni and nivel = p_nivel
             and condicion is distinct from 'Aprobado' and creado > now() - interval '48 hours') then
    raise exception 'debe esperar 48 hs para volver a rendir';
  end if;
  insert into examen_resultados (marca, dni, nivel, porcentaje, condicion, nombre, apellido, local, payload)
  values (p_marca, p_dni, p_nivel, p_porcentaje, p_condicion,
          left(p_nombre, 80), left(p_apellido, 80), left(p_local, 80), p_payload);
end;
$$;

-- Para el Campus de Ascensos: un registro por examen, sin DNI ni detalle de respuestas.
create or replace function public.examenes_campus()
returns table (id bigint, marca text, local text, nombre text, apellido text, nivel text,
               porcentaje int, condicion text, motivo_cierre text, creado timestamptz)
language sql stable security definer set search_path = public as $$
  select id, marca, local, nombre, apellido, nivel, porcentaje, condicion,
         payload->>'motivo_cierre', creado
  from examen_resultados
  order by creado desc;
$$;

revoke all on function public.niveles_aprobados(text,text) from public;
revoke all on function public.estado_dni(text,text) from public;
revoke all on function public.registrar_resultado(text,text,text,int,text,text,text,text,jsonb) from public;
revoke all on function public.examenes_campus() from public;
grant execute on function public.estado_dni(text,text) to anon;
grant execute on function public.registrar_resultado(text,text,text,int,text,text,text,text,jsonb) to anon;
grant execute on function public.examenes_campus() to anon;
