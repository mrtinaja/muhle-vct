# Baja del servidor TODOS los CSS/JS de /css/ y /js/ a assets\css y assets\js,
# para versionar lo que esta publicado y no la copia local.
# Lee el listado de carpetas del servidor (IIS con exploracion de directorios),
# asi que un archivo nuevo subido al servidor entra solo. Se excluyen las
# librerias de terceros y los respaldos listados en tools\assets_excluir.txt.
# Uso:  powershell -ExecutionPolicy Bypass -File tools\pull_assets.ps1 [-Servidor https://vocaturo.desa.interdev.online]
param(
    [string]$Servidor = "https://vocaturo.desa.interdev.online"
)

$raiz = Split-Path -Parent $PSScriptRoot
$excluir = Get-Content (Join-Path $PSScriptRoot "assets_excluir.txt") |
    Where-Object { $_ -and -not $_.StartsWith("#") } | ForEach-Object { $_.Trim().ToLower() }
$ok = 0; $fallan = @(); $excluidos = @(); $nuevos = @()

foreach ($tipo in "css", "js") {
    $listado = (Invoke-WebRequest "$Servidor/$tipo/" -UseBasicParsing -ErrorAction Stop).Content
    $nombres = [regex]::Matches($listado, '(?i)<A HREF="[^"]*/([^"/]+\.' + $tipo + ')">') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

    foreach ($nombre in $nombres) {
        if ($excluir -contains "$tipo/$nombre".ToLower()) { $excluidos += "$tipo/$nombre"; continue }
        $destino = Join-Path $raiz "assets\$tipo\$nombre"
        New-Item -ItemType Directory -Force (Split-Path $destino) | Out-Null
        if (-not (Test-Path $destino)) { $nuevos += "$tipo/$nombre" }
        try {
            # cache-busting: el servidor cachea con el mismo nombre
            $url = "$Servidor/$tipo/$nombre" + "?nocache=" + [DateTime]::Now.Ticks
            Invoke-WebRequest -Uri $url -OutFile $destino -UseBasicParsing -ErrorAction Stop
            $ok++
        } catch {
            $fallan += "$tipo/$nombre"
        }
    }
}

Write-Output "$ok archivos bajados de $Servidor"
if ($nuevos.Count -gt 0)   { Write-Output ("Nuevos (no estaban en el repo): " + ($nuevos -join ", ")) }
if ($excluidos.Count -gt 0) { Write-Output ("Excluidos (terceros/respaldos): " + ($excluidos -join ", ")) }
if ($fallan.Count -gt 0)    { Write-Output ("No se pudieron bajar: " + ($fallan -join ", ")) }
