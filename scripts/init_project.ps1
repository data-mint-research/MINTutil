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
$script:EnvTemplate = Join-Path $script:MintUtilRoot "config\system.env.template"
$script:RequirementsFile = Join-Path $script:MintUtilRoot "requirements.txt"
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
        $logEntry = "[$timestamp] [$Level] [init_project] $Message"
        
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

function Test-SystemRequirements {
    <#
    .SYNOPSIS
        Pr?ft alle Systemvoraussetzungen
    #>
    Write-Host "? Pr?fe Systemvoraussetzungen..." -ForegroundColor Cyan
    Write-Log "Starte Systempr?fung" -Level INFO
    
    $requirements = @{
        "Python (3.8-3.12)" = {
            $pythonVersion = python --version 2>&1
            if ($LASTEXITCODE -eq 0 -and $pythonVersion -match "Python (\d+)\.(\d+)") {
                $major = [int]$Matches[1]
                $minor = [int]$Matches[2]
                $versionOk = ($major -eq 3 -and $minor -ge 8 -and $minor -le 12)
                Write-Log "Python gefunden: $pythonVersion (OK: $versionOk)" -Level INFO
                return $versionOk
            }
            Write-Log "Python nicht gefunden oder falsche Version" -Level ERROR
            return $false
        }
        "Git" = {
            $gitVersion = git --version 2>&1
            $gitOk = $LASTEXITCODE -eq 0
            if ($gitOk) {
                Write-Log "Git gefunden: $gitVersion" -Level INFO
            } else {
                Write-Log "Git nicht gefunden" -Level ERROR
            }
            return $gitOk
        }
        "Docker" = {
            $dockerVersion = docker --version 2>&1
            $dockerOk = $LASTEXITCODE -eq 0
            if ($dockerOk) {
                Write-Log "Docker gefunden: $dockerVersion" -Level INFO
                # Pr?fe ob Docker l?uft
                $dockerPs = docker ps 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Log "Docker-Daemon l?uft nicht" -Level WARN
                    Write-Host "      ??  Docker ist installiert, aber der Daemon l?uft nicht" -ForegroundColor Yellow
                    Write-Host "      ? Starten Sie Docker Desktop" -ForegroundColor DarkGray
                }
            } else {
                Write-Log "Docker nicht gefunden" -Level INFO
            }
            return $dockerOk
        }
        "Ollama" = {
            $ollamaVersion = ollama --version 2>&1
            $ollamaOk = $LASTEXITCODE -eq 0
            if ($ollamaOk) {
                Write-Log "Ollama gefunden: $ollamaVersion" -Level INFO
                # Pr?fe ob Ollama Service l?uft
                try {
                    $response = Invoke-WebRequest -Uri "http://localhost:11434" -TimeoutSec 2 -UseBasicParsing 2>&1
                    Write-Log "Ollama Service l?uft" -Level INFO
                } catch {
                    Write-Log "Ollama Service l?uft nicht - wird gestartet" -Level INFO
                    Write-Host "      ??  Starte Ollama Service..." -ForegroundColor Yellow
                    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
                    Start-Sleep -Seconds 2
                }
            } else {
                Write-Log "Ollama nicht gefunden" -Level INFO
            }
            return $ollamaOk
        }
    }
    
    $failed = @()
    $optional = @("Docker", "Ollama")
    
    foreach ($req in $requirements.GetEnumerator()) {
        Write-Host -NoNewline "   Pr?fe $($req.Key)... "
        if (& $req.Value) {
            Write-Host "?" -ForegroundColor Green
        } else {
            Write-Host "?" -ForegroundColor Red
            if ($req.Key -notin $optional) {
                $failed += $req.Key
                Write-Host "      ? Installieren Sie $($req.Key)" -ForegroundColor Yellow
            } else {
                Write-Host "      ? Optional: $($req.Key) f?r erweiterte Features" -ForegroundColor DarkGray
            }
        }
    }
    
    # Port 8501 pr?fen
    Write-Host -NoNewline "   Pr?fe Port 8501... "
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 8501)
        $listener.Start()
        $listener.Stop()
        Write-Host "? frei" -ForegroundColor Green
        Write-Log "Port 8501 ist frei" -Level INFO
    } catch {
        Write-Host "? belegt" -ForegroundColor Red
        Write-Host "      ? Beenden Sie den Prozess auf Port 8501 oder konfigurieren Sie einen anderen Port" -ForegroundColor Yellow
        Write-Log "Port 8501 ist belegt" -Level WARN
    }
    
    return $failed
}

function Initialize-Directories {
    <#
    .SYNOPSIS
        Erstellt alle notwendigen Verzeichnisse
    #>
    Write-Host "`n? Erstelle Verzeichnisstruktur..." -ForegroundColor Cyan
    Write-Log "Erstelle Verzeichnisse" -Level INFO
    
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
            try {
                New-Item -ItemType Directory -Path $path -Force | Out-Null
                Write-Host "   ? Erstellt: $dir" -ForegroundColor Green
                Write-Log "Verzeichnis erstellt: $dir" -Level INFO
            } catch {
                Write-Host "   ? Fehler beim Erstellen: $dir" -ForegroundColor Red
                Write-Log "Fehler beim Erstellen von $dir : $_" -Level ERROR
                throw
            }
        } else {
            Write-Host "   ? Existiert: $dir" -ForegroundColor DarkGray
            Write-Log "Verzeichnis existiert bereits: $dir" -Level DEBUG
        }
    }
}

