#Requires -Version 5.1
<#
.SYNOPSIS
    MINTutil Projekt-Initialisierung
.DESCRIPTION
    F?hrt die erstmalige Einrichtung von MINTutil durch:
    - Erstellt notwendige Verzeichnisse
    - Konfiguriert .env Datei
    - Installiert Dependencies
    - Erstellt initiales Glossar
    - Pr?ft Systemvoraussetzungen
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
$script:RequirementsFile = Join-Path $script:MintUtilRoot "requirements.txt"
$script:ConfirmScript = Join-Path $PSScriptRoot "confirm.ps1"

# Importiere Hilfsfunktionen
if (Test-Path $script:ConfirmScript) {
    . $script:ConfirmScript
}

function Test-SystemRequirements {
    <#
    .SYNOPSIS
        Pr?ft alle Systemvoraussetzungen
    #>
    Write-Host "? Pr?fe Systemvoraussetzungen..." -ForegroundColor Cyan
    
    $requirements = @{
        "Python (3.9+)" = {
            $pythonVersion = python --version 2>&1
            if ($LASTEXITCODE -eq 0 -and $pythonVersion -match "Python (\d+)\.(\d+)") {
                $major = [int]$Matches[1]
                $minor = [int]$Matches[2]
                return ($major -gt 3) -or ($major -eq 3 -and $minor -ge 9)
            }
            return $false
        }
        "Git" = {
            $null = git --version 2>&1
            return $LASTEXITCODE -eq 0
        }
        "Docker (optional)" = {
            $null = docker --version 2>&1
            return $LASTEXITCODE -eq 0
        }
    }
    
    $failed = @()
    foreach ($req in $requirements.GetEnumerator()) {
        Write-Host -NoNewline "   Pr?fe $($req.Key)... "
        if (& $req.Value) {
            Write-Host "?" -ForegroundColor Green
        } else {
            Write-Host "?" -ForegroundColor Red
            if (-not $req.Key.Contains("optional")) {
                $failed += $req.Key
            }
        }
    }
    
    return $failed
}

function Initialize-Directories {
    <#
    .SYNOPSIS
        Erstellt alle notwendigen Verzeichnisse
    #>
    Write-Host "`n? Erstelle Verzeichnisstruktur..." -ForegroundColor Cyan
    
    $directories = @(
        "tools",
        "scripts", 
        "shared",
        "config",
        "logs",
        "data",
        "tests",
        "docs",
        "streamlit_app"
    )
    
    foreach ($dir in $directories) {
        $path = Join-Path $script:MintUtilRoot $dir
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Host "   ? Erstellt: $dir" -ForegroundColor Green
        } else {
            Write-Host "   ? Existiert: $dir" -ForegroundColor DarkGray
        }
    }
}

function Initialize-EnvFile {
    <#
    .SYNOPSIS
        Konfiguriert die .env Datei interaktiv
    #>
    Write-Host "`n? Konfiguriere Umgebungsvariablen..." -ForegroundColor Cyan
    
    if ((Test-Path $script:EnvFile) -and -not $Force) {
        Write-Host "   ??  .env existiert bereits" -ForegroundColor Yellow
        if (-not (Get-UserConfirmation "M?chten Sie die bestehende .env ?berschreiben?")) {
            Write-Host "   ? ?berspringe .env Konfiguration" -ForegroundColor DarkGray
            return
        }
    }
    
    # Lade Template
    $envTemplate = @"
# MINTutil Environment Configuration
# Generiert am: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Application Settings
APP_NAME=MINTutil
APP_VERSION=0.1.0
ENVIRONMENT=development
DEBUG=True

# Streamlit Configuration  
STREAMLIT_SERVER_PORT=8501
STREAMLIT_SERVER_ADDRESS=0.0.0.0
STREAMLIT_THEME=dark

# API Keys (Optional)
OPENAI_API_KEY=
ANTHROPIC_API_KEY=

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mintutil
DB_USER=mintuser
DB_PASSWORD=changeme

# Logging
LOG_LEVEL=INFO
LOG_FORMAT=json
LOG_RETENTION_DAYS=30

# Security
SECRET_KEY=$(New-Guid)
ALLOWED_HOSTS=localhost,127.0.0.1

# Feature Flags
ENABLE_CACHE=True
ENABLE_MONITORING=True
ENABLE_API_RATE_LIMITING=True
"@

    # Interaktive Konfiguration wichtiger Werte
    Write-Host "`n   M?chten Sie wichtige Werte jetzt konfigurieren?" -ForegroundColor Yellow
    if (Get-UserConfirmation "API-Keys und Ports anpassen?") {
        # Port
        $port = Read-Host "   Streamlit Port (Standard: 8501)"
        if ($port) {
            $envTemplate = $envTemplate -replace "STREAMLIT_SERVER_PORT=8501", "STREAMLIT_SERVER_PORT=$port"
        }
        
        # OpenAI Key
        $openaiKey = Read-Host "   OpenAI API Key (optional, Enter f?r sp?ter)"
        if ($openaiKey) {
            $envTemplate = $envTemplate -replace "OPENAI_API_KEY=", "OPENAI_API_KEY=$openaiKey"
        }
        
        # Anthropic Key  
        $anthropicKey = Read-Host "   Anthropic API Key (optional, Enter f?r sp?ter)"
        if ($anthropicKey) {
            $envTemplate = $envTemplate -replace "ANTHROPIC_API_KEY=", "ANTHROPIC_API_KEY=$anthropicKey"
        }
    }
    
    # Speichere .env
    $envTemplate | Out-File -FilePath $script:EnvFile -Encoding UTF8
    Write-Host "   ? .env Datei erstellt" -ForegroundColor Green
}

