-- ============================================================
-- Empanada Mania: actualización del banco de Entrenador
-- (devolución de Capacitación, 04/11/2026) + pinza plateada de Sabores
--  · Mania Entrenador (21):
--      1: horno POWER HOT con distractores nuevos (sigue siendo 6 a 8 minutos).
--     14: pasa a ser el leudado de las chipás (sale la del agua sanitizada).
--     17: pasa a ser pizza cortada al entregarla (sale la del extintor ABC).
--     19: pinza plateada, la correcta pasa a "Para empanadas".
--     20 y 21 (nuevas): papel manteca y porciones de la pizza.
--  · Sabores (Entrenador, Encargado y Gerente): la pinza plateada también
--    pasa a "Para empanadas".
-- Las preguntas corregidas conservan su id; las nuevas llevan id nuevo.
-- La opción correcta va primera. Nadie había rendido todavía las preguntas
-- de pinza plateada, así que no hay resultados guardados afectados.
-- Se puede volver a correr sin romper nada.
-- Correr completo en Supabase > SQL Editor.
-- (Sin signos pesos ni barras invertidas dentro de textos: el SQL Editor de Supabase los interpreta mal.)
-- ============================================================

begin;

-- ---------- Mania · Entrenador ----------
delete from public.preguntas where marca = 'mania' and nivel = 'entrenador' and id in (615, 618);

update public.preguntas set opciones = '["6 a 8 minutos","11 a 13 minutos","11 a 14 minutos","10 a 11 minutos"]'::jsonb
 where marca = 'mania' and nivel = 'entrenador' and id = 601;
update public.preguntas set opciones = '["Para empanadas","Para las delicias","Únicamente para medialunas","Para todo excepto medialunas"]'::jsonb
 where marca = 'mania' and nivel = 'entrenador' and id = 620;

insert into public.preguntas (marca, nivel, id, orden, tipo, texto, opciones, filas, columnas, correcta) values
  ('mania', 'entrenador', 621, 14, 'opciones', '¿Cuánto tiempo se deben leudar las chipás?', '["No es procedimiento","8 horas exactas","8 horas, dependiendo del clima","De 5 a 8 horas"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 622, 17, 'opciones', '¿Debemos cortar la pizza cuando se la entregamos al cliente?', '["Sí, debe ir cortada","No, el cliente la corta","Solo si el cliente lo solicita","No, solo le consultamos por el orégano"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 623, 20, 'opciones', '¿Cuántas veces podemos utilizar el papel manteca?', '["2 veces","3 veces","1 vez","8 horas"]'::jsonb, null, null, '0'::jsonb),
  ('mania', 'entrenador', 624, 21, 'opciones', '¿En cuántas porciones cortamos la pizza?', '["En 8 porciones","En 4 porciones","En 7 porciones","En 10 porciones"]'::jsonb, null, null, '0'::jsonb)
on conflict (marca, nivel, id) do update set
  orden = excluded.orden, tipo = excluded.tipo, texto = excluded.texto, opciones = excluded.opciones,
  filas = excluded.filas, columnas = excluded.columnas, correcta = excluded.correcta;

update public.preguntas p set orden = v.orden
  from (values
    (601, 1), (602, 2), (603, 3), (604, 4), (605, 5), (606, 6), (607, 7), (608, 8), (609, 9), (610, 10),
    (611, 11), (612, 12), (614, 13), (621, 14), (616, 15), (617, 16), (622, 17), (619, 18), (620, 19),
    (623, 20), (624, 21)
  ) as v(id, orden)
 where p.marca = 'mania' and p.nivel = 'entrenador' and p.id = v.id;

-- ---------- Sabores · pinza plateada ----------
update public.preguntas set opciones = '["Para empanadas","Para las delicias","Únicamente para medialunas","Para todo excepto medialunas"]'::jsonb
 where marca = 'sabores' and ((nivel = 'entrenador' and id = 23) or (nivel = 'encargado' and id = 122) or (nivel = 'gerente' and id = 222));

commit;
