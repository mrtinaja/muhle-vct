const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType,
  Table, TableRow, TableCell, WidthType, ShadingType, BorderStyle,
  TableOfContents, PageBreak, LevelFormat, convertInchesToTwip
} = require("docx");

const BORDO = "66062D";
const NAVY = "172033";
const GRAY = "64748B";
const LIGHT = "F7EAF0";

function h1(text) {
  return new Paragraph({ text, heading: HeadingLevel.HEADING_1, spacing: { before: 400, after: 200 } });
}
function h2(text) {
  return new Paragraph({ text, heading: HeadingLevel.HEADING_2, spacing: { before: 300, after: 150 } });
}
function h3(text) {
  return new Paragraph({ text, heading: HeadingLevel.HEADING_3, spacing: { before: 200, after: 100 } });
}
function p(text, opts) {
  opts = opts || {};
  return new Paragraph({
    spacing: { after: 160 },
    children: [new TextRun({ text, ...opts })]
  });
}
function bullet(text, level) {
  return new Paragraph({
    numbering: { reference: "bullets", level: level || 0 },
    spacing: { after: 80 },
    children: [new TextRun({ text })]
  });
}
function numbered(text, ref) {
  return new Paragraph({
    numbering: { reference: ref || "steps", level: 0 },
    spacing: { after: 80 },
    children: [new TextRun({ text })]
  });
}
function note(title, text) {
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [
      new TableRow({
        children: [
          new TableCell({
            shading: { type: ShadingType.CLEAR, fill: LIGHT },
            margins: { top: 120, bottom: 120, left: 160, right: 160 },
            borders: {
              top: { style: BorderStyle.SINGLE, size: 4, color: BORDO },
              bottom: { style: BorderStyle.SINGLE, size: 4, color: BORDO },
              left: { style: BorderStyle.SINGLE, size: 24, color: BORDO },
              right: { style: BorderStyle.SINGLE, size: 4, color: BORDO }
            },
            children: [
              new Paragraph({
                spacing: { after: 60 },
                children: [new TextRun({ text: title, bold: true, color: BORDO })]
              }),
              new Paragraph({
                children: [new TextRun({ text, color: NAVY })]
              })
            ]
          })
        ]
      })
    ]
  });
}
function spacer(h) {
  return new Paragraph({ spacing: { after: h || 120 }, children: [] });
}

function fieldTable(rows) {
  // rows: [ [campo, descripcion], ... ]
  return new Table({
    width: { size: 9350, type: WidthType.DXA },
    columnWidths: [2600, 6750],
    rows: [
      new TableRow({
        tableHeader: true,
        children: [
          new TableCell({
            width: { size: 2600, type: WidthType.DXA },
            shading: { type: ShadingType.CLEAR, fill: BORDO },
            margins: { top: 80, bottom: 80, left: 120, right: 120 },
            children: [new Paragraph({ children: [new TextRun({ text: "Campo", bold: true, color: "FFFFFF" })] })]
          }),
          new TableCell({
            width: { size: 6750, type: WidthType.DXA },
            shading: { type: ShadingType.CLEAR, fill: BORDO },
            margins: { top: 80, bottom: 80, left: 120, right: 120 },
            children: [new Paragraph({ children: [new TextRun({ text: "Descripción", bold: true, color: "FFFFFF" })] })]
          })
        ]
      }),
      ...rows.map((r, i) => new TableRow({
        children: [
          new TableCell({
            width: { size: 2600, type: WidthType.DXA },
            shading: { type: ShadingType.CLEAR, fill: i % 2 === 0 ? "FFFFFF" : "F8FAFC" },
            margins: { top: 80, bottom: 80, left: 120, right: 120 },
            children: [new Paragraph({ children: [new TextRun({ text: r[0], bold: true })] })]
          }),
          new TableCell({
            width: { size: 6750, type: WidthType.DXA },
            shading: { type: ShadingType.CLEAR, fill: i % 2 === 0 ? "FFFFFF" : "F8FAFC" },
            margins: { top: 80, bottom: 80, left: 120, right: 120 },
            children: [new Paragraph({ children: [new TextRun({ text: r[1] })] })]
          })
        ]
      }))
    ]
  });
}