function Initialize-EnvFile {
    <#
    .SYNOPSIS
        Konfiguriert die .env Datei interaktiv
    #>
    Write-Host "`n? Konfiguriere Umgebungsvariablen..." -ForegroundColor Cyan
    Write-Log "Starte .env Konfiguration" -Level INFO
    
    # Pr?fe ob .env bereits existiert
    if ((Test-Path $script:EnvFile) -and -not $Force) {
        Write-Host "   ??  .env existiert bereits" -ForegroundColor Yellow
        Write-Log ".env existiert bereits" -Level INFO
        
        # Pr?fe .env auf Vollst?ndigkeit
        $envContent = Get-Content $script:EnvFile -Raw
        $requiredVars = @(
            "APP_NAME",
            "APP_VERSION", 
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
            Write-Host "   ??  Folgende Variablen fehlen in .env:" -ForegroundColor Yellow
            $missingVars | ForEach-Object { Write-Host "      - $_" -ForegroundColor Yellow }
            Write-Log "Fehlende Variablen in .env: $($missingVars -join ', ')" -Level WARN
            
            if (Get-UserConfirmation "M?chten Sie die fehlenden Variablen erg?nzen?") {
                # Lade Template und erg?nze fehlende Variablen
                $Force = $true
            } else {
                Write-Host "   ? ?berspringe .env Konfiguration" -ForegroundColor DarkGray
                return
            }
        } else {
            if (-not (Get-UserConfirmation "M?chten Sie die bestehende .env ?berschreiben?")) {
                Write-Host "   ? ?berspringe .env Konfiguration" -ForegroundColor DarkGray
                return
            }
        }
    }
    
    # Lade Template
    $envTemplate = if (Test-Path $script:EnvTemplate) {
        Write-Log "Lade .env aus Template: $script:EnvTemplate" -Level INFO
        Get-Content $script:EnvTemplate -Raw
    } else {
        Write-Log "Template nicht gefunden, verwende Standard" -Level WARN
        @"
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

# Ollama Configuration
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama2
"@
    }

    # Interaktive Konfiguration wichtiger Werte
    Write-Host "`n   M?chten Sie wichtige Werte jetzt konfigurieren?" -ForegroundColor Yellow
    if (Get-UserConfirmation "API-Keys und Ports anpassen?") {
        # Port
        $currentPort = if ($envTemplate -match "STREAMLIT_SERVER_PORT=(\d+)") { $Matches[1] } else { "8501" }
        Write-Host "   Aktueller Port: $currentPort" -ForegroundColor DarkGray
        $port = Read-Host "   Streamlit Port (Enter f?r $currentPort)"
        if ($port) {
            $envTemplate = $envTemplate -replace "STREAMLIT_SERVER_PORT=\d+", "STREAMLIT_SERVER_PORT=$port"
            Write-Log "Port ge?ndert auf: $port" -Level INFO
        }
        
        # OpenAI Key
        $openaiKey = Read-Host "   OpenAI API Key (optional, Enter f?r sp?ter)"
        if ($openaiKey) {
            $envTemplate = $envTemplate -replace "OPENAI_API_KEY=.*", "OPENAI_API_KEY=$openaiKey"
            Write-Log "OpenAI API Key konfiguriert" -Level INFO
        }
        
        # Anthropic Key  
        $anthropicKey = Read-Host "   Anthropic API Key (optional, Enter f?r sp?ter)"
        if ($anthropicKey) {
            $envTemplate = $envTemplate -replace "ANTHROPIC_API_KEY=.*", "ANTHROPIC_API_KEY=$anthropicKey"
            Write-Log "Anthropic API Key konfiguriert" -Level INFO
        }
    }
    
    # Speichere .env
    try {
        $envTemplate | Out-File -FilePath $script:EnvFile -Encoding UTF8
        Write-Host "   ? .env Datei erstellt" -ForegroundColor Green
        Write-Log ".env erfolgreich erstellt" -Level INFO
    } catch {
        Write-Host "   ? Fehler beim Erstellen der .env Datei" -ForegroundColor Red
        Write-Log "Fehler beim Erstellen der .env: $_" -Level ERROR
        throw
    }
}

