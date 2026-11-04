-- ============================================================
-- Sabores Express: actualización del banco de preguntas
-- (devolución de Capacitación, 04/11/2026, a partir del % de error del Campus)
--  · Entrenador (20): se corrigen 3, 4, 5, 7, 10 y 19; la 13 pasa a ser el
--    horno POWER HOT, la 18 la pinza roja y la 20 la pinza plateada
--    (se retiran mercadería de fábrica, promo de 2 empanadas y tacho verde).
--  · Encargado (18): se retiran la 3, 5, 6, 10, 11, 12, 17 y 18; se corrige la 14;
--    se suman pinza roja, pinza plateada, aceitunas, inspección de extintores,
--    tacho verde y pizza cortada en delivery.
--  · Gerente (20): se retiran la 10, 14 y 15; se corrige la 16; se suman
--    pinza roja, pinza plateada y pizza cortada en delivery.
-- Las preguntas corregidas conservan su id; las nuevas llevan id nuevo, así el
-- % de error del Campus arranca de cero para ellas. La opción correcta va primera.
-- Los resultados ya guardados no cambian (guardan el texto de cada pregunta).
-- Se puede volver a correr sin romper nada.
-- Correr completo en Supabase > SQL Editor.
-- (Sin signos pesos ni barras invertidas dentro de textos: el SQL Editor de Supabase los interpreta mal.)
-- ============================================================

begin;

-- ---------- Entrenador ----------
delete from public.preguntas where marca = 'sabores' and nivel = 'entrenador' and id in (13, 18, 20);

update public.preguntas set opciones = '["8 unidades, sin que se toquen","6 unidades, sin que se toquen","10 unidades, sin que se toquen","12 unidades, sin que se toquen"]'::jsonb
 where marca = 'sabores' and nivel = 'entrenador' and id = 3;
update public.preguntas set texto = '¿Cuál es el vencimiento de la empanada de jamón y queso?'
 where marca = 'sabores' and nivel = 'entrenador' and id = 4;
update public.preguntas set texto = '¿Cuál es el vencimiento de la empanada de humita?'
 where marca = 'sabores' and nivel = 'entrenador' and id = 5;
update public.preguntas set texto = '¿Cuánto tiempo de leudado necesita una medialuna?',
       opciones = '["8 horas, 28 por bandeja en 4 filas de 7","7 horas, 28 por bandeja en 4 filas de 7","8 horas, 32 por bandeja en 4 filas de 8","6 horas, 24 por bandeja en 4 filas de 6"]'::jsonb
 where marca = 'sabores' and nivel = 'entrenador' and id = 7;
update public.preguntas set opciones = '["5 por estante, sectorizadas por gusto","4 por estante, sectorizadas por gusto","6 por estante, sectorizadas por gusto","3 por estante, sectorizadas por gusto"]'::jsonb
 where marca = 'sabores' and nivel = 'entrenador' and id = 10;
update public.preguntas set texto = '¿Cuál de los siguientes extintores es el más versátil para cubrir casi todos los tipos de fuego?'
 where marca = 'sabores' and nivel = 'entrenador' and id = 19;