function simpleTable(header, rows, widths) {
  widths = widths || header.map(() => Math.floor(9350 / header.length));
  return new Table({
    width: { size: 9350, type: WidthType.DXA },
    columnWidths: widths,
    rows: [
      new TableRow({
        tableHeader: true,
        children: header.map((htext, i) => new TableCell({
          width: { size: widths[i], type: WidthType.DXA },
          shading: { type: ShadingType.CLEAR, fill: BORDO },
          margins: { top: 80, bottom: 80, left: 120, right: 120 },
          children: [new Paragraph({ children: [new TextRun({ text: htext, bold: true, color: "FFFFFF" })] })]
        }))
      }),
      ...rows.map((r, ri) => new TableRow({
        children: r.map((cell, ci) => new TableCell({
          width: { size: widths[ci], type: WidthType.DXA },
          shading: { type: ShadingType.CLEAR, fill: ri % 2 === 0 ? "FFFFFF" : "F8FAFC" },
          margins: { top: 80, bottom: 80, left: 120, right: 120 },
          children: [new Paragraph({ children: [new TextRun({ text: cell })] })]
        }))
      }))
    ]
  });
}

const doc = new Document({
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [
          { level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 440, hanging: 260 } } } },
          { level: 1, format: LevelFormat.BULLET, text: "◦", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 880, hanging: 260 } } } }
        ]
      },
      {
        reference: "steps",
        levels: [
          { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 440, hanging: 260 } } } }
        ]
      }
    ]
  },
  styles: {
    default: {
      document: { run: { font: "Calibri", size: 22, color: "1E293B" } }
    },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, color: BORDO, font: "Calibri" },
        paragraph: { spacing: { before: 400, after: 200 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 26, bold: true, color: NAVY, font: "Calibri" },
        paragraph: { spacing: { before: 300, after: 150 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 23, bold: true, color: BORDO, font: "Calibri" },
        paragraph: { spacing: { before: 200, after: 100 }, outlineLevel: 2 } }
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1440, bottom: 1440, left: 1440, right: 1440 }
      }
    },
    children: [
      // ---------- PORTADA ----------
      new Paragraph({ spacing: { before: 2000, after: 100 }, alignment: AlignmentType.CENTER,
        children: [new TextRun({ text: "vocaturo", bold: true, size: 56, color: BORDO })] }),
      new Paragraph({ spacing: { after: 600 }, alignment: AlignmentType.CENTER,
        children: [new TextRun({ text: "Sistema de Seguridad — Panel de Administración", size: 26, color: NAVY })] }),
      new Paragraph({ spacing: { after: 100 }, alignment: AlignmentType.CENTER,
        children: [new TextRun({ text: "Manual de Usuario", bold: true, size: 44, color: NAVY })] }),
      new Paragraph({ spacing: { after: 2000 }, alignment: AlignmentType.CENTER,
        children: [new TextRun({ text: "Gestión de Usuarios, Perfiles, Permisos y Auditoría", size: 24, color: GRAY })] }),
      new Paragraph({ alignment: AlignmentType.CENTER,
        children: [new TextRun({ text: "Versión 1.0 — Septiembre 2026", size: 20, color: GRAY, italics: true })] }),
      new Paragraph({ children: [new PageBreak()] }),

      // ---------- TABLA DE CONTENIDOS ----------
      h1("Índice"),
      new TableOfContents("Índice", { hyperlink: true, headingStyleRange: "1-3" }),
      new Paragraph({ children: [new PageBreak()] }),

      // ---------- 1. INTRODUCCION ----------
      h1("1. Introducción"),
      p("Este manual explica, de punta a punta, cómo usar el Panel de Administración (\"Sistema de Seguridad\") de Vocaturo/Mühle. Este panel es un sistema distinto del portal principal de gestión (Clientes, Proyectos, Consultores, etc.): sirve exclusivamente para administrar quién puede entrar al sistema, qué puede ver y hacer cada uno, y para consultar el historial de cambios de seguridad."),
      note("Importante — no confundir los dos sistemas",
        "El portal principal (donde se gestionan Clientes, Proyectos, Consultores, Empleados, Templates de email, etc.) es una aplicación separada. Este manual cubre únicamente el Panel de Administración: Usuarios, Perfiles, Estructura organizacional y Reportes de auditoría."),
      h2("1.1 Acceso al panel"),
      p("El panel admin tiene su propia pantalla de login, distinta a la del portal principal (dice \"Sistema de Seguridad\" en vez de \"Sistema de Gestión\")."),
      numbered("Ingresar a la URL del panel de administración."),
      numbered("Completar Usuario y Contraseña."),
      numbered("Presionar \"Ingresar\"."),
      p("Al ingresar correctamente, el sistema muestra el saludo \"BIENVENIDO, [Nombre]\" arriba a la derecha, junto al botón para salir del sistema."),
      h2("1.2 Estructura general de la pantalla"),
      p("Todas las secciones comparten el mismo diseño:"),
      bullet("Barra lateral izquierda: 4 íconos para moverse entre las secciones — Usuarios, Perfiles, Estructura y Reportes."),
      bullet("Encabezado de cada pantalla: título, descripción breve y, en las grillas, una barra de acciones (cantidad por página, exportar a Excel/PDF/Word, buscador)."),
      bullet("Grillas (listados): tienen búsqueda libre, orden por columna (flechita junto al título) y paginado abajo a la derecha."),
      bullet("Cada fila de una grilla tiene, a la derecha, los botones de acción disponibles para ese registro (Editar, Usuarios asociados, etc., según la sección)."),

      // ---------- 2. GESTION DE USUARIOS ----------
      h1("2. Gestión de Usuarios"),
      p("Sección para dar de alta, editar y controlar el estado de todas las personas que pueden loguearse en el sistema. Se accede con el primer ícono de la barra lateral (silueta de persona)."),

      h2("2.1 Listado de usuarios"),
      p("Muestra todos los usuarios dados de alta, con las columnas:"),
      fieldTable([
        ["Usuario", "Nombre de login (el que se usa para ingresar al sistema)."],
        ["Descripción", "Nombre y apellido de la persona."],
        ["Email", "Casilla de correo asociada."],
        ["Estado", "Activa / Inactiva. Un usuario Inactivo no puede loguearse."],
        ["Perfil", "El perfil (rol) actualmente asignado a ese usuario — define qué puede ver y hacer."],
        ["Fallidos", "Cantidad de intentos de login fallidos consecutivos."]
      ]),
      spacer(),
      p("Herramientas disponibles arriba de la grilla:"),
      bullet("Selector de cantidad por página (10/25/50/100)."),
      bullet("Exportar el listado a Excel, PDF o Word."),
      bullet("Buscador libre (busca por usuario, nombre, email, etc.)."),
      bullet("Botón \"Nuevo\" para dar de alta un usuario."),

      h2("2.2 Crear un usuario nuevo"),
      numbered("Ir a Usuarios y presionar \"Nuevo\" (arriba a la derecha)."),
      numbered("Completar el formulario \"Nuevo usuario\" (ver campos en la tabla siguiente)."),
      numbered("Presionar \"Crear usuario\" (o \"Guardar\", según la versión) para confirmar."),
      spacer(),
      fieldTable([
        ["Usuario", "Nombre de login único (obligatorio). No se puede repetir entre usuarios."],
        ["Nombre y Apellido", "Nombre completo de la persona (obligatorio)."],
        ["Email", "Casilla de correo de la persona."],
        ["Contraseña", "Clave inicial de acceso (obligatorio)."],
        ["Perfil / Grupo", "El perfil que va a tener este usuario. Obligatorio — define sus permisos desde el primer login."],
        ["Estado", "Activa / Inactiva."]
      ]),

      h2("2.3 Editar un usuario existente"),
      numbered("En el listado de Usuarios, presionar el lápiz (\"Editar\") en la fila del usuario deseado."),
      numbered("Modificar los campos necesarios (nombre, email, contraseña, perfil, estado)."),
      numbered("Presionar \"Guardar cambios\"."),
      note("Regla clave: un solo perfil activo por usuario",
        "Un usuario solo puede tener un Perfil activo a la vez. Si se le asigna un perfil nuevo (ya sea desde esta pantalla o desde Perfiles → Usuarios asociados), el sistema lo desvincula automáticamente del perfil anterior."),

      h2("2.4 Estado y bloqueo por intentos fallidos"),
      p("La columna \"Fallidos\" cuenta los intentos de login incorrectos consecutivos de cada usuario. Si un usuario no puede ingresar, revisar primero:"),
      bullet("Que el Estado sea \"Activa\"."),
      bullet("Que el contador de Fallidos no esté indicando bloqueo por intentos reiterados."),
      bullet("Que tenga un Perfil asignado (sin perfil, no tiene permisos habilitados en ningún módulo)."),

      // ---------- 3. GESTION DE PERFILES ----------
      h1("3. Gestión de Perfiles"),
      p("Los \"Perfiles\" son los roles del sistema (por ejemplo: Gerencia, Proyectos, Clientes, Consultores, Administración). Cada usuario tiene un único perfil activo, y todo lo que ese usuario puede ver o hacer en el portal principal depende exclusivamente de los permisos y menús asociados a su perfil. Se accede con el segundo ícono de la barra lateral (escudo)."),

      h2("3.1 Listado y creación de perfiles"),
      p("La grilla principal de Perfiles muestra: Perfil (código), Descripción, Email de contacto del perfil (usado, por ejemplo, para el destinatario \"Gerencia\" en el envío automático de emails) y una columna de Acciones con 4 botones por fila."),
      spacer(),
      simpleTable(
        ["Acción", "Qué hace"],
        [
          ["Editar (lápiz)", "Modifica el código, nombre o email del perfil."],
          ["Usuarios asociados", "Ve y gestiona qué usuarios pertenecen a este perfil."],
          ["Opciones Sidebar / Menúes asociados", "Define qué módulos del menú lateral del portal principal ve este perfil."],
          ["Permisos asociados", "Abre la Matriz de Permisos Funcionales: qué acciones concretas puede hacer este perfil."]
        ],
        [3200, 6150]
      ),
      spacer(),
      p("Para crear un perfil nuevo: presionar \"Nuevo\" arriba a la derecha, completar Código/ID de Perfil y Nombre del perfil, y confirmar con \"Crear perfil\". Un perfil recién creado no tiene usuarios, menús ni permisos asignados — hay que configurarlos con los 3 botones descriptos arriba."),

      h2("3.2 Usuarios asociados a un perfil"),
      p("Desde el botón \"Usuarios asociados\" de un perfil se puede:"),
      bullet("Ver la lista de usuarios que actualmente tienen ese perfil (con su estado y cantidad de logins fallidos)."),
      bullet("Asignar un usuario nuevo a este perfil: elegirlo del desplegable \"Seleccione un usuario\" y presionar \"Agregar\"."),
      note("Recordar", "Al asignar un usuario a este perfil, se desvincula automáticamente de cualquier perfil anterior que tuviera (un usuario = un perfil activo)."),

      h2("3.3 Menúes / Opciones de sidebar asociados"),
      p("Controla qué opciones del menú lateral del portal principal (Inicio, Planificación, Proyectos, Clientes, Consultores, Empleados, Proveedores, Calendario, Agenda, Reportes, Configuración) puede ver un perfil. Si un módulo no está asociado a un perfil, los usuarios de ese perfil no lo ven en su menú."),
      numbered("Entrar a \"Opciones Sidebar\" / \"Menúes Asociados\" del perfil deseado."),
      numbered("Elegir el menú a agregar en el desplegable \"Seleccione un menú\" y presionar \"Agregar\"."),
      numbered("Para quitar un menú ya asociado, usar la acción correspondiente en su fila del listado."),

      h2("3.4 Matriz de Permisos Funcionales"),
      p("Esta es la pantalla más importante para controlar en detalle qué puede hacer cada perfil. Muestra una lista de acciones puntuales del sistema (por ejemplo \"Crear consultores\", \"Editar proyectos\", \"Administrar configuración\", \"Ver configuración\"), cada una con:"),
      fieldTable([
        ["Descripción", "Nombre legible de la acción (ej. \"Administrar configuración\")."],
        ["Código", "Identificador técnico de la acción (ej. CONFIGURACION.EDIT)."],
        ["Estado", "Interruptor (on/off) para habilitar o denegar esa acción al perfil."]
      ]),
      spacer(),
      numbered("Entrar a \"Permisos asociados\" del perfil que se quiere configurar."),
      numbered("Buscar la acción deseada (hay buscador arriba de la grilla) o recorrer la lista."),
      numbered("Activar o desactivar el interruptor de \"Estado\" para otorgar o quitar ese permiso puntual."),
      p("El cambio se aplica de inmediato: no hace falta un botón \"Guardar\" aparte, cada interruptor guarda al tocarlo."),
      note("Por qué esta pantalla es central",
        "Para que una acción aparezca habilitada para un usuario hacen falta DOS cosas a la vez: que su perfil tenga el permiso activado acá, y que el módulo correspondiente esté asociado al perfil en \"Menúes asociados\" (punto 3.3). Si falta cualquiera de las dos, la acción no va a estar disponible aunque la otra esté bien configurada."),

      // ---------- 4. ESTRUCTURA ----------
      h1("4. Estructura organizacional"),
      p("Vista jerárquica (de solo lectura) de la organización, útil para tener una foto rápida de cómo está armada la estructura de perfiles y cuántos usuarios tiene cada uno. Se accede con el tercer ícono de la barra lateral (organigrama)."),
      numbered("Presionar sobre el nodo \"vocaturo\" para desplegar la estructura."),
      numbered("Cada perfil aparece como una tarjeta con: nombre, email de contacto (si tiene) y cantidad de usuarios asignados."),
      numbered("Presionar \"Ver usuarios\" en la tarjeta de un perfil para ver el detalle de sus usuarios (mismo resultado que \"Usuarios asociados\" en la sección Perfiles)."),
      p("Esta pantalla no permite crear ni editar nada: es solo una vista de consulta. Para modificar la estructura hay que usar la sección Perfiles (punto 3)."),

      // ---------- 5. REPORTES ----------
      h1("5. Reportes"),
      p("Sección de consulta y auditoría. Se accede con el cuarto ícono de la barra lateral (gráfico de torta). Arriba de la grilla hay un desplegable \"Reporte\" para elegir cuál de los 4 reportes disponibles consultar:"),
      simpleTable(
        ["Reporte", "Para qué sirve"],
        [
          ["Log Auditoría", "Historial completo de cambios de seguridad: alta/baja de usuarios, cambios de perfil, permisos habilitados o deshabilitados, etc. Es el registro de \"quién hizo qué y cuándo\"."],
          ["Estructura de Perfiles", "Listado de los perfiles existentes y su composición."],
          ["Permisos por Perfil", "Detalle de qué permisos tiene habilitados cada perfil — una foto de la Matriz de Permisos (punto 3.4) en formato reporte."],
          ["Usuarios por Perfil", "Cantidad y detalle de usuarios agrupados por perfil."]
        ],
        [2800, 6550]
      ),

      h2("5.1 Log de Auditoría — filtros y columnas"),
      p("El reporte más usado para investigar cambios. Permite filtrar por:"),
      bullet("Fecha Desde / Fecha Hasta."),
      bullet("Módulo (por ejemplo PERFIL_ADMIN, USUARIOS, PERFILES)."),
      bullet("Acción (ASOCIAR, DESASOCIAR, MODIFICACIÓN, etc.)."),
      bullet("Usuario (quién hizo el cambio)."),
      spacer(),
      p("Cada fila del resultado muestra: Fecha, Módulo, Acción, Usuario que hizo la modificación, Registro afectado y un Detalle en texto plano que explica el cambio (por ejemplo: \"Permiso 'Ver configuración' habilitado para el perfil Gerencia\")."),
      note("Uso recomendado", "Ante cualquier duda de \"¿por qué este usuario ya no ve tal módulo?\" o \"¿quién le sacó tal permiso a este perfil?\", el Log de Auditoría filtrado por Módulo=PERFIL_ADMIN y por el perfil/usuario en cuestión suele tener la respuesta exacta, con fecha y responsable."),

      h2("5.2 Exportar reportes"),
      p("Todos los reportes se pueden exportar con los botones Excel, PDF o Word que aparecen arriba de la grilla, respetando los filtros aplicados en ese momento."),

      // ---------- 6. BUENAS PRACTICAS ----------
      h1("6. Buenas prácticas"),
      bullet("Antes de crear un perfil nuevo, revisar si alguno de los 6 perfiles existentes (Administración, Clientes, Consultores, Gerencia, Proyectos, Test) ya cubre la necesidad — evita duplicar configuraciones de permisos y menús."),
      bullet("Al dar de baja a una persona, cambiar su Estado a \"Inactiva\" en vez de solo quitarle el perfil: así queda registrado que ya no debe poder loguearse, aunque el usuario y su historial se conserven."),
      bullet("Cada vez que se cambie un permiso sensible (por ejemplo, permisos de administración), revisar después en el Log de Auditoría que el cambio haya quedado registrado como se esperaba."),
      bullet("Recordar siempre la regla de las dos condiciones (punto 3.4): un permiso solo tiene efecto si el módulo correspondiente también está asociado al perfil en \"Menúes asociados\"."),
      bullet("Usar el buscador de cada grilla antes de recorrer varias páginas manualmente — los listados de Usuarios y del Log de Auditoría pueden tener decenas de registros."),

      // ---------- 7. PREGUNTAS FRECUENTES ----------
      h1("7. Preguntas frecuentes"),
      h3("Le di un permiso a un perfil pero el usuario sigue sin ver la opción, ¿por qué?"),
      p("Revisar que el módulo correspondiente esté también asociado al perfil en \"Menúes asociados\" (Perfiles → Opciones Sidebar). Hacen falta las dos cosas a la vez: el permiso Y el menú."),
      h3("¿Puedo darle dos perfiles a un mismo usuario?"),
      p("No. El sistema solo permite un perfil activo por usuario. Si se le asigna un perfil nuevo, se pierde automáticamente el anterior."),
      h3("Un usuario no puede loguearse, ¿qué reviso?"),
      p("En Usuarios: que el Estado sea \"Activa\", que tenga un Perfil asignado, y el contador de \"Fallidos\" (intentos de login incorrectos)."),
      h3("¿Cómo sé quién cambió un permiso o dio de baja a un usuario?"),
      p("En Reportes → Log Auditoría, filtrando por fecha, módulo, acción o usuario. El detalle de cada fila indica exactamente qué cambió y quién lo hizo."),
      h3("¿Este panel afecta al portal principal (Clientes, Proyectos, etc.)?"),
      p("Sí, indirectamente: los permisos y menús configurados acá determinan qué puede ver y hacer cada usuario en el portal principal, pero la carga de datos (clientes, proyectos, templates de email, etc.) se hace en el portal principal, no en este panel.")
    ]
  }]
});

Packer.toBuffer(doc).then(buf => {
  require("fs").writeFileSync("Manual_Panel_Administracion_Vocaturo.docx", buf);
  console.log("OK, wrote docx");
});
