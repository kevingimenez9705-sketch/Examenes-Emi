-- ============================================================
-- Resultado con preguntas incorrectas
--  · entregar_examen devuelve además 'incorrectas': las preguntas que el
--    postulante respondió mal o dejó sin responder, con su respuesta.
--    No incluye la respuesta correcta (el banco no se filtra para reintentos).
--  · El resto de la función no cambia.
-- Correr completo en Supabase > SQL Editor.
-- ============================================================

create or replace function public.entregar_examen(p_token uuid, p_respuestas jsonb, p_motivo text)
returns json language plpgsql security definer set search_path = public as $$
declare
  t examen_intentos;
  p preguntas;
  r jsonb;
  total int := 0;
  ok int := 0;
  respondidas int := 0;
  detalle jsonb := '[]'::jsonb;
  incorrectas jsonb := '[]'::jsonb;
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
    if r = p.correcta then
      ok := ok + 1;
    else
      incorrectas := incorrectas || jsonb_build_array(jsonb_build_object(
        'pregunta', p.texto, 'respuesta', texto_respuesta(p, r)));
    end if;
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

  return json_build_object('porcentaje', pct, 'condicion', cond,
    'aciertos', ok, 'total', total, 'incorrectas', incorrectas);
end;
$$;

revoke all on function public.entregar_examen(uuid,jsonb,text) from public;
grant execute on function public.entregar_examen(uuid,jsonb,text) to anon;
