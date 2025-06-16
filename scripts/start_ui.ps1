#Requires -Version 5.1
<#
.SYNOPSIS
    Startet die MINTutil Streamlit Web-Oberfl?che
.DESCRIPTION
    Startet den Streamlit-Server mit korrekten Einstellungen.
    Pr?ft Ports, Virtual Environment und Dependencies.
    Bietet Optionen f?r Browser-Start und Debug-Modus.
#>

[CmdletBinding()]
param(
    [int]$Port = 8501,
    [switch]$NoBrowser,
    [switch]$Debug,
    [switch]$DockerMode,
    [switch]$Verbose
)

# Strikte Fehlerbehandlung
$ErrorActionPreference = 'Stop'

# Globale Variablen
$script:MintUtilRoot = Split-Path $PSScriptRoot -Parent
$script:StreamlitApp = Join-Path $script:MintUtilRoot "streamlit_app\main.py"
$script:EnvFile = Join-Path $script:MintUtilRoot ".env"
$script:VenvPath = Join-Path $script:MintUtilRoot "venv"
$script:ConfirmScript = Join-Path $PSScriptRoot "confirm.ps1"
$script:LogFile = Join-Path $script:MintUtilRoot "logs\mintutil-cli.log"

# Importiere Hilfsfunktionen
if (Test-Path $script:ConfirmScript) {
    . $script:ConfirmScript
}

# Logging-Funktionen
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    try {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logEntry = "[$timestamp] [$Level] [start_ui] $Message"
        
        # Stelle sicher, dass logs-Verzeichnis existiert
        $logsDir = Split-Path $script:LogFile -Parent
        if (-not (Test-Path $logsDir)) {
            New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
        }
        
        # In Datei schreiben
        $logEntry | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
        
        # Debug-Ausgabe bei Verbose
        if ($Verbose -and $Level -eq 'DEBUG') {
            Write-Host "[DEBUG] $Message" -ForegroundColor DarkGray
        }
    } catch {
        # Fehler beim Logging ignorieren
    }
}

function Test-Port {
    <#
    .SYNOPSIS
        Pr?ft ob ein Port verf?gbar ist
    #>
    param([int]$Port)
    
    Write-Log "Pr?fe Port $Port" -Level DEBUG
    
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        Write-Log "Port $Port ist frei" -Level DEBUG
        return $true
    } catch {
        Write-Log "Port $Port ist belegt: $_" -Level DEBUG
        return $false
    }
}

function Find-FreePort {
    <#
    .SYNOPSIS
        Findet einen freien Port ab Startport
    #>
    param([int]$StartPort = 8501)
    
    Write-Log "Suche freien Port ab $StartPort" -Level INFO
    
    for ($port = $StartPort; $port -le ($StartPort + 10); $port++) {
        if (Test-Port -Port $port) {
            Write-Log "Freier Port gefunden: $port" -Level INFO
            return $port
        }
    }
    
    Write-Log "Kein freier Port gefunden im Bereich $StartPort-$($StartPort + 10)" -Level WARN
    return $null
}

function Test-EnvFile {
    <#
    .SYNOPSIS
        Pr?ft .env Datei auf Vollst?ndigkeit
    #>
    Write-Log "Pr?fe .env Datei" -Level INFO
    
    if (-not (Test-Path $script:EnvFile)) {
        Write-Log ".env Datei fehlt" -Level ERROR
        return $false
    }
    
    $envContent = Get-Content $script:EnvFile -Raw
    $requiredVars = @(
        "APP_NAME",
        "STREAMLIT_SERVER_PORT",
        "LOG_LEVEL"
    )
    
    $missingVars = @()
    foreach ($var in $requiredVars) {
        if ($envContent -notmatch "^$var=") {
            $missingVars += $var
        }
    }
    
    if ($missingVars.Count -gt 0) {
        Write-Log "Fehlende Variablen in .env: $($missingVars -join ', ')" -Level WARN
        Write-Host "   ??  Folgende Variablen fehlen in .env:" -ForegroundColor Yellow
        $missingVars | ForEach-Object { Write-Host "      - $_" -ForegroundColor Yellow }
        return $false
    }
    
    Write-Log ".env Datei ist vollst?ndig" -Level INFO
    return $true
}

