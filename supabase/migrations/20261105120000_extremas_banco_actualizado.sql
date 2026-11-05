-- ============================================================
-- Hamburguesas Extremas: actualización del banco de preguntas
-- (devolución de Capacitación, 05/11/2026)
--  · Entrenador (21): la 2 (recorrido de la cadena del broiler) pasa a Encargado;
--    se corrigen la 7 (enemigos del aceite) y la 8 (cestas de papas); se suman
--    parrilla, retención de carne en el PHU, cámara y precámara.
--  · Encargado (24): se retiran la 2, 3, 10 y 25; la 4 (teflón del rodadero) pasa
--    a Gerente; se corrige la 24 (medidas de café); se suman vencimiento de
--    toppings, topping del Swing de Oreo y vencimiento de la leche abierta.
--  · Gerente (28): suma la del teflón del rodadero, las 4 nuevas de Entrenador
--    (parrilla, PHU, cámara, precámara) y la del bajo mesada.
-- Las preguntas que cambian de nivel conservan su id. Las nuevas llevan id nuevo,
-- así el % de error del Campus arranca de cero para ellas. La opción correcta va primera.
-- Los resultados ya guardados no cambian (guardan el texto de cada pregunta).
-- Se puede volver a correr sin romper nada.
-- Correr completo en Supabase > SQL Editor.
-- (Sin signos pesos ni barras invertidas dentro de textos: el SQL Editor de Supabase los interpreta mal.)
-- ============================================================

begin;

-- ---------- Cambios de nivel ----------
update public.preguntas set nivel = 'encargado' where marca = 'hex' and nivel = 'entrenador' and id = 302;
update public.preguntas set nivel = 'gerente'   where marca = 'hex' and nivel = 'encargado'  and id = 404;

-- ---------- Entrenador ----------
update public.preguntas set opciones = '["Agua, carbonilla y sal","Azúcar, luz y frío","Agua","El uso de cestas limpias"]'::jsonb
 where marca = 'hex' and nivel = 'entrenador' and id = 307;
update public.preguntas set texto = 'Si debemos activar 4 cestas de papas, ¿cuál sería la forma correcta?',
       opciones = '["Siempre de forma intercalada (1 - 3 - 2 - 4) para que el aceite no baje de temperatura","Todas juntas para ganar tiempo, ya que la operación lo demanda","De a una y esperando que termine la anterior, y la temperatura no baje","En el orden que me diga mi encargado"]'::jsonb
 where marca = 'hex' and nivel = 'entrenador' and id = 308;

-- ---------- Encargado ----------
delete from public.preguntas where marca = 'hex' and nivel = 'encargado' and id in (402, 403, 411, 429);
update public.preguntas set opciones = '["Latte 90% leche y 10% café, Cortado 90% café y 10% leche, Expresso 100% café","Latte 90% café y 10% leche, Cortado 90% leche y 10% café, Expresso 100% café","Latte 50% leche y 50% café, Cortado 100% café, Expresso 90% café y 10% leche","Latte 50% leche y 50% café, Cortado 90% café y 10% café, Expresso 100% café"]'::jsonb
 where marca = 'hex' and nivel = 'encargado' and id = 428;

