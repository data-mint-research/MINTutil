#Requires -Version 5.1
<#
.SYNOPSIS
    MINTutil CLI - Zentrale Steuerungskonsole f?r modulare Infrastruktur-Tools
.DESCRIPTION
    Haupteinstiegspunkt f?r MINTutil. Bietet Subkommandos f?r Initialisierung,
    Start, Update und Systemdiagnose. Unterst?tzt One-Click-Installation.
.PARAMETER Command
    Verf?gbare Kommandos: install, init, start, stop, update, doctor, help
.PARAMETER Args
    Zus?tzliche Argumente f?r das gew?hlte Kommando
.EXAMPLE
    .\mint.ps1 install    # One-Click-Installation
    .\mint.ps1 start      # MINTutil starten
    .\mint.ps1 doctor     # System-Check
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('install', 'init', 'start', 'stop', 'update', 'doctor', 'help', '')]
    [string]$Command = '',
    
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Args = @()
)

# Setze strikte Fehlerbehandlung
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# Globale Variablen
$script:MintUtilRoot = $PSScriptRoot
$script:ScriptsPath = Join-Path $MintUtilRoot "scripts"
$script:LogsPath = Join-Path $MintUtilRoot "logs"
$script:LogFile = Join-Path $script:LogsPath "mintutil-cli.log"
$script:Version = "0.1.0"

