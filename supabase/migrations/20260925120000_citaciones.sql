-- ============================================================
-- Citaciones a examen
--  · Capacitación carga la lista de citados (DNI, nivel, fecha) con su clave
--    desde citaciones.html.
--  · Al iniciar el examen, la citación pendiente de ese DNI y nivel pasa a "presente".
--  · Si a las 20:00 (hora Argentina) del día de la citación la persona no hizo
--    ningún examen ese día, queda "ausente" y se genera un resultado Desaprobado
--    (0%, motivo_cierre = 'ausente'), que también aplica la espera de 48 hs.
--  · Las ausencias se cierran solas a las 20:00 (pg_cron) y además cada vez que
--    se consulta el listado o se inicia un examen.
-- Se puede volver a correr sin romper nada.
-- ============================================================

create table if not exists public.examen_citaciones (
  id bigint generated always as identity primary key,
  marca text not null check (marca in ('sabores','hex')),
  dni text not null check (dni ~ '^\d{7,8}$'),
  nivel text not null check (nivel in ('entrenador','encargado','gerente')),
  nombre text,
  apellido text,
  local text,
  fecha date not null,
  estado text not null default 'citado' check (estado in ('citado','presente','ausente')),
  resultado_id bigint references public.examen_resultados(id) on delete set null,
  creado timestamptz not null default now()
);
create index if not exists examen_citaciones_pend_idx on public.examen_citaciones (marca, dni, nivel) where estado = 'citado';
create index if not exists examen_citaciones_fecha_idx on public.examen_citaciones (fecha);
alter table public.examen_citaciones enable row level security;
revoke all on public.examen_citaciones from anon, authenticated;

-- Hora límite de una citación: las 20:00 (hora Argentina) del día citado.
create or replace function public.limite_citacion(p_fecha date)
returns timestamptz language sql immutable as $$
  select (p_fecha + time '20:00') at time zone 'America/Argentina/Buenos_Aires';
$$;

-- A la hora límite: presente si hizo algún examen ese día; si no, ausente (Desaprobado).
create or replace function public.cerrar_ausencias()
returns int language plpgsql security definer set search_path = public as $$
declare
  c examen_citaciones;
  fin timestamptz;
  rid bigint;
  n int := 0;
begin
  for c in select * from examen_citaciones
           where estado = 'citado'
             and limite_citacion(fecha) <= now()
           for update skip locked loop
    fin := limite_citacion(c.fecha);
    if exists (select 1 from examen_intentos i where i.marca = c.marca and i.dni = c.dni
               and i.inicio >= c.fecha::timestamp at time zone 'America/Argentina/Buenos_Aires'
               and i.inicio < fin) then
      update examen_citaciones set estado = 'presente' where id = c.id;
      continue;
    end if;
    insert into examen_resultados (marca, dni, nivel, porcentaje, condicion, nombre, apellido, local, payload, creado)
    values (c.marca, c.dni, c.nivel, 0, 'Desaprobado', c.nombre, c.apellido, c.local,
            jsonb_build_object('motivo_cierre', 'ausente', 'citacion_id', c.id, 'fecha_citacion', c.fecha, 'detalle', '[]'::jsonb),
            fin)
    returning id into rid;
    update examen_citaciones set estado = 'ausente', resultado_id = rid where id = c.id;
    n := n + 1;
  end loop;
  return n;
end;
$$;
revoke all on function public.cerrar_ausencias() from public;
revoke all on function public.limite_citacion(date) from public;

-- Carga citados. p_personas: [{dni, nivel, nombre, apellido, local}]
-- Si ya hay una citación pendiente del mismo DNI y nivel, se actualiza (fecha y datos).
create or replace function public.citar_personas(p_clave text, p_marca text, p_fecha date, p_personas jsonb)
returns json language plpgsql security definer set search_path = public as $$
declare
  p jsonb;
  v_dni text;
  v_nivel text;
  ok int := 0;
  errores jsonb := '[]'::jsonb;
