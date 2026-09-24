// preguntas.js
// Bancos de preguntas de los exámenes de ascenso (fuente: Manual de Operaciones).
// Lo usan el examen (index.html) y el Campus de Ascensos (panel de Capacitación),
// que lo carga desde https://examenes-emi.vercel.app/preguntas.js.

/* ===========================================================
   PREGUNTAS (fuente: Manual de Operaciones Sabores Express)
   correcta = índice de la opción correcta (0 = primera).
   Al comenzar, el orden de preguntas y de opciones se mezcla al azar.
   Grilla: correcta = [colFila1, colFila2, ...] (no se mezcla).
   =========================================================== */

// Nivel 1 — Entrenador: productos, equipos, higiene y atención.
const PREGUNTAS_ENTRENADOR = [
  { id:1, texto:"¿Cuál es el tiempo de cinta del horno BURNER?",
    opciones:["5 a 7 minutos","6 a 8 minutos","3 a 5 minutos","10 a 11 minutos"], correcta:0 },
  { id:2, texto:"¿A qué temperatura se cocinan las empanadas en el horno de cinta?",
    opciones:["265 °C a 280 °C","200 °C a 220 °C","230 °C a 250 °C","150 °C a 180 °C"], correcta:0 },
  { id:3, texto:"¿Cuál es la cantidad máxima de empanadas por bandeja para hornear?",
    opciones:["8 unidades, sin que se toquen","6 unidades","10 unidades","12 unidades"], correcta:0 },
  { id:4, texto:"¿Cuál es el vencimiento de las empanadas de jamón y queso y de jamón y roquefort?",
    opciones:["7 días","5 días","3 días","9 días"], correcta:0 },
  { id:5, texto:"¿Cuál es el vencimiento del resto de los gustos de empanadas?",
    opciones:["5 días","7 días","3 días","10 días"], correcta:0 },
  { id:6, texto:"¿Qué temperatura interna debe registrar el pirómetro en una empanada cocida?",
    opciones:["Entre 55 °C y 65 °C","Entre 40 °C y 50 °C","Entre 70 °C y 90 °C","Entre 30 °C y 45 °C"], correcta:0 },
  { id:7, texto:"Medialunas: tiempo de leudado y armado de bandeja.",
    opciones:["8 horas exactas, 28 por bandeja en 4 filas de 7","7 horas, 28 por bandeja en 4 filas de 7","8 horas, 32 por bandeja en 4 filas de 8","6 horas, 24 por bandeja en 4 filas de 6"], correcta:0 },
  { id:8, texto:"¿Cuántas chipás se colocan por bandeja para descongelar?",
    opciones:["60 unidades (6 filas de 10)","50 unidades (5 filas de 10)","40 unidades (4 filas de 10)","72 unidades (6 filas de 12)"], correcta:0 },
  { id:9, texto:"¿Cuántos criollitos se colocan en la placa para su cocción?",
    opciones:["21 unidades (3 filas de 7)","20 unidades (4 filas de 5)","28 unidades (4 filas de 7)","24 unidades (3 filas de 8)"], correcta:0 },
  { id:10, texto:"¿Cuántas pizzas se colocan por estante en la heladera?",
    opciones:["5 por estante, sectorizadas por gusto","4 por estante","6 por estante","3 por estante"], correcta:0 },
  { id:11, texto:"¿A qué temperatura debe estar la cámara de frío?",
    opciones:["0 °C a 5 °C","-15 °C a -20 °C","5 °C a 10 °C","-5 °C a 0 °C"], correcta:0 },
  { id:12, texto:'¿Qué significa el método "PEPS"?',
    opciones:["Primero en entrar, primero en salir","Primero en vencer, primero en salir","Primero en encargar, primero en sacar","Productos en perfecto estado"], correcta:0 },
  { id:13, texto:"Cuando llega mercadería de fábrica, ¿cómo se ordena en la heladera?",
    opciones:["Lo nuevo abajo y lo que ya estaba en stock arriba","Lo nuevo arriba y lo viejo abajo","Todo mezclado por gusto","Lo nuevo al fondo de la cámara sin rotular"], correcta:0 },
  { id:14, tipo:"grilla", texto:"Completá con el color de trapo correspondiente.",
    filas:["Limpieza de baños","Superficies y utensilios en contacto con alimentos","Limpieza de equipos (hornos, heladeras)"],
    columnas:["Verde","Azul","Amarillo"], correcta:[2,0,1] },
  { id:15, texto:"¿Cómo se prepara el agua sanitizada y cuánto dura?",
    opciones:["2 tapas de lavandina en 2 litros de agua, vence a las 4 horas","1 tapa de lavandina en 5 litros, vence a las 8 horas","2 tapas en 1 litro, vence a las 24 horas","Media tapa en 2 litros, dura todo el turno"], correcta:0 },
  { id:16, texto:"Además de al ingresar, después del baño o de tocar dinero, ¿cada cuánto nos lavamos las manos?",
    opciones:["Cada 1 hora","Cada 4 horas","Solo al terminar el turno","Una vez por turno"], correcta:0 },
  { id:17, texto:"¿Cuándo se pintan las medialunas con almíbar?",
    opciones:["Únicamente al momento de la entrega al cliente, con pincel de silicona","Apenas salen del horno, con pincel de cerdas","Antes de hornearlas","Al abrir el local, todas juntas"], correcta:0 },
  { id:18, texto:"Un cliente va a llevar 2 empanadas. ¿Qué le ofrecemos?",
    opciones:["La promo de 3 empanadas + gaseosa","Nada, ya decidió","Media docena","Un descuento en la próxima compra"], correcta:0 },
  { id:19, texto:"¿Cuál de los siguientes extintores es el más versátil por cubrir casi todos los tipos de fuego?",
    opciones:["Extintor ABC","Extintor K","Extintor de agua","Extintor de espuma"], correcta:0 },
  { id:20, texto:"¿Qué va en el tacho verde (reciclables)?",
    opciones:["Tickets, cartón seco, servilletas y bolsas secas, limpios y sin restos","Restos de comida y cartón húmedo","Residuos de baño","Papel manteca sucio y servilletas usadas"], correcta:0 }
];

