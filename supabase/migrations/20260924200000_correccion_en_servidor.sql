-- ============================================================
-- Seguridad: corrección del examen en el servidor
--  · Las preguntas y respuestas correctas viven solo en la base (tabla preguntas).
--    La página recibe las preguntas SIN la respuesta correcta.
--  · iniciar_examen valida DNI, nivel habilitado y espera de 48 hs, y abre un intento.
--  · entregar_examen corrige en el servidor y guarda el resultado (una sola vez por intento).
--  · Un intento abierto que no se entregó (página cerrada, reinicio) cuenta como desaprobado.
--  · Se cierran permisos que permitían cargar resultados a mano o editar la tabla.
-- Correr completo en Supabase > SQL Editor.
-- ============================================================

-- 1) Cerrar accesos abiertos
revoke all on function public.registrar_resultado(text,text,text,int,text,text,text,text,jsonb) from anon, public;
revoke select, update, delete on public.examen_resultados from authenticated;
drop policy if exists "capacitacion lee" on public.examen_resultados;
drop policy if exists "capacitacion corrige" on public.examen_resultados;
drop policy if exists "capacitacion borra" on public.examen_resultados;

-- 2) Banco de preguntas (privado)
create table if not exists public.preguntas (
  marca text not null check (marca in ('sabores','hex')),
  nivel text not null check (nivel in ('entrenador','encargado','gerente')),
  id int not null,
  orden int not null,
  tipo text not null default 'opciones' check (tipo in ('opciones','grilla')),
  texto text not null,
  opciones jsonb,
  filas jsonb,
  columnas jsonb,
  correcta jsonb not null,
  primary key (marca, nivel, id)
);
alter table public.preguntas enable row level security;
revoke all on public.preguntas from anon, authenticated;

