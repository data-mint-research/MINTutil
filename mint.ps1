#Requires -Version 5.1
<#
.SYNOPSIS
    MINTutil CLI - Zentrale Steuerungskonsole f?r modulare Infrastruktur-Tools
.DESCRIPTION
    Haupteinstiegspunkt f?r MINTutil. Bietet Subkommandos f?r Initialisierung,
    Start, Update und Systemdiagnose. Alle Benutzerinteraktionen erfolgen
    ?ber klare Dialoge ohne implizite Annahmen.
.PARAMETER Command
    Verf?gbare Kommandos: init, start, update, doctor, help
.PARAMETER Args
    Zus?tzliche Argumente f?r das gew?hlte Kommando
.EXAMPLE
    .\mint.ps1 init
    .\mint.ps1 start
    .\mint.ps1 doctor -verbose
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('init', 'start', 'update', 'doctor', 'help', '')]
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
$script:Version = "0.1.0"

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
}

function Test-Prerequisites {
    <#
    .SYNOPSIS
        Pr?ft minimale Voraussetzungen f?r MINTutil
    #>
    $issues = @()
    
    # PowerShell Version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $issues += "PowerShell 5.1 oder h?her wird ben?tigt (aktuell: $($PSVersionTable.PSVersion))"
    }
    
    # Scripts-Verzeichnis
    if (-not (Test-Path $script:ScriptsPath)) {
        $issues += "Scripts-Verzeichnis fehlt: $script:ScriptsPath"
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
    
    switch ($Command) {
        'init' {
            $scriptPath = Join-Path $script:ScriptsPath "init_project.ps1"
            if (Test-Path $scriptPath) {
                & $scriptPath @Arguments
            } else {
                Write-Error "Initialisierungsskript nicht gefunden: $scriptPath"
            }
        }
        
        'start' {
            $scriptPath = Join-Path $script:ScriptsPath "start_ui.ps1"
            if (Test-Path $scriptPath) {
                & $scriptPath @Arguments
            } else {
                Write-Error "Start-Skript nicht gefunden: $scriptPath"
            }
        }
        
        'update' {
            $scriptPath = Join-Path $script:ScriptsPath "update.ps1"
            if (Test-Path $scriptPath) {
                & $scriptPath @Arguments
            } else {
                Write-Error "Update-Skript nicht gefunden: $scriptPath"
            }
        }
        
        'doctor' {
            $scriptPath = Join-Path $script:ScriptsPath "health_check.ps1"
            if (Test-Path $scriptPath) {
                & $scriptPath @Arguments
            } else {
                Write-Error "Diagnose-Skript nicht gefunden: $scriptPath"
            }
        }
        
        'help' {
            Show-Help
        }
        
        default {
            Show-Help
        }
    }
}

function Show-Help {
    <#
    .SYNOPSIS
        Zeigt die Hilfe f?r MINTutil
    #>
    Write-Host "Verwendung: .\mint.ps1 <command> [args]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Verf?gbare Kommandos:" -ForegroundColor Green
    Write-Host "  init      Initialisiert MINTutil (erstmalige Einrichtung)"
    Write-Host "  start     Startet die MINTutil Web-Oberfl?che"
    Write-Host "  update    Aktualisiert MINTutil-Komponenten"
    Write-Host "  doctor    F?hrt Systemdiagnose durch"
    Write-Host "  help      Zeigt diese Hilfe"
    Write-Host ""
    Write-Host "Beispiele:" -ForegroundColor Green
    Write-Host "  .\mint.ps1 init          # Erstmalige Einrichtung"
    Write-Host "  .\mint.ps1 start         # Startet Web-UI"
    Write-Host "  .\mint.ps1 doctor        # Pr?ft Systemstatus"
    Write-Host "  .\mint.ps1 update        # Aktualisiert Komponenten"
    Write-Host ""
    Write-Host "Weitere Informationen:" -ForegroundColor Blue
    Write-Host "  GitHub: https://github.com/data-mint-research/MINTutil"
    Write-Host "  Docs:   https://github.com/data-mint-research/MINTutil/docs"
}

# Hauptprogramm
try {
    # Zeige Header
    Write-MintHeader
    
    # Pr?fe Voraussetzungen
    $prerequisites = Test-Prerequisites
    if ($prerequisites.Count -gt 0) {
        Write-Host "??  Voraussetzungen nicht erf?llt:" -ForegroundColor Red
        $prerequisites | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
        exit 1
    }
    
    # F?hre Kommando aus
    if ([string]::IsNullOrWhiteSpace($Command)) {
        Show-Help
    } else {
        Write-Host "? F?hre aus: $Command" -ForegroundColor Green
        Write-Host ""
        Invoke-MintCommand -Command $Command -Arguments $Args
    }
    
} catch {
    Write-Host ""
    Write-Host "? Fehler aufgetreten:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "F?r Details: .\mint.ps1 doctor" -ForegroundColor Yellow
    exit 1
}
