const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell,
  WidthType, BorderStyle, AlignmentType, ShadingType, Header, Footer, PageNumber,
} = require("docx");

const MAROON = "66062D";
const MAROON_LIGHT = "F7E9EE";
const GREY = "6B5A5E";
const LINE = "E8DCD6";

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 360, after: 160 },
    children: [new TextRun({ text, bold: true, color: MAROON, size: 30 })],
  });
}

function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 280, after: 120 },
    children: [new TextRun({ text, bold: true, color: "241417", size: 24 })],
  });
}

function p(text, opts = {}) {
  return new Paragraph({
    spacing: { after: 160, line: 300 },
    children: [new TextRun({ text, size: 22, color: "241417", ...opts })],
  });
}

function bullet(text, opts = {}) {
  return new Paragraph({
    bullet: { level: 0 },
    spacing: { after: 90, line: 280 },
    children: [new TextRun({ text, size: 22, color: "241417", ...opts })],
  });
}

function code(text) {
  return new TextRun({ text, font: "Consolas", size: 20, color: MAROON });
}

function cell(text, opts = {}) {
  return new TableCell({
    width: opts.width ? { size: opts.width, type: WidthType.PERCENTAGE } : undefined,
    shading: opts.header ? { type: ShadingType.CLEAR, fill: MAROON, color: "auto" } : undefined,
    margins: { top: 80, bottom: 80, left: 120, right: 120 },
    children: [
      new Paragraph({
        children: [
          new TextRun({
            text,
            bold: !!opts.header,
            color: opts.header ? "FFFFFF" : "241417",
            size: 20,
            font: opts.mono ? "Consolas" : undefined,
          }),
        ],
      }),
    ],
  });
}

function table(headers, rows, widths) {
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    borders: {
      top: { style: BorderStyle.SINGLE, size: 4, color: LINE },
      bottom: { style: BorderStyle.SINGLE, size: 4, color: LINE },
      left: { style: BorderStyle.SINGLE, size: 4, color: LINE },
      right: { style: BorderStyle.SINGLE, size: 4, color: LINE },
      insideHorizontal: { style: BorderStyle.SINGLE, size: 2, color: LINE },
      insideVertical: { style: BorderStyle.SINGLE, size: 2, color: LINE },
    },
    rows: [
      new TableRow({
        children: headers.map((hd, i) => cell(hd, { header: true, width: widths ? widths[i] : undefined })),
        tableHeader: true,
      }),
      ...rows.map(
        (r) =>
          new TableRow({
            children: r.map((c, i) => cell(c, { width: widths ? widths[i] : undefined, mono: i === 0 })),
          })
      ),
    ],
  });
}