function Install-Dependencies {
    <#
    .SYNOPSIS
        Installiert Python-Dependencies
    #>
    if ($SkipDependencies) {
        Write-Host "`n? ?berspringe Dependency-Installation" -ForegroundColor DarkGray
        Write-Log "Dependency-Installation ?bersprungen" -Level INFO
        return
    }
    
    Write-Host "`n? Installiere Python-Dependencies..." -ForegroundColor Cyan
    Write-Log "Starte Dependency-Installation" -Level INFO
    
    # Pr?fe auf Virtual Environment
    $venvPath = Join-Path $script:MintUtilRoot "venv"
    if (-not (Test-Path $venvPath)) {
        Write-Host "   Erstelle Virtual Environment..." -ForegroundColor Yellow
        if (Get-UserConfirmation "Virtual Environment erstellen?") {
            try {
                python -m venv $venvPath
                Write-Host "   ? Virtual Environment erstellt" -ForegroundColor Green
                Write-Log "Virtual Environment erstellt" -Level INFO
            } catch {
                Write-Host "   ? Fehler beim Erstellen des Virtual Environment" -ForegroundColor Red
                Write-Log "Fehler beim Erstellen des venv: $_" -Level ERROR
                throw
            }
        }
    }
    
    # Aktiviere venv wenn vorhanden
    $activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
    if (Test-Path $activateScript) {
        Write-Host "   Aktiviere Virtual Environment..." -ForegroundColor Yellow
        & $activateScript
        Write-Log "Virtual Environment aktiviert" -Level INFO
    }
    
    # Installiere Requirements
    if (Test-Path $script:RequirementsFile) {
        Write-Host "   Installiere Packages aus requirements.txt..." -ForegroundColor Yellow
        if (Get-UserConfirmation "Python-Packages installieren?") {
            try {
                pip install -r $script:RequirementsFile
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "   ? Dependencies installiert" -ForegroundColor Green
                    Write-Log "Dependencies erfolgreich installiert" -Level INFO
                } else {
                    Write-Host "   ? Fehler bei der Installation" -ForegroundColor Red
                    Write-Log "pip install fehlgeschlagen mit Exit-Code: $LASTEXITCODE" -Level ERROR
                    exit 1
                }
            } catch {
                Write-Host "   ? Fehler bei der Installation: $_" -ForegroundColor Red
                Write-Log "Fehler bei pip install: $_" -Level ERROR
                exit 1
            }
        }
    } else {
        Write-Host "   ??  requirements.txt nicht gefunden" -ForegroundColor Yellow
        Write-Log "requirements.txt nicht gefunden" -Level WARN
    }
}

function Initialize-Glossary {
    <#
    .SYNOPSIS
        Erstellt initiales Tool-Glossar
    #>
    Write-Host "`n? Erstelle Tool-Glossar..." -ForegroundColor Cyan
    Write-Log "Erstelle Glossar" -Level INFO
    
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

### AI Tools
- **Ollama Integration**: Lokale LLM-Unterst?tzung
- **Prompt Manager**: Verwaltung von AI-Prompts
- **Model Manager**: Download und Verwaltung von AI-Modellen

## Geplante Module
- Cloud Integration (AWS, Azure, GCP)
- Container Management (Docker, Kubernetes)
- Security Scanner
- API Testing Suite

---
Letzte Aktualisierung: $(Get-Date -Format "yyyy-MM-dd")
"@

    try {
        $glossaryContent | Out-File -FilePath $glossaryPath -Encoding UTF8
        Write-Host "   ? Glossar erstellt: docs\glossary.md" -ForegroundColor Green
        Write-Log "Glossar erstellt: $glossaryPath" -Level INFO
    } catch {
        Write-Host "   ? Fehler beim Erstellen des Glossars" -ForegroundColor Red
        Write-Log "Fehler beim Erstellen des Glossars: $_" -Level ERROR
        throw
    }
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
    
    Write-Host "`nLog-Datei:" -ForegroundColor DarkGray
    Write-Host "   $script:LogFile"
    
    Write-Log "Initialisierung erfolgreich abgeschlossen" -Level INFO
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
$exitCode = 0

try {
    Write-Host "? Starte MINTutil Initialisierung..." -ForegroundColor Cyan
    Write-Host "?" * 50 -ForegroundColor DarkGray
    Write-Log "=== Starte Initialisierung ===" -Level INFO
    
    # Pr?fe Systemvoraussetzungen
    $failedReqs = Test-SystemRequirements
    if ($failedReqs.Count -gt 0) {
        Write-Host "`n? Fehlende Voraussetzungen:" -ForegroundColor Red
        $failedReqs | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
        Write-Host "`nBitte installieren Sie die fehlenden Komponenten." -ForegroundColor Yellow
        Write-Log "Initialisierung abgebrochen - fehlende Voraussetzungen: $($failedReqs -join ', ')" -Level ERROR
        exit 1
    }
    
    # F?hre Initialisierung durch
    Initialize-Directories
    Initialize-EnvFile
    Install-Dependencies
    Initialize-Glossary
    
    # Zeige Zusammenfassung
    Show-Summary
    
    $exitCode = 0
    
} catch {
    $errorMsg = $_.Exception.Message
    Write-Host "`n? Fehler w?hrend der Initialisierung:" -ForegroundColor Red
    Write-Host "   $errorMsg" -ForegroundColor Red
    Write-Host "`nDetails: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
    
    Write-Log "Kritischer Fehler: $errorMsg" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    
    $exitCode = 1
} finally {
    Write-Log "=== Initialisierung beendet (Exit-Code: $exitCode) ===" -Level INFO
}

exit $exitCode
