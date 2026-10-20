-- ============================================================
-- Habilitaciones manuales y nota oculta al postulante
--  · Capacitación puede habilitar a un DNI para rendir un nivel sin haber
--    aprobado los anteriores (p. ej. quienes rindieron una versión en papel).
--    Los niveles anteriores al habilitado se dan por cumplidos (no cuentan
--    como aprobados en los resultados). No saltea la espera de 48 hs.
--  · Se cargan, listan y borran con la clave de Capacitación desde el Campus.
--    A mano, en Supabase > SQL Editor:
--      select public.habilitar_personas('TU-CLAVE', 'sabores',
--        '[{"dni":"30111222","nivel":"gerente","nombre":"Ana","apellido":"Pérez","motivo":"Rindió en papel"}]');
--  · entregar_examen ya no devuelve el porcentaje: el postulante solo ve si
--    aprobó o no. La nota sigue guardada y visible en el Campus.
-- Se puede volver a correr sin romper nada.
-- (Sin signos pesos ni barras invertidas dentro de textos: el SQL Editor de Supabase los interpreta mal.)
-- ============================================================

create table if not exists public.examen_habilitaciones (
  id bigint generated always as identity primary key,
  marca text not null check (marca in ('sabores','hex')),
  dni text not null check (length(dni) between 7 and 8 and dni !~ '[^0-9]'),
  nivel text not null check (nivel in ('entrenador','encargado','gerente')),
  nombre text,
  apellido text,
  motivo text,
  creado timestamptz not null default now(),
  unique (marca, dni, nivel)
);
alter table public.examen_habilitaciones enable row level security;
revoke all on public.examen_habilitaciones from anon, authenticated;

-- Niveles habilitados a mano para un DNI en una marca.
create or replace function public.niveles_habilitados(p_marca text, p_dni text)
returns text[] language sql stable security definer set search_path = public as $fn$
  select coalesce(array_agg(nivel), '{}') from examen_habilitaciones where marca = p_marca and dni = p_dni;
$fn$;
revoke all on function public.niveles_habilitados(text,text) from public;

-- estado_dni: igual que antes + niveles habilitados a mano.
create or replace function public.estado_dni(p_marca text, p_dni text)
returns json language sql stable security definer set search_path = public as $fn$
  select json_build_object(
    'aprobados', niveles_aprobados(p_marca, p_dni),
    'habilitados', niveles_habilitados(p_marca, p_dni),
    'desaprobados', coalesce((
      select json_object_agg(nivel, ultimo) from (
        select nivel, max(creado) as ultimo from examen_resultados
        where marca = p_marca and dni = p_dni and condicion is distinct from 'Aprobado'
        group by nivel) t), '{}'::json));
$fn$;

-- Carga habilitaciones. p_personas: [{dni, nivel, nombre, apellido, motivo}]
-- Si ya existe la del mismo DNI y nivel, se actualizan los datos.
create or replace function public.habilitar_personas(p_clave text, p_marca text, p_personas jsonb)
returns json language plpgsql security definer set search_path = public as $fn$
declare
  p jsonb;
  v_dni text;
  v_nivel text;
  ok int := 0;
  errores jsonb := '[]'::jsonb;
begin
  if not clave_valida(p_clave) then raise exception 'clave incorrecta'; end if;
  if p_marca not in ('sabores','hex') or jsonb_typeof(p_personas) <> 'array' then
    raise exception 'datos inválidos';
  end if;
  for p in select * from jsonb_array_elements(p_personas) loop
    v_dni := regexp_replace(coalesce(p->>'dni', ''), '[^0-9]', '', 'g');
    v_nivel := lower(trim(coalesce(p->>'nivel', '')));
    if length(v_dni) not between 7 and 8 or v_nivel not in ('entrenador','encargado','gerente') then
      errores := errores || jsonb_build_array(p);
      continue;
    end if;
    insert into examen_habilitaciones (marca, dni, nivel, nombre, apellido, motivo)
    values (p_marca, v_dni, v_nivel, left(trim(p->>'nombre'), 80), left(trim(p->>'apellido'), 80),
            left(trim(p->>'motivo'), 200))
    on conflict (marca, dni, nivel) do update
      set nombre = excluded.nombre, apellido = excluded.apellido, motivo = excluded.motivo;
    ok := ok + 1;
  end loop;
  return json_build_object('cargados', ok, 'rechazados', errores);
end;
$fn$;

-- Listado de habilitaciones (con DNI) y el último resultado de ese nivel desde que se habilitó.
create or replace function public.habilitaciones_listado(p_clave text)
returns table (id bigint, marca text, dni text, nivel text, nombre text, apellido text, motivo text,
               creado timestamptz, porcentaje int, condicion text)
language plpgsql stable security definer set search_path = public as $fn$
begin
  if not clave_valida(p_clave) then raise exception 'clave incorrecta'; end if;
  return query
    select h.id, h.marca, h.dni, h.nivel, h.nombre, h.apellido, h.motivo, h.creado, r.porcentaje, r.condicion
    from examen_habilitaciones h
    left join lateral (
      select x.porcentaje, x.condicion from examen_resultados x
      where x.marca = h.marca and x.dni = h.dni and x.nivel = h.nivel and x.creado >= h.creado
      order by x.creado desc limit 1) r on true
    order by h.creado desc;
