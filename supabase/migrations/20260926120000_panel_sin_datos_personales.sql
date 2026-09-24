-- ============================================================
-- Panel sin datos personales
--  · examenes_panel: el payload se arma con una lista blanca de campos
--    del examen (antes se quitaban dni/postulante/correo, y cualquier otro
--    dato personal de payloads viejos quedaba expuesto). Misma firma: el
--    Campus sigue funcionando sin cambios.
--  · search_path fijo en texto_respuesta y limite_citacion (Security Advisor).
-- ============================================================

create or replace function public.examenes_panel()
returns table (id bigint, marca text, local text, nombre text, apellido text, nivel text,
               porcentaje int, condicion text, payload jsonb, creado timestamptz)
language sql stable security definer set search_path = public as $$
  select id, marca, local, nombre, apellido, nivel, porcentaje, condicion,
         jsonb_build_object(
           'motivo_cierre', payload->'motivo_cierre',
           'inicio', payload->'inicio',
           'fin', payload->'fin',
           'segundos_usados', payload->'segundos_usados',
           'respondidas', payload->'respondidas',
           'total_preguntas', payload->'total_preguntas',
           'aciertos', payload->'aciertos',
           'detalle', payload->'detalle'),
         creado
  from examen_resultados order by creado desc;
$$;

revoke all on function public.examenes_panel() from public;
grant execute on function public.examenes_panel() to anon;

alter function public.texto_respuesta(public.preguntas, jsonb) set search_path = public;
alter function public.limite_citacion(date) set search_path = public;
