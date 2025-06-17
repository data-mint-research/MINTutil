#Requires -Version 5.1
<#
.SYNOPSIS
    MINTutil Projekt-Initialisierung (Wrapper)
.DESCRIPTION
    Dies ist ein Wrapper-Skript, das die modularisierte Version
    der Initialisierung aufruft (NeoMINT-konform).
.PARAMETER Force
    Ueberschreibt bestehende Konfiguration
.PARAMETER SkipDependencies
    Ueberspringt die Installation von Python-Dependencies
.PARAMETER Verbose
    Zeigt detaillierte Ausgaben
.EXAMPLE
    .\init_project.ps1
    .\init_project.ps1 -Force -Verbose
.NOTES
    Autor: MINTutil Team
    Datum: 2024-01-01
    Version: 2.0.0
    Wrapper fuer init-project-main.ps1 (NeoMINT-Compliance)
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$SkipDependencies,
    [switch]$Verbose
)

# Leite zur neuen modularen Version weiter
$mainScript = Join-Path $PSScriptRoot "init-project-main.ps1"

if (Test-Path $mainScript) {
    # Fuehre die neue Version aus
    & $mainScript @PSBoundParameters
    exit $LASTEXITCODE
} else {
    Write-Error "Hauptmodul nicht gefunden: $mainScript"
    Write-Host "Bitte stellen Sie sicher, dass alle Module vorhanden sind:" -ForegroundColor Yellow
    Write-Host "  - init-project-main.ps1" -ForegroundColor Yellow
    Write-Host "  - init-project-validation.ps1" -ForegroundColor Yellow
    Write-Host "  - init-project-setup.ps1" -ForegroundColor Yellow
    exit 1
}
