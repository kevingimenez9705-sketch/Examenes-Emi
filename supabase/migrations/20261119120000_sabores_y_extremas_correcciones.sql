-- ============================================================
-- Sabores y Extremas: correcciones de Capacitación (19/11/2026)
--
-- SABORES
--  · Entrenador (20): la 13 (horno POWER HOT) vuelve a tener como correcta
--    "6 a 8 minutos".
--  · Encargado (25): la 3 pasa a "¿Qué mide el AWT?"; suma cómo tomar la
--    temperatura de una empanada y papel manteca (copias de Gerente).
--  · Gerente (30): se retira la 13 (tope para comprar a un distribuidor
--    externo); suma objetivo de Inaccuracy por local, qué mide el Inaccuracy
--    y prioridad de equipos en un corte de luz (copias de Encargado).
--
-- EXTREMAS
--  · Entrenador (20): la 18 (parrilla) cambia el texto; también su copia en Gerente (24).
--  · Encargado (25): la 20 (medidas de café) cambia la correcta; se retiran
--    la 10 (distribuidor externo de Coca-Cola) y la 18 (topping del Swing);
--    suma visión y misión de la compañía.
--  · Gerente (30): cambian las opciones de la 3 (REBA) y la 4 (daño en el inmueble).
--
-- Las copias se toman de la pregunta original, con id nuevo, así el % de error
-- del Campus arranca de cero. La opción correcta va primera.
-- Los resultados ya guardados no cambian (guardan su corrección del momento).
-- Se puede volver a correr sin romper nada.
-- Correr completo en Supabase > SQL Editor.
-- (Sin signos pesos ni barras invertidas dentro de textos: el SQL Editor de Supabase los interpreta mal.)
-- ============================================================

begin;

-- ================= SABORES =================
update public.preguntas
   set opciones = '["6 a 8 minutos","11 a 13 minutos","11 a 14 minutos","10 a 11 minutos"]'::jsonb, correcta = '0'::jsonb
 where marca = 'sabores' and nivel = 'entrenador' and id = 21;

update public.preguntas set texto = '¿Qué mide el AWT?'
 where marca = 'sabores' and nivel = 'encargado' and id = 104;

delete from public.preguntas where marca = 'sabores' and nivel = 'gerente' and id = 217;

insert into public.preguntas (marca, nivel, id, orden, tipo, texto, opciones, filas, columnas, correcta)
select 'sabores', c.nivel, c.nuevo, c.orden, p.tipo, p.texto, p.opciones, p.filas, p.columnas, p.correcta
  from (values
    ('gerente',   229, 'encargado', 132, 24),
    ('gerente',   230, 'encargado', 133, 25),
    ('encargado', 102, 'gerente',   233, 28),
    ('encargado', 101, 'gerente',   234, 29),
    ('encargado', 114, 'gerente',   235, 30)
  ) as c(nivel_origen, origen, nivel, nuevo, orden)
  join public.preguntas p on p.marca = 'sabores' and p.nivel = c.nivel_origen and p.id = c.origen
on conflict (marca, nivel, id) do update set
  orden = excluded.orden, tipo = excluded.tipo, texto = excluded.texto, opciones = excluded.opciones,
  filas = excluded.filas, columnas = excluded.columnas, correcta = excluded.correcta;

update public.preguntas p set orden = v.orden
  from (values
    (201, 1), (202, 2), (204, 3), (205, 4), (206, 5), (207, 6), (208, 7), (209, 8), (211, 9), (212, 10),
    (213, 11), (216, 12), (218, 13), (219, 14), (220, 15), (221, 16), (222, 17), (223, 18), (224, 19), (225, 20),
    (226, 21), (227, 22), (228, 23), (229, 24), (230, 25), (231, 26), (232, 27)
  ) as v(id, orden)
 where p.marca = 'sabores' and p.nivel = 'gerente' and p.id = v.id;

-- ================= EXTREMAS =================
update public.preguntas set texto = '¿Cuál de las siguientes opciones es la temperatura adecuada para la cocción de carnes en la parrilla?'
 where marca = 'hex' and ((nivel = 'entrenador' and id = 322) or (nivel = 'gerente' and id = 531));

update public.preguntas
   set opciones = '["Latte 50% leche y 50% café, Cortado 90% café y 10% café, Expresso 100% café","Latte 90% leche y 10% café, Cortado 90% café y 10% leche, Expresso 100% café","Latte 90% café y 10% leche, Cortado 90% leche y 10% café, Expresso 100% café","Latte 50% leche y 50% café, Cortado 100% café, Expresso 90% café y 10% leche"]'::jsonb,
       correcta = '0'::jsonb
 where marca = 'hex' and nivel = 'encargado' and id = 428;

delete from public.preguntas where marca = 'hex' and nivel = 'encargado' and id in (417, 426);

insert into public.preguntas (marca, nivel, id, orden, tipo, texto, opciones, filas, columnas, correcta) values
  ('hex', 'encargado', 433, 24, 'opciones', '¿Cuál es la visión de la compañía?', '["Ser la empresa líder en la comercialización de productos alimenticios en forma take away y delivery a nivel nacional","Satisfacer las necesidades del cliente con un vínculo comercial sustentable, la mejor calidad al menor precio posible","Honestidad, integridad y respeto","Abrir la mayor cantidad de locales posible"]'::jsonb, null, null, '0'::jsonb),
  ('hex', 'encargado', 434, 25, 'opciones', '¿Cuál es la misión de la compañía?', '["Satisfacer las necesidades del cliente con un vínculo comercial sustentable, la mejor calidad al menor precio posible","Ser la empresa líder en take away y delivery a nivel nacional","Honestidad, integridad y respeto","Abrir la mayor cantidad de locales posible"]'::jsonb, null, null, '0'::jsonb)
on conflict (marca, nivel, id) do update set
  orden = excluded.orden, tipo = excluded.tipo, texto = excluded.texto, opciones = excluded.opciones,
  filas = excluded.filas, columnas = excluded.columnas, correcta = excluded.correcta;

update public.preguntas p set orden = v.orden
  from (values
    (401, 1), (405, 2), (406, 3), (407, 4), (408, 5), (409, 6), (412, 7), (413, 8), (414, 9), (418, 10),
    (420, 11), (421, 12), (422, 13), (423, 14), (424, 15), (425, 16), (427, 17), (428, 18), (302, 19), (430, 20),
    (431, 21), (432, 22), (325, 23)
  ) as v(id, orden)
 where p.marca = 'hex' and p.nivel = 'encargado' and p.id = v.id;

update public.preguntas
   set opciones = '["1 año; avisar 60 días antes a Habilitaciones","2 años; avisar 30 días antes a Habilitaciones","1 año; avisar 7 días antes a Habilitaciones","6 meses; avisar 15 días antes a Habilitaciones"]'::jsonb,
       correcta = '0'::jsonb
 where marca = 'hex' and nivel = 'gerente' and id = 503;

update public.preguntas
   set opciones = '["Dentro de las primeras 72 horas; pasado el plazo el seguro no cubre","Dentro de los primeros 15 días; pasado el plazo el seguro no cubre","A fin de mes","No hay plazo determinado"]'::jsonb,
       correcta = '0'::jsonb
 where marca = 'hex' and nivel = 'gerente' and id = 505;

commit;
