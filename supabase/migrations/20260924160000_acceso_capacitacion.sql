-- ============================================================
-- Acceso de Capacitación (Campus de Ascensos)
-- Los usuarios logueados (Supabase Auth) pueden ver el detalle completo,
-- corregir y borrar resultados. El público (anon) sigue sin acceso a la tabla.
--
-- IMPORTANTE: cualquier usuario autenticado queda como administrador.
-- En Supabase > Authentication > Sign In / Providers desactivá
-- "Allow new users to sign up" y creá a mano los usuarios de Capacitación
-- en Authentication > Users > Add user.
-- ============================================================

grant select, update, delete on public.examen_resultados to authenticated;

drop policy if exists "capacitacion lee" on public.examen_resultados;
drop policy if exists "capacitacion corrige" on public.examen_resultados;
drop policy if exists "capacitacion borra" on public.examen_resultados;

create policy "capacitacion lee" on public.examen_resultados
  for select to authenticated using (true);
create policy "capacitacion corrige" on public.examen_resultados
  for update to authenticated using (true) with check (true);
create policy "capacitacion borra" on public.examen_resultados
  for delete to authenticated using (true);