-- ---------- Preguntas nuevas ----------
insert into public.preguntas (marca, nivel, id, orden, tipo, texto, opciones, filas, columnas, correcta) values
  ('hex', 'entrenador', 322, 18, 'opciones', '¿Cuál de las siguientes opciones es la temperatura adecuada para la parrilla?', '["210° a 220°","200° a 220°","220° a 250°","180° a 200°"]'::jsonb, null, null, '0'::jsonb),
  ('hex', 'entrenador', 323, 19, 'opciones', '¿Cuál es el tiempo de retención de una carne en el PHU?', '["30 minutos","15 minutos","15 minutos carnes junior y 30 minutos carnes grandes","1 hora"]'::jsonb, null, null, '0'::jsonb),
  ('hex', 'entrenador', 324, 20, 'opciones', '¿Cuál es la temperatura adecuada en la que debe estar la cámara?', '["-18° a -24°","-18° a -23°","0° a 5°","0° a -5°"]'::jsonb, null, null, '0'::jsonb),
  ('hex', 'entrenador', 325, 21, 'opciones', '¿Cuál es la temperatura adecuada en la que debe estar la precámara?', '["0° a 5°","-18° a -23°","18° a 23°","0° a -5°"]'::jsonb, null, null, '0'::jsonb),
  ('hex', 'encargado', 430, 22, 'opciones', '¿Cuál es el vencimiento de los toppings en los recipientes?', '["72 horas","48 horas","24 horas","6 horas"]'::jsonb, null, null, '0'::jsonb),
  ('hex', 'encargado', 431, 23, 'opciones', '¿Cuántos gramos de topping lleva el Swing de Oreo?', '["30 gramos","35 gramos","15 gramos","36 gramos"]'::jsonb, null, null, '0'::jsonb),
  ('hex', 'encargado', 432, 24, 'opciones', '¿Cuál es el vencimiento de la leche una vez abierta?', '["24 horas","48 horas","12 horas","Hasta el cierre"]'::jsonb, null, null, '0'::jsonb),
  ('hex', 'gerente', 531, 24, 'opciones', '¿Cuál de las siguientes opciones es la temperatura adecuada para la parrilla?', '["210° a 220°","200° a 220°","220° a 250°","180° a 200°"]'::jsonb, null, null, '0'::jsonb),
  ('hex', 'gerente', 532, 25, 'opciones', '¿Cuál es el tiempo de retención de una carne en el PHU?', '["30 minutos","15 minutos","15 minutos carnes junior y 30 minutos carnes grandes","1 hora"]'::jsonb, null, null, '0'::jsonb),
  ('hex', 'gerente', 533, 26, 'opciones', '¿Cuál es la temperatura adecuada en la que debe estar la cámara?', '["-18° a -24°","-18° a -23°","0° a 5°","0° a -5°"]'::jsonb, null, null, '0'::jsonb),
  ('hex', 'gerente', 534, 27, 'opciones', '¿Cuál es la temperatura adecuada en la que debe estar la precámara?', '["0° a 5°","-18° a -23°","18° a 23°","0° a -5°"]'::jsonb, null, null, '0'::jsonb),
  ('hex', 'gerente', 535, 28, 'opciones', '¿Cuál es la temperatura del bajo mesada?', '["De 0° a 5°","De -15° a -23°","De 0° a -5°","De -18° a -24°"]'::jsonb, null, null, '0'::jsonb)
on conflict (marca, nivel, id) do update set
  orden = excluded.orden, tipo = excluded.tipo, texto = excluded.texto, opciones = excluded.opciones,
  filas = excluded.filas, columnas = excluded.columnas, correcta = excluded.correcta;

-- ---------- Orden final (el número que se ve en el banco del Campus) ----------
update public.preguntas p set orden = v.orden
  from (values
    ('entrenador', 301, 1), ('entrenador', 303, 2), ('entrenador', 304, 3), ('entrenador', 305, 4), ('entrenador', 306, 5),
    ('entrenador', 307, 6), ('entrenador', 308, 7), ('entrenador', 309, 8), ('entrenador', 310, 9), ('entrenador', 321, 10),
    ('entrenador', 312, 11), ('entrenador', 313, 12), ('entrenador', 314, 13), ('entrenador', 315, 14), ('entrenador', 316, 15),
    ('entrenador', 319, 16), ('entrenador', 320, 17), ('entrenador', 322, 18), ('entrenador', 323, 19), ('entrenador', 324, 20),
    ('entrenador', 325, 21),
    ('encargado', 401, 1), ('encargado', 405, 2), ('encargado', 406, 3), ('encargado', 407, 4), ('encargado', 408, 5),
    ('encargado', 409, 6), ('encargado', 412, 7), ('encargado', 413, 8), ('encargado', 414, 9), ('encargado', 417, 10),
    ('encargado', 418, 11), ('encargado', 420, 12), ('encargado', 421, 13), ('encargado', 422, 14), ('encargado', 423, 15),
    ('encargado', 424, 16), ('encargado', 425, 17), ('encargado', 426, 18), ('encargado', 427, 19), ('encargado', 428, 20),
    ('encargado', 302, 21), ('encargado', 430, 22), ('encargado', 431, 23), ('encargado', 432, 24),
    ('gerente', 501, 1), ('gerente', 502, 2), ('gerente', 503, 3), ('gerente', 505, 4), ('gerente', 507, 5),
    ('gerente', 510, 6), ('gerente', 512, 7), ('gerente', 513, 8), ('gerente', 515, 9), ('gerente', 518, 10),
    ('gerente', 519, 11), ('gerente', 520, 12), ('gerente', 521, 13), ('gerente', 522, 14), ('gerente', 523, 15),
    ('gerente', 524, 16), ('gerente', 525, 17), ('gerente', 526, 18), ('gerente', 527, 19), ('gerente', 528, 20),
    ('gerente', 529, 21), ('gerente', 530, 22), ('gerente', 404, 23), ('gerente', 531, 24), ('gerente', 532, 25),
    ('gerente', 533, 26), ('gerente', 534, 27), ('gerente', 535, 28)
  ) as v(nivel, id, orden)
 where p.marca = 'hex' and p.nivel = v.nivel and p.id = v.id;

commit;