insert into public.preguntas (marca, nivel, id, orden, tipo, texto, opciones, filas, columnas, correcta) values
  ('sabores', 'entrenador', 21, 13, 'opciones', '¿Cuál es el tiempo de cinta del horno POWER HOT?', '["6 a 8 minutos","5 a 7 minutos","3 a 5 minutos","10 a 11 minutos"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'entrenador', 22, 18, 'opciones', '¿Para qué se utiliza la pinza roja?', '["Para las delicias","Para empanadas","Únicamente para medialunas","Para todo excepto medialunas"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'entrenador', 23, 20, 'opciones', '¿Para qué se utiliza la pinza plateada?', '["Para las delicias","Para empanadas","Únicamente para medialunas","Para todo excepto medialunas"]'::jsonb, null, null, '0'::jsonb)
on conflict (marca, nivel, id) do update set
  orden = excluded.orden, tipo = excluded.tipo, texto = excluded.texto, opciones = excluded.opciones,
  filas = excluded.filas, columnas = excluded.columnas, correcta = excluded.correcta;

-- ---------- Encargado ----------
delete from public.preguntas where marca = 'sabores' and nivel = 'encargado' and id in (103, 105, 106, 110, 111, 112, 117, 118);

update public.preguntas set texto = 'Si se corta la luz y activamos el protocolo, ¿a qué equipos debemos darles prioridad?'
 where marca = 'sabores' and nivel = 'encargado' and id = 114;

insert into public.preguntas (marca, nivel, id, orden, tipo, texto, opciones, filas, columnas, correcta) values
  ('sabores', 'encargado', 121, 13, 'opciones', '¿Para qué se utiliza la pinza roja?', '["Para las delicias","Para empanadas","Únicamente para medialunas","Para todo excepto medialunas"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'encargado', 122, 14, 'opciones', '¿Para qué se utiliza la pinza plateada?', '["Para las delicias","Para empanadas","Únicamente para medialunas","Para todo excepto medialunas"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'encargado', 123, 15, 'opciones', 'Según la última actualización, ¿cuántas aceitunas debemos colocar en las pizzas?', '["No es procedimiento","8 unidades","12 unidades","4 unidades"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'encargado', 124, 16, 'opciones', '¿Con qué frecuencia mínima se debe realizar una inspección visual a los extintores, según las buenas prácticas?', '["Mensual","Anual","Semanal","Diario"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'encargado', 125, 17, 'opciones', '¿Qué tipo de residuo debe colocarse en el tacho de color verde?', '["Residuos reciclables","Residuos húmedos u orgánicos","Basura"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'encargado', 126, 18, 'opciones', '¿Debemos cortar la pizza cuando la enviamos por delivery?', '["Sí, debe ir cortada","No, la corta el cliente"]'::jsonb, null, null, '0'::jsonb)
on conflict (marca, nivel, id) do update set
  orden = excluded.orden, tipo = excluded.tipo, texto = excluded.texto, opciones = excluded.opciones,
  filas = excluded.filas, columnas = excluded.columnas, correcta = excluded.correcta;

-- ---------- Gerente ----------
delete from public.preguntas where marca = 'sabores' and nivel = 'gerente' and id in (210, 214, 215);

update public.preguntas set opciones = '["Adjuntar el certificado médico; el reposo vale solo si está indicado en él","Deben dar aviso por WhatsApp","Deben dar aviso por mail","Autorización del responsable"]'::jsonb
 where marca = 'sabores' and nivel = 'gerente' and id = 216;

insert into public.preguntas (marca, nivel, id, orden, tipo, texto, opciones, filas, columnas, correcta) values
  ('sabores', 'gerente', 221, 18, 'opciones', '¿Para qué se utiliza la pinza roja?', '["Para las delicias","Para empanadas","Únicamente para medialunas","Para todo excepto medialunas"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'gerente', 222, 19, 'opciones', '¿Para qué se utiliza la pinza plateada?', '["Para las delicias","Para empanadas","Únicamente para medialunas","Para todo excepto medialunas"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'gerente', 223, 20, 'opciones', '¿Debemos cortar la pizza cuando la enviamos por delivery?', '["Sí, debe ir cortada","No, la corta el cliente"]'::jsonb, null, null, '0'::jsonb)
on conflict (marca, nivel, id) do update set
  orden = excluded.orden, tipo = excluded.tipo, texto = excluded.texto, opciones = excluded.opciones,
  filas = excluded.filas, columnas = excluded.columnas, correcta = excluded.correcta;

-- ---------- Orden final (el número que se ve en el banco del Campus) ----------
update public.preguntas p set orden = v.orden
  from (values
    ('entrenador', 1, 1), ('entrenador', 2, 2), ('entrenador', 3, 3), ('entrenador', 4, 4), ('entrenador', 5, 5),
    ('entrenador', 6, 6), ('entrenador', 7, 7), ('entrenador', 8, 8), ('entrenador', 9, 9), ('entrenador', 10, 10),
    ('entrenador', 11, 11), ('entrenador', 12, 12), ('entrenador', 21, 13), ('entrenador', 14, 14), ('entrenador', 15, 15),
    ('entrenador', 16, 16), ('entrenador', 17, 17), ('entrenador', 22, 18), ('entrenador', 19, 19), ('entrenador', 23, 20),
    ('encargado', 101, 1), ('encargado', 102, 2), ('encargado', 104, 3), ('encargado', 107, 4), ('encargado', 108, 5),
    ('encargado', 109, 6), ('encargado', 113, 7), ('encargado', 114, 8), ('encargado', 115, 9), ('encargado', 116, 10),
    ('encargado', 119, 11), ('encargado', 120, 12), ('encargado', 121, 13), ('encargado', 122, 14), ('encargado', 123, 15),
    ('encargado', 124, 16), ('encargado', 125, 17), ('encargado', 126, 18),
    ('gerente', 201, 1), ('gerente', 202, 2), ('gerente', 203, 3), ('gerente', 204, 4), ('gerente', 205, 5),
    ('gerente', 206, 6), ('gerente', 207, 7), ('gerente', 208, 8), ('gerente', 209, 9), ('gerente', 211, 10),
    ('gerente', 212, 11), ('gerente', 213, 12), ('gerente', 216, 13), ('gerente', 217, 14), ('gerente', 218, 15),
    ('gerente', 219, 16), ('gerente', 220, 17), ('gerente', 221, 18), ('gerente', 222, 19), ('gerente', 223, 20)
  ) as v(nivel, id, orden)
 where p.marca = 'sabores' and p.nivel = v.nivel and p.id = v.id;

commit;