begin
  if not clave_valida(p_clave) then raise exception 'clave incorrecta'; end if;
  if p_marca not in ('sabores','hex') or p_fecha is null or jsonb_typeof(p_personas) <> 'array' then
    raise exception 'datos inválidos';
  end if;
  for p in select * from jsonb_array_elements(p_personas) loop
    v_dni := regexp_replace(coalesce(p->>'dni', ''), '\D', '', 'g');
    v_nivel := lower(trim(coalesce(p->>'nivel', '')));
    if v_dni !~ '^\d{7,8}$' or v_nivel not in ('entrenador','encargado','gerente') then
      errores := errores || jsonb_build_array(p);
      continue;
    end if;
    update examen_citaciones
       set fecha = p_fecha, nombre = left(trim(p->>'nombre'), 80), apellido = left(trim(p->>'apellido'), 80),
           local = left(trim(p->>'local'), 80)
     where marca = p_marca and dni = v_dni and nivel = v_nivel and estado = 'citado';
    if not found then
      insert into examen_citaciones (marca, dni, nivel, nombre, apellido, local, fecha)
      values (p_marca, v_dni, v_nivel, left(trim(p->>'nombre'), 80), left(trim(p->>'apellido'), 80),
              left(trim(p->>'local'), 80), p_fecha);
    end if;
    ok := ok + 1;
  end loop;
  return json_build_object('cargados', ok, 'rechazados', errores);
end;
$$;

-- Listado de citaciones (con DNI) para Capacitación. Cierra ausencias antes de listar.
create or replace function public.citaciones_listado(p_clave text, p_desde date, p_hasta date)
returns table (id bigint, marca text, dni text, nivel text, nombre text, apellido text, local text,
               fecha date, estado text, porcentaje int, condicion text, creado timestamptz)
language plpgsql security definer set search_path = public as $$
begin
  if not clave_valida(p_clave) then raise exception 'clave incorrecta'; end if;
  perform cerrar_ausencias();
  return query
    select c.id, c.marca, c.dni, c.nivel, c.nombre, c.apellido, c.local, c.fecha, c.estado,
           r.porcentaje, r.condicion, c.creado
    from examen_citaciones c
    -- Ausentes: su resultado generado. Presentes: el último resultado desde la citación.
    left join lateral (
      select x.porcentaje, x.condicion from examen_resultados x
      where x.id = c.resultado_id
         or (c.resultado_id is null and x.marca = c.marca and x.dni = c.dni and x.nivel = c.nivel and x.creado >= c.creado)
      order by x.creado desc limit 1) r on true
    where c.fecha between coalesce(p_desde, '-infinity'::date) and coalesce(p_hasta, 'infinity'::date)
    order by c.fecha desc, c.marca, c.local, c.apellido;
end;
$$;

-- Borra una citación pendiente (no toca resultados ya generados).
create or replace function public.borrar_citacion(p_clave text, p_id bigint)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not clave_valida(p_clave) then raise exception 'clave incorrecta'; end if;
  delete from examen_citaciones where id = p_id and estado = 'citado';
end;
$$;

-- Resumen de asistencia por marca, local y nivel (sin DNI ni nombres), para el Campus.
create or replace function public.asistencia_resumen(p_desde date default null, p_hasta date default null)
returns table (marca text, local text, nivel text, citados int, presentes int, ausentes int, pendientes int)
language plpgsql security definer set search_path = public as $$
begin
  perform cerrar_ausencias();
  return query
    select c.marca, c.local, c.nivel, count(*)::int,
           count(*) filter (where c.estado = 'presente')::int,
           count(*) filter (where c.estado = 'ausente')::int,
           count(*) filter (where c.estado = 'citado')::int
    from examen_citaciones c
    where c.fecha between coalesce(p_desde, '-infinity'::date) and coalesce(p_hasta, 'infinity'::date)
    group by c.marca, c.local, c.nivel
    order by c.marca, c.local, c.nivel;
end;
$$;

-- iniciar_examen: igual que antes + cierra ausencias y marca presente la citación pendiente.
create or replace function public.iniciar_examen(
  p_marca text, p_dni text, p_nivel text, p_nombre text, p_apellido text, p_local text, p_correo text)