# Logging-Funktionen
function Initialize-Logging {
    <#
    .SYNOPSIS
        Initialisiert das Logging-System
    #>
    try {
        if (-not (Test-Path $script:LogsPath)) {
            New-Item -ItemType Directory -Path $script:LogsPath -Force | Out-Null
        }
        
        # Session-Start im Log markieren
        $sessionStart = "`n" + "=" * 80 + "`n"
        $sessionStart += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [INFO] === MINTutil Session Start ===`n"
        $sessionStart += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [INFO] Version: $script:Version`n"
        $sessionStart += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [INFO] Command: $Command $($Args -join ' ')`n"
        $sessionStart += "=" * 80
        
        $sessionStart | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
    } catch {
        Write-Warning "Logging konnte nicht initialisiert werden: $_"
    }
}

function Write-Log {
    <#
    .SYNOPSIS
        Schreibt eine Nachricht ins Log
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    try {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logEntry = "[$timestamp] [$Level] $Message"
        
        # In Datei schreiben
        if (Test-Path $script:LogFile) {
            $logEntry | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
        }
        
        # Konsolen-Ausgabe mit Farbe
        switch ($Level) {
            'ERROR' { Write-Host $Message -ForegroundColor Red }
            'WARN'  { Write-Host $Message -ForegroundColor Yellow }
            'DEBUG' { if ($VerbosePreference -eq 'Continue') { Write-Host $Message -ForegroundColor DarkGray } }
            default { Write-Verbose $Message }
        }
    } catch {
        # Fehler beim Logging ignorieren, um Hauptprogramm nicht zu st?ren
    }
}

function Write-MintHeader {
    <#
    .SYNOPSIS
        Zeigt den MINTutil ASCII-Header
    #>
    Write-Host ""
    Write-Host "  __  __ ___ _   _ _____ _   _ _   _ _ " -ForegroundColor Cyan
    Write-Host " |  \/  |_ _| \ | |_   _| | | | |_(_) |" -ForegroundColor Cyan
    Write-Host " | |\/| || ||  \| | | | | | | | __| | |" -ForegroundColor Cyan
    Write-Host " | |  | || || |\  | | | | |_| | |_| | |" -ForegroundColor Cyan
    Write-Host " |_|  |_|___|_| \_| |_|  \___/ \__|_|_|" -ForegroundColor Cyan
    Write-Host "" 
    Write-Host " Modular Infrastructure and Network Tools v$script:Version" -ForegroundColor DarkGray
    Write-Host " ========================================" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Log "MINTutil gestartet - v$script:Version" -Level INFO
}

function Test-Prerequisites {
    <#
    .SYNOPSIS
        Pr?ft minimale Voraussetzungen f?r MINTutil
    #>
    Write-Log "Pr?fe Systemvoraussetzungen..." -Level INFO
    $issues = @()
    
    # PowerShell Version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $msg = "PowerShell 5.1 oder h?her wird ben?tigt (aktuell: $($PSVersionTable.PSVersion))"
        $issues += $msg
        Write-Log $msg -Level ERROR
    } else {
        Write-Log "PowerShell Version OK: $($PSVersionTable.PSVersion)" -Level INFO
    }
    
    # Scripts-Verzeichnis
    if (-not (Test-Path $script:ScriptsPath)) {
        $msg = "Scripts-Verzeichnis fehlt: $script:ScriptsPath"
        $issues += $msg
        Write-Log $msg -Level ERROR
    } else {
        Write-Log "Scripts-Verzeichnis vorhanden" -Level INFO
    }
    
    return $issues
}

function Invoke-MintCommand {
    <#
    .SYNOPSIS
        F?hrt das gew?hlte Kommando aus
    #>
    param(
        [string]$Command,
        [string[]]$Arguments
    )
    
    Write-Log "F?hre Kommando aus: $Command" -Level INFO
    
    $exitCode = 0
    
    switch ($Command) {
        'install' {
            # One-Click-Installation
            Write-Host "? Starte One-Click-Installation..." -ForegroundColor Green
            Write-Host ""
            
            # Pr?fe ob bereits installiert
            if (Test-Path "$script:MintUtilRoot\venv") {
                Write-Host "? MINTutil ist bereits installiert!" -ForegroundColor Green
                Write-Host "   Verwenden Sie 'mint start' zum Starten." -ForegroundColor DarkGray
                $exitCode = 0
            } else {
                # F?hre Setup aus
                $setupScript = Join-Path $script:ScriptsPath "setup_windows.ps1"
                if (Test-Path $setupScript) {
                    & $setupScript -InstallPath $script:MintUtilRoot @Arguments
                    $exitCode = $LASTEXITCODE
                } else {
                    Write-Error "Setup-Script nicht gefunden. Bitte laden Sie MINTutil erneut herunter."
                    $exitCode = 1
                }
            }
        }
        
        'init' {
            $scriptPath = Join-Path $script:ScriptsPath "init_project.ps1"
            if (Test-Path $scriptPath) {
                Write-Log "Starte Initialisierung..." -Level INFO
                & $scriptPath @Arguments
                $exitCode = $LASTEXITCODE
            } else {
                Write-Log "Initialisierungsskript nicht gefunden: $scriptPath" -Level ERROR
                Write-Error "Initialisierungsskript nicht gefunden: $scriptPath"
                $exitCode = 1
            }
        }
        
        'start' {
            # Pr?fe ob Installation vollst?ndig
            if (-not (Test-Path "$script:MintUtilRoot\venv")) {
                Write-Host "??  MINTutil ist noch nicht installiert!" -ForegroundColor Yellow
                Write-Host "   F?hren Sie zuerst 'mint install' aus." -ForegroundColor DarkGray
                $exitCode = 1
            } else {
                $scriptPath = Join-Path $script:ScriptsPath "start_ui.ps1"
                if (Test-Path $scriptPath) {
                    Write-Log "Starte Web-UI..." -Level INFO
                    & $scriptPath @Arguments
                    $exitCode = $LASTEXITCODE
                } else {
                    Write-Log "Start-Skript nicht gefunden: $scriptPath" -Level ERROR
                    Write-Error "Start-Skript nicht gefunden: $scriptPath"
                    $exitCode = 1
                }
            }
        }
        
        'stop' {
            Write-Host "? Stoppe MINTutil..." -ForegroundColor Yellow
            # Finde Streamlit-Prozesse
            $processes = Get-Process | Where-Object { $_.ProcessName -like "*streamlit*" -or $_.CommandLine -like "*streamlit*" }
            if ($processes) {
                $processes | Stop-Process -Force
                Write-Host "? MINTutil wurde gestoppt." -ForegroundColor Green
            } else {
                Write-Host "??  MINTutil l?uft nicht." -ForegroundColor DarkGray
            }
            $exitCode = 0
        }
        
        'update' {
            $scriptPath = Join-Path $script:ScriptsPath "update.ps1"
            if (Test-Path $scriptPath) {
                Write-Log "Starte Update-Prozess..." -Level INFO
                & $scriptPath @Arguments
                $exitCode = $LASTEXITCODE
            } else {
                Write-Log "Update-Skript nicht gefunden: $scriptPath" -Level ERROR
                Write-Error "Update-Skript nicht gefunden: $scriptPath"
                $exitCode = 1
            }
        }
        
        'doctor' {
            $scriptPath = Join-Path $script:ScriptsPath "health_check.ps1"
            if (Test-Path $scriptPath) {
                Write-Log "Starte System-Diagnose..." -Level INFO
                & $scriptPath @Arguments
                $exitCode = $LASTEXITCODE
            } else {
                Write-Log "Diagnose-Skript nicht gefunden: $scriptPath" -Level ERROR
                Write-Error "Diagnose-Skript nicht gefunden: $scriptPath"
                $exitCode = 1
            }
        }
        
        'help' {
            Show-Help
            $exitCode = 0
        }
        
        default {
            Show-Help
            $exitCode = 0
        }
    }
    
    return $exitCode
}

function Show-Help {
    <#
    .SYNOPSIS
        Zeigt die Hilfe f?r MINTutil
    #>
    Write-Host "Verwendung: .\mint.ps1 <command> [args]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Verf?gbare Kommandos:" -ForegroundColor Green
    Write-Host "  install   ? One-Click-Installation (empfohlen f?r neue Nutzer)"
    Write-Host "  start     ??  Startet die MINTutil Web-Oberfl?che"
    Write-Host "  stop      ??  Stoppt MINTutil"
    Write-Host "  doctor    ? F?hrt Systemdiagnose durch"
    Write-Host "  update    ? Aktualisiert MINTutil-Komponenten"
    Write-Host "  init      ? Initialisiert Projekt (f?r Entwickler)"
    Write-Host "  help      ? Zeigt diese Hilfe"
    Write-Host ""
    Write-Host "Beispiele:" -ForegroundColor Green
    Write-Host "  .\mint.ps1 install       # Installiert MINTutil komplett"
    Write-Host "  .\mint.ps1 start         # Startet Web-UI"
    Write-Host "  .\mint.ps1 doctor        # Pr?ft Systemstatus"
    Write-Host ""
    Write-Host "Quick Start:" -ForegroundColor Cyan
    Write-Host "  Neu hier? F?hren Sie einfach aus: .\mint.ps1 install"
    Write-Host ""
    Write-Host "Weitere Informationen:" -ForegroundColor Blue
    Write-Host "  GitHub: https://github.com/data-mint-research/MINTutil"
    Write-Host "  Docs:   https://github.com/data-mint-research/MINTutil/wiki"
    Write-Host "  Logs:   $script:LogFile"
    
    Write-Log "Hilfe angezeigt" -Level INFO
}

# Hauptprogramm
$exitCode = 0

try {
    # Initialisiere Logging
    Initialize-Logging
    
    # Zeige Header
    Write-MintHeader
    
    # Pr?fe Voraussetzungen
    $prerequisites = Test-Prerequisites
    if ($prerequisites.Count -gt 0) {
        Write-Host "??  Voraussetzungen nicht erf?llt:" -ForegroundColor Red
        $prerequisites | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
        Write-Log "Voraussetzungen nicht erf?llt. Beende mit Fehler." -Level ERROR
        exit 1
    }
    
    # F?hre Kommando aus
    if ([string]::IsNullOrWhiteSpace($Command)) {
        Show-Help
        $exitCode = 0
    } else {
        Write-Host "? F?hre aus: $Command" -ForegroundColor Green
        Write-Host ""
        $exitCode = Invoke-MintCommand -Command $Command -Arguments $Args
    }
    
    Write-Log "Kommando abgeschlossen mit Exit-Code: $exitCode" -Level INFO
    
} catch {
    $errorMsg = $_.Exception.Message
    Write-Host ""
    Write-Host "? Fehler aufgetreten:" -ForegroundColor Red
    Write-Host "   $errorMsg" -ForegroundColor Red
    Write-Host ""
    Write-Host "F?r Details: .\mint.ps1 doctor" -ForegroundColor Yellow
    Write-Host "Log-Datei: $script:LogFile" -ForegroundColor Yellow
    
    Write-Log "Kritischer Fehler: $errorMsg" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    
    $exitCode = 1
} finally {
    # Session-Ende markieren
    Write-Log "=== MINTutil Session Ende (Exit-Code: $exitCode) ===" -Level INFO
}

# Beende mit korrektem Exit-Code
exit $exitCode
