-- ============================================================
-- Empanada Mania: marca propia con su banco de preguntas
--  · Nueva marca "mania" (sin relación con Sabores: progreso, resultados,
--    citaciones y habilitaciones propios). La usan los dos botones del examen:
--      Mania Propios     (zonal Tamara Migoya):      Ciudadela, Isidro Casanova
--      Mania Franquicias (zonal María José Cóceres): Del Viso, Monte Castro
--    Rinden el mismo examen y comparten el progreso por DNI.
--  · Por ahora Mania tiene solo el nivel Entrenador (19 preguntas, docx
--    "Exámenes Mania" de Capacitación, 03/11/2026). La 13 no vino en el docx.
--  · iniciar_examen rechaza un nivel que no tiene preguntas cargadas
--    (Encargado y Gerente de Mania) en vez de abrir un examen vacío.
--  · oficina_resumen_examenes: Mania se cuenta aparte (antes caía en Sabores).
-- Reemplaza todo el banco de mania, así que se puede volver a correr sin romper nada.
-- Correr completo en Supabase > SQL Editor.
-- (Sin signos pesos ni barras invertidas dentro de textos: el SQL Editor de Supabase los interpreta mal.)
-- ============================================================

begin;

-- 1) La marca mania pasa a ser válida en todas las tablas.
alter table public.examen_resultados drop constraint if exists examen_resultados_marca_check;
alter table public.examen_resultados add constraint examen_resultados_marca_check check (marca in ('sabores','hex','mania'));
alter table public.preguntas drop constraint if exists preguntas_marca_check;
alter table public.preguntas add constraint preguntas_marca_check check (marca in ('sabores','hex','mania'));
alter table public.examen_citaciones drop constraint if exists examen_citaciones_marca_check;
alter table public.examen_citaciones add constraint examen_citaciones_marca_check check (marca in ('sabores','hex','mania'));
alter table public.examen_habilitaciones drop constraint if exists examen_habilitaciones_marca_check;
alter table public.examen_habilitaciones add constraint examen_habilitaciones_marca_check check (marca in ('sabores','hex','mania'));

-- 2) iniciar_examen: igual que antes + marca mania + no abre niveles sin preguntas.
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
  if length(coalesce(p_dni, '')) not between 7 and 8 or p_dni ~ '[^0-9]' or pos is null
     or p_marca not in ('sabores','hex','mania')
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
  if not exists (select 1 from preguntas where marca = p_marca and nivel = p_nivel) then
    return json_build_object('error', 'nivel no habilitado');
  end if;
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

-- 3) Citaciones y habilitaciones: igual que antes + marca mania.
create or replace function public.citar_personas(p_clave text, p_marca text, p_fecha date, p_personas jsonb)
returns json language plpgsql security definer set search_path = public as $fn$
declare
  p jsonb;
  v_dni text;
  v_nivel text;
  ok int := 0;
  errores jsonb := '[]'::jsonb;
begin
  if not clave_valida(p_clave) then raise exception 'clave incorrecta'; end if;
  if p_marca not in ('sabores','hex','mania') or p_fecha is null or jsonb_typeof(p_personas) <> 'array' then
    raise exception 'datos inválidos';
  end if;
  for p in select * from jsonb_array_elements(p_personas) loop
    v_dni := regexp_replace(coalesce(p->>'dni', ''), '[^0-9]', '', 'g');
    v_nivel := lower(trim(coalesce(p->>'nivel', '')));
    if length(v_dni) not between 7 and 8 or v_nivel not in ('entrenador','encargado','gerente') then
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
$fn$;

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
  if p_marca not in ('sabores','hex','mania') or jsonb_typeof(p_personas) <> 'array' then
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

-- 4) Resumen del portal de oficina: Mania aparte de Sabores (mismo resultado para las demás marcas).
create or replace function public.oficina_resumen_examenes()
returns json language sql stable security definer set search_path = public as $fn$
  select json_build_object(
    'por_nivel', (
      select coalesce(json_agg(x order by x.marca, x.nivel), '[]'::json) from (
        select case marca when 'hex' then 'Extremas' when 'mania' then 'Mania' else 'Sabores' end as marca, nivel,
               count(*)::int as rendidos,
               count(*) filter (where condicion = 'Aprobado')::int as aprobados,
               count(*) filter (where condicion = 'Desaprobado')::int as desaprobados,
               round(avg(porcentaje))::int as promedio
        from public.examen_resultados group by 1, 2) x),
    'ultimos_7_dias', (select count(*)::int from public.examen_resultados where creado > now() - interval '7 days'),
    'citaciones', (select json_build_object(
        'citados', count(*) filter (where estado = 'citado'),
        'presentes', count(*) filter (where estado = 'presente'),
        'ausentes', count(*) filter (where estado = 'ausente'),
        'proximas', count(*) filter (where estado = 'citado' and fecha >= (now() at time zone 'America/Argentina/Buenos_Aires')::date))
      from public.examen_citaciones),
    'habilitaciones', (select count(*)::int from public.examen_habilitaciones),
    'en_curso', (select count(*)::int from public.examen_intentos where not entregado and inicio > now() - interval '1 day'),
    'ultimo', (select max(creado) from public.examen_resultados)
  );
$fn$;

revoke all on function public.iniciar_examen(text,text,text,text,text,text,text) from public;
revoke all on function public.citar_personas(text,text,date,jsonb) from public;
revoke all on function public.habilitar_personas(text,text,jsonb) from public;
revoke all on function public.oficina_resumen_examenes() from public;
grant execute on function public.iniciar_examen(text,text,text,text,text,text,text) to anon;
grant execute on function public.citar_personas(text,text,date,jsonb) to anon;
grant execute on function public.habilitar_personas(text,text,jsonb) to anon;
grant execute on function public.oficina_resumen_examenes() to anon;

