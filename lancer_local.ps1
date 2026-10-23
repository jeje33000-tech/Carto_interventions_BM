# lancer_local.ps1 - PowerShell alternative to lancer_local.bat
# Run with:  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\lancer_local.ps1

$ErrorActionPreference = 'Continue'

# Set working directory to the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $ScriptDir

Write-Host ''
Write-Host '============================================================'
Write-Host '  Lanceur local - Interventions sur les arbres (PowerShell)'
Write-Host '============================================================'
Write-Host ("Repertoire : " + (Get-Location).Path)
Write-Host ''

# Pick Python
$python = $null
foreach ($c in @('py','python','python3')) {
    $w = Get-Command $c -ErrorAction SilentlyContinue
    if ($w) { $python = $c; break }
}
if (-not $python) {
    Write-Host ''
    Write-Host 'ERREUR : aucun interpreteur Python trouve.'
    Write-Host '         Installez Python 3 ou ajoutez-le au PATH.'
    Write-Host ''
    Read-Host 'Appuyez sur Entree pour quitter'
    exit 1
}
Write-Host ("Python detecte : " + $python)

# Pick a free port starting at 8000
function Test-PortBusy([int]$Port) {
    try {
        $c = New-Object Net.Sockets.TcpClient
        $c.Connect('127.0.0.1', $Port)
        $c.Close()
        return $true
    } catch {
        return $false
    }
}
$port = 8000
while ((Test-PortBusy $port) -and ($port -lt 8100)) { $port++ }
if ($port -ge 8100) {
    Write-Host ''
    Write-Host 'ERREUR : aucun port libre entre 8000 et 8099.'
    Write-Host ''
    Read-Host 'Appuyez sur Entree pour quitter'
    exit 1
}
Write-Host ("Port choisi : " + $port)

# Start the HTTP server in a new window
$logPath = Join-Path $env:TEMP ("lancer_local_server_" + $port + ".log")
Write-Host ("Demarrage du serveur (log : " + $logPath + ")")
$serverCmd = "Set-Location -LiteralPath '" + (Get-Location).Path + "'; & {" + $python + " -m http.server " + $port + " --bind 127.0.0.1 2>&1 | Tee-Object -FilePath '" + $logPath + "'}; Read-Host 'Appuyez sur Entree pour fermer'"
Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-Command', $serverCmd) -WindowStyle Normal

# Wait until the server responds (max 30 s)
Write-Host 'Attente du serveur (max 30 s) ...'
$ok = $false
for ($i=0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 500
    if (Test-PortBusy $port) { $ok = $true; break }
}
if (-not $ok) {
    Write-Host ''
    Write-Host 'ERREUR : le serveur n''a pas repondu apres 30 s.'
    if (Test-Path $logPath) { Get-Content $logPath | Write-Host }
    Write-Host ''
    Read-Host 'Appuyez sur Entree pour quitter'
    exit 1
}

$url = "http://localhost:$port/"
Write-Host ("Ouverture du navigateur sur " + $url)
Start-Process $url

Write-Host ''
Write-Host 'Le serveur tourne en arriere-plan dans une autre fenetre.'
Write-Host 'Pour arreter : fermez la fenetre du serveur.'
Write-Host ''
Read-Host 'Appuyez sur Entree pour fermer cette fenetre'
exit 0