// Nivel 2 — Encargado: delivery, Data Live, caja, pedidos y seguridad.
const PREGUNTAS_ENCARGADO = [
  { id:101, texto:"¿Qué mide el Inaccuracy en Delivery?",
    opciones:["La cantidad de órdenes con errores generados desde la operación","El tiempo de espera del rider","La cantidad de órdenes del día","Los pedidos que cancela el cliente"], correcta:0 },
  { id:102, texto:"¿Cuál es el objetivo de Inaccuracy por local?",
    opciones:["Estar por debajo del 2,5%","Estar por debajo del 5%","Estar por debajo del 10%","Estar por encima del 2,5%"], correcta:0 },
  { id:103, texto:"¿Qué son los rechazos en delivery?",
    opciones:["Pedidos que el local cancela por falta de producto, fallas operativas o alta demanda","Pedidos que el cliente devuelve","Pedidos que el rider no retira","Pedidos con demora mayor a 10 minutos"], correcta:0 },
  { id:104, texto:"¿Qué mide el AWT (tiempo de espera evitable)?",
    opciones:["Órdenes donde el rider espera más de 10 minutos en el local hasta retirar el pedido","Órdenes entregadas fuera de horario","Órdenes con productos faltantes","El tiempo total de entrega al cliente"], correcta:0 },
  { id:105, texto:"Falta un producto de un pedido de delivery. ¿Qué hacemos?",
    opciones:["No enviamos productos sustitutos","Enviamos un producto parecido","Enviamos el pedido sin avisar","Agregamos una gaseosa de regalo"], correcta:0 },
  { id:106, texto:"Cuando llega el rider, ¿cómo confirmamos qué pedido entregarle?",
    opciones:["Con el nombre del cliente y los últimos 4 números de la orden, verificando el ticket antes de precintar","Con el nombre del rider","Por el color de la bolsa","Le damos el primero que esté listo"], correcta:0 },
  { id:107, texto:"¿Hasta qué hora se genera el pedido a fábrica en Data Live para recibirlo al día siguiente?",
    opciones:["Antes de las 15 hs (los sábados, el refuerzo antes de las 11 hs)","Antes de las 12 hs","Antes de las 18 hs","Antes de las 20 hs"], correcta:0 },
  { id:108, texto:"Las empanadas se piden a fábrica en múltiplos de:",
    opciones:["50 unidades","12 unidades","35 unidades","100 unidades"], correcta:0 },
  { id:109, texto:"¿Hasta cuándo se hace el pedido en Coca-Cola a un Click?",
    opciones:["Antes de las 12:00 hs del día anterior a la entrega","Antes de las 16:00 hs del día anterior","El mismo día de la entrega","Antes de las 15:00 hs del día anterior"], correcta:0 },
  { id:110, texto:"¿Cómo se hacen los egresos de caja?",
    opciones:["En fajos de $20.000 con el ticket de egreso, y se envían al cofre","En fajos de $10.000 sin comprobante","En un sobre al final del mes","Se entregan en mano al encargado siguiente"], correcta:0 },
  { id:111, texto:"¿Cuál es la función del Testigo en el manejo de dinero?",
    opciones:["Verificar que lo contado por el gerencial es correcto (doble control)","Contar el dinero solo","Firmar la planilla sin controlar","Llevar los bolsines al banco"], correcta:0 },
  { id:112, texto:"Sin generador, ¿cuándo se activa el protocolo de corte de luz?",
    opciones:["Cuando se confirma que el corte será mayor a 3 horas","Apenas se corta la luz","Cuando el corte supera 1 hora","Al día siguiente"], correcta:0 },
  { id:113, texto:"¿Dónde se enciende el grupo electrógeno?",
    opciones:["Siempre fuera del local","Dentro del local con la puerta abierta","En la cocina, cerca del tablero","Donde haya lugar"], correcta:0 },
  { id:114, texto:"Con el generador en marcha, ¿qué equipos son prioridad?",
    opciones:["Cámara frigorífica, DVR y horno a gas","La batea y los focos","Todas las térmicas, incluidas las tetrapolares","Las heladeras de bebidas"], correcta:0 },
  { id:115, texto:"Al recibir mercadería por traslado, ¿cómo controlamos la calidad de las empanadas?",
    opciones:["Cocinamos dos empanadas de cada bandeja (primera y última fila)","Probamos una empanada al azar","Solo revisamos el remito","No hace falta controlar"], correcta:0 },
  { id:116, texto:'¿Qué significa "PAS" ante un accidente?',
    opciones:["Proteger, Avisar, Socorrer","Prevenir, Actuar, Sanar","Parar, Analizar, Seguir","Pedir, Asistir, Salir"], correcta:0 },
  { id:117, texto:"Ocurre un accidente laboral a las 21 hs. ¿A quién se contacta para la denuncia?",
    opciones:["A la ART, con el Anexo 1 completo (SyH atiende de 9 a 18 hs)","Al equipo de Seguridad e Higiene al día siguiente","A nadie si no es grave","Solo a RR.HH."], correcta:0 },
  { id:118, texto:"Un cliente paga con un billete dudoso. ¿Qué hacemos?",
    opciones:["Pedimos asistencia al responsable de turno, doble verificación y solicitamos otro medio de pago","Lo aceptamos para no perder la venta","Lo retenemos y llamamos a la policía","Lo aceptamos y lo informamos al cierre"], correcta:0 },
  { id:119, texto:"Con la lapicera detectora, ¿qué indica una marca oscura o negra?",
    opciones:["Billete sospechoso","Billete auténtico","Billete de baja denominación","Que la lapicera está nueva"], correcta:0 },
  { id:120, texto:"¿Para qué tipo de fuego se usa el extintor K?",
    opciones:["Aceites vegetales y grasas de cocina","Tableros eléctricos","Papel y madera","Gasolina y solventes"], correcta:0 }
];