-- 5) Banco de Mania · Entrenador (ids 600 + número de pregunta del docx; la opción correcta va primera).
--  Ajustes sobre el docx:
--   · 5: se toma la marcada con asterisco (48 horas).
--   · 9: la cuarta opción venía repetida; se usa "24 unidades (3 filas de 8)".
--   · 11: se toma la que venía marcada en azul (-8 °C a -12 °C).
--   · 15: vuelve a ser la del agua sanitizada (el docx tenía el texto de leudado de chipás con estas opciones).
--   · 19 y 20: "Para las delicias", confirmado por Capacitación.
delete from public.preguntas where marca = 'mania';

insert into public.preguntas (marca, nivel, id, orden, tipo, texto, opciones, filas, columnas, correcta) values
  ('mania', 'entrenador', 601, 1, 'opciones', '¿Cuál es el tiempo de cinta del horno POWER HOT?', '["6 a 8 minutos","5 a 7 minutos","3 a 5 minutos","10 a 11 minutos"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 602, 2, 'opciones', '¿A qué temperatura se cocinan las empanadas en el horno de cinta?', '["250 °C","280 °C","220 °C","270 °C"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 603, 3, 'opciones', '¿Cuál es la cantidad máxima de empanadas por bandeja para hornear?', '["8 unidades","6 unidades","10 unidades","12 unidades"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 604, 4, 'opciones', '¿Cuál es el vencimiento de las empanadas en el freezer?', '["3 meses","2 meses","1 mes","3 semanas"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 605, 5, 'opciones', '¿Cuál es el vencimiento de la pizza en la heladera?', '["48 horas","24 horas","72 horas","12 horas"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 606, 6, 'opciones', '¿Qué temperatura interna debe registrar el pirómetro en una empanada cocida?', '["Entre 55 °C y 65 °C","Entre 40 °C y 50 °C","Entre 70 °C y 90 °C","Entre 30 °C y 45 °C"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 607, 7, 'opciones', 'Medialunas: tiempo de leudado y armado de bandeja.', '["8 horas, 28 por bandeja en 4 filas de 7","5 horas, 28 por bandeja en 4 filas de 7","8 horas, 32 por bandeja en 4 filas de 8","6 horas, 24 por bandeja en 4 filas de 6"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 608, 8, 'opciones', '¿Cuántas chipás se colocan por bandeja?', '["60 unidades (6 filas de 10)","50 unidades (5 filas de 10)","40 unidades (4 filas de 10)","72 unidades (6 filas de 12)"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 609, 9, 'opciones', '¿Cuántos criollitos se colocan en la placa para su cocción?', '["21 unidades (3 filas de 7)","20 unidades (4 filas de 5)","28 unidades (4 filas de 7)","24 unidades (3 filas de 8)"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 610, 10, 'opciones', '¿Cuántas pizzas se colocan por estante en la heladera?', '["5 por estante, sectorizadas por gusto","4 por estante, sectorizadas por gusto","6 por estante, sectorizadas por gusto","3 por estante, sectorizadas por gusto"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 611, 11, 'opciones', '¿A qué temperatura deben estar los freezers?', '["-8 °C a -12 °C","-15 °C a -20 °C","0 °C a 5 °C","-12 °C a -18 °C"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 612, 12, 'opciones', '¿Qué significa el método "PEPS"?', '["Primero en entrar, primero en salir","Primero en vencer, primero en salir","Primero en encargar, primero en sacar","Productos en perfecto estado"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 614, 13, 'grilla', 'Completá con el color de trapo correspondiente.', null, '["Limpieza de baños","Superficies y utensilios en contacto con alimentos","Limpieza de equipos (hornos, heladeras)"]'::jsonb, '["Verde","Azul","Amarillo"]'::jsonb, '[2,0,1]'::jsonb),
  ('mania', 'entrenador', 615, 14, 'opciones', '¿Cómo se prepara el agua sanitizada y cuánto dura?', '["2 tapas de lavandina en 2 litros de agua, vence a las 4 horas","1 tapa de lavandina en 5 litros, vence a las 8 horas","2 tapas en 1 litro, vence a las 24 horas","Media tapa en 2 litros, dura todo el turno"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 616, 15, 'opciones', 'Además de al ingresar, después del baño o de tocar dinero, ¿cada cuánto nos lavamos las manos?', '["Cada 1 hora","Cada 4 horas","Al terminar el turno","Cada 30 minutos"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 617, 16, 'opciones', '¿Cuándo se pintan las medialunas con almíbar?', '["Únicamente al momento de la entrega al cliente, con pincel de silicona","Apenas salen del horno, con pincel de silicona","Antes de hornearlas","Únicamente al momento de la entrega al cliente, con pincel de cerdas"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 618, 17, 'opciones', '¿Cuál de los siguientes extintores es el más versátil por cubrir casi todos los tipos de fuego?', '["Extintor ABC","Extintor K","Extintor de agua","Extintor de espuma"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 619, 18, 'opciones', '¿Para qué se utiliza la pinza roja?', '["Para las delicias","Para empanadas","Únicamente para medialunas","Para todo excepto medialunas"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 620, 19, 'opciones', '¿Para qué se utiliza la pinza plateada?', '["Para las delicias","Para empanadas","Únicamente para medialunas","Para todo excepto medialunas"]'::jsonb, null, null, '0'::jsonb);

commit;
