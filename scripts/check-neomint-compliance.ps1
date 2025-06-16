#Requires -Version 5.1
<#
.SYNOPSIS
    NeoMINT Compliance Checker - Pr?ft die Einhaltung der NeoMINT Coding Practices
.DESCRIPTION
    Dieses Skript ?berpr?ft automatisch alle PowerShell- und Python-Dateien
    im MINTutil-Projekt auf Einhaltung der NeoMINT Standards v0.2.
    Pr?ft Dateil?nge, Encoding, Namenskonventionen, Header und Dokumentation.
.PARAMETER Verbose
    Zeigt detaillierte Ausgabe w?hrend der Pr?fung
.EXAMPLE
    .\check-neomint-compliance.ps1
    F?hrt die Standard-Compliance-Pr?fung durch
.EXAMPLE
    .\check-neomint-compliance.ps1 -Verbose
    F?hrt die Pr?fung mit detaillierter Ausgabe durch
.NOTES
    Author: MINT-RESEARCH Team
    Date: 2025-06-16
    Version: 1.1.0
    Dependencies: PowerShell 5.1+
.LINK
    https://github.com/data-mint-research/MINTutil/blob/main/docs/neomint-coding-practices.md
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
        Pr?ft ob Dateien die 500 LOC Grenze einhalten
    #>
    param([string]$Path)
    
    $lines = (Get-Content $Path | Measure-Object -Line).Lines
    if ($lines -gt 500) {
        $script:Issues += "Datei ?berschreitet 500 LOC: $Path ($lines Zeilen)"
        return $false
    }
    return $true
}

function Test-Encoding {
    <#
    .SYNOPSIS
        Pr?ft ob Dateien korrektes UTF-8 Encoding verwenden
    #>
    param([string]$Path)
    
    try {
        # Teste ob die Datei korrekt als UTF-8 gelesen werden kann
        $content = Get-Content $Path -Raw -Encoding UTF8
        return $true
    }
    catch {
        $script:Issues += "Datei hat Encoding-Probleme: $Path"
        return $false
    }
}

function Test-FunctionNaming {
    <#
    .SYNOPSIS
        Pr?ft PowerShell Funktionsnamen auf PascalCase
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
        Pr?ft Dateinamen auf kebab-case
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
        Pr?ft ob Skript-Dateien einen vollst?ndigen Metadata-Block haben
    #>
    param([string]$Path)
    
    $extension = [System.IO.Path]::GetExtension($Path)
    
    switch ($extension) {
        '.ps1' {
            $content = Get-Content $Path -Raw
            # Pr?fe auf PowerShell Metadata Block
            if ($content -notmatch '<#[\s\S]*?\.SYNOPSIS[\s\S]*?\.NOTES[\s\S]*?Author:[\s\S]*?Date:[\s\S]*?Version:[\s\S]*?#>') {
                $script:Issues += "Unvollst?ndiger oder fehlender Metadata-Block in: $Path"
                return $false
            }
        }
        '.py' {
            $content = Get-Content $Path -Raw
            # Pr?fe auf Python Docstring
            if ($content -notmatch '"""[\s\S]*?Author:[\s\S]*?Date:[\s\S]*?Version:[\s\S]*?"""') {
                $script:Warnings += "Unvollst?ndiger oder fehlender Docstring in: $Path"
            }
        }
    }
    return $true
}

