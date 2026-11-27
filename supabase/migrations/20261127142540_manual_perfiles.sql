-- Manuales operativos interactivos (Sabores / Extremas): perfil por DNI y progreso.
-- Ya aplicada en el proyecto Examenes-Emi; este archivo deja el repo sincronizado.
create table if not exists public.manual_perfiles (
  id bigint generated always as identity primary key,
  marca text not null check (marca in ('sabores','hex')),
  dni text not null check (dni ~ '^[0-9]{7,8}$'),
  nombre text not null check (char_length(btrim(nombre)) between 1 and 60),
  apellido text not null check (char_length(btrim(apellido)) between 1 and 60),
  local text check (local is null or char_length(btrim(local)) between 1 and 80),
  origen text not null default 'nuevo' check (origen in ('nuevo','campus')),
  progreso jsonb not null default '{}'::jsonb,
  accesos integer not null default 0,
  creado timestamptz not null default now(),
  ultimo_acceso timestamptz,
  unique (marca, dni)
);
alter table public.manual_perfiles enable row level security;
revoke all on public.manual_perfiles from anon, authenticated;

-- Datos del campus para un DNI (cualquier marca, priorizando la pedida)
create or replace function public.manual_datos_campus(p_marca text, p_dni text)
returns table(nombre text, apellido text, local text)
language sql stable security definer set search_path to 'public' as $$
  select nombre, apellido, local from (
    select nombre, apellido, local, marca, creado from examen_resultados where dni = p_dni
    union all select nombre, apellido, local, marca, creado from examen_citaciones where dni = p_dni
    union all select nombre, apellido, null, marca, creado from examen_habilitaciones where dni = p_dni
    union all select nombre, apellido, local, marca, inicio from examen_intentos where dni = p_dni
  ) t
  where coalesce(btrim(nombre),'') <> ''
  order by (marca = p_marca) desc, creado desc
  limit 1;
$$;

create or replace function public.manual_ingresar(p_marca text, p_dni text)
returns json language plpgsql security definer set search_path to 'public' as $$
declare
  v_dni text := regexp_replace(coalesce(p_dni,''), '[^0-9]', '', 'g');
  pf manual_perfiles;
  c record;
  aprob text[];
  roles text[] := array['emp'];
  puesto text;
begin
  if p_marca not in ('sabores','hex') then raise exception 'marca invalida'; end if;
  if v_dni !~ '^[0-9]{7,8}$' then raise exception 'dni invalido'; end if;

  select * into pf from manual_perfiles where marca = p_marca and dni = v_dni;
  if not found then
    select * into c from manual_datos_campus(p_marca, v_dni);
    if c.nombre is null then
      return json_build_object('nuevo', true);
    end if;
    insert into manual_perfiles (marca, dni, nombre, apellido, local, origen)
    values (p_marca, v_dni, left(btrim(c.nombre),60), left(coalesce(nullif(btrim(c.apellido),''),'-'),60), nullif(left(btrim(coalesce(c.local,'')),80),''), 'campus')
    on conflict (marca, dni) do nothing;
    select * into pf from manual_perfiles where marca = p_marca and dni = v_dni;
  end if;

  update manual_perfiles set accesos = accesos + 1, ultimo_acceso = now() where id = pf.id;

  aprob := niveles_aprobados(p_marca, v_dni);
  if aprob && array['entrenador','encargado','gerente'] then roles := roles || 'enc'; end if;
  if aprob && array['encargado','gerente'] then roles := roles || 'ger'; end if;
  puesto := case
    when 'gerente' = any(aprob) then 'Gerente'
    when 'encargado' = any(aprob) then 'Encargado de turno'
    when 'entrenador' = any(aprob) then 'Entrenador'
    else 'Empleado / Polivalente' end;

  return json_build_object(
    'nuevo', false,
    'nombre', pf.nombre,
    'apellido_inicial', left(pf.apellido, 1),
    'local', pf.local,
    'origen', pf.origen,
    'creado', pf.creado,
    'puesto', puesto,
    'aprobados', aprob,
    'roles', roles,
    'progreso', pf.progreso);
end;
$$;

create or replace function public.manual_crear_perfil(p_marca text, p_dni text, p_nombre text, p_apellido text, p_local text)
returns json language plpgsql security definer set search_path to 'public' as $$
declare
  v_dni text := regexp_replace(coalesce(p_dni,''), '[^0-9]', '', 'g');
begin
  if p_marca not in ('sabores','hex') then raise exception 'marca invalida'; end if;
  if v_dni !~ '^[0-9]{7,8}$' then raise exception 'dni invalido'; end if;
  if char_length(btrim(coalesce(p_nombre,''))) not between 1 and 60
     or char_length(btrim(coalesce(p_apellido,''))) not between 1 and 60
     or char_length(btrim(coalesce(p_local,''))) not between 1 and 80 then
    raise exception 'datos incompletos';
  end if;
  if not exists (select 1 from manual_perfiles where marca = p_marca and dni = v_dni)
     and not exists (select 1 from manual_datos_campus(p_marca, v_dni)) then
    insert into manual_perfiles (marca, dni, nombre, apellido, local, origen)
    values (p_marca, v_dni, btrim(p_nombre), btrim(p_apellido), btrim(p_local), 'nuevo');
  end if;
  return manual_ingresar(p_marca, v_dni);
end;
$$;

create or replace function public.manual_guardar_progreso(p_marca text, p_dni text, p_progreso jsonb)
returns void language plpgsql security definer set search_path to 'public' as $$
begin
  if jsonb_typeof(p_progreso) <> 'object' or octet_length(p_progreso::text) > 20000 then
    raise exception 'progreso invalido';
  end if;
  update manual_perfiles set progreso = p_progreso
  where marca = p_marca and dni = regexp_replace(coalesce(p_dni,''), '[^0-9]', '', 'g');
end;
$$;

create or replace function public.manual_perfiles_listado(p_clave text)
returns table(id bigint, marca text, dni text, nombre text, apellido text, local text, origen text, accesos integer, creado timestamptz, ultimo_acceso timestamptz, progreso jsonb)
language plpgsql stable security definer set search_path to 'public' as $$
begin
  if not clave_valida(p_clave) then raise exception 'clave incorrecta'; end if;
  return query select m.id, m.marca, m.dni, m.nombre, m.apellido, m.local, m.origen, m.accesos, m.creado, m.ultimo_acceso, m.progreso
    from manual_perfiles m order by m.creado desc;
end;
$$;

revoke execute on function public.manual_datos_campus(text,text) from public, anon, authenticated;
grant execute on function public.manual_ingresar(text,text) to anon, authenticated;
grant execute on function public.manual_crear_perfil(text,text,text,text,text) to anon, authenticated;
grant execute on function public.manual_guardar_progreso(text,text,jsonb) to anon, authenticated;
grant execute on function public.manual_perfiles_listado(text) to anon, authenticated;
