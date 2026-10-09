# Baja del servidor TODO /css/ y /js/ (con subcarpetas) a css\ y js\ del repo,
# que es un espejo de C:\inetpub\wwwroot\muhle-vct.
# Lee el listado de carpetas del servidor (IIS con exploracion de directorios),
# asi que un archivo nuevo subido al servidor entra solo. Lo unico que no se
# baja esta en tools\assets_excluir.txt.
# Uso:  powershell -ExecutionPolicy Bypass -File tools\pull_assets.ps1 [-Servidor https://vocaturo.desa.interdev.online]
param(
    [string]$Servidor = "https://vocaturo.desa.interdev.online"
)

$raiz = Split-Path -Parent $PSScriptRoot
$excluir = Get-Content (Join-Path $PSScriptRoot "assets_excluir.txt") |
    Where-Object { $_ -and -not $_.StartsWith("#") } | ForEach-Object { $_.Trim().ToLower() }
$script:ok = 0; $script:fallan = @(); $script:nuevos = @()

function Archivos-Remotos([string]$rel) {
    # Con exploracion de directorios: lo que lista el servidor (recursivo).
    # Si el servidor no deja listar (401/403): los archivos que ya tiene el repo.
    try {
        $listado = (Invoke-WebRequest "$Servidor/$rel" -UseBasicParsing -ErrorAction Stop).Content
    } catch {
        if (-not $script:avisoListado) { Write-Host "El servidor no deja listar carpetas: se actualizan los archivos que ya estan en el repo (los nuevos hay que copiarlos del servidor)."; $script:avisoListado = $true }
        $base = Join-Path $raiz ($rel -replace "/", "\")
        if (Test-Path $base) {
            Get-ChildItem $base -Recurse -File | ForEach-Object { $rel + ($_.FullName.Substring($base.Length) -replace "\\", "/") }
        }
        return
    }
    foreach ($m in [regex]::Matches($listado, '(?i)<A HREF="([^"]+)">([^<]+)</A>')) {
        $href = [System.Uri]::UnescapeDataString($m.Groups[1].Value)
        $nombre = $m.Groups[2].Value
        if ($nombre -match '^\[To Parent Directory\]$') { continue }
        if ($href.EndsWith("/")) { Archivos-Remotos ($rel + $nombre + "/"); continue }
        $rel + $nombre
    }
}

function Bajar-Carpeta([string]$rel) {
    foreach ($relArchivo in @(Archivos-Remotos $rel)) {
        if ($excluir -contains $relArchivo.ToLower()) { continue }
        $destino = Join-Path $raiz ($relArchivo -replace "/", "\")
        New-Item -ItemType Directory -Force (Split-Path $destino) | Out-Null
        if (-not (Test-Path $destino)) { $script:nuevos += $relArchivo }
        try {
            # cache-busting: el servidor cachea con el mismo nombre
            $rutaUrl = (($relArchivo -split "/") | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join "/"
            $url = "$Servidor/$rutaUrl"
            Invoke-WebRequest -Uri ($url + "?nocache=" + [DateTime]::Now.Ticks) -OutFile $destino -UseBasicParsing -ErrorAction Stop
            $script:ok++
        } catch {
            $script:fallan += $relArchivo
        }
    }
}

Bajar-Carpeta "css/"
Bajar-Carpeta "js/"

Write-Output "$($script:ok) archivos bajados de $Servidor"
if ($script:nuevos.Count -gt 0) { Write-Output ("Nuevos (no estaban en el repo): " + ($script:nuevos -join ", ")) }
if ($script:fallan.Count -gt 0) { Write-Output ("No se pudieron bajar: " + ($script:fallan -join ", ")) }