const doc = new Document({
  sections: [
    {
      properties: {},
      headers: {
        default: new Header({
          children: [
            new Paragraph({
              alignment: AlignmentType.RIGHT,
              children: [new TextRun({ text: "Mühle · Vocaturo & Asociados", size: 16, color: GREY })],
            }),
          ],
        }),
      },
      footers: {
        default: new Footer({
          children: [
            new Paragraph({
              alignment: AlignmentType.CENTER,
              children: [
                new TextRun({ text: "Página ", size: 16, color: GREY }),
                new TextRun({ children: [PageNumber.CURRENT], size: 16, color: GREY }),
              ],
            }),
          ],
        }),
      },
      children: [
        new Paragraph({
          spacing: { after: 60 },
          children: [new TextRun({ text: "DOCUMENTACIÓN TÉCNICA", size: 18, color: GREY, bold: true })],
        }),
        new Paragraph({
          spacing: { after: 300 },
          children: [
            new TextRun({
              text: "Matriz de Permisos Funcionales y Asociación por Grupo",
              bold: true,
              size: 40,
              color: MAROON,
            }),
          ],
        }),
        p(
          "Este documento describe cómo funciona el modelo de permisos de Mühle: cómo se le otorgan permisos a un Perfil (Grupo) a través de la Matriz de Permisos Funcionales, y cómo un Usuario queda asociado a ese Perfil para heredar esos permisos."
        ),

        h1("1. Modelo de datos"),
        p(
          "El modelo se apoya en cuatro tablas. Ninguna de ellas guarda permisos \"por usuario\": todo permiso se define a nivel de Perfil, y el usuario hereda los permisos del Perfil al que está asociado."
        ),
        table(
          ["Tabla", "Qué representa", "Relación"],
          [
            ["Groups", "Los Perfiles del sistema (ej. Gerencia, Consultores, Clientes).", "—"],
            ["Actions", "Los permisos/acciones disponibles en el sistema (ej. SEGURIDAD.USERS, PARAMETRIA.EDIT).", "—"],
            [
              "GroupsActions",
              "La Matriz de Permisos en sí: qué Acciones tiene habilitadas cada Perfil.",
              "Groups (1) — (N) GroupsActions (N) — (1) Actions",
            ],
            [
              "GroupsUserMembers",
              "La asociación de un Usuario a un Perfil.",
              "Groups (1) — (N) GroupsUserMembers (N) — (1) Users",
            ],
          ],
          [22, 46, 32]
        ),

        h1("2. Matriz de Permisos Funcionales"),
        p("Se accede desde Perfiles / Grupos → ícono de escudo (\"Permisos asociados\") en la fila del Perfil que se quiere configurar."),

        h2("2.1 Qué hace cada interruptor"),
        p(
          "Cada fila de la matriz es una Acción (un permiso: \"Administrar usuarios\", \"Cerrar gestiones\", etc.) con un interruptor a la derecha. El interruptor refleja si existe o no una fila en GroupsActions para ese Perfil + esa Acción."
        ),
        bullet("Interruptor activado → existe una fila en GroupsActions (GroupId + ActionId). El Perfil tiene ese permiso."),
        bullet("Interruptor desactivado → no existe esa fila. El Perfil no tiene ese permiso."),

        h2("2.2 Cómo persiste el cambio"),
        p("El guardado es inmediato: no hay un botón \"Guardar\" para la matriz. Al tocar un interruptor:"),
        bullet("El cliente dispara al instante una llamada al motor (sin recarga de página) marcando la Acción como habilitada o deshabilitada para ese Perfil."),
        bullet("El servidor inserta o elimina la fila correspondiente en GroupsActions."),
        bullet("Cada cambio queda registrado en M_AUDITORIA_ADMIN bajo el módulo PERFIL_ADMIN, acción ASOCIAR o DESASOCIAR, con el detalle de qué permiso se tocó y para qué Perfil."),
        p("Esto se verificó en vivo esta sesión: activar y desactivar \"Administrar usuarios\" para el Perfil Consultores insertó y luego eliminó correctamente la fila en GroupsActions.", {
          italics: true, color: GREY, size: 20,
        }),

        h2("2.3 Regla de integridad clave"),
        p(
          "GroupsActions es la única fuente de verdad sobre qué puede hacer un Perfil. Existe una tabla legada, PrmActions, que no debe usarse en paralelo como una segunda fuente de autorización: si en algún momento se consulta o se escribe permisos ahí, se rompe la consistencia del modelo."
        ),

        h1("3. Asociación de un Usuario a un Perfil"),
        p("Se define en el formulario de alta/edición de Usuario (Gestión de Usuarios → Nuevo / Editar), en el campo \"Perfil / Grupo\"."),

        h2("3.1 Cómo se guarda"),
        p(
          "A diferencia de lo que el nombre de la tabla GroupsUserMembers sugiere (una relación muchos-a-muchos), la aplicación trata la asociación Usuario–Perfil como uno-a-uno: un usuario tiene en todo momento un único Perfil activo."
        ),
        p("Al guardar el formulario de Usuario, el motor ejecuta dos pasos dentro de la misma transacción:"),
        bullet([
          "Borra cualquier fila existente en GroupsUserMembers para ese usuario.",
        ].join(""), {}),
        bullet("Inserta una única fila nueva con el Perfil elegido en el combo."),
        p(
          "Esto significa que cambiar el Perfil de un usuario reemplaza su Perfil anterior — no lo agrega como uno más. El mismo patrón se usa ahora para la asociación de Sector (tabla UsersSector), agregada en esta revisión.",
          { italics: true, color: GREY, size: 20 }
        ),

        h2("3.2 Qué hereda el usuario"),
        p(
          "Un usuario no tiene permisos propios. En tiempo de ejecución, sus permisos efectivos son exactamente los de su Perfil actual: todas las filas de GroupsActions donde GroupId coincide con el Perfil asociado en GroupsUserMembers."
        ),

        h1("4. Flujo completo, de punta a punta"),
        table(
          ["Paso", "Acción", "Tabla afectada"],
          [
            ["1", "Se crea un Perfil nuevo (ej. \"Auditoría\").", "Groups"],
            ["2", "Se abre la Matriz de Permisos de ese Perfil y se activan los interruptores necesarios.", "GroupsActions"],
            ["3", "Se crea o edita un Usuario y se le asigna ese Perfil en el combo.", "GroupsUserMembers"],
            ["4", "El usuario inicia sesión: el sistema resuelve sus permisos combinando GroupsUserMembers → GroupsActions → Actions.", "(lectura, sin escritura)"],
          ],
          [12, 62, 26]
        ),

        h1("5. Resumen"),
        bullet("Los permisos viven en el Perfil, nunca en el Usuario directamente."),
        bullet("La Matriz de Permisos Funcionales edita GroupsActions en tiempo real, interruptor por interruptor, con auditoría automática."),
        bullet("Un Usuario tiene un único Perfil activo a la vez; asignar uno nuevo reemplaza al anterior."),
        bullet("GroupsActions es la única fuente de verdad de autorización — PrmActions no debe usarse en paralelo."),
      ],
    },
  ],
});

Packer.toBuffer(doc).then((buffer) => {
  fs.writeFileSync(
    "C:\\Users\\Usuario\\AppData\\Roaming\\Claude\\scratch-workspaces\\213282b1-762e-41db-8f6f-5d22cfc3a176\\4e31e2e2-21bc-4635-b377-a033fa8d9a09\\scratch-2026-09-12-698566\\Matriz_Permisos_Funcionales.docx",
    buffer
  );
  console.log("OK");
});
