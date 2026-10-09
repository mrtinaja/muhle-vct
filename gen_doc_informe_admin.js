const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell,
  WidthType, BorderStyle, AlignmentType, ShadingType, Header, Footer, PageNumber,
  PageBreak,
} = require("docx");

const MAROON = "66062D";
const GREY = "6B5A5E";
const LINE = "E8DCD6";
const OK = "1F7A4D";
const OK_BG = "E6F4EC";
const CRIT = "A3251F";
const CRIT_BG = "FBE9E7";

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 400, after: 180 },
    children: [new TextRun({ text, bold: true, color: MAROON, size: 30 })],
  });
}
function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 260, after: 110 },
    children: [new TextRun({ text, bold: true, color: "241417", size: 24 })],
  });
}
function p(text, opts = {}) {
  return new Paragraph({
    spacing: { after: 150, line: 300 },
    children: [new TextRun({ text, size: 21, color: "241417", ...opts })],
  });
}
function bullet(text, opts = {}) {
  return new Paragraph({
    bullet: { level: 0 },
    spacing: { after: 80, line: 280 },
    children: [new TextRun({ text, size: 21, color: "241417", ...opts })],
  });
}
function statusLine(label, status, detail) {
  const isOk = status === "OK";
  return new Paragraph({
    spacing: { after: 90, line: 280 },
    children: [
      new TextRun({ text: isOk ? "✓ " : "○ ", bold: true, color: isOk ? OK : CRIT, size: 21 }),
      new TextRun({ text: label + ": ", bold: true, size: 21, color: "241417" }),
      new TextRun({ text: detail, size: 21, color: "241417" }),
    ],
  });
}
function cell(text, opts = {}) {
  return new TableCell({
    width: opts.width ? { size: opts.width, type: WidthType.PERCENTAGE } : undefined,
    shading: opts.header ? { type: ShadingType.CLEAR, fill: MAROON, color: "auto" } : undefined,
    margins: { top: 80, bottom: 80, left: 110, right: 110 },
    children: [
      new Paragraph({
        children: [
          new TextRun({
            text,
            bold: !!opts.header,
            color: opts.header ? "FFFFFF" : "241417",
            size: 19,
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
      new TableRow({ children: headers.map((hd, i) => cell(hd, { header: true, width: widths ? widths[i] : undefined })), tableHeader: true }),
      ...rows.map((r) => new TableRow({ children: r.map((c, i) => cell(c, { width: widths ? widths[i] : undefined, mono: i === 0 })) })),
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
              children: [new TextRun({ text: "Mühle · Vocaturo & Asociados — Panel de Administración", size: 16, color: GREY })],
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
                new TextRun({ text: " de ", size: 16, color: GREY }),
                new TextRun({ children: [PageNumber.TOTAL_PAGES], size: 16, color: GREY }),
              ],
            }),
          ],
        }),
      },
      children: [
        new Paragraph({ spacing: { after: 60 }, children: [new TextRun({ text: "INFORME TÉCNICO", size: 18, color: GREY, bold: true })] }),
        new Paragraph({
          spacing: { after: 200 },
          children: [new TextRun({ text: "Panel de Administración — Revisión de punta a punta", bold: true, size: 40, color: MAROON })],
        }),
        p("Este documento consolida todo el trabajo realizado sobre el panel de administración de Mühle: correcciones funcionales, cambios de modelo de datos, ajustes visuales, e ítems pendientes, organizados por módulo."),
        p("Ambiente de trabajo: vocaturo.desa.interdev.online · Base: MuhlePROD", { italics: true, color: GREY, size: 19 }),

        h1("1. Resumen ejecutivo"),
        statusLine("Áreas (alta, edición, baja)", "OK", "Rota de punta a punta al inicio; hoy funciona completo con validaciones y auditoría."),
        statusLine("Acciones / Permisos (ABM)", "OK", "El SP no sabía editar; ahora soporta alta y edición, con jerarquía (Padre/Tipo/Orden) nueva."),
        statusLine("Matriz de Permisos Funcionales", "OK", "El SP real que ejecuta el toggle no auditaba nada; corregido."),
        statusLine("Usuarios", "OK", "Se agregó el campo Sector, que existía en la grilla pero no en el formulario."),
        statusLine("Sectores / Estructura", "OK", "Header y árbol visual alineados al resto de la app; rama Externos aplanada a pedido."),
        statusLine("Reportes", "OK", "Combos de filtro vacíos corregidos; reporte de Usuarios por Sector ya no muestra filas huérfanas."),
        statusLine("Login / Logoff (PSESSIONS)", "PENDIENTE", "No existe SP: vive en código .NET compilado, fuera de nuestro alcance por SQL."),
        statusLine("Motor de grilla duplicado", "PENDIENTE", "Áreas/Acciones usan un motor viejo; Grupos usa uno nuevo. Documentado como deuda técnica, migración pospuesta a pedido."),

        h1("2. Áreas"),
        h2("2.1 Qué estaba roto"),
        bullet("El alta nunca llegaba a ejecutar la transacción: un PKEY corrupto en TRANSACTIONS, un wiring de \"Asociar estados\" incompleto, y un input oculto _ResultCode que goto() nunca seteaba."),
        bullet("La edición traía el formulario vacío: los atributos data-vct-field no coincidían con las claves reales del JSON de la grilla."),
        bullet("El campo ID (autogenerado) quedaba editable al abrir \"Nueva Área\", y al escribir texto no numérico rompía el SP (@NEW_ID tipado como INT)."),
        bullet("Al guardar, la pestaña \"Editar\" quedaba pegada en vez de volver a la grilla."),
        h2("2.2 Qué se corrigió"),
        bullet("M_CONFIG_ADD_AREA: soporta alta y edición, valida duplicados, valida sectores asociados antes de eliminar, limpia su propia selección al terminar, y audita ALTA/MODIFICACION/BAJA."),
        bullet("M_CONFIG_PREV_AREAS: campos de formulario realineados a los datos reales de la grilla; ID no editable en alta."),
        bullet("M_CONFIG_DEL_AREA: ahora escribe el error en M_CONFIG.DESC_ERROR (para que el modal propio lo muestre) y audita la baja."),
        p("Verificado en vivo: alta, edición y baja, con validación de descripción duplicada y de sectores asociados, todas con persistencia real confirmada en base."),

        h1("3. Acciones (ABM de Permisos)"),
        h2("3.1 Qué estaba roto"),
        bullet("M_CONFIG_ADD_ACTION solo sabía dar de alta: si el código ya existía (el caso normal al editar), tiraba \"ya existe\" y no guardaba nada."),
        bullet("El mismo problema de data-vct-field desalineado que en Áreas, más el combo \"Tipo de Acción\" marcado obligatorio sin persistencia real."),
        h2("3.2 Qué se corrigió"),
        bullet("M_CONFIG_ADD_ACTION: agregada la rama de edición completa (UPDATE en Actions, log de MODIFICACION)."),
        bullet("Se agregaron columnas nuevas a dbo.Actions: IdPadre, Tipo y Orden — decisión de negocio: dar soporte real a la jerarquía de permisos (antes solo existían en el formulario, sin persistir)."),
        bullet("M_CONFIG_ACTIONS (grilla) actualizado para incluir esos campos como datos ocultos, necesarios para que la edición los precargue correctamente."),
        p("Nota de alcance: no se agregó la acción \"Eliminar\" en la grilla de Acciones — decisión de Esteban de no habilitar el borrado de permisos desde esta pantalla.", { italics: true, color: GREY, size: 19 }),

        h1("4. Perfiles y Matriz de Permisos Funcionales"),
        bullet("Se identificó que el SP realmente ejecutado por el interruptor de la Matriz es M_CONFIG_UPD_ACT_PERM (no M_CONFIG_UPDATE_ACTION_PERM, un SP homónimo que resultó no estar en uso)."),
        bullet("Ese SP conmutaba el permiso en GroupsActions correctamente, pero no dejaba ningún rastro en M_AUDITORIA_ADMIN."),
        bullet("Se agregó el log de auditoría (ASOCIAR / DESASOCIAR) verificado en vivo: activar y desactivar un permiso ahora aparece en el Reporte de Actividad."),
        p("Se entregó por separado un documento específico (\"Matriz de Permisos Funcionales y Asociación por Grupo\") con el detalle del modelo de datos completo."),

        h1("5. Usuarios"),
        bullet("La grilla mostraba una columna Sector que el formulario de edición no exponía en absoluto."),
        bullet("Se agregó el combo Sector al formulario (M_CONFIG_PREV_USERS), poblado desde Sectores y precargado desde UsersSector al editar."),
        bullet("M_CONFIG_UPD_USER ahora persiste esa asociación con el mismo patrón borrar-e-insertar que ya usaba para el Perfil (un usuario tiene un único Sector activo a la vez)."),

        h1("6. Sectores / Estructura Organizacional"),
        bullet("El header era un bloque gris armado a mano, inconsistente con el resto de la app; se reemplazó por el componente VCT estándar (mismo que usan Áreas, Usuarios, Acciones)."),
        bullet("El árbol de sectores se rediseñó: acento de color a la izquierda de cada tarjeta, ícono identificador, líneas de jerarquía más suaves."),
        bullet("A pedido, la rama \"Externos\" no se muestra como tarjeta propia; sus hijos (Consultor, Cliente) se aplanan directamente bajo Vocaturo."),
        bullet("Pendiente sin resolver: la imagen de fondo de la tarjeta raíz (Vfondo Bordo.png) da 404 — hay que subir el archivo o sacar la referencia."),

        h1("7. Reportes"),
        bullet("Los combos de filtro \"Módulo\", \"Acción\" y \"Usuario\" se veían completamente vacíos en pantalla, aunque las opciones existían por detrás. Causa: la opción placeholder se generaba sin texto visible (<option value=\"\"></option>>); se corrigió agregando textos como \"Todos los módulos\"."),
        bullet("El reporte \"Usuarios por Sector\" mostraba filas con Usuario/Email en blanco: eran registros huérfanos en UsersSector apuntando a usuarios ya borrados. Se cambió el LEFT JOIN a Users por INNER JOIN."),

        h1("8. Deuda técnica y pendientes"),
        table(
          ["Ítem", "Estado", "Nota"],
          [
            ["Motor de grilla duplicado (vct-Table.js viejo vs. nativo)", "Documentado", "Migración de Áreas/Acciones pospuesta a pedido explícito."],
            ["Login / Logoff sin auditoría", "Fuera de alcance", "No existe SP; vive en código .NET compilado."],
            ["Imagen Vfondo Bordo.png rota (404)", "Abierto", "Falta subir el archivo o quitar la referencia."],
            ["Alta de Sector sin selector de Área/Padre", "Abierto", "El formulario de \"Nuevo Sector\" solo pide Nombre y Email."],
          ],
          [42, 20, 38]
        ),

        h1("9. Cierre"),
        p("El estado actual del panel, módulo por módulo, es funcional de punta a punta: alta, edición, baja y auditoría verificadas en vivo contra la base de datos real, no solo contra la interfaz. Los pendientes que quedan abiertos están documentados con su motivo y no bloquean el uso normal del sistema."),
      ],
    },
  ],
});

Packer.toBuffer(doc).then((buffer) => {
  fs.writeFileSync(
    "C:\\Users\\Usuario\\AppData\\Roaming\\Claude\\scratch-workspaces\\213282b1-762e-41db-8f6f-5d22cfc3a176\\4e31e2e2-21bc-4635-b377-a033fa8d9a09\\scratch-2026-09-12-698566\\Informe_Admin_Punta_a_Punta.docx",
    buffer
  );
  console.log("OK");
});
