# Compresión HTTP en IIS (gzip/brotli) — baja los assets ~75%

Hoy los assets van **sin comprimir** (`content-encoding: none`): `vct-main.css` 487 KB,
`vct-main.js` 152 KB, etc. (~945 KB por carga). Con compresión quedan en ~200 KB.
Es **configuración de IIS**, no toca código.

## Paso 1 — Instalar/activar los módulos de compresión (una vez, en el server)
En el servidor IIS, asegurar que estén instalados y habilitados:
- **Static Content Compression**
- **Dynamic Content Compression**

(IIS Manager → el sitio/servidor → "Compression" → tildar ambas. Si no aparece el
módulo, instalarlo desde "Agregar roles y características → Web Server → Performance".)

## Paso 2 — web.config del sitio
`httpCompression` suele estar **bloqueado** a nivel servidor (applicationHost.config),
así que en el `web.config` del sitio alcanza con `urlCompression` (que normalmente NO
está bloqueado). Agregar dentro de `<system.webServer>`:

```xml
<system.webServer>
  <!-- ...lo que ya haya... -->
  <urlCompression doStaticCompression="true" doDynamicCompression="true" />
</system.webServer>
```

## Paso 3 (opcional, si querés afinar los tipos) — a nivel servidor
Esto va en `applicationHost.config` (o IIS Manager → Configuration Editor →
`system.webServer/httpCompression`), NO en el web.config del sitio (ahí está bloqueado):

```xml
<httpCompression directory="%SystemDrive%\inetpub\temp\IIS Temporary Compressed Files">
  <scheme name="gzip" dll="%Windir%\system32\inetsrv\gzip.dll" />
  <staticTypes>
    <add mimeType="text/*" enabled="true" />
    <add mimeType="application/javascript" enabled="true" />
    <add mimeType="application/json" enabled="true" />
    <add mimeType="image/svg+xml" enabled="true" />
    <add mimeType="*/*" enabled="false" />
  </staticTypes>
  <dynamicTypes>
    <add mimeType="text/*" enabled="true" />
    <add mimeType="application/javascript" enabled="true" />
    <add mimeType="application/json" enabled="true" />
    <add mimeType="*/*" enabled="false" />
  </dynamicTypes>
</httpCompression>
```

## Verificar
Después, en el navegador (F12 → Network) un `.css`/`.js` debe mostrar
`Content-Encoding: gzip` y el "Size" (transferido) mucho menor que el "Content".
O desde la consola:
```js
fetch('../css/vct-main.css?x='+Date.now()).then(r=>console.log(r.headers.get('content-encoding')));
```
Debe decir `gzip` (hoy dice `null`).

> Nota: NO tocar el `machineKey` ni `Log/` del web.config. Solo agregar la línea de
> `urlCompression`.
