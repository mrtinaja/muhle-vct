# Instala el vigilante en el SERVIDOR WEB (correr en PowerShell como Administrador).
# 1) Guarda la credencial del login VIGILANTE_ARCHIVOS cifrada para esta maquina
#    (la clave la escribe quien instala; no queda en texto plano). Omitir con -SinCredencial
#    si SQL Server acepta la cuenta de Windows de la tarea.
# 2) Copia vigilar_archivos.ps1 a C:\ProgramData\VocaturoVigilante y toma la foto inicial.
# 3) Crea la tarea programada "Vocaturo - Vigilante de archivos" cada 10 minutos (cuenta SYSTEM).
# Uso: .\instalar_vigilante.ps1 -Sitio "C:\inetpub\vocaturo" -SqlServidor "192.168.x.x"
param(
    [Parameter(Mandatory = $true)][string]$Sitio,
    [Parameter(Mandatory = $true)][string]$SqlServidor,
    [string]$Base = "MuhlePROD",
    [int]$Minutos = 10,
    [switch]$SinCredencial
)
$ErrorActionPreference = "Stop"
$carpeta = "$env:ProgramData\VocaturoVigilante"
New-Item -ItemType Directory -Force $carpeta | Out-Null

# solo Administradores y SYSTEM pueden leer la carpeta (tiene la credencial y la historia)
icacls $carpeta /inheritance:r /grant:r "Administrators:(OI)(CI)F" "SYSTEM:(OI)(CI)F" | Out-Null

if (-not $SinCredencial) {
    Add-Type -AssemblyName System.Security
    $usuario = Read-Host "Login SQL del vigilante [VIGILANTE_ARCHIVOS]"
    if (-not $usuario) { $usuario = "VIGILANTE_ARCHIVOS" }
    $seg = Read-Host "Clave de $usuario" -AsSecureString
    $plano = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($seg))
    $cif = [Security.Cryptography.ProtectedData]::Protect([Text.Encoding]::UTF8.GetBytes($plano), $null, "LocalMachine")
    @{ Usuario = $usuario; Clave = [Convert]::ToBase64String($cif) } | ConvertTo-Json | Set-Content (Join-Path $carpeta "credencial.json") -Encoding UTF8
    $plano = $null
    Write-Output "Credencial guardada cifrada en $carpeta\credencial.json"
}

Copy-Item -Path (Join-Path $PSScriptRoot "vigilar_archivos.ps1") -Destination $carpeta -Force
$script = Join-Path $carpeta "vigilar_archivos.ps1"

& $script -Sitio $Sitio -SqlServidor $SqlServidor -Base $Base

$args = "-NoProfile -ExecutionPolicy Bypass -File `"$script`" -Sitio `"$Sitio`" -SqlServidor `"$SqlServidor`" -Base `"$Base`""
$accion = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $args
$disparo = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $Minutos) -RepetitionDuration (New-TimeSpan -Days 3650)
$quien = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "Vocaturo - Vigilante de archivos" -Action $accion -Trigger $disparo -Principal $quien -Force | Out-Null
Write-Output "Tarea programada creada: cada $Minutos minutos. Log: $carpeta\vigilante.log"