returns json language plpgsql security definer set search_path = public as $$
declare
  orden text[] := array['entrenador','encargado','gerente'];
  pos int := array_position(orden, p_nivel);
  aprob text[];
  t examen_intentos;
  nuevo uuid;
begin
  if p_dni !~ '^\d{7,8}$' or pos is null or p_marca not in ('sabores','hex')
     or coalesce(trim(p_nombre), '') = '' or coalesce(trim(p_apellido), '') = '' or coalesce(trim(p_local), '') = '' then
    raise exception 'datos inválidos';
  end if;

  -- Intentos que quedaron abiertos (página cerrada o recargada) cuentan como desaprobados.
  for t in select * from examen_intentos where marca = p_marca and dni = p_dni and not entregado loop
    perform cerrar_intento_abandonado(t);
  end loop;
  -- Citaciones vencidas sin presentarse cuentan como desaprobadas.
  perform cerrar_ausencias();

  -- Estos rechazos se devuelven como {error} (sin exception) para que quede
  -- guardado el cierre de los intentos abandonados y ausencias de arriba.
  aprob := niveles_aprobados(p_marca, p_dni);
  if p_nivel = any(aprob) then return json_build_object('error', 'nivel ya aprobado'); end if;
  if pos > 1 and not (orden[1:pos-1] <@ aprob) then return json_build_object('error', 'nivel no habilitado'); end if;
  if exists (select 1 from examen_resultados where marca = p_marca and dni = p_dni and nivel = p_nivel
             and condicion is distinct from 'Aprobado' and creado > now() - interval '48 hours') then
    return json_build_object('error', 'debe esperar 48 hs para volver a rendir');
  end if;

  insert into examen_intentos (marca, dni, nivel, nombre, apellido, local, correo)
  values (p_marca, p_dni, p_nivel, left(trim(p_nombre), 80), left(trim(p_apellido), 80), left(trim(p_local), 80), left(trim(p_correo), 120))
  returning token into nuevo;

  -- Presente: la citación de este nivel, o cualquier citación de hoy (antes de las 20 hs).
  update examen_citaciones set estado = 'presente'
   where marca = p_marca and dni = p_dni and estado = 'citado'
     and (nivel = p_nivel or (fecha = (now() at time zone 'America/Argentina/Buenos_Aires')::date
                              and now() < limite_citacion(fecha)));

  return json_build_object(
    'token', nuevo,
    'minutos', 15,
    'aprobado', 80,
    'preguntas', (select coalesce(json_agg(json_build_object(
        'id', id, 'tipo', tipo, 'texto', texto, 'opciones', opciones, 'filas', filas, 'columnas', columnas)
        order by random()), '[]'::json)
      from preguntas where marca = p_marca and nivel = p_nivel));
end;
$$;

revoke all on function public.citar_personas(text,text,date,jsonb) from public;
revoke all on function public.citaciones_listado(text,date,date) from public;
revoke all on function public.borrar_citacion(text,bigint) from public;
revoke all on function public.asistencia_resumen(date,date) from public;
revoke all on function public.iniciar_examen(text,text,text,text,text,text,text) from public;
grant execute on function public.citar_personas(text,text,date,jsonb) to anon;
grant execute on function public.citaciones_listado(text,date,date) to anon;
grant execute on function public.borrar_citacion(text,bigint) to anon;
grant execute on function public.asistencia_resumen(date,date) to anon;
grant execute on function public.iniciar_examen(text,text,text,text,text,text,text) to anon;

-- Cierre automático a las 20:00 hora Argentina = 23:00 UTC (si pg_cron está disponible; si no, se cierra al consultar).
do $$
begin
  create extension if not exists pg_cron;
  perform cron.unschedule(jobid) from cron.job where jobname = 'cerrar_ausencias';
  perform cron.schedule('cerrar_ausencias', '0 23 * * *', 'select public.cerrar_ausencias()');
exception when others then
  raise notice 'pg_cron no disponible: las ausencias se cierran al consultar (%).', sqlerrm;
end;
$$;
