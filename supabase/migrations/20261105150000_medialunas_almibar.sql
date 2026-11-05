-- ============================================================
-- Sabores y Mania · Entrenador: medialunas con almíbar
-- (devolución de Capacitación, 05/11/2026)
--  · Sabores 17 y Mania 16: la tercera opción pasa a ser "Una vez pasan
--    5 minutos después de hornearlas y en la bandeja de acero inoxidable".
--    La correcta sigue siendo la primera.
-- Se puede volver a correr sin romper nada.
-- Correr completo en Supabase > SQL Editor.
-- ============================================================

update public.preguntas
   set opciones = '["Únicamente al momento de la entrega al cliente, con pincel de silicona","Apenas salen del horno, con pincel de cerdas","Una vez pasan 5 minutos después de hornearlas y en la bandeja de acero inoxidable","Al abrir el local, todas juntas"]'::jsonb,
       correcta = '0'::jsonb
 where marca = 'sabores' and nivel = 'entrenador' and id = 17;

update public.preguntas
   set opciones = '["Únicamente al momento de la entrega al cliente, con pincel de silicona","Apenas salen del horno, con pincel de silicona","Una vez pasan 5 minutos después de hornearlas y en la bandeja de acero inoxidable","Únicamente al momento de la entrega al cliente, con pincel de cerdas"]'::jsonb,
       correcta = '0'::jsonb
 where marca = 'mania' and nivel = 'entrenador' and id = 617;
