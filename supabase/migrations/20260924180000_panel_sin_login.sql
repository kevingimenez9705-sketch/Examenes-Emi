-- ============================================================
-- Panel de Capacitación sin login
--  · examenes_panel: el Campus ve todos los resultados con el detalle
--    de respuestas (sin DNI), sin necesidad de ingresar.
--  · corregir_resultado / borrar_resultado: piden una clave de
--    Capacitación que vive solo en la base (nunca en el código de la página).
--
-- Para definir la clave, correr en Supabase > SQL Editor:
--   update public.capacitacion_clave set clave = 'TU-CLAVE';
-- Hasta que se defina, la clave es un valor aleatorio y nadie puede corregir ni borrar.
-- ============================================================

create table if not exists public.capacitacion_clave (
  id int primary key default 1 check (id = 1),
  clave text not null
);
insert into public.capacitacion_clave (id, clave)
values (1, gen_random_uuid()::text)
on conflict (id) do nothing;

alter table public.capacitacion_clave enable row level security;
revoke all on public.capacitacion_clave from anon, authenticated;

create or replace function public.clave_valida(p_clave text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from capacitacion_clave where clave = p_clave);
$$;
revoke all on function public.clave_valida(text) from public;

-- Todos los resultados con el detalle de respuestas, sin DNI.
create or replace function public.examenes_panel()
returns table (id bigint, marca text, local text, nombre text, apellido text, nivel text,
               porcentaje int, condicion text, payload jsonb, creado timestamptz)
language sql stable security definer set search_path = public as $$
  select id, marca, local, nombre, apellido, nivel, porcentaje, condicion,
         payload - 'dni' - 'postulante', creado
  from examen_resultados
  order by creado desc;
$$;

create or replace function public.corregir_resultado(
  p_clave text, p_id bigint, p_nombre text, p_apellido text, p_local text,
  p_nivel text, p_porcentaje int, p_condicion text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not clave_valida(p_clave) then raise exception 'clave incorrecta'; end if;
  if p_nivel not in ('entrenador','encargado','gerente') or p_condicion not in ('Aprobado','Desaprobado') then
    raise exception 'datos inválidos';
  end if;
  update examen_resultados
     set nombre = left(p_nombre, 80), apellido = left(p_apellido, 80), local = left(p_local, 80),
         nivel = p_nivel, porcentaje = p_porcentaje, condicion = p_condicion
   where id = p_id;
end;
$$;

create or replace function public.borrar_resultado(p_clave text, p_id bigint)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not clave_valida(p_clave) then raise exception 'clave incorrecta'; end if;
  delete from examen_resultados where id = p_id;
end;
$$;

revoke all on function public.examenes_panel() from public;
revoke all on function public.corregir_resultado(text,bigint,text,text,text,text,int,text) from public;
revoke all on function public.borrar_resultado(text,bigint) from public;
grant execute on function public.examenes_panel() to anon;
grant execute on function public.corregir_resultado(text,bigint,text,text,text,text,int,text) to anon;
grant execute on function public.borrar_resultado(text,bigint) to anon;
