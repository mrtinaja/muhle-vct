# Baja del servidor los CSS/JS propios de MAIN (vct-*) a assets\css y assets\js,
# para versionar lo que esta publicado y no la copia local.
# Uso:  powershell -ExecutionPolicy Bypass -File tools\pull_assets.ps1 [-Servidor https://vocaturo.desa.interdev.online]
param(
    [string]$Servidor = "https://vocaturo.desa.interdev.online"
)

$raiz = Split-Path -Parent $PSScriptRoot
$lista = Get-Content (Join-Path $PSScriptRoot "assets.txt") | Where-Object { $_ -and -not $_.StartsWith("#") }
$ok = 0; $faltan = @()

foreach ($nombre in $lista) {
    $tipo = if ($nombre.EndsWith(".css")) { "css" } else { "js" }
    $destino = Join-Path $raiz "assets\$tipo\$nombre"
    New-Item -ItemType Directory -Force (Split-Path $destino) | Out-Null
    try {
        # cache-busting: el servidor cachea con el mismo nombre
        $url = "$Servidor/$tipo/$nombre" + "?nocache=" + [DateTime]::Now.Ticks
        Invoke-WebRequest -Uri $url -OutFile $destino -UseBasicParsing -ErrorAction Stop
        $ok++
    } catch {
        $faltan += "$tipo/$nombre"
    }
}

Write-Output "$ok archivos bajados de $Servidor"
if ($faltan.Count -gt 0) { Write-Output ("No encontrados: " + ($faltan -join ", ")) }