function Install-Dependencies {
    <#
    .SYNOPSIS
        Installiert Python-Dependencies
    #>
    if ($SkipDependencies) {
        Write-Host "`n? ?berspringe Dependency-Installation" -ForegroundColor DarkGray
        return
    }
    
    Write-Host "`n? Installiere Python-Dependencies..." -ForegroundColor Cyan
    
    # Pr?fe auf Virtual Environment
    $venvPath = Join-Path $script:MintUtilRoot "venv"
    if (-not (Test-Path $venvPath)) {
        Write-Host "   Erstelle Virtual Environment..." -ForegroundColor Yellow
        if (Get-UserConfirmation "Virtual Environment erstellen?") {
            python -m venv $venvPath
            Write-Host "   ? Virtual Environment erstellt" -ForegroundColor Green
        }
    }
    
    # Aktiviere venv wenn vorhanden
    $activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
    if (Test-Path $activateScript) {
        Write-Host "   Aktiviere Virtual Environment..." -ForegroundColor Yellow
        & $activateScript
    }
    
    # Installiere Requirements
    if (Test-Path $script:RequirementsFile) {
        Write-Host "   Installiere Packages aus requirements.txt..." -ForegroundColor Yellow
        if (Get-UserConfirmation "Python-Packages installieren?") {
            pip install -r $script:RequirementsFile
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ? Dependencies installiert" -ForegroundColor Green
            } else {
                Write-Host "   ? Fehler bei der Installation" -ForegroundColor Red
            }
        }
    }
}

function Initialize-Glossary {
    <#
    .SYNOPSIS
        Erstellt initiales Tool-Glossar
    #>
    Write-Host "`n? Erstelle Tool-Glossar..." -ForegroundColor Cyan
    
    $glossaryPath = Join-Path $script:MintUtilRoot "docs\glossary.md"
    $glossaryContent = @"
# MINTutil Tool-Glossar

## Verf?gbare Module

### Core Tools
- **System Monitor**: ?berwacht Systemressourcen und Performance
- **Log Analyzer**: Analysiert und visualisiert Log-Dateien
- **Config Manager**: Verwaltet Konfigurationsdateien zentral

### Network Tools  
- **Port Scanner**: Scannt Netzwerk-Ports und Services
- **DNS Resolver**: DNS-Lookup und Analyse-Tool
- **Network Monitor**: ?berwacht Netzwerk-Traffic

### Automation Tools
- **Task Scheduler**: Plant und f?hrt automatisierte Tasks aus
- **Script Runner**: F?hrt Skripte mit Monitoring aus
- **Backup Manager**: Automatisierte Backup-Verwaltung

## Geplante Module
- Cloud Integration (AWS, Azure, GCP)
- Container Management (Docker, Kubernetes)
- Security Scanner
- API Testing Suite

---
Letzte Aktualisierung: $(Get-Date -Format "yyyy-MM-dd")
"@

    $glossaryContent | Out-File -FilePath $glossaryPath -Encoding UTF8
    Write-Host "   ? Glossar erstellt: docs\glossary.md" -ForegroundColor Green
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
    
    Write-Host "`nN?chste Schritte:" -ForegroundColor Yellow
    Write-Host "1. Passen Sie die .env Datei an Ihre Bed?rfnisse an"
    Write-Host "2. Starten Sie MINTutil mit: .\mint.ps1 start"
    Write-Host "3. ?ffnen Sie http://localhost:8501 im Browser"
    
    Write-Host "`nWeitere Kommandos:" -ForegroundColor Cyan
    Write-Host "   .\mint.ps1 doctor    - System-Diagnose"
    Write-Host "   .\mint.ps1 update    - Updates installieren"
    Write-Host "   .\mint.ps1 help      - Hilfe anzeigen"
}

function Get-UserConfirmation {
    param([string]$Message)
    
    if ($script:ConfirmScript -and (Test-Path $script:ConfirmScript)) {
        # Nutze confirm.ps1 wenn verf?gbar
        return & $script:ConfirmScript -Message $Message
    } else {
        # Fallback
        $response = Read-Host "$Message (J/N)"
        return $response -match '^[jJyY]'
    }
}

# Hauptprogramm
try {
    Write-Host "? Starte MINTutil Initialisierung..." -ForegroundColor Cyan
    Write-Host "?" * 50 -ForegroundColor DarkGray
    
    # Pr?fe Systemvoraussetzungen
    $failedReqs = Test-SystemRequirements
    if ($failedReqs.Count -gt 0) {
        Write-Host "`n? Fehlende Voraussetzungen:" -ForegroundColor Red
        $failedReqs | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
        Write-Host "`nBitte installieren Sie die fehlenden Komponenten." -ForegroundColor Yellow
        exit 1
    }
    
    # F?hre Initialisierung durch
    Initialize-Directories
    Initialize-EnvFile
    Install-Dependencies
    Initialize-Glossary
    
    # Zeige Zusammenfassung
    Show-Summary
    
} catch {
    Write-Host "`n? Fehler w?hrend der Initialisierung:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nDetails: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
    exit 1
}