// Nivel 3 — Gerente: administración, inspecciones, RR.HH. y gestión.
const PREGUNTAS_GERENTE = [
  { id:201, texto:"¿Cuál es el orden del plan de carrera?",
    opciones:["Principiante → Entrenador → Encargado de turno → Gte. de Local → Supervisor → Asistente → Gte. de Operaciones",
      "Principiante → Encargado de turno → Entrenador → Gte. de Local → Asistente → Supervisor → Gte. de Operaciones",
      "Entrenador → Principiante → Encargado de turno → Supervisor → Gte. de Local → Asistente → Gte. de Operaciones",
      "Principiante → Entrenador → Gte. de Local → Encargado de turno → Supervisor → Gte. de Operaciones → Asistente"], correcta:0 },
  { id:202, texto:"¿Quiénes están autorizados a modificar el stock de cierre en Data Live?",
    opciones:["Solo los Gerentes de Operaciones","El Gerente de Local","Cualquier encargado de turno","Auditoría"], correcta:0 },
  { id:203, texto:'Al cargar el inventario de fin de mes, ¿qué pasa si se presiona "Volver"?',
    opciones:["El inventario queda en 0 y el mes siguiente no se podrá vender ningún producto","Se guarda automáticamente","Se envía a auditoría para revisión","No pasa nada"], correcta:0 },
  { id:204, texto:"¿Quiénes pueden visualizar las diferencias de stock?",
    opciones:["Gerentes Zonales, Gerentes de Operaciones, Asistentes y Auditoría","Todo el personal del local","Solo el Gerente de Local","Solo RR.HH."], correcta:0 },
  { id:205, texto:"¿Qué comprobante debe tener un gasto para ser válido?",
    opciones:["Factura A a nombre de la razón social del local","Ticket o Factura B","Factura C","Cualquier comprobante con foto"], correcta:0 },
  { id:206, texto:"Llega un inspector y labra un acta. ¿Qué corresponde?",
    opciones:["Avisar urgente al Gerente Zonal con foto del acta; el original se entrega dentro de las 48 hs","Guardar el acta hasta fin de mes","Avisar solo si hay multa","Entregar el original dentro de los 7 días"], correcta:0 },
  { id:207, texto:"¿Qué NO están autorizados a hacer los inspectores?",
    opciones:["Manipular la caja, hacer arqueos o tocar el punto de venta","Ingresar al local","Labrar un acta","Pedir documentación"], correcta:0 },
  { id:208, texto:"¿Cuál es la vigencia del REBA y con cuánta anticipación se avisa su renovación?",
    opciones:["1 año; avisar 60 días antes a Habilitaciones","2 años; avisar 30 días antes","1 año; avisar 7 días antes","6 meses; avisar 15 días antes"], correcta:0 },
  { id:209, texto:"Ante un daño en el inmueble (siniestro), ¿en qué plazo se envía la documentación?",
    opciones:["Dentro de las primeras 72 horas","Dentro de las 24 horas","Dentro de los 7 días","A fin de mes"], correcta:0 },
  { id:210, texto:"En iCheck, ¿qué dato se carga en el campo Legajo?",
    opciones:["El número de DNI, sin excepciones","El CUIL","Un número interno correlativo","El teléfono del empleado"], correcta:0 },
  { id:211, texto:"¿Quién carga las justificaciones en iCheck y cuándo?",
    opciones:["Exclusivamente el Gerente de Local, el mismo día a justificar","Cualquier empleado, a fin de mes","RR.HH., al liquidar","El encargado, una vez por semana"], correcta:0 },
  { id:212, texto:"¿Cuándo es el cierre de novedades para la liquidación?",
    opciones:["El día 20 (excepciones hasta el día 30)","El día 1","El día 15","El último día hábil del mes"], correcta:0 },
  { id:213, texto:"¿Desde cuándo son efectivos los ascensos?",
    opciones:["Desde el 1° de cada mes, comunicándolo el mes anterior","Desde el día que se comunica","Desde mitad de mes","A los 30 días de la evaluación"], correcta:0 },
  { id:214, texto:"En el tablero de asistencia de iCheck, ¿qué indica el color celeste?",
    opciones:["Fichada justificada","Ausencia de fichada","Fichada correcta","Fichada fuera de rango"], correcta:0 },
  { id:215, texto:"¿Quién está autorizado a enviar solicitudes de traslado de personal?",
    opciones:["Solo el Gerente Zonal (con la solicitud firmada por el Gerente Regional)","El Gerente de Local","El propio empleado","El encargado de turno"], correcta:0 },
  { id:216, texto:"¿Qué se requiere para cargar una licencia por enfermedad?",
    opciones:["Adjuntar el certificado médico; el reposo vale solo si está indicado en él","Solo el aviso por WhatsApp","Nada si es de un día","La firma del encargado"], correcta:0 },
  { id:217, texto:"Coca-Cola no entrega y hay quiebre de stock. ¿Cuál es el tope para comprar a un distribuidor externo?",
    opciones:["Hasta un 40% más caro que Coca-Cola, con autorización del Gte. Zonal y Regional","Sin tope, lo importante es tener stock","Hasta un 10% más caro","El encargado compra lo que haga falta"], correcta:0 },
  { id:218, texto:'¿Qué competencia se define como "identificar potenciales y gestionar los talentos del equipo"?',
    opciones:["Coaching","Liderazgo","Compromiso","Perfil comercial"], correcta:0 },
  { id:219, texto:"¿Cuál es la misión de Sabores Express?",
    opciones:["Satisfacer las necesidades del cliente con un vínculo comercial sustentable, la mejor calidad al menor precio posible","Ser la empresa líder en take away y delivery a nivel nacional","Honestidad, integridad y respeto","Abrir la mayor cantidad de locales posible"], correcta:0 },
  { id:220, texto:"¿Qué documento debe exhibirse en la pared del local, de fácil acceso para una inspección?",
    opciones:["REBA, fumigación, análisis de agua, habilitación y formulario 960 ARCA","Solo la habilitación","Ninguno, se muestran si los piden","El plan de carrera"], correcta:0 }
];

// Hamburguesas Extremas: mismos niveles y criterios que Sabores. Bancos pendientes de cargar desde su manual.
const EXTREMAS_ENTRENADOR = [];
const EXTREMAS_ENCARGADO = [];
const EXTREMAS_GERENTE = [];

// Acceso único para quien lo cargue desde afuera: BANCOS[marca][nivel].
window.BANCOS = {
  sabores: { entrenador: PREGUNTAS_ENTRENADOR, encargado: PREGUNTAS_ENCARGADO, gerente: PREGUNTAS_GERENTE },
  hex:     { entrenador: EXTREMAS_ENTRENADOR, encargado: EXTREMAS_ENCARGADO, gerente: EXTREMAS_GERENTE }
};