function Test-LoggingUsage {
    <#
    .SYNOPSIS
        Pr?ft ob Write-Log verwendet wird
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

function Test-Comments {
    <#
    .SYNOPSIS
        Pr?ft ob komplexe Logik kommentiert ist
    #>
    param([string]$Path)
    
    $content = Get-Content $Path -Raw
    
    # Suche nach potentiell komplexer Logik ohne Kommentare
    $complexPatterns = @(
        # Verschachtelte Schleifen ohne Kommentar
        'for\s*\([^)]+\)\s*{\s*for\s*\(',
        'foreach\s*\([^)]+\)\s*{\s*foreach\s*\(',
        'while\s*\([^)]+\)\s*{\s*while\s*\(',
        # Regex ohne Kommentar
        '\[regex\]::',
        # Komplexe Berechnungen
        '\$\w+\s*=\s*[^;]+[+\-*/]{2,}'
    )
    
    foreach ($pattern in $complexPatterns) {
        if ($content -match $pattern) {
            # Pr?fe ob ein Kommentar in der N?he ist (3 Zeilen vor oder nach)
            $matches = [regex]::Matches($content, $pattern)
            foreach ($match in $matches) {
                $startIndex = $match.Index
                $contextStart = [Math]::Max(0, $startIndex - 200)
                $contextEnd = [Math]::Min($content.Length, $startIndex + 200)
                $context = $content.Substring($contextStart, $contextEnd - $contextStart)
                
                if ($context -notmatch '#|//|/\*') {
                    $script:Warnings += "Komplexe Logik ohne Kommentar gefunden in: $Path"
                    break
                }
            }
        }
    }
    return $true
}

function Test-GitIgnore {
    <#
    .SYNOPSIS
        Pr?ft ob .gitignore wichtige Eintr?ge enth?lt
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
        Pr?ft ob wichtige Dokumentation vorhanden ist
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

function Test-TODOs {
    <#
    .SYNOPSIS
        Pr?ft ob TODOs konkret und nachvollziehbar sind
    #>
    param([string]$Path)
    
    $content = Get-Content $Path -Raw
    $todos = [regex]::Matches($content, 'TODO:?\s*(.+)')
    
    foreach ($match in $todos) {
        $todoText = $match.Groups[1].Value.Trim()
        # Ein guter TODO sollte mindestens 10 Zeichen lang sein und beschreibend
        if ($todoText.Length -lt 10 -or $todoText -match '^(fix|implement|add|update)$') {
            $script:Warnings += "Unkonkreter TODO gefunden in $Path : '$todoText'"
        }
    }
    return $true
}

# Hauptprogramm
Write-Host ""
Write-Host "=== NeoMINT Compliance Check v1.1 ===" -ForegroundColor Cyan
Write-Host ""

# Sammle alle zu pr?fenden Dateien
$psFiles = Get-ChildItem -Path $script:ProjectRoot -Filter "*.ps1" -Recurse -File | Where-Object { $_.FullName -notmatch 'venv|\.git|node_modules' }
$pyFiles = Get-ChildItem -Path $script:ProjectRoot -Filter "*.py" -Recurse -File | Where-Object { $_.FullName -notmatch 'venv|\.git|node_modules' }
$allFiles = $psFiles + $pyFiles

Write-ComplianceLog "Pr?fe $($allFiles.Count) Dateien..." -Level INFO

# Pr?fe jede Datei
foreach ($file in $allFiles) {
    $relativePath = $file.FullName.Replace($script:ProjectRoot, '').TrimStart('\', '/')
    Write-Verbose "Pr?fe: $relativePath"
    
    # Alle Tests durchf?hren
    $tests = @(
        (Test-FileLength -Path $file.FullName),
        (Test-Encoding -Path $file.FullName),
        (Test-FunctionNaming -Path $file.FullName),
        (Test-FileNaming -Path $file.FullName),
        (Test-Header -Path $file.FullName),
        (Test-LoggingUsage -Path $file.FullName),
        (Test-Comments -Path $file.FullName),
        (Test-TODOs -Path $file.FullName)
    )
}

# Pr?fe projektweite Anforderungen
Test-GitIgnore | Out-Null
Test-Documentation | Out-Null

# Ergebnis ausgeben
Write-Host ""
Write-Host "=== Ergebnis ===" -ForegroundColor Cyan

if ($script:Issues.Count -eq 0) {
    Write-ComplianceLog "Alle kritischen Pr?fungen bestanden!" -Level SUCCESS
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
