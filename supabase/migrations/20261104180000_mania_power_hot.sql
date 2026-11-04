-- ============================================================
-- Empanada Mania · Entrenador: pregunta 1 (horno POWER HOT)
-- La correcta pasa a ser "11 a 13 minutos" (devolución de Capacitación, 04/11/2026).
-- La opción correcta va primera. Se puede volver a correr sin romper nada.
-- Correr completo en Supabase > SQL Editor.
-- ============================================================

update public.preguntas
   set opciones = '["11 a 13 minutos","6 a 8 minutos","11 a 14 minutos","10 a 11 minutos"]'::jsonb,
       correcta = '0'::jsonb
 where marca = 'mania' and nivel = 'entrenador' and id = 601;
