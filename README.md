# MAIN Vocaturo (Muhle)

Repositorio del desarrollo de MAIN sobre la plataforma Muhle: stored procedures, funciones y
vistas de la base `MuhlePROD`, assets propios (`vct-*.css` / `vct-*.js`) y los scripts de cada entrega.

**La fuente de verdad es el servidor.** El repo es la foto de lo que esta publicado en
**desarrollo** (`vocaturo.desa.interdev.online`) mas el historial de cada cambio. Antes de tocar
algo, se baja la version vigente; despues de publicarlo, se vuelve a bajar y se commitea.

## Estructura

| Carpeta | Que hay |
| --- | --- |
| `db/objetos/` | Un `.sql` por SP, funcion, vista y trigger, tal como estan en el servidor (los genera `tools/split_dump.py`) |
| `db/DUMP_OBJETOS.sql` | Script de solo lectura que baja todas las definiciones |
| `css/`, `js/`, `main/`, `task/`... | Espejo de `C:\inetpub\wwwroot\muhle-vct` (css/js se bajan con `tools/pull_assets.ps1`) |
| raiz (`*.sql`) | Scripts de entrega (`PROYECTO_*`, `INICIO_*`, `PERMISOS_*`...) y diagnosticos (`DIAG_*`) |
| `tools/` | Herramientas para sincronizar con el servidor |

No se versionan: `Bin/`, `lib/`, `img/`, `fonts/`, `web.config` (tiene la machineKey),
`vocaturo_mail_setup.sql` (tiene la clave del mail) ni `_diag/` (salidas con datos reales).

## Flujo de trabajo (para no pisarnos)

1. **Antes de empezar:** `git pull`. Avisar en el grupo que objeto se va a tocar.
2. **Bajar lo vigente** de lo que se va a tocar:
   - SPs: correr `db/DUMP_OBJETOS.sql` en SSMS (Query > SQLCMD Mode, F5) y despues
     `python tools/split_dump.py`. Si `git status` muestra cambios que nadie commiteo,
     alguien toco el servidor directo: commitearlos aparte ("sync servidor") antes de seguir.
   - Assets: `powershell -ExecutionPolicy Bypass -File tools\pull_assets.ps1`.
3. **Hacer el cambio** y publicarlo en desarrollo (ALTER en SSMS / subir el asset, subiendo el `?v=` en el SP que lo carga).
4. **Volver a bajar** (paso 2) y commitear: el diff de `db/objetos/`, `css/` y `js/` es exactamente lo que cambio en el servidor.
   El script de entrega va en la raiz con el mismo commit.
5. **Pasaje a produccion:** se hace desde un commit con tag (`prod-AAAA-MM-DD`), asi se sabe que version esta en cada ambiente.

Un cambio = un commit con mensaje que diga que y por que (`Plan: aviso por mail al cambiar fecha`).
Nunca commitear claves, ni salidas de diagnostico con datos de clientes.

## Ambientes

| Ambiente | URL | Base |
| --- | --- | --- |
| Desarrollo | https://vocaturo.desa.interdev.online/main | MuhlePROD (servidor de desarrollo) |
| Produccion | https://vocaturo.muhle.io/main | MuhlePROD (produccion) |
