-- Tabla de resultados para el progreso por DNI (Entrenador -> Encargado -> Gerente).
create table if not exists public.examen_resultados (
  id bigint generated always as identity primary key,
  dni text not null,
  nivel text not null check (nivel in ('entrenador','encargado','gerente')),
  porcentaje int,
  condicion text,
  nombre text,
  local text,
  payload jsonb,
  creado timestamptz not null default now()
);
create index if not exists examen_resultados_dni_idx on public.examen_resultados (dni);

alter table public.examen_resultados enable row level security;

-- La página usa la anon key: puede insertar resultados y leer el nivel aprobado.
create policy "anon inserta resultados" on public.examen_resultados
  for insert to anon with check (true);
create policy "anon lee resultados" on public.examen_resultados
  for select to anon using (true);