function Get-PortFromEnv {
    <#
    .SYNOPSIS
        Liest Port aus .env wenn vorhanden
    #>
    if (Test-Path $script:EnvFile) {
        $envContent = Get-Content $script:EnvFile
        $portLine = $envContent | Where-Object { $_ -match "^STREAMLIT_SERVER_PORT=(\d+)" }
        if ($portLine -and $Matches[1]) {
            $envPort = [int]$Matches[1]
            Write-Log "Port aus .env gelesen: $envPort" -Level INFO
            return $envPort
        }
    }
    return $null
}

function Test-Prerequisites {
    <#
    .SYNOPSIS
        Pr?ft Voraussetzungen f?r Streamlit
    #>
    Write-Host "? Pr?fe Voraussetzungen..." -ForegroundColor Cyan
    Write-Log "Starte Voraussetzungspr?fung" -Level INFO
    
    $issues = @()
    
    # Pr?fe Streamlit App
    if (-not (Test-Path $script:StreamlitApp)) {
        $msg = "Streamlit App nicht gefunden: $script:StreamlitApp"
        $issues += $msg
        Write-Log $msg -Level ERROR
    } else {
        Write-Log "Streamlit App gefunden" -Level INFO
    }
    
    # Pr?fe .env
    if (-not (Test-EnvFile)) {
        $msg = ".env Datei fehlt oder ist unvollst?ndig. F?hren Sie zuerst '.\mint.ps1 init' aus."
        $issues += $msg
        Write-Log $msg -Level ERROR
    }
    
    # Pr?fe Python/Streamlit
    if (-not $DockerMode) {
        # Aktiviere venv wenn vorhanden
        $activateScript = Join-Path $script:VenvPath "Scripts\Activate.ps1"
        if (Test-Path $activateScript) {
            Write-Host "   Aktiviere Virtual Environment..." -ForegroundColor DarkGray
            Write-Log "Aktiviere Virtual Environment" -Level INFO
            & $activateScript
        } else {
            Write-Log "Kein Virtual Environment gefunden" -Level WARN
        }
        
        # Pr?fe Streamlit Installation
        $streamlitVersion = pip show streamlit 2>&1
        if ($LASTEXITCODE -ne 0) {
            $msg = "Streamlit nicht installiert. F?hren Sie 'mint.ps1 init' aus."
            $issues += $msg
            Write-Log $msg -Level ERROR
        } else {
            if ($streamlitVersion -match "Version: ([\d.]+)") {
                Write-Log "Streamlit gefunden: Version $($Matches[1])" -Level INFO
            }
        }
    }
    
    return $issues
}

function Start-StreamlitApp {
    <#
    .SYNOPSIS
        Startet die Streamlit-Anwendung
    #>
    param(
        [int]$Port,
        [bool]$OpenBrowser = $true
    )
    
    Write-Host "`n? Starte Streamlit-Server..." -ForegroundColor Green
    Write-Log "Starte Streamlit auf Port $Port" -Level INFO
    
    # Setze Umgebungsvariablen
    $env:STREAMLIT_SERVER_PORT = $Port
    $env:STREAMLIT_SERVER_ADDRESS = "0.0.0.0"
    $env:STREAMLIT_SERVER_HEADLESS = "true"
    $env:STREAMLIT_BROWSER_GATHER_USAGE_STATS = "false"
    
    if ($Debug) {
        $env:STREAMLIT_LOGGER_LEVEL = "debug"
        Write-Log "Debug-Modus aktiviert" -Level INFO
    }
    
    # Erstelle Streamlit-Kommando
    $streamlitArgs = @(
        "run",
        $script:StreamlitApp,
        "--server.port=$Port",
        "--server.address=0.0.0.0"
    )
    
    if (-not $OpenBrowser) {
        $streamlitArgs += "--server.headless=true"
    }
    
    if ($Debug) {
        $streamlitArgs += "--logger.level=debug"
    }
    
    Write-Host "   Server l?uft auf: http://localhost:$Port" -ForegroundColor Cyan
    Write-Host "   Zum Beenden: Strg+C" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Log "Streamlit-Kommando: streamlit $($streamlitArgs -join ' ')" -Level DEBUG
    
    # Starte Streamlit
    try {
        streamlit @streamlitArgs
        $exitCode = $LASTEXITCODE
        Write-Log "Streamlit beendet mit Exit-Code: $exitCode" -Level INFO
        return $exitCode
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Host "? Fehler beim Start von Streamlit" -ForegroundColor Red
        Write-Log "Fehler beim Start von Streamlit: $errorMsg" -Level ERROR
        throw
    }
}

