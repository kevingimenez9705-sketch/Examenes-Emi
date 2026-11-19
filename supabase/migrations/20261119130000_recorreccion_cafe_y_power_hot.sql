-- ============================================================
-- Recorrección de exámenes ya rendidos (pedido de Capacitación, 19/11/2026)
-- Con las correctas nuevas de 20261119120000_sabores_y_extremas_correcciones.sql:
--  · Extremas Encargado, medidas de café (id 428): correcta = "Latte 50% leche y
--    50% café, Cortado 90% café y 10% café, Expresso 100% café".
--  · Sabores Entrenador, horno POWER HOT (id 21): correcta = "6 a 8 minutos".
-- Para cada examen donde esa pregunta cambia de correcta a incorrecta (o al revés)
-- se actualizan el detalle, los aciertos, el porcentaje y la condición (80% aprueba).
-- La nota y la condición anteriores quedan en payload.recorreccion para poder deshacerlo.
-- Solo toca los exámenes cuyo detalle no coincide con la correcta nueva, así que
-- se puede volver a correr sin romper nada.
-- Correr completo en Supabase > SQL Editor.
-- ============================================================

begin;

with afectados as (
  select r.id, r.porcentaje, r.condicion, (d.ord - 1)::int as idx, (d.elem->>'id')::int as pregunta_id,
         (r.payload->>'aciertos')::int as aciertos, (r.payload->>'total_preguntas')::int as total,
         case when (r.marca = 'hex' and d.elem->>'respuesta' = 'Latte 50% leche y 50% café, Cortado 90% café y 10% café, Expresso 100% café')
                or (r.marca = 'sabores' and d.elem->>'respuesta' = '6 a 8 minutos')
              then 'correcta' else 'incorrecta' end as nuevo
    from public.examen_resultados r,
         jsonb_array_elements(r.payload->'detalle') with ordinality as d(elem, ord)
   where ((r.marca = 'hex' and r.nivel = 'encargado' and (d.elem->>'id')::int = 428)
       or (r.marca = 'sabores' and r.nivel = 'entrenador' and (d.elem->>'id')::int = 21))
     and r.payload ? 'aciertos' and r.payload ? 'total_preguntas'
), cambios as (
  select a.*, a.aciertos + case when a.nuevo = 'correcta' then 1 else -1 end as nuevos_aciertos
    from afectados a
    join public.examen_resultados r on r.id = a.id
   where r.payload #>> array['detalle', a.idx::text, 'resultado'] is distinct from a.nuevo
     and a.total > 0
)
update public.examen_resultados r
   set porcentaje = round(100.0 * c.nuevos_aciertos / c.total),
       condicion = case when round(100.0 * c.nuevos_aciertos / c.total) >= 80 then 'Aprobado' else 'Desaprobado' end,
       payload = jsonb_set(
                   jsonb_set(
                     jsonb_set(r.payload, array['detalle', c.idx::text, 'resultado'], to_jsonb(c.nuevo)),
                     '{aciertos}', to_jsonb(c.nuevos_aciertos)),
                   '{recorreccion}',
                   coalesce(r.payload->'recorreccion', '[]'::jsonb) || jsonb_build_array(jsonb_build_object(
                     'fecha', now(), 'pregunta_id', c.pregunta_id, 'motivo', 'cambio de respuesta correcta',
                     'porcentaje_anterior', c.porcentaje, 'condicion_anterior', c.condicion)))
  from cambios c
 where r.id = c.id;

commit;