end;
$fn$;

create or replace function public.borrar_habilitacion(p_clave text, p_id bigint)
returns void language plpgsql security definer set search_path = public as $fn$
begin
  if not clave_valida(p_clave) then raise exception 'clave incorrecta'; end if;
  delete from examen_habilitaciones where id = p_id;
end;
$fn$;

-- iniciar_examen: igual que antes, pero una habilitación da por cumplidos los niveles anteriores.
create or replace function public.iniciar_examen(
  p_marca text, p_dni text, p_nivel text, p_nombre text, p_apellido text, p_local text, p_correo text)
returns json language plpgsql security definer set search_path = public as $fn$
declare
  orden text[] := array['entrenador','encargado','gerente'];
  pos int := array_position(orden, p_nivel);
  aprob text[];
  tope int;
  t examen_intentos;
  nuevo uuid;
begin
  if length(coalesce(p_dni, '')) not between 7 and 8 or p_dni ~ '[^0-9]' or pos is null or p_marca not in ('sabores','hex')
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
  -- Nivel habilitado más alto (0 = ninguno): los anteriores a él no se exigen.
  select coalesce(max(array_position(orden, h)), 0) into tope from unnest(niveles_habilitados(p_marca, p_dni)) h;
  if p_nivel = any(aprob) then return json_build_object('error', 'nivel ya aprobado'); end if;
  if pos > 1 and not (orden[greatest(tope, 1):pos-1] <@ aprob) then
    return json_build_object('error', 'nivel no habilitado');
  end if;
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
$fn$;

-- entregar_examen: igual que antes, pero al postulante solo le devuelve la condición (sin la nota).
create or replace function public.entregar_examen(p_token uuid, p_respuestas jsonb, p_motivo text)
returns json language plpgsql security definer set search_path = public as $fn$
declare
  t examen_intentos;
  p preguntas;
  r jsonb;
  total int := 0;
  ok int := 0;
  respondidas int := 0;
  detalle jsonb := '[]'::jsonb;
  motivo text := left(coalesce(p_motivo, 'entregado'), 40);
  pct int;
  cond text;
begin
  select * into t from examen_intentos where token = p_token for update;
  if not found or t.entregado then raise exception 'examen inexistente o ya entregado'; end if;
  if now() > t.inicio + interval '17 minutes' then motivo := 'tiempo'; end if;
  if jsonb_typeof(coalesce(p_respuestas, '{}'::jsonb)) <> 'object' then p_respuestas := '{}'::jsonb; end if;

  for p in select * from preguntas where marca = t.marca and nivel = t.nivel order by orden loop
    total := total + 1;
    r := p_respuestas -> p.id::text;
    if r is not null and r <> 'null'::jsonb then respondidas := respondidas + 1; end if;
    if r = p.correcta then ok := ok + 1; end if;
    detalle := detalle || jsonb_build_array(jsonb_build_object(
      'id', p.id, 'pregunta', p.texto,
      'respuesta', texto_respuesta(p, r),
      'resultado', case when r = p.correcta then 'correcta' else 'incorrecta' end));
  end loop;

  pct := case when total > 0 then round(100.0 * ok / total) else 0 end;
  cond := case when pct >= 80 then 'Aprobado' else 'Desaprobado' end;

  update examen_intentos set entregado = true where token = p_token;
  insert into examen_resultados (marca, dni, nivel, porcentaje, condicion, nombre, apellido, local, payload)
  values (t.marca, t.dni, t.nivel, pct, cond, t.nombre, t.apellido, t.local, jsonb_build_object(
    'motivo_cierre', motivo, 'inicio', t.inicio, 'fin', now(),
    'segundos_usados', least(900, extract(epoch from now() - t.inicio)::int),
    'respondidas', respondidas, 'total_preguntas', total, 'aciertos', ok,
    'correo', t.correo, 'detalle', detalle));

  return json_build_object('condicion', cond);
end;
$fn$;

revoke all on function public.estado_dni(text,text) from public;
revoke all on function public.habilitar_personas(text,text,jsonb) from public;
revoke all on function public.habilitaciones_listado(text) from public;
revoke all on function public.borrar_habilitacion(text,bigint) from public;
revoke all on function public.iniciar_examen(text,text,text,text,text,text,text) from public;
revoke all on function public.entregar_examen(uuid,jsonb,text) from public;
grant execute on function public.estado_dni(text,text) to anon;
grant execute on function public.habilitar_personas(text,text,jsonb) to anon;
grant execute on function public.habilitaciones_listado(text) to anon;
grant execute on function public.borrar_habilitacion(text,bigint) to anon;
grant execute on function public.iniciar_examen(text,text,text,text,text,text,text) to anon;
grant execute on function public.entregar_examen(uuid,jsonb,text) to anon;