function Start-DockerMode {
    <#
    .SYNOPSIS
        Startet MINTutil im Docker-Modus
    #>
    Write-Host "`n? Starte im Docker-Modus..." -ForegroundColor Cyan
    Write-Log "Starte Docker-Modus" -Level INFO
    
    # Pr?fe Docker
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        $msg = "Docker ist nicht installiert oder nicht erreichbar"
        Write-Log $msg -Level ERROR
        throw $msg
    }
    
    Write-Log "Docker gefunden: $dockerVersion" -Level INFO
    
    # Pr?fe Docker-Daemon
    $dockerPs = docker ps 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ??  Docker-Daemon l?uft nicht" -ForegroundColor Yellow
        Write-Host "   ? Starten Sie Docker Desktop" -ForegroundColor DarkGray
        Write-Log "Docker-Daemon l?uft nicht" -Level ERROR
        
        if (Get-UserConfirmation "Docker Desktop jetzt starten?") {
            Write-Log "Versuche Docker Desktop zu starten" -Level INFO
            Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
            Write-Host "   Warte auf Docker-Start (30 Sekunden)..." -ForegroundColor Yellow
            Start-Sleep -Seconds 30
            
            # Pr?fe erneut
            $dockerPs = docker ps 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Docker konnte nicht gestartet werden"
            }
        } else {
            throw "Docker-Daemon muss laufen"
        }
    }
    
    # Pr?fe docker-compose
    $composeFile = Join-Path $script:MintUtilRoot "docker-compose.yml"
    if (-not (Test-Path $composeFile)) {
        $msg = "docker-compose.yml nicht gefunden"
        Write-Log $msg -Level ERROR
        throw $msg
    }
    
    Write-Host "   Baue Container..." -ForegroundColor Yellow
    Write-Log "Baue Docker-Container" -Level INFO
    docker-compose build
    
    if ($LASTEXITCODE -ne 0) {
        $msg = "Fehler beim Container-Build"
        Write-Log $msg -Level ERROR
        throw $msg
    }
    
    Write-Host "   Starte Container..." -ForegroundColor Yellow
    Write-Log "Starte Docker-Container" -Level INFO
    docker-compose up
    
    $exitCode = $LASTEXITCODE
    Write-Log "Docker-Container beendet mit Exit-Code: $exitCode" -Level INFO
    return $exitCode
}

function Show-StartupInfo {
    <#
    .SYNOPSIS
        Zeigt Startup-Informationen
    #>
    param([int]$Port)
    
    Write-Host ""
    Write-Host "?" * 50 -ForegroundColor Green
    Write-Host "? MINTutil gestartet!" -ForegroundColor Green
    Write-Host "?" * 50 -ForegroundColor Green
    Write-Host ""
    Write-Host "? Zugriff ?ber:" -ForegroundColor Cyan
    Write-Host "   Local:    http://localhost:$Port"
    Write-Host "   Network:  http://$($env:COMPUTERNAME):$Port"
    Write-Host ""
    Write-Host "? Shortcuts:" -ForegroundColor Yellow
    Write-Host "   Strg+C    Server beenden"
    Write-Host "   F5        Browser neu laden"
    Write-Host ""
    Write-Host "? Log-Datei:" -ForegroundColor DarkGray
    Write-Host "   $script:LogFile"
    Write-Host ""
    
    Write-Log "Startup-Info angezeigt f?r Port $Port" -Level INFO
}

