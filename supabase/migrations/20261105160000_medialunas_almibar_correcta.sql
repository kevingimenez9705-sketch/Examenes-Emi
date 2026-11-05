-- ============================================================
-- Sabores y Mania · Entrenador: medialunas con almíbar (corrección)
-- La correcta es "Una vez pasan 5 minutos después de hornearlas y en la
-- bandeja de acero inoxidable" (marcada en azul por Capacitación, 05/11/2026),
-- no la del pincel de silicona. La opción correcta va primera.
-- Se puede volver a correr sin romper nada.
-- Correr completo en Supabase > SQL Editor.
-- ============================================================

update public.preguntas
   set opciones = '["Una vez pasan 5 minutos después de hornearlas y en la bandeja de acero inoxidable","Únicamente al momento de la entrega al cliente, con pincel de silicona","Apenas salen del horno, con pincel de cerdas","Al abrir el local, todas juntas"]'::jsonb,
       correcta = '0'::jsonb
 where marca = 'sabores' and nivel = 'entrenador' and id = 17;

update public.preguntas
   set opciones = '["Una vez pasan 5 minutos después de hornearlas y en la bandeja de acero inoxidable","Únicamente al momento de la entrega al cliente, con pincel de silicona","Apenas salen del horno, con pincel de silicona","Únicamente al momento de la entrega al cliente, con pincel de cerdas"]'::jsonb,
       correcta = '0'::jsonb
 where marca = 'mania' and nivel = 'entrenador' and id = 617;
