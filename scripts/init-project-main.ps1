#Requires -Version 5.1
<#
.SYNOPSIS
    MINTutil Projekt-Initialisierung - Hauptmodul
.DESCRIPTION
    Fuehrt die erstmalige Einrichtung von MINTutil durch:
    - Erstellt notwendige Verzeichnisse
    - Konfiguriert .env Datei
    - Installiert Dependencies
    - Erstellt initiales Glossar
    - Prueft Systemvoraussetzungen
.PARAMETER Force
    Ueberschreibt bestehende Konfiguration
.PARAMETER SkipDependencies
    Ueberspringt die Installation von Python-Dependencies
.PARAMETER Verbose
    Zeigt detaillierte Ausgaben
.EXAMPLE
    .\init-project-main.ps1
    .\init-project-main.ps1 -Force -Verbose
.NOTES
    Autor: MINTutil Team
    Datum: 2024-01-01
    Version: 2.0.0
    Refactored fuer NeoMINT-Compliance (max 500 LOC)
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$SkipDependencies,
    [switch]$Verbose
)

# Strikte Fehlerbehandlung
$ErrorActionPreference = 'Stop'

# Globale Variablen
$script:MintUtilRoot = Split-Path $PSScriptRoot -Parent
$script:EnvFile = Join-Path $script:MintUtilRoot ".env"
$script:EnvExample = Join-Path $script:MintUtilRoot ".env.example"
$script:RequirementsFile = Join-Path $script:MintUtilRoot "requirements.txt"
$script:ConfirmScript = Join-Path $PSScriptRoot "confirm.ps1"
$script:LogFile = Join-Path $script:MintUtilRoot "logs\mintutil-cli.log"
$script:Force = $Force
$script:SkipDependencies = $SkipDependencies
$script:Verbose = $Verbose

# Module laden
$modulePath = $PSScriptRoot
. "$modulePath\init-project-validation.ps1"
. "$modulePath\init-project-setup.ps1"

# Importiere Hilfsfunktionen
if (Test-Path $script:ConfirmScript) {
    . $script:ConfirmScript
}

function Show-Summary {
    <#
    .SYNOPSIS
        Zeigt Zusammenfassung der Initialisierung
    #>
    Write-Host "`n" -NoNewline
    Write-Host "?" * 50 -ForegroundColor Green
    Write-Host "? MINTutil Initialisierung abgeschlossen!" -ForegroundColor Green
    Write-Host "?" * 50 -ForegroundColor Green
    
    Write-Host "`nNaechste Schritte:" -ForegroundColor Yellow
    Write-Host "1. Passen Sie die .env Datei an Ihre Beduerfnisse an"
    Write-Host "2. Starten Sie MINTutil mit: .\mint.ps1 start"
    Write-Host "3. Oeffnen Sie http://localhost:8501 im Browser"
    
    Write-Host "`nWeitere Kommandos:" -ForegroundColor Cyan
    Write-Host "   .\mint.ps1 doctor    - System-Diagnose"
    Write-Host "   .\mint.ps1 update    - Updates installieren"
    Write-Host "   .\mint.ps1 help      - Hilfe anzeigen"
    
    Write-Host "`nLog-Datei:" -ForegroundColor DarkGray
    Write-Host "   $script:LogFile"
    
    Write-Log "Initialisierung erfolgreich abgeschlossen" -Level INFO
}

function Start-ProjectInitialization {
    <#
    .SYNOPSIS
        Hauptfunktion fuer die Projekt-Initialisierung
    #>
    Write-Host "? Starte MINTutil Initialisierung..." -ForegroundColor Cyan
    Write-Host "?" * 50 -ForegroundColor DarkGray
    Write-Log "=== Starte Initialisierung ===" -Level INFO
    
    # Pruefe Systemvoraussetzungen
    $failedReqs = Test-SystemRequirements
    if ($failedReqs.Count -gt 0) {
        Write-Host "`n? Fehlende Voraussetzungen:" -ForegroundColor Red
        $failedReqs | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
        Write-Host "`nBitte installieren Sie die fehlenden Komponenten." -ForegroundColor Yellow
        Write-Log "Initialisierung abgebrochen - fehlende Voraussetzungen: $($failedReqs -join ', ')" -Level ERROR
        return 1
    }
    
    # Pruefe Umgebungsintegritaet
    $integrityIssues = Test-EnvironmentIntegrity
    if ($integrityIssues.Count -gt 0) {
        Write-Host "`n? Integritaetsprobleme gefunden:" -ForegroundColor Yellow
        $integrityIssues | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
        if (-not (Get-UserConfirmation "Trotzdem fortfahren?")) {
            Write-Log "Initialisierung vom Benutzer abgebrochen" -Level INFO
            return 2
        }
    }
    
    # Fuehre Initialisierung durch
    Initialize-Directories
    Initialize-EnvFile
    Install-Dependencies
    Initialize-Glossary
    
    # Zeige Zusammenfassung
    Show-Summary
    
    return 0
}

# Hauptprogramm
$exitCode = 0

try {
    $exitCode = Start-ProjectInitialization
} catch {
    $errorMsg = $_.Exception.Message
    Write-Host "`n? Fehler waehrend der Initialisierung:" -ForegroundColor Red
    Write-Host "   $errorMsg" -ForegroundColor Red
    Write-Host "`nDetails: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
    
    Write-Log "Kritischer Fehler: $errorMsg" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    
    $exitCode = 1
} finally {
    Write-Log "=== Initialisierung beendet (Exit-Code: $exitCode) ===" -Level INFO
}

exit $exitCode
