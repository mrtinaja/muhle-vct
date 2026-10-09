# Vigilante de archivos del servidor web

Avisa por mail cada vez que se agrega, cambia o borra un archivo del sitio MAIN
(`.js`, `.css`, `.aspx`, `.ashx`, `.asmx`, `.master`, `.config`, `.dll`, `.html`).
Revisa cada 10 minutos. Guarda una copia de cada version nueva (salvo `.config` y `.dll`)
en `C:\ProgramData\VocaturoVigilante\historial\<fecha>\`, para ver que se cambio.

## Instalacion

1. **En SQL Server** (primero desarrollo): correr `db/AUDITORIA_ARCHIVOS_INSTALACION.sql`
   reemplazando `<CLAVE>` por una clave nueva para el login `VIGILANTE_ARCHIVOS`.
   Ese login solo puede ejecutar un SP y mandar mail.
2. **En el servidor web**, con PowerShell como Administrador, desde esta carpeta:
   ```
   .\instalar_vigilante.ps1 -Sitio "C:\ruta\del\sitio" -SqlServidor "servidor-sql"
   ```
   Pide el login y la clave del paso 1: se guardan cifradas para esa maquina
   (solo Administradores y SYSTEM pueden leer la carpeta). Toma la foto inicial
   y crea la tarea programada "Vocaturo - Vigilante de archivos".
3. **Probar**: cambiar un comentario en algun `.js` del sitio y esperar 10 minutos.
   Tiene que llegar un mail "[Archivos SERVIDOR] 1 archivo(s) cambiado(s)".

## Que mirar si no llega el mail

- `C:\ProgramData\VocaturoVigilante\vigilante.log`: cada corrida con cambios o errores.
- `SELECT TOP 20 * FROM dbo.VCT_AUDITORIA_ARCHIVOS ORDER BY ID DESC`: si hay filas con
  `MAIL_ENVIADO = 0`, el problema es Database Mail, no el vigilante.
- Si falla la conexion a SQL, la foto no se actualiza y el aviso se reintenta en la proxima corrida.

## Quitarlo

```
Unregister-ScheduledTask -TaskName "Vocaturo - Vigilante de archivos" -Confirm:$false
```
