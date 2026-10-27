/* ============================================================================
   SIDEBAR_ICONO_PROYECTOS_KANBAN
   Cambia el icono de Proyectos en el sidebar: carpeta simple -> folder-kanban
   (carpeta con barras). Mantiene el formato actual (22x22, stroke #ffffff).
   Re-ejecutable: solo toca la fila Code='PROYECTOS'.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

UPDATE dbo.SIDEBAR
SET SvgIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13c0 1.1.9 2 2 2Z"/><path d="M8 10v4"/><path d="M12 10v2"/><path d="M16 10v6"/></svg>',
    ModifiedDate = GETDATE()
WHERE Code = 'PROYECTOS';

PRINT 'OK: icono de Proyectos (sidebar) cambiado a folder-kanban. Filas: ' + CONVERT(VARCHAR(10), @@ROWCOUNT);
GO