function Get-UserConfirmation {
    param([string]$Message)
    
    if (Test-Path $script:ConfirmScript) {
        return & $script:ConfirmScript -Message $Message
    } else {
        $response = Read-Host "$Message (J/N)"
        return $response -match '^[jJyY]'
    }
}

# Hauptprogramm
$exitCode = 0

try {
    Write-Host "? MINTutil Web-UI Starter" -ForegroundColor Cyan
    Write-Host "?" * 50 -ForegroundColor DarkGray
    Write-Log "=== Start Web-UI gestartet ===" -Level INFO
    
    # Docker-Modus
    if ($DockerMode) {
        $exitCode = Start-DockerMode
        exit $exitCode
    }
    
    # Pr?fe Voraussetzungen
    $issues = Test-Prerequisites
    if ($issues.Count -gt 0) {
        Write-Host "`n? Voraussetzungen nicht erf?llt:" -ForegroundColor Red
        $issues | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
        Write-Log "Start abgebrochen - Voraussetzungen nicht erf?llt" -Level ERROR
        exit 1
    }
    
    # Port aus Parameter oder .env
    if ($Port -eq 8501) {
        $envPort = Get-PortFromEnv
        if ($envPort) {
            $Port = $envPort
            Write-Host "   ?  Verwende Port aus .env: $Port" -ForegroundColor DarkGray
        }
    }
    
    # Pr?fe Port-Verf?gbarkeit
    if (-not (Test-Port -Port $Port)) {
        Write-Host "`n??  Port $Port ist belegt" -ForegroundColor Yellow
        Write-Log "Port $Port ist belegt" -Level WARN
        
        # Finde Prozess auf Port
        try {
            $netstat = netstat -ano | Select-String ":$Port\s.*LISTENING"
            if ($netstat) {
                Write-Host "   ?  Prozess auf Port $Port gefunden" -ForegroundColor DarkGray
                Write-Log "Prozess auf Port $Port: $netstat" -Level DEBUG
            }
        } catch {
            # Netstat fehlgeschlagen, ignorieren
        }
        
        $freePort = Find-FreePort -StartPort $Port
        
        if ($freePort) {
            if (Get-UserConfirmation "Port $freePort verwenden?") {
                $Port = $freePort
                Write-Log "Verwende alternativen Port: $Port" -Level INFO
            } else {
                Write-Host "Abbruch durch Benutzer" -ForegroundColor Red
                Write-Log "Abbruch durch Benutzer" -Level INFO
                exit 0
            }
        } else {
            Write-Host "? Kein freier Port gefunden" -ForegroundColor Red
            Write-Log "Kein freier Port gefunden" -Level ERROR
            exit 1
        }
    }
    
    # Zeige Startup-Info
    Show-StartupInfo -Port $Port
    
    # Starte Streamlit
    $exitCode = Start-StreamlitApp -Port $Port -OpenBrowser (-not $NoBrowser)
    
} catch {
    $errorMsg = $_.Exception.Message
    Write-Host "`n? Fehler beim Start:" -ForegroundColor Red
    Write-Host "   $errorMsg" -ForegroundColor Red
    
    Write-Log "Kritischer Fehler: $errorMsg" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    
    if ($Verbose) {
        Write-Host "`nDetails:" -ForegroundColor DarkGray
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    
    Write-Host "`nLog-Datei: $script:LogFile" -ForegroundColor Yellow
    
    $exitCode = 1
} finally {
    # Cleanup
    Write-Host "`n? MINTutil beendet" -ForegroundColor Cyan
    Write-Log "=== Web-UI beendet (Exit-Code: $exitCode) ===" -Level INFO
}

exit $exitCode
