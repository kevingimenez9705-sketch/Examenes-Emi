-- ============================================================
-- Sabores Express · Entrenador (devolución de Capacitación, 04/11/2026)
--  · 13 (horno POWER HOT): la correcta pasa a "11 a 13 minutos", con las
--    mismas opciones que Mania.
--  · 7 (leudado de la medialuna): sigue siendo 8 horas; la tercera opción
--    pasa a 10 horas para que haya una sola opción con 8 horas.
-- La opción correcta va primera. Se puede volver a correr sin romper nada.
-- Correr completo en Supabase > SQL Editor.
-- ============================================================

update public.preguntas
   set opciones = '["11 a 13 minutos","6 a 8 minutos","11 a 14 minutos","10 a 11 minutos"]'::jsonb,
       correcta = '0'::jsonb
 where marca = 'sabores' and nivel = 'entrenador' and id = 21;

update public.preguntas
   set opciones = '["8 horas, 28 por bandeja en 4 filas de 7","7 horas, 28 por bandeja en 4 filas de 7","10 horas, 32 por bandeja en 4 filas de 8","6 horas, 24 por bandeja en 4 filas de 6"]'::jsonb,
       correcta = '0'::jsonb
 where marca = 'sabores' and nivel = 'entrenador' and id = 7;
