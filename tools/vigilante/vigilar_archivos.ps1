# Vigilante de archivos del sitio MAIN (se instala en el SERVIDOR WEB).
# Compara los archivos del sitio contra la ultima foto; si hay altas, cambios o bajas:
#   - guarda una copia de cada version nueva en <Carpeta>\historial\<fecha>\ (no copia .config ni .dll),
#   - llama a dbo.VCT_AUDITORIA_ARCHIVOS_AVISAR en SQL Server, que registra y manda el mail.
# La primera corrida solo toma la foto inicial (no avisa).
# Prueba sin enviar nada:  .\vigilar_archivos.ps1 -Sitio C:\inetpub\vocaturo -SinEnvio
param(
    [Parameter(Mandatory = $true)][string]$Sitio,
    [string]$SqlServidor = "",
    [string]$Base = "MuhlePROD",
    [string]$Carpeta = "$env:ProgramData\VocaturoVigilante",
    [string[]]$Extensiones = @(".js", ".css", ".aspx", ".ashx", ".asmx", ".master", ".config", ".dll", ".html", ".htm"),
    [string[]]$Excluir = @("\Log\", "\Logs\", "\AttachedFiles\", "\Upload", "\Temp\", "\aspnet_client\"),
    [switch]$SinEnvio
)
$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force $Carpeta | Out-Null
$fotoPath = Join-Path $Carpeta "foto.csv"
$logPath  = Join-Path $Carpeta "vigilante.log"
function Escribir-Log([string]$m) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m" | Add-Content -Path $logPath -Encoding UTF8 }

try {
    $raiz = (Resolve-Path $Sitio).Path.TrimEnd("\")

    # foto anterior (ruta -> registro) para no recalcular hashes de lo que no cambio
    $anterior = @{}
    if (Test-Path $fotoPath) {
        foreach ($r in (Import-Csv $fotoPath)) { $anterior[$r.Ruta] = $r }
    }

    $actual = @{}
    foreach ($f in (Get-ChildItem -Path $raiz -Recurse -File -Force -ErrorAction SilentlyContinue)) {
        if ($Extensiones -notcontains $f.Extension.ToLower()) { continue }
        $rel = $f.FullName.Substring($raiz.Length).TrimStart("\")
        # las exclusiones se comparan contra la ruta DENTRO del sitio, no contra la ruta completa
        $excluido = $false
        foreach ($x in $Excluir) { if (("\" + $rel).IndexOf($x, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $excluido = $true; break } }
        if ($excluido) { continue }
        $mod = $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        $prev = $anterior[$rel]
        if ($prev -and $prev.Tamano -eq [string]$f.Length -and $prev.Modificado -eq $mod) {
            $hash = $prev.Hash
        } else {
            $hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash
        }
        $actual[$rel] = [pscustomobject]@{ Ruta = $rel; Tamano = [string]$f.Length; Modificado = $mod; Hash = $hash }
    }

    if (-not (Test-Path $fotoPath)) {
        $actual.Values | Sort-Object Ruta | Export-Csv -Path $fotoPath -NoTypeInformation -Encoding UTF8
        Escribir-Log "Foto inicial: $($actual.Count) archivos de $raiz. No se avisa."
        Write-Output "Foto inicial tomada: $($actual.Count) archivos."
        return
    }

    $cambios = New-Object System.Collections.Generic.List[object]
    foreach ($k in $actual.Keys) {
        $a = $actual[$k]
        if (-not $anterior.ContainsKey($k)) { $cambios.Add([pscustomobject]@{ Accion = "ALTA"; Item = $a }) }
        elseif ($anterior[$k].Hash -ne $a.Hash) { $cambios.Add([pscustomobject]@{ Accion = "CAMBIO"; Item = $a }) }
    }
    foreach ($k in $anterior.Keys) {
        if (-not $actual.ContainsKey($k)) { $cambios.Add([pscustomobject]@{ Accion = "BAJA"; Item = $anterior[$k] }) }
    }

    if ($cambios.Count -eq 0) { return }

    # copia de las versiones nuevas (sin .config ni .dll: pueden tener claves o ser binarios)
    $sello = Get-Date -Format "yyyyMMdd_HHmmss"
    foreach ($c in $cambios) {
        if ($c.Accion -eq "BAJA") { continue }
        $ext = [IO.Path]::GetExtension($c.Item.Ruta).ToLower()
        if ($ext -eq ".config" -or $ext -eq ".dll") { continue }
        $dest = Join-Path (Join-Path $Carpeta "historial\$sello") $c.Item.Ruta
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        Copy-Item -Path (Join-Path $raiz $c.Item.Ruta) -Destination $dest -Force
    }

    $lineas = $cambios | Sort-Object { $_.Item.Ruta } | ForEach-Object {
        "{0}`t{1}`t{2}`t{3}`t{4}" -f $_.Accion, $_.Item.Ruta, $_.Item.Tamano, $_.Item.Modificado, $_.Item.Hash
    }
    $lista = $lineas -join "`n"

    if ($SinEnvio) {
        Write-Output "Cambios detectados (no se envian):"
        Write-Output $lista
    } else {
        if (-not $SqlServidor) { throw "Falta -SqlServidor." }
        $cred = Join-Path $Carpeta "credencial.json"
        if (Test-Path $cred) {
            Add-Type -AssemblyName System.Security
            $j = Get-Content $cred -Raw | ConvertFrom-Json
            $bytes = [Security.Cryptography.ProtectedData]::Unprotect([Convert]::FromBase64String($j.Clave), $null, "LocalMachine")
            $clave = [Text.Encoding]::UTF8.GetString($bytes)
            $cs = "Server=$SqlServidor;Database=$Base;User ID=$($j.Usuario);Password=$clave;Application Name=VigilanteArchivos"
        } else {
            $cs = "Server=$SqlServidor;Database=$Base;Integrated Security=SSPI;Application Name=VigilanteArchivos"
        }
        $cn = New-Object System.Data.SqlClient.SqlConnection $cs
        $cn.Open()
        try {
            $cmd = $cn.CreateCommand()
            $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
            $cmd.CommandText = "dbo.VCT_AUDITORIA_ARCHIVOS_AVISAR"
            [void]$cmd.Parameters.AddWithValue("@SERVIDOR", $env:COMPUTERNAME)
            [void]$cmd.Parameters.AddWithValue("@LISTA", $lista)
            [void]$cmd.ExecuteNonQuery()
        } finally { $cn.Close() }
    }

    # la foto se actualiza solo si se pudo avisar (si fallo, se reintenta en la proxima corrida)
    $actual.Values | Sort-Object Ruta | Export-Csv -Path $fotoPath -NoTypeInformation -Encoding UTF8
    Escribir-Log "$($cambios.Count) cambio(s) $(if ($SinEnvio) { '(sin envio)' } else { 'avisados' }). Copias en historial\$sello"
}
catch {
    Escribir-Log "ERROR: $($_.Exception.Message)"
    throw
}