insert into public.preguntas (marca, nivel, id, orden, tipo, texto, opciones, filas, columnas, correcta) values
  ($q$sabores$q$, $q$entrenador$q$, 1, 1, $q$opciones$q$, $q$¿Cuál es el tiempo de cinta del horno BURNER?$q$, $q$["5 a 7 minutos","6 a 8 minutos","3 a 5 minutos","10 a 11 minutos"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 2, 2, $q$opciones$q$, $q$¿A qué temperatura se cocinan las empanadas en el horno de cinta?$q$, $q$["265 °C a 280 °C","200 °C a 220 °C","230 °C a 250 °C","150 °C a 180 °C"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 3, 3, $q$opciones$q$, $q$¿Cuál es la cantidad máxima de empanadas por bandeja para hornear?$q$, $q$["8 unidades, sin que se toquen","6 unidades","10 unidades","12 unidades"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 4, 4, $q$opciones$q$, $q$¿Cuál es el vencimiento de las empanadas de jamón y queso y de jamón y roquefort?$q$, $q$["7 días","5 días","3 días","9 días"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 5, 5, $q$opciones$q$, $q$¿Cuál es el vencimiento del resto de los gustos de empanadas?$q$, $q$["5 días","7 días","3 días","10 días"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 6, 6, $q$opciones$q$, $q$¿Qué temperatura interna debe registrar el pirómetro en una empanada cocida?$q$, $q$["Entre 55 °C y 65 °C","Entre 40 °C y 50 °C","Entre 70 °C y 90 °C","Entre 30 °C y 45 °C"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 7, 7, $q$opciones$q$, $q$Medialunas: tiempo de leudado y armado de bandeja.$q$, $q$["8 horas exactas, 28 por bandeja en 4 filas de 7","7 horas, 28 por bandeja en 4 filas de 7","8 horas, 32 por bandeja en 4 filas de 8","6 horas, 24 por bandeja en 4 filas de 6"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 8, 8, $q$opciones$q$, $q$¿Cuántas chipás se colocan por bandeja para descongelar?$q$, $q$["60 unidades (6 filas de 10)","50 unidades (5 filas de 10)","40 unidades (4 filas de 10)","72 unidades (6 filas de 12)"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 9, 9, $q$opciones$q$, $q$¿Cuántos criollitos se colocan en la placa para su cocción?$q$, $q$["21 unidades (3 filas de 7)","20 unidades (4 filas de 5)","28 unidades (4 filas de 7)","24 unidades (3 filas de 8)"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 10, 10, $q$opciones$q$, $q$¿Cuántas pizzas se colocan por estante en la heladera?$q$, $q$["5 por estante, sectorizadas por gusto","4 por estante","6 por estante","3 por estante"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 11, 11, $q$opciones$q$, $q$¿A qué temperatura debe estar la cámara de frío?$q$, $q$["0 °C a 5 °C","-15 °C a -20 °C","5 °C a 10 °C","-5 °C a 0 °C"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 12, 12, $q$opciones$q$, $q$¿Qué significa el método "PEPS"?$q$, $q$["Primero en entrar, primero en salir","Primero en vencer, primero en salir","Primero en encargar, primero en sacar","Productos en perfecto estado"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 13, 13, $q$opciones$q$, $q$Cuando llega mercadería de fábrica, ¿cómo se ordena en la heladera?$q$, $q$["Lo nuevo abajo y lo que ya estaba en stock arriba","Lo nuevo arriba y lo viejo abajo","Todo mezclado por gusto","Lo nuevo al fondo de la cámara sin rotular"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 14, 14, $q$grilla$q$, $q$Completá con el color de trapo correspondiente.$q$, null, $q$["Limpieza de baños","Superficies y utensilios en contacto con alimentos","Limpieza de equipos (hornos, heladeras)"]$q$::jsonb, $q$["Verde","Azul","Amarillo"]$q$::jsonb, $q$[2,0,1]$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 15, 15, $q$opciones$q$, $q$¿Cómo se prepara el agua sanitizada y cuánto dura?$q$, $q$["2 tapas de lavandina en 2 litros de agua, vence a las 4 horas","1 tapa de lavandina en 5 litros, vence a las 8 horas","2 tapas en 1 litro, vence a las 24 horas","Media tapa en 2 litros, dura todo el turno"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 16, 16, $q$opciones$q$, $q$Además de al ingresar, después del baño o de tocar dinero, ¿cada cuánto nos lavamos las manos?$q$, $q$["Cada 1 hora","Cada 4 horas","Solo al terminar el turno","Una vez por turno"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 17, 17, $q$opciones$q$, $q$¿Cuándo se pintan las medialunas con almíbar?$q$, $q$["Únicamente al momento de la entrega al cliente, con pincel de silicona","Apenas salen del horno, con pincel de cerdas","Antes de hornearlas","Al abrir el local, todas juntas"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 18, 18, $q$opciones$q$, $q$Un cliente va a llevar 2 empanadas. ¿Qué le ofrecemos?$q$, $q$["La promo de 3 empanadas + gaseosa","Nada, ya decidió","Media docena","Un descuento en la próxima compra"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 19, 19, $q$opciones$q$, $q$¿Cuál de los siguientes extintores es el más versátil por cubrir casi todos los tipos de fuego?$q$, $q$["Extintor ABC","Extintor K","Extintor de agua","Extintor de espuma"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$entrenador$q$, 20, 20, $q$opciones$q$, $q$¿Qué va en el tacho verde (reciclables)?$q$, $q$["Tickets, cartón seco, servilletas y bolsas secas, limpios y sin restos","Restos de comida y cartón húmedo","Residuos de baño","Papel manteca sucio y servilletas usadas"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 101, 1, $q$opciones$q$, $q$¿Qué mide el Inaccuracy en Delivery?$q$, $q$["La cantidad de órdenes con errores generados desde la operación","El tiempo de espera del rider","La cantidad de órdenes del día","Los pedidos que cancela el cliente"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 102, 2, $q$opciones$q$, $q$¿Cuál es el objetivo de Inaccuracy por local?$q$, $q$["Estar por debajo del 2,5%","Estar por debajo del 5%","Estar por debajo del 10%","Estar por encima del 2,5%"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 103, 3, $q$opciones$q$, $q$¿Qué son los rechazos en delivery?$q$, $q$["Pedidos que el local cancela por falta de producto, fallas operativas o alta demanda","Pedidos que el cliente devuelve","Pedidos que el rider no retira","Pedidos con demora mayor a 10 minutos"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 104, 4, $q$opciones$q$, $q$¿Qué mide el AWT (tiempo de espera evitable)?$q$, $q$["Órdenes donde el rider espera más de 10 minutos en el local hasta retirar el pedido","Órdenes entregadas fuera de horario","Órdenes con productos faltantes","El tiempo total de entrega al cliente"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 105, 5, $q$opciones$q$, $q$Falta un producto de un pedido de delivery. ¿Qué hacemos?$q$, $q$["No enviamos productos sustitutos","Enviamos un producto parecido","Enviamos el pedido sin avisar","Agregamos una gaseosa de regalo"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 106, 6, $q$opciones$q$, $q$Cuando llega el rider, ¿cómo confirmamos qué pedido entregarle?$q$, $q$["Con el nombre del cliente y los últimos 4 números de la orden, verificando el ticket antes de precintar","Con el nombre del rider","Por el color de la bolsa","Le damos el primero que esté listo"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 107, 7, $q$opciones$q$, $q$¿Hasta qué hora se genera el pedido a fábrica en Data Live para recibirlo al día siguiente?$q$, $q$["Antes de las 15 hs (los sábados, el refuerzo antes de las 11 hs)","Antes de las 12 hs","Antes de las 18 hs","Antes de las 20 hs"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 108, 8, $q$opciones$q$, $q$Las empanadas se piden a fábrica en múltiplos de:$q$, $q$["50 unidades","12 unidades","35 unidades","100 unidades"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 109, 9, $q$opciones$q$, $q$¿Hasta cuándo se hace el pedido en Coca-Cola a un Click?$q$, $q$["Antes de las 12:00 hs del día anterior a la entrega","Antes de las 16:00 hs del día anterior","El mismo día de la entrega","Antes de las 15:00 hs del día anterior"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 110, 10, $q$opciones$q$, $q$¿Cómo se hacen los egresos de caja?$q$, $q$["En fajos de $20.000 con el ticket de egreso, y se envían al cofre","En fajos de $10.000 sin comprobante","En un sobre al final del mes","Se entregan en mano al encargado siguiente"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 111, 11, $q$opciones$q$, $q$¿Cuál es la función del Testigo en el manejo de dinero?$q$, $q$["Verificar que lo contado por el gerencial es correcto (doble control)","Contar el dinero solo","Firmar la planilla sin controlar","Llevar los bolsines al banco"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 112, 12, $q$opciones$q$, $q$Sin generador, ¿cuándo se activa el protocolo de corte de luz?$q$, $q$["Cuando se confirma que el corte será mayor a 3 horas","Apenas se corta la luz","Cuando el corte supera 1 hora","Al día siguiente"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 113, 13, $q$opciones$q$, $q$¿Dónde se enciende el grupo electrógeno?$q$, $q$["Siempre fuera del local","Dentro del local con la puerta abierta","En la cocina, cerca del tablero","Donde haya lugar"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 114, 14, $q$opciones$q$, $q$Con el generador en marcha, ¿qué equipos son prioridad?$q$, $q$["Cámara frigorífica, DVR y horno a gas","La batea y los focos","Todas las térmicas, incluidas las tetrapolares","Las heladeras de bebidas"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 115, 15, $q$opciones$q$, $q$Al recibir mercadería por traslado, ¿cómo controlamos la calidad de las empanadas?$q$, $q$["Cocinamos dos empanadas de cada bandeja (primera y última fila)","Probamos una empanada al azar","Solo revisamos el remito","No hace falta controlar"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 116, 16, $q$opciones$q$, $q$¿Qué significa "PAS" ante un accidente?$q$, $q$["Proteger, Avisar, Socorrer","Prevenir, Actuar, Sanar","Parar, Analizar, Seguir","Pedir, Asistir, Salir"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 117, 17, $q$opciones$q$, $q$Ocurre un accidente laboral a las 21 hs. ¿A quién se contacta para la denuncia?$q$, $q$["A la ART, con el Anexo 1 completo (SyH atiende de 9 a 18 hs)","Al equipo de Seguridad e Higiene al día siguiente","A nadie si no es grave","Solo a RR.HH."]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 118, 18, $q$opciones$q$, $q$Un cliente paga con un billete dudoso. ¿Qué hacemos?$q$, $q$["Pedimos asistencia al responsable de turno, doble verificación y solicitamos otro medio de pago","Lo aceptamos para no perder la venta","Lo retenemos y llamamos a la policía","Lo aceptamos y lo informamos al cierre"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 119, 19, $q$opciones$q$, $q$Con la lapicera detectora, ¿qué indica una marca oscura o negra?$q$, $q$["Billete sospechoso","Billete auténtico","Billete de baja denominación","Que la lapicera está nueva"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$encargado$q$, 120, 20, $q$opciones$q$, $q$¿Para qué tipo de fuego se usa el extintor K?$q$, $q$["Aceites vegetales y grasas de cocina","Tableros eléctricos","Papel y madera","Gasolina y solventes"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 201, 1, $q$opciones$q$, $q$¿Cuál es el orden del plan de carrera?$q$, $q$["Principiante → Entrenador → Encargado de turno → Gte. de Local → Supervisor → Asistente → Gte. de Operaciones","Principiante → Encargado de turno → Entrenador → Gte. de Local → Asistente → Supervisor → Gte. de Operaciones","Entrenador → Principiante → Encargado de turno → Supervisor → Gte. de Local → Asistente → Gte. de Operaciones","Principiante → Entrenador → Gte. de Local → Encargado de turno → Supervisor → Gte. de Operaciones → Asistente"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 202, 2, $q$opciones$q$, $q$¿Quiénes están autorizados a modificar el stock de cierre en Data Live?$q$, $q$["Solo los Gerentes de Operaciones","El Gerente de Local","Cualquier encargado de turno","Auditoría"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 203, 3, $q$opciones$q$, $q$Al cargar el inventario de fin de mes, ¿qué pasa si se presiona "Volver"?$q$, $q$["El inventario queda en 0 y el mes siguiente no se podrá vender ningún producto","Se guarda automáticamente","Se envía a auditoría para revisión","No pasa nada"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 204, 4, $q$opciones$q$, $q$¿Quiénes pueden visualizar las diferencias de stock?$q$, $q$["Gerentes Zonales, Gerentes de Operaciones, Asistentes y Auditoría","Todo el personal del local","Solo el Gerente de Local","Solo RR.HH."]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 205, 5, $q$opciones$q$, $q$¿Qué comprobante debe tener un gasto para ser válido?$q$, $q$["Factura A a nombre de la razón social del local","Ticket o Factura B","Factura C","Cualquier comprobante con foto"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 206, 6, $q$opciones$q$, $q$Llega un inspector y labra un acta. ¿Qué corresponde?$q$, $q$["Avisar urgente al Gerente Zonal con foto del acta; el original se entrega dentro de las 48 hs","Guardar el acta hasta fin de mes","Avisar solo si hay multa","Entregar el original dentro de los 7 días"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 207, 7, $q$opciones$q$, $q$¿Qué NO están autorizados a hacer los inspectores?$q$, $q$["Manipular la caja, hacer arqueos o tocar el punto de venta","Ingresar al local","Labrar un acta","Pedir documentación"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 208, 8, $q$opciones$q$, $q$¿Cuál es la vigencia del REBA y con cuánta anticipación se avisa su renovación?$q$, $q$["1 año; avisar 60 días antes a Habilitaciones","2 años; avisar 30 días antes","1 año; avisar 7 días antes","6 meses; avisar 15 días antes"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 209, 9, $q$opciones$q$, $q$Ante un daño en el inmueble (siniestro), ¿en qué plazo se envía la documentación?$q$, $q$["Dentro de las primeras 72 horas","Dentro de las 24 horas","Dentro de los 7 días","A fin de mes"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 210, 10, $q$opciones$q$, $q$En iCheck, ¿qué dato se carga en el campo Legajo?$q$, $q$["El número de DNI, sin excepciones","El CUIL","Un número interno correlativo","El teléfono del empleado"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 211, 11, $q$opciones$q$, $q$¿Quién carga las justificaciones en iCheck y cuándo?$q$, $q$["Exclusivamente el Gerente de Local, el mismo día a justificar","Cualquier empleado, a fin de mes","RR.HH., al liquidar","El encargado, una vez por semana"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 212, 12, $q$opciones$q$, $q$¿Cuándo es el cierre de novedades para la liquidación?$q$, $q$["El día 20 (excepciones hasta el día 30)","El día 1","El día 15","El último día hábil del mes"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 213, 13, $q$opciones$q$, $q$¿Desde cuándo son efectivos los ascensos?$q$, $q$["Desde el 1° de cada mes, comunicándolo el mes anterior","Desde el día que se comunica","Desde mitad de mes","A los 30 días de la evaluación"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 214, 14, $q$opciones$q$, $q$En el tablero de asistencia de iCheck, ¿qué indica el color celeste?$q$, $q$["Fichada justificada","Ausencia de fichada","Fichada correcta","Fichada fuera de rango"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 215, 15, $q$opciones$q$, $q$¿Quién está autorizado a enviar solicitudes de traslado de personal?$q$, $q$["Solo el Gerente Zonal (con la solicitud firmada por el Gerente Regional)","El Gerente de Local","El propio empleado","El encargado de turno"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 216, 16, $q$opciones$q$, $q$¿Qué se requiere para cargar una licencia por enfermedad?$q$, $q$["Adjuntar el certificado médico; el reposo vale solo si está indicado en él","Solo el aviso por WhatsApp","Nada si es de un día","La firma del encargado"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 217, 17, $q$opciones$q$, $q$Coca-Cola no entrega y hay quiebre de stock. ¿Cuál es el tope para comprar a un distribuidor externo?$q$, $q$["Hasta un 40% más caro que Coca-Cola, con autorización del Gte. Zonal y Regional","Sin tope, lo importante es tener stock","Hasta un 10% más caro","El encargado compra lo que haga falta"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 218, 18, $q$opciones$q$, $q$¿Qué competencia se define como "identificar potenciales y gestionar los talentos del equipo"?$q$, $q$["Coaching","Liderazgo","Compromiso","Perfil comercial"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 219, 19, $q$opciones$q$, $q$¿Cuál es la misión de Sabores Express?$q$, $q$["Satisfacer las necesidades del cliente con un vínculo comercial sustentable, la mejor calidad al menor precio posible","Ser la empresa líder en take away y delivery a nivel nacional","Honestidad, integridad y respeto","Abrir la mayor cantidad de locales posible"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$sabores$q$, $q$gerente$q$, 220, 20, $q$opciones$q$, $q$¿Qué documento debe exhibirse en la pared del local, de fácil acceso para una inspección?$q$, $q$["REBA, fumigación, análisis de agua, habilitación y formulario 960 ARCA","Solo la habilitación","Ninguno, se muestran si los piden","El plan de carrera"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 301, 1, $q$opciones$q$, $q$¿A qué temperatura trabaja el broiler para la cocción de carnes?$q$, $q$["570 °F","400 °F","290 °F","185 °F"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 302, 2, $q$opciones$q$, $q$¿Cuánto dura el recorrido de la cadena del broiler?$q$, $q$["2 minutos (120 segundos)","1 minuto (60 segundos)","4 minutos","30 segundos"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 303, 3, $q$opciones$q$, $q$¿Cuántas carnes se colocan como máximo por fila en el broiler?$q$, $q$["4, en el centro de las bases y alejadas de los bordes","6, ocupando todo el ancho","2 por fila","8 por fila"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 304, 4, $q$opciones$q$, $q$¿Qué temperatura interna debe tener la carne al salir del broiler?$q$, $q$["71 °C o más","Entre 40 °C y 50 °C","Entre 55 °C y 60 °C","30 °C"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 305, 5, $q$opciones$q$, $q$¿Cómo debe estar la carne para ser apta para cocinar?$q$, $q$["Congelada, color rosa, sin hielo y que se separe fácilmente","Descongelada, blanda y rosa oscuro","Cristalizada, pálida y con exceso de hielo","A temperatura ambiente"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 306, 6, $q$opciones$q$, $q$¿A qué temperatura debe estar el aceite de la freidora?$q$, $q$["Entre 170 °C y 185 °C","Entre 200 °C y 220 °C","Entre 150 °C y 160 °C","Entre 190 °C y 210 °C"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 307, 7, $q$opciones$q$, $q$¿Cuáles son los enemigos del aceite?$q$, $q$["Agua, carbonilla, temperatura (más de 185 °C) y sal","Azúcar, luz y frío","Solo el agua","El uso de cestas limpias"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 308, 8, $q$opciones$q$, $q$¿Cómo se activan las cestas de papas?$q$, $q$["Siempre de forma intercalada (1 - 3 - 2 - 4) para que el aceite no baje de temperatura","Todas juntas para ganar tiempo","De a una y esperando que termine la anterior","En el orden que se liberen"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 309, 9, $q$grilla$q$, $q$Completá con el color de envoltorio de cada hamburguesa.$q$, null, $q$["Cuarto","Bacon","Clásica"]$q$::jsonb, $q$["Verde","Naranja","Bordó"]$q$::jsonb, $q$[1,2,0]$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 310, 10, $q$opciones$q$, $q$¿Cuánto aderezo se aplica en la corona de las hamburguesas?$q$, $q$["1 vuelta y media","3 vueltas","Media vuelta","2 vueltas y media"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 311, 11, $q$opciones$q$, $q$¿Cuánta cebolla lleva la hamburguesa Cuarto?$q$, $q$["15 gramos","10 gramos","35 gramos","25 gramos"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 312, 12, $q$opciones$q$, $q$¿Qué temperatura interna debe tener la hamburguesa ya armada (medida en el transfer, entre el pan y la carne)?$q$, $q$["Entre 50 °C y 60 °C","71 °C o más","Entre 30 °C y 40 °C","Entre 80 °C y 90 °C"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 313, 13, $q$opciones$q$, $q$Si la rodaja de tomate es mediana (ocupa el 50% de la corona), ¿cuántas se colocan?$q$, $q$["2 rodajas","1 rodaja","3 rodajas","4 rodajas"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 314, 14, $q$opciones$q$, $q$Colocás bacon nuevo en la mesa de armado a las 10:00. ¿A qué hora marcás el reloj de vencimiento secundario?$q$, $q$["16:00 (6 horas)","14:00 (4 horas)","12:00 (2 horas)","22:00 (12 horas)"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 315, 15, $q$opciones$q$, $q$¿A qué temperatura debe estar el freezer (carnes, papas y bacon)?$q$, $q$["Entre -15 °C y -23 °C","Entre 0 °C y 5 °C","Entre -5 °C y 0 °C","Entre -30 °C y -40 °C"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 316, 16, $q$opciones$q$, $q$¿Cuál es el tiempo de cocción de los nuggets?$q$, $q$["3:45 minutos","2 minutos","5 minutos","7 minutos"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 317, 17, $q$opciones$q$, $q$¿Qué pinza se usa para los nuggets y el medallón de pollo?$q$, $q$["La pinza naranja, nunca la de carnes, para evitar contaminación cruzada","La misma pinza de las carnes","Cualquier pinza limpia","Se manipulan con la mano con guantes"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 318, 18, $q$opciones$q$, $q$Una vez armada la hamburguesa de pollo, ¿qué vencimiento se marca con el lápiz de cera?$q$, $q$["15 minutos","30 minutos","1 hora","5 minutos"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 319, 19, $q$opciones$q$, $q$¿Cuántas vueltas de helado lleva el sundae?$q$, $q$["3 ½ vueltas","2 ½ vueltas","4 ½ vueltas","5 vueltas"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$entrenador$q$, 320, 20, $q$opciones$q$, $q$Además de al ingresar, al cambiar de tarea o tocar dinero, ¿cada cuánto nos lavamos las manos?$q$, $q$["Cada 60 minutos","Cada 4 horas","Solo al terminar el turno","Una vez por turno"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 401, 1, $q$opciones$q$, $q$Antes de apagar el broiler para la limpieza, ¿qué se hace?$q$, $q$["Se deja encendido y sin productos 15 minutos para quemar los residuos de las cadenas","Se apaga de inmediato y se desarma","Se moja con agua para enfriarlo","Se deja encendido 1 hora con productos"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 402, 2, $q$opciones$q$, $q$Durante el enfriamiento del broiler, ¿qué pasa con la campana de ventilación?$q$, $q$["Se mantiene encendida: apagarla puede provocar un incendio","Se apaga para ahorrar energía","Se apaga y se abre la puerta","Da igual"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 403, 3, $q$opciones$q$, $q$¿Cómo se limpia el catalizador del broiler?$q$, $q$["Cepillado suave, 1 hora solo en agua caliente y secado al aire toda la noche; sin desengrasante, detergente ni esponja 3M","Con desengrasante y esponja 3M","En el lavavajillas","Con detergente y agua fría"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 404, 4, $q$opciones$q$, $q$¿Por qué no se usa desengrasante sobre el teflón del rodadero?$q$, $q$["Porque entra en contacto directo con la carne y el químico podría contaminarla","Porque lo decolora","Porque no limpia bien","Sí se usa desengrasante"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 405, 5, $q$opciones$q$, $q$¿Cada cuánto se limpian los cambros del broiler?$q$, $q$["Cada 4 horas","Una vez por semana","Solo al cierre","Cada 30 minutos"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 406, 6, $q$opciones$q$, $q$¿Cuándo se realiza el Boil Out de la freidora?$q$, $q$["El último día de cada mes","Todos los días","Lunes y jueves","Una vez al año"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 407, 7, $q$opciones$q$, $q$En el control de vatiaje del microondas (inicio de cada mes), ¿qué resultado debe dar?$q$, $q$["Superior a 1250 W","Superior a 800 W","Exactamente 1000 W","Inferior a 1250 W"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 408, 8, $q$opciones$q$, $q$Al calibrar el pirómetro en un vaso con hielo y agua fría, ¿qué debe indicar?$q$, $q$["Entre 0 °C y 4 °C","Entre 10 °C y 15 °C","Exactamente 20 °C","Entre -10 °C y -5 °C"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 409, 9, $q$opciones$q$, $q$¿Cuál es la retención máxima de las carnes en el PHU?$q$, $q$["30 minutos","2 horas","10 minutos","Hasta el cierre"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 410, 10, $q$opciones$q$, $q$Si detectás una carne cruda al salir del broiler, ¿qué corresponde?$q$, $q$["Realizar obligatoriamente el corte de seguridad en la siguiente unidad","Servirla igual si está caliente","Pasarla por el microondas","No hace falta ningún control"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 411, 11, $q$opciones$q$, $q$Nuggets en el PHU (rush): ¿cuál es la retención y cómo se guardan?$q$, $q$["30 minutos, sin tapa y hasta 50 nuggets por cambro","2 horas con tapa","10 minutos en el BIN de hamburguesas","60 minutos con tapa cerrada"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 412, 12, $q$opciones$q$, $q$En la pantalla de cocina (Datalive Kitchen), ¿desde qué tiempo un pedido es crítico?$q$, $q$["Desde 4 minutos","Desde 2 minutos","Desde 6 minutos","Desde 10 minutos"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 413, 13, $q$opciones$q$, $q$¿Cuál es el objetivo de Inaccuracy por local en Extremas?$q$, $q$["Estar por debajo del 2%","Estar por debajo del 5%","Estar por debajo del 10%","Estar por encima del 2%"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 414, 14, $q$opciones$q$, $q$¿Qué calificación debemos garantizar en PedidosYa?$q$, $q$["Mayor a 4.2","Mayor a 3","Mayor a 2.5","No importa la calificación"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 415, 15, $q$opciones$q$, $q$Al cierre del día, ¿cuánto puede tener como máximo la caja chica?$q$, $q$["200.000 ARS","100.000 ARS","500.000 ARS","No tiene límite"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 416, 16, $q$opciones$q$, $q$¿Cuándo se completa la planilla de retiro de disponibles?$q$, $q$["Cada vez que depositamos, no cuando llega el recaudador","Cuando llega el recaudador","Una vez por semana","A fin de mes"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 417, 17, $q$opciones$q$, $q$Coca-Cola no entregó y hay que comprar a un distribuidor externo. ¿Qué tenemos en cuenta?$q$, $q$["Comprar solo lo mínimo: el distribuidor externo es un 40% más caro","Comprar todo el pedido original","Comprar el doble para no quedarnos sin stock","No avisar a nadie"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 418, 18, $q$opciones$q$, $q$Al recibir la mercadería de Coca-Cola, ¿qué se hace en Datalive?$q$, $q$["Ingresarla el mismo día seleccionando el proveedor y subir la foto de la factura","Ingresarla a fin de semana","Solo guardar la factura en el cajón","Ingresarla cuando se termine el stock"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 419, 19, $q$opciones$q$, $q$Ocurre un accidente laboral a las 22 hs. ¿Qué corresponde?$q$, $q$["Aplicar PAS, avisar al Gerente Zonal/Regional y llamar a la ART con el Anexo 1 completo","Esperar al día siguiente para avisar a Seguridad e Higiene","Llamar a la ART sin tomar datos","No hacer nada si no fue grave"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$encargado$q$, 420, 20, $q$opciones$q$, $q$Un cliente paga con un billete dudoso. ¿Qué hacemos?$q$, $q$["Pedimos asistencia al responsable de turno, doble verificación y solicitamos otro medio de pago","Lo aceptamos para no perder la venta","Lo retenemos y llamamos a la policía","Lo aceptamos y lo informamos al cierre"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 501, 1, $q$opciones$q$, $q$Un inspector labra un acta en el local. ¿Qué corresponde?$q$, $q$["Avisar de inmediato al Gerente Zonal con foto del acta; el original se entrega dentro de las 48 hs","Guardar el acta hasta fin de mes","Avisar solo si hay multa","Entregar el original dentro de los 7 días"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 502, 2, $q$opciones$q$, $q$¿Qué NO están autorizados a hacer los inspectores?$q$, $q$["Manipular la caja de dinero, hacer arqueos o tocar el punto de venta","Ingresar al local si lo requieren","Labrar un acta","Pedir la credencial y documentación"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 503, 3, $q$opciones$q$, $q$¿Cuál es la vigencia del REBA y con cuánta anticipación se avisa su renovación?$q$, $q$["1 año; avisar 60 días antes a Habilitaciones","2 años; avisar 30 días antes","1 año; avisar 7 días antes","6 meses; avisar 15 días antes"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 504, 4, $q$opciones$q$, $q$Cuando el proveedor se lleva los matafuegos para recargarlos, ¿qué debe dejar?$q$, $q$["Un matafuego provisorio con su oblea correspondiente","Nada, se devuelven en el día","Solo el remito","Un cartel de aviso"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 505, 5, $q$opciones$q$, $q$Ante un daño en el inmueble, ¿en qué plazo se envía la documentación al seguro?$q$, $q$["Dentro de las primeras 72 horas; pasado el plazo el seguro no cubre","Dentro de los 15 días","A fin de mes","No hay plazo"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 506, 6, $q$opciones$q$, $q$Un cliente se cae en la rampa de acceso (accidente de tercero). ¿Qué hace el Gerente Regional?$q$, $q$["Envía el mismo día un email a RRHH y Legales con la planilla de denuncia de siniestro","Espera a que el cliente reclame","Lo informa en la reunión mensual","Nada, lo resuelve el local"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 507, 7, $q$opciones$q$, $q$En iCheck, ¿qué día de la semana se cargan los horarios del equipo?$q$, $q$["Los jueves","Los lunes","Los viernes","El último día del mes"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 508, 8, $q$opciones$q$, $q$¿Cómo se carga en iCheck un horario nocturno (00:00 a 05:00)?$q$, $q$["Activando el ícono de la luna","Como un horario normal","Se carga al día siguiente","No se carga"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 509, 9, $q$opciones$q$, $q$¿Cómo se carga un día de franco en la carga de horarios?$q$, $q$["No se carga horario: los campos quedan vacíos","Con horario 00:00 a 00:00","Con la palabra FRANCO","Con el horario habitual"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 510, 10, $q$opciones$q$, $q$En una jornada itinerante (varios locales), ¿cuánto pueden sumar como máximo los trayectos?$q$, $q$["1 hora","2 horas","30 minutos","No hay límite"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 511, 11, $q$opciones$q$, $q$En iCheck, ¿qué dato se carga en el campo Legajo?$q$, $q$["El número de DNI, sin excepciones","El CUIL","Un número interno correlativo","El teléfono"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 512, 12, $q$opciones$q$, $q$¿Desde cuándo son efectivos los ascensos?$q$, $q$["Desde el 1° de cada mes, comunicándolo el mes anterior","Desde el día que se comunica","Desde mitad de mes","A los 30 días de la evaluación"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 513, 13, $q$opciones$q$, $q$¿Cuándo se carga la baja de un empleado en iCheck?$q$, $q$["El mismo día en que el colaborador notifica su desvinculación","A fin de mes","Cuando llega el telegrama","Al liquidar el sueldo"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 514, 14, $q$opciones$q$, $q$Traslados de personal: ¿qué es correcto?$q$, $q$["Solo el Gerente Zonal envía la solicitud, firmada por el Gerente Regional; no se puede volver a una unidad anterior con la misma razón social","Lo pide el empleado directamente a RRHH","Lo decide el encargado de turno","Se puede volver a cualquier local sin solicitud"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 515, 15, $q$opciones$q$, $q$¿Qué se requiere para cargar una licencia por enfermedad?$q$, $q$["Adjuntar el certificado médico; el reposo vale solo si está indicado en él","Solo el aviso por WhatsApp","Nada si es de un día","La firma del encargado"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 516, 16, $q$opciones$q$, $q$¿Por qué se lanzó la Clásica Deluxe exclusiva de PedidosYa?$q$, $q$["Para traccionar ventas en locales que no alcanzan el promedio de combos mensuales o están por debajo de las ventas comp 2025","Para reemplazar a la Clásica en todos los locales","Para usar sobrante de bacon","Para vender solo en mostrador"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 517, 17, $q$opciones$q$, $q$¿Por qué la hamburguesa de pollo pasó del pan grande al pan Junior?$q$, $q$["Para unificar el estándar de armado en todos los locales y la rentabilidad del combo","Porque el pan grande se discontinuó","Por pedido de los clientes","Para bajar el tiempo de tostado"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 518, 18, $q$opciones$q$, $q$¿Qué documentación debe estar exhibida en la pared del local, de fácil acceso para una inspección?$q$, $q$["REBA, fumigación, análisis de agua, habilitación comercial y formulario 960 ARCA","Solo la habilitación","Ninguna, se muestra si la piden","El organigrama del local"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 519, 19, $q$opciones$q$, $q$Si no cumplimos el procedimiento de pedido a Coca-Cola (en tiempo y forma) y compramos afuera, ¿qué pasa?$q$, $q$["Compras no puede gestionar el reintegro y el sobreprecio queda a cargo del local","Coca-Cola reintegra igual","El distribuidor devuelve la diferencia","No pasa nada"]$q$::jsonb, null, null, $q$0$q$::jsonb),
  ($q$hex$q$, $q$gerente$q$, 520, 20, $q$opciones$q$, $q$¿Cuál es la misión de la compañía?$q$, $q$["Satisfacer las necesidades del cliente con un vínculo comercial sustentable, la mejor calidad al menor precio posible","Ser la empresa líder en take away y delivery a nivel nacional","Honestidad, integridad y respeto","Abrir la mayor cantidad de locales posible"]$q$::jsonb, null, null, $q$0$q$::jsonb)
on conflict (marca, nivel, id) do update set
  orden = excluded.orden, tipo = excluded.tipo, texto = excluded.texto, opciones = excluded.opciones,
  filas = excluded.filas, columnas = excluded.columnas, correcta = excluded.correcta;

-- 3) Intentos en curso (privado)
create table if not exists public.examen_intentos (
  token uuid primary key default gen_random_uuid(),
  marca text not null,
  dni text not null,
  nivel text not null,
  nombre text,
  apellido text,
  local text,
  correo text,
  inicio timestamptz not null default now(),
  entregado boolean not null default false
);
create index if not exists examen_intentos_dni_idx on public.examen_intentos (marca, dni, nivel);
alter table public.examen_intentos enable row level security;
revoke all on public.examen_intentos from anon, authenticated;

-- Texto legible de una respuesta (para el detalle del panel).
create or replace function public.texto_respuesta(p public.preguntas, r jsonb)
returns text language sql immutable as $$
  select case
    when r is null or r = 'null'::jsonb then null
    when p.tipo = 'grilla' and jsonb_typeof(r) = 'array' then (
      select string_agg((p.filas->>(i-1)) || ': ' || coalesce(
        case when (r->>(i-1)) ~ '^\d{1,2}$' then p.columnas->>((r->>(i-1))::int) end, '—'), ' · ' order by i)
      from generate_series(1, jsonb_array_length(p.filas)) i)
    when p.tipo = 'opciones' and jsonb_typeof(r) = 'number' and (r#>>'{}') ~ '^\d{1,2}$' then p.opciones->>((r#>>'{}')::int)
    else 'respuesta inválida'
  end;
$$;

-- Cierra como desaprobado un intento que nunca se entregó.
create or replace function public.cerrar_intento_abandonado(t public.examen_intentos)
returns void language plpgsql security definer set search_path = public as $$
begin
  update examen_intentos set entregado = true where token = t.token;
  insert into examen_resultados (marca, dni, nivel, porcentaje, condicion, nombre, apellido, local, payload, creado)
  values (t.marca, t.dni, t.nivel, 0, 'Desaprobado', t.nombre, t.apellido, t.local,
          jsonb_build_object('motivo_cierre', 'abandono', 'inicio', t.inicio, 'detalle', '[]'::jsonb, 'correo', t.correo),
          least(now(), t.inicio + interval '17 minutes'));
end;
$$;
revoke all on function public.cerrar_intento_abandonado(public.examen_intentos) from public;

-- Inicia un examen: valida y devuelve las preguntas sin la respuesta correcta.
create or replace function public.iniciar_examen(
  p_marca text, p_dni text, p_nivel text, p_nombre text, p_apellido text, p_local text, p_correo text)
returns json language plpgsql security definer set search_path = public as $$
declare
  orden text[] := array['entrenador','encargado','gerente'];
  pos int := array_position(orden, p_nivel);
  aprob text[];
  t examen_intentos;
  nuevo uuid;
begin
  if p_dni !~ '^\d{7,8}$' or pos is null or p_marca not in ('sabores','hex')
     or coalesce(trim(p_nombre), '') = '' or coalesce(trim(p_apellido), '') = '' or coalesce(trim(p_local), '') = '' then
    raise exception 'datos inválidos';
  end if;

  -- Intentos que quedaron abiertos (página cerrada o recargada) cuentan como desaprobados.
  for t in select * from examen_intentos where marca = p_marca and dni = p_dni and not entregado loop
    perform cerrar_intento_abandonado(t);
  end loop;

  -- Estos rechazos se devuelven como {error} (sin exception) para que quede
  -- guardado el cierre de los intentos abandonados de arriba.
  aprob := niveles_aprobados(p_marca, p_dni);
  if p_nivel = any(aprob) then return json_build_object('error', 'nivel ya aprobado'); end if;
  if pos > 1 and not (orden[1:pos-1] <@ aprob) then return json_build_object('error', 'nivel no habilitado'); end if;
  if exists (select 1 from examen_resultados where marca = p_marca and dni = p_dni and nivel = p_nivel
             and condicion is distinct from 'Aprobado' and creado > now() - interval '48 hours') then
    return json_build_object('error', 'debe esperar 48 hs para volver a rendir');
  end if;

  insert into examen_intentos (marca, dni, nivel, nombre, apellido, local, correo)
  values (p_marca, p_dni, p_nivel, left(trim(p_nombre), 80), left(trim(p_apellido), 80), left(trim(p_local), 80), left(trim(p_correo), 120))
  returning token into nuevo;

  return json_build_object(
    'token', nuevo,
    'minutos', 15,
    'aprobado', 80,
    'preguntas', (select coalesce(json_agg(json_build_object(
        'id', id, 'tipo', tipo, 'texto', texto, 'opciones', opciones, 'filas', filas, 'columnas', columnas)
        order by random()), '[]'::json)
      from preguntas where marca = p_marca and nivel = p_nivel));
end;
$$;

-- Entrega un examen: corrige en el servidor y guarda el resultado.
-- p_respuestas: { "<id pregunta>": índice de opción | [columna por fila] }
create or replace function public.entregar_examen(p_token uuid, p_respuestas jsonb, p_motivo text)
returns json language plpgsql security definer set search_path = public as $$
declare
  t examen_intentos;
  p preguntas;
  r jsonb;
  total int := 0;
  ok int := 0;
  respondidas int := 0;
  detalle jsonb := '[]'::jsonb;
  motivo text := left(coalesce(p_motivo, 'entregado'), 40);
  pct int;
  cond text;
begin
  select * into t from examen_intentos where token = p_token for update;
  if not found or t.entregado then raise exception 'examen inexistente o ya entregado'; end if;
  if now() > t.inicio + interval '17 minutes' then motivo := 'tiempo'; end if;
  if jsonb_typeof(coalesce(p_respuestas, '{}'::jsonb)) <> 'object' then p_respuestas := '{}'::jsonb; end if;

  for p in select * from preguntas where marca = t.marca and nivel = t.nivel order by orden loop
    total := total + 1;
    r := p_respuestas -> p.id::text;
    if r is not null and r <> 'null'::jsonb then respondidas := respondidas + 1; end if;
    if r = p.correcta then ok := ok + 1; end if;
    detalle := detalle || jsonb_build_array(jsonb_build_object(
      'id', p.id, 'pregunta', p.texto,
      'respuesta', texto_respuesta(p, r),
      'resultado', case when r = p.correcta then 'correcta' else 'incorrecta' end));
  end loop;

  pct := case when total > 0 then round(100.0 * ok / total) else 0 end;
  cond := case when pct >= 80 then 'Aprobado' else 'Desaprobado' end;

  update examen_intentos set entregado = true where token = p_token;
  insert into examen_resultados (marca, dni, nivel, porcentaje, condicion, nombre, apellido, local, payload)
  values (t.marca, t.dni, t.nivel, pct, cond, t.nombre, t.apellido, t.local, jsonb_build_object(
    'motivo_cierre', motivo, 'inicio', t.inicio, 'fin', now(),
    'segundos_usados', least(900, extract(epoch from now() - t.inicio)::int),
    'respondidas', respondidas, 'total_preguntas', total, 'aciertos', ok,
    'correo', t.correo, 'detalle', detalle));

  return json_build_object('porcentaje', pct, 'condicion', cond);
end;
$$;

-- Banco completo con respuestas, solo con la clave de Capacitación (panel del Campus).
create or replace function public.banco_preguntas(p_clave text)
returns json language plpgsql stable security definer set search_path = public as $$
begin
  if not clave_valida(p_clave) then raise exception 'clave incorrecta'; end if;
  return (select coalesce(json_agg(json_build_object(
      'marca', marca, 'nivel', nivel, 'id', id, 'tipo', tipo, 'texto', texto,
      'opciones', opciones, 'filas', filas, 'columnas', columnas, 'correcta', correcta)
      order by marca, nivel, orden), '[]'::json) from preguntas);
end;
$$;

-- El panel no expone datos personales de contacto.
create or replace function public.examenes_panel()
returns table (id bigint, marca text, local text, nombre text, apellido text, nivel text,
               porcentaje int, condicion text, payload jsonb, creado timestamptz)
language sql stable security definer set search_path = public as $$
  select id, marca, local, nombre, apellido, nivel, porcentaje, condicion,
         payload - 'dni' - 'postulante' - 'correo', creado
  from examen_resultados order by creado desc;
$$;

revoke all on function public.texto_respuesta(public.preguntas, jsonb) from public;
revoke all on function public.iniciar_examen(text,text,text,text,text,text,text) from public;
revoke all on function public.entregar_examen(uuid,jsonb,text) from public;
revoke all on function public.banco_preguntas(text) from public;
grant execute on function public.iniciar_examen(text,text,text,text,text,text,text) to anon;
grant execute on function public.entregar_examen(uuid,jsonb,text) to anon;
grant execute on function public.banco_preguntas(text) to anon;
grant execute on function public.examenes_panel() to anon;
