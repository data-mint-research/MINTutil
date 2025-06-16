#Requires -Version 5.1
<#
.SYNOPSIS
    NeoMINT Compliance Checker - Prueft die Einhaltung der NeoMINT Coding Practices
.DESCRIPTION
    Dieses Skript ueberprueft automatisch alle PowerShell- und Python-Dateien
    im MINTutil-Projekt auf Einhaltung der NeoMINT Standards.
.EXAMPLE
    .\check-neomint-compliance.ps1
    .\check-neomint-compliance.ps1 -Verbose
.NOTES
    Autor: MINTutil Team
    Datum: 2025-06-16
    Version: 1.0.0
#>

[CmdletBinding()]
param()

# Globale Variablen
$script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$script:Issues = @()
$script:Warnings = @()

function Write-ComplianceLog {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    switch ($Level) {
        'ERROR'   { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        'WARN'    { Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
        'SUCCESS' { Write-Host "[OK]    $Message" -ForegroundColor Green }
        default   { Write-Host "[INFO]  $Message" -ForegroundColor Gray }
    }
}

function Test-FileLength {
    <#
    .SYNOPSIS
        Prueft ob Dateien die 500 LOC Grenze einhalten
    #>
    param([string]$Path)
    
    $lines = (Get-Content $Path | Measure-Object -Line).Lines
    if ($lines -gt 500) {
        $script:Issues += "Datei ueberschreitet 500 LOC: $Path ($lines Zeilen)"
        return $false
    }
    return $true
}

function Test-Encoding {
    <#
    .SYNOPSIS
        Prueft ob Dateien keine Umlaute enthalten
    #>
    param([string]$Path)
    
    $content = Get-Content $Path -Raw
    if ($content -match '[???????]') {
        $script:Issues += "Datei enthaelt Umlaute: $Path"
        return $false
    }
    return $true
}

function Test-FunctionNaming {
    <#
    .SYNOPSIS
        Prueft PowerShell Funktionsnamen auf PascalCase
    #>
    param([string]$Path)
    
    if ($Path -notlike "*.ps1") { return $true }
    
    $content = Get-Content $Path -Raw
    $functions = [regex]::Matches($content, 'function\s+([a-zA-Z0-9-_]+)')
    
    foreach ($match in $functions) {
        $funcName = $match.Groups[1].Value
        if ($funcName -notmatch '^[A-Z][a-zA-Z0-9]*(-[A-Z][a-zA-Z0-9]*)*$') {
            $script:Issues += "Funktion nicht in PascalCase: $funcName in $Path"
            return $false
        }
    }
    return $true
}

function Test-FileNaming {
    <#
    .SYNOPSIS
        Prueft Dateinamen auf kebab-case
    #>
    param([string]$Path)
    
    $fileName = Split-Path -Leaf $Path
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    
    # Ausnahmen
    if ($fileName -in @('README.md', 'LICENSE', 'Dockerfile', '.gitignore', '.gitkeep')) {
        return $true
    }
    
    if ($baseName -notmatch '^[a-z]+(-[a-z]+)*$') {
        $script:Warnings += "Dateiname nicht in kebab-case: $fileName"
        return $true  # Nur Warnung, kein Fehler
    }
    return $true
}

function Test-Header {
    <#
    .SYNOPSIS
        Prueft ob PS1-Dateien einen vollstaendigen Header haben
    #>
    param([string]$Path)
    
    if ($Path -notlike "*.ps1") { return $true }
    
    $content = Get-Content $Path -Raw
    if ($content -notmatch '\.NOTES[\s\S]*?Autor:[\s\S]*?Datum:') {
        $script:Warnings += "Unvollstaendiger Header in: $Path"
    }
    return $true
}

function Test-LoggingUsage {
    <#
    .SYNOPSIS
        Prueft ob Write-Log verwendet wird
    #>
    param([string]$Path)
    
    if ($Path -notlike "*.ps1") { return $true }
    
    $content = Get-Content $Path -Raw
    
    # Wenn die Datei Logging macht, sollte sie Write-Log verwenden
    if ($content -match 'Write-(Host|Output|Verbose|Warning|Error)' -and 
        $content -notmatch 'Write-Log' -and
        $Path -notlike "*check-neomint-compliance*") {
        $script:Warnings += "Datei verwendet nicht Write-Log: $Path"
    }
    return $true
}

function Test-GitIgnore {
    <#
    .SYNOPSIS
        Prueft ob .gitignore wichtige Eintraege enthaelt
    #>
    
    $gitignorePath = Join-Path $script:ProjectRoot ".gitignore"
    if (-not (Test-Path $gitignorePath)) {
        $script:Issues += ".gitignore fehlt!"
        return $false
    }
    
    $content = Get-Content $gitignorePath -Raw
    $requiredEntries = @('.env', 'venv/', '__pycache__/', '*.log', '.vscode/')
    
    foreach ($entry in $requiredEntries) {
        if ($content -notmatch [regex]::Escape($entry)) {
            $script:Warnings += ".gitignore fehlt Eintrag: $entry"
        }
    }
    return $true
}

function Test-Documentation {
    <#
    .SYNOPSIS
        Prueft ob wichtige Dokumentation vorhanden ist
    #>
    
    $requiredDocs = @(
        'docs/abweichungen.md',
        'docs/neomint-coding-practices.md'
    )
    
    foreach ($doc in $requiredDocs) {
        $docPath = Join-Path $script:ProjectRoot $doc
        if (-not (Test-Path $docPath)) {
            $script:Issues += "Erforderliche Dokumentation fehlt: $doc"
        }
    }
    return $true
}

# Hauptprogramm
Write-Host ""
Write-Host "=== NeoMINT Compliance Check ===" -ForegroundColor Cyan
Write-Host ""

# Sammle alle zu pruefenden Dateien
$psFiles = Get-ChildItem -Path $script:ProjectRoot -Filter "*.ps1" -Recurse -File | Where-Object { $_.FullName -notmatch 'venv|\.git|node_modules' }
$pyFiles = Get-ChildItem -Path $script:ProjectRoot -Filter "*.py" -Recurse -File | Where-Object { $_.FullName -notmatch 'venv|\.git|node_modules' }
$allFiles = $psFiles + $pyFiles

Write-ComplianceLog "Pruefe $($allFiles.Count) Dateien..." -Level INFO

# Pruefe jede Datei
foreach ($file in $allFiles) {
    $relativePath = $file.FullName.Replace($script:ProjectRoot, '').TrimStart('\', '/')
    Write-Verbose "Pruefe: $relativePath"
    
    # Alle Tests durchfuehren
    $tests = @(
        (Test-FileLength -Path $file.FullName),
        (Test-Encoding -Path $file.FullName),
        (Test-FunctionNaming -Path $file.FullName),
        (Test-FileNaming -Path $file.FullName),
        (Test-Header -Path $file.FullName),
        (Test-LoggingUsage -Path $file.FullName)
    )
}

# Pruefe projektweite Anforderungen
Test-GitIgnore | Out-Null
Test-Documentation | Out-Null

# Ergebnis ausgeben
Write-Host ""
Write-Host "=== Ergebnis ===" -ForegroundColor Cyan

if ($script:Issues.Count -eq 0) {
    Write-ComplianceLog "Alle kritischen Pruefungen bestanden!" -Level SUCCESS
} else {
    Write-Host ""
    Write-Host "Kritische Probleme gefunden:" -ForegroundColor Red
    $script:Issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

if ($script:Warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnungen:" -ForegroundColor Yellow
    $script:Warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

Write-Host ""
Write-Host "Zusammenfassung:" -ForegroundColor Cyan
Write-Host "  Kritische Probleme: $($script:Issues.Count)" -ForegroundColor $(if ($script:Issues.Count -eq 0) { 'Green' } else { 'Red' })
Write-Host "  Warnungen: $($script:Warnings.Count)" -ForegroundColor $(if ($script:Warnings.Count -eq 0) { 'Green' } else { 'Yellow' })
Write-Host ""

# Exit-Code setzen
if ($script:Issues.Count -gt 0) {
    exit 1
} else {
    exit 0
}
