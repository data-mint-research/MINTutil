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

# Importiere Hilfsfunktionen
if (Test-Path $script:ConfirmScript) {
    . $script:ConfirmScript
}

function Test-Port {
    <#
    .SYNOPSIS
        Pr?ft ob ein Port verf?gbar ist
    #>
    param([int]$Port)
    
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    } catch {
        return $false
    }
}

function Find-FreePort {
    <#
    .SYNOPSIS
        Findet einen freien Port ab Startport
    #>
    param([int]$StartPort = 8501)
    
    for ($port = $StartPort; $port -le ($StartPort + 10); $port++) {
        if (Test-Port -Port $port) {
            return $port
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
    
    $issues = @()
    
    # Pr?fe Streamlit App
    if (-not (Test-Path $script:StreamlitApp)) {
        $issues += "Streamlit App nicht gefunden: $script:StreamlitApp"
    }
    
    # Pr?fe .env
    if (-not (Test-Path $script:EnvFile)) {
        $issues += ".env Datei fehlt. F?hren Sie zuerst 'mint.ps1 init' aus."
    }
    
    # Pr?fe Python/Streamlit
    if (-not $DockerMode) {
        # Aktiviere venv wenn vorhanden
        $activateScript = Join-Path $script:VenvPath "Scripts\Activate.ps1"
        if (Test-Path $activateScript) {
            Write-Host "   Aktiviere Virtual Environment..." -ForegroundColor DarkGray
            & $activateScript
        }
        
        # Pr?fe Streamlit Installation
        $streamlitVersion = pip show streamlit 2>&1
        if ($LASTEXITCODE -ne 0) {
            $issues += "Streamlit nicht installiert. F?hren Sie 'mint.ps1 init' aus."
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
    
    # Setze Umgebungsvariablen
    $env:STREAMLIT_SERVER_PORT = $Port
    $env:STREAMLIT_SERVER_ADDRESS = "0.0.0.0"
    $env:STREAMLIT_SERVER_HEADLESS = "true"
    $env:STREAMLIT_BROWSER_GATHER_USAGE_STATS = "false"
    
    if ($Debug) {
        $env:STREAMLIT_LOGGER_LEVEL = "debug"
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
    
    # Starte Streamlit
    try {
        streamlit @streamlitArgs
    } catch {
        Write-Host "? Fehler beim Start von Streamlit" -ForegroundColor Red
        throw
    }
}

function Start-DockerMode {
    <#
    .SYNOPSIS
        Startet MINTutil im Docker-Modus
    #>
    Write-Host "`n? Starte im Docker-Modus..." -ForegroundColor Cyan
    
    # Pr?fe Docker
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker ist nicht installiert oder nicht erreichbar"
    }
    
    # Pr?fe docker-compose
    $composeFile = Join-Path $script:MintUtilRoot "docker-compose.yml"
    if (-not (Test-Path $composeFile)) {
        throw "docker-compose.yml nicht gefunden"
    }
    
    Write-Host "   Baue Container..." -ForegroundColor Yellow
    docker-compose build
    
    if ($LASTEXITCODE -ne 0) {
        throw "Fehler beim Container-Build"
    }
    
    Write-Host "   Starte Container..." -ForegroundColor Yellow
    docker-compose up
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
try {
    Write-Host "? MINTutil Web-UI Starter" -ForegroundColor Cyan
    Write-Host "?" * 50 -ForegroundColor DarkGray
    
    # Docker-Modus
    if ($DockerMode) {
        Start-DockerMode
        exit 0
    }
    
    # Pr?fe Voraussetzungen
    $issues = Test-Prerequisites
    if ($issues.Count -gt 0) {
        Write-Host "`n? Voraussetzungen nicht erf?llt:" -ForegroundColor Red
        $issues | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
        exit 1
    }
    
    # Pr?fe Port-Verf?gbarkeit
    if (-not (Test-Port -Port $Port)) {
        Write-Host "`n??  Port $Port ist belegt" -ForegroundColor Yellow
        $freePort = Find-FreePort -StartPort $Port
        
        if ($freePort) {
            if (Get-UserConfirmation "Port $freePort verwenden?") {
                $Port = $freePort
            } else {
                Write-Host "Abbruch durch Benutzer" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "? Kein freier Port gefunden" -ForegroundColor Red
            exit 1
        }
    }
    
    # Zeige Startup-Info
    Show-StartupInfo -Port $Port
    
    # Starte Streamlit
    Start-StreamlitApp -Port $Port -OpenBrowser (-not $NoBrowser)
    
} catch {
    Write-Host "`n? Fehler beim Start:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    
    if ($Verbose) {
        Write-Host "`nDetails:" -ForegroundColor DarkGray
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    
    exit 1
} finally {
    # Cleanup
    Write-Host "`n? MINTutil beendet" -ForegroundColor Cyan
}
