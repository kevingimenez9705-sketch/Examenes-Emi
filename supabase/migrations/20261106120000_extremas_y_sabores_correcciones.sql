-- ============================================================
-- Extremas y Sabores: correcciones de Capacitación (06/11/2026)
--
-- EXTREMAS
--  · Entrenador (20): la 18 (parrilla) cambia el texto, también su copia en
--    Gerente; la 21 (precámara) pasa a Encargado.
--  · Encargado (25): la 13 (tostadora Spidocook) y la 16 (carnes congeladas)
--    cambian el texto; suma la precámara.
--  · Gerente (30): suma copias de la 3 (temperatura interna de la carne) y la 1
--    (temperatura del broiler) de Entrenador, que también quedan en Entrenador.
--
-- SABORES
--  · Encargado (23): suma misión, visión, onboarding, cultura organizacional y
--    pase de turno con diferencia negativa.
--  · Gerente (28): se retira la 3 (botón Volver del inventario); suma visión,
--    onboarding, cultura organizacional, empanadas verticales por bandeja,
--    conteo de fin de mes, cómo tomar la temperatura de una empanada y copias
--    de papel manteca, leudado de chipás y pirómetro (del banco de Mania).
--
-- Las copias se toman de la pregunta original, con id nuevo, así el % de error
-- del Campus arranca de cero. La opción correcta va primera.
-- Los resultados ya guardados no cambian (guardan el texto de cada pregunta).
-- Se puede volver a correr sin romper nada.
-- Correr completo en Supabase > SQL Editor.
-- (Sin signos pesos ni barras invertidas dentro de textos: el SQL Editor de Supabase los interpreta mal.)
-- ============================================================

begin;

-- ================= EXTREMAS =================
update public.preguntas set texto = '¿Cuál de las siguientes opciones es la temperatura adecuada para la parrilla, para la cocción de carnes?'
 where marca = 'hex' and ((nivel = 'entrenador' and id = 322) or (nivel = 'gerente' and id = 531));
update public.preguntas set texto = '¿A qué temperatura debe estar la tostadora Spidocook, para la cocción del tostado?'
 where marca = 'hex' and nivel = 'encargado' and id = 421;
update public.preguntas set texto = '¿Cuál es la temperatura de las carnes congeladas?'
 where marca = 'hex' and nivel = 'encargado' and id = 424;
update public.preguntas set nivel = 'encargado', orden = 25
 where marca = 'hex' and nivel = 'entrenador' and id = 325;

-- Copias para Gerente: 536 = Entrenador 3 (id 304), 537 = Entrenador 1 (id 301).
insert into public.preguntas (marca, nivel, id, orden, tipo, texto, opciones, filas, columnas, correcta)
select 'hex', 'gerente', c.nuevo, c.orden, p.tipo, p.texto, p.opciones, p.filas, p.columnas, p.correcta
  from (values (304, 536, 29), (301, 537, 30)) as c(origen, nuevo, orden)
  join public.preguntas p on p.marca = 'hex' and p.nivel = 'entrenador' and p.id = c.origen
on conflict (marca, nivel, id) do update set
  orden = excluded.orden, tipo = excluded.tipo, texto = excluded.texto, opciones = excluded.opciones,
  filas = excluded.filas, columnas = excluded.columnas, correcta = excluded.correcta;

-- ================= SABORES =================
delete from public.preguntas where marca = 'sabores' and nivel = 'gerente' and id = 203;

insert into public.preguntas (marca, nivel, id, orden, tipo, texto, opciones, filas, columnas, correcta) values
  -- Encargado
  ('sabores', 'encargado', 128, 20, 'opciones', '¿Cuál es la visión de Sabores Express?', '["Ser la empresa líder en take away y delivery a nivel nacional","Satisfacer las necesidades del cliente con un vínculo comercial sustentable, la mejor calidad al menor precio posible","Honestidad, integridad y respeto","Abrir la mayor cantidad de locales posible"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'encargado', 129, 21, 'opciones', '¿Cuál de las siguientes opciones describe mejor un onboarding efectivo?', '["Un proceso integral que acompaña la adaptación cultural, técnica, social y emocional del nuevo colaborador","Un proceso corto que se realiza solo el primer día","Un proceso centrado únicamente en entregar manuales y procedimientos"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'encargado', 130, 22, 'opciones', '¿Qué es la cultura organizacional?', '["El “ADN” de la compañía porque reúne los valores, creencias, normas y comportamientos que marcan cómo trabajan las personas, cómo se relacionan entre sí y cómo se toman decisiones dentro de la organización. También se refleja en el liderazgo, la historia, los procesos y la manera en que la empresa se vincula con clientes y su entorno","La cultura de Sabores","El ADN de nuestro control en las auditorías","La cultura del local"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'encargado', 131, 23, 'opciones', 'En el pase de turno, cuando tengo una diferencia negativa en la caja:', '["Verifico que todos los pedidos estén cargados - las comandas de Dely pasadas - realizo conteo de mercadería - paso el sobrante","Verifico que todos los pedidos estén cargados - las comandas de Dely pasadas - realizo conteo de mercadería - dejo el sobrante hasta el final del día por las dudas, para que compense","Verifico que todos los pedidos estén cargados - las comandas de Dely pasadas - realizo conteo de mercadería - dejo el sobrante separado, por si Data se actualiza"]'::jsonb, null, null, '0'::jsonb),
  -- Gerente
  ('sabores', 'gerente', 224, 20, 'opciones', '¿Cuál es la visión de Sabores Express?', '["Ser la empresa líder en take away y delivery a nivel nacional","Satisfacer las necesidades del cliente con un vínculo comercial sustentable, la mejor calidad al menor precio posible","Honestidad, integridad y respeto","Abrir la mayor cantidad de locales posible"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'gerente', 225, 21, 'opciones', '¿Cuál de las siguientes opciones describe mejor un onboarding efectivo?', '["Un proceso integral que acompaña la adaptación cultural, técnica, social y emocional del nuevo colaborador","Un proceso corto que se realiza solo el primer día","Un proceso centrado únicamente en entregar manuales y procedimientos"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'gerente', 226, 22, 'opciones', '¿Qué es la cultura organizacional?', '["El “ADN” de la compañía porque reúne los valores, creencias, normas y comportamientos que marcan cómo trabajan las personas, cómo se relacionan entre sí y cómo se toman decisiones dentro de la organización. También se refleja en el liderazgo, la historia, los procesos y la manera en que la empresa se vincula con clientes y su entorno","La cultura de Sabores","El ADN de nuestro control en las auditorías","La cultura del local"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'gerente', 227, 23, 'opciones', '¿Cuántas empanadas verticales se colocan en la bandeja de hornear?', '["8 unidades","10 unidades","9 unidades","6 unidades"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'gerente', 228, 24, 'opciones', 'Luego del conteo de fin de mes, debemos:', '["Controlar los resultados, chequear las diferencias más grandes, contar nuevamente esos productos, dar aviso al Gte Regional y, una vez confirmadas todas las diferencias, cerrar el conteo con las variaciones que correspondan","Revisar las diferencias y colocar todo en 0 para arrancar el mes","Controlar los resultados, contar nuevamente las diferencias más grandes, dar aviso al Gte Regional de las diferencias más grandes y hacer la puesta a 0 para arrancar el mes","Revisar las diferencias, contar nuevamente las diferencias más grandes y colocar todo en 0 para arrancar el mes"]'::jsonb, null, null, '0'::jsonb),
  ('sabores', 'gerente', 229, 25, 'opciones', '¿Cómo se toma adecuadamente la temperatura de una empanada?', '["Sostenemos la empanada en el aire con la pinza metálica (sin apoyarla sobre la mesa para evitar cambios por el contacto) e insertamos el pirómetro exclusivamente por la base inferior","Sostenemos la empanada en el aire con la pinza metálica (sin apoyarla sobre la mesa para evitar cambios por el contacto) e insertamos el pirómetro exclusivamente por el repulgue","Pinchamos la empanada sin tocarla, directamente desde la batea, para que con la pinza no modifiquemos su temperatura"]'::jsonb, null, null, '0'::jsonb)
on conflict (marca, nivel, id) do update set
  orden = excluded.orden, tipo = excluded.tipo, texto = excluded.texto, opciones = excluded.opciones,
  filas = excluded.filas, columnas = excluded.columnas, correcta = excluded.correcta;

-- Copias: misión (Gerente 219) a Encargado; papel manteca, chipás y pirómetro (Mania 623, 621, 606) a Gerente.
insert into public.preguntas (marca, nivel, id, orden, tipo, texto, opciones, filas, columnas, correcta)
select 'sabores', c.nivel, c.nuevo, c.orden, p.tipo, p.texto, p.opciones, p.filas, p.columnas, p.correcta
  from (values
    ('sabores', 'gerente',    219, 'encargado', 127, 19),
    ('mania',   'entrenador', 623, 'gerente',   230, 26),
    ('mania',   'entrenador', 621, 'gerente',   231, 27),
    ('mania',   'entrenador', 606, 'gerente',   232, 28)
  ) as c(marca_origen, nivel_origen, origen, nivel, nuevo, orden)
  join public.preguntas p on p.marca = c.marca_origen and p.nivel = c.nivel_origen and p.id = c.origen
on conflict (marca, nivel, id) do update set
  orden = excluded.orden, tipo = excluded.tipo, texto = excluded.texto, opciones = excluded.opciones,
  filas = excluded.filas, columnas = excluded.columnas, correcta = excluded.correcta;

-- Orden de Gerente sin la 3.
update public.preguntas p set orden = v.orden
  from (values
    (201, 1), (202, 2), (204, 3), (205, 4), (206, 5), (207, 6), (208, 7), (209, 8), (211, 9), (212, 10),
    (213, 11), (216, 12), (217, 13), (218, 14), (219, 15), (220, 16), (221, 17), (222, 18), (223, 19)
  ) as v(id, orden)
 where p.marca = 'sabores' and p.nivel = 'gerente' and p.id = v.id;

commit;
