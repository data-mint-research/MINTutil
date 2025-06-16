#Requires -Version 5.1
<#
.SYNOPSIS
    MINTutil Projekt-Initialisierung - Setup-Funktionen
.DESCRIPTION
    Enthaelt alle Setup-Funktionen fuer die MINTutil-Initialisierung:
    Verzeichnisse, Environment-Dateien, Dependencies und Glossar.
.NOTES
    Autor: MINTutil Team
    Datum: 2024-01-01
    Version: 1.0.0
    Dies ist ein Modul von init_project.ps1 (NeoMINT-konform aufgeteilt)
#>

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
    
    # Pruefe ob .env bereits existiert
    if ((Test-Path $script:EnvFile) -and -not $script:Force) {
        Write-Host "   ?  .env existiert bereits" -ForegroundColor Yellow
        Write-Log ".env existiert bereits" -Level INFO
        
        # Pruefe .env auf Vollstaendigkeit
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
            Write-Host "   ?  Folgende Variablen fehlen in .env:" -ForegroundColor Yellow
            $missingVars | ForEach-Object { Write-Host "      - $_" -ForegroundColor Yellow }
            Write-Log "Fehlende Variablen in .env: $($missingVars -join ', ')" -Level WARN
            
            if (Get-UserConfirmation "Moechten Sie die fehlenden Variablen ergaenzen?") {
                # Lade Template und ergaenze fehlende Variablen
                $script:Force = $true
            } else {
                Write-Host "   ? Ueberspringe .env Konfiguration" -ForegroundColor DarkGray
                return
            }
        } else {
            if (-not (Get-UserConfirmation "Moechten Sie die bestehende .env ueberschreiben?")) {
                Write-Host "   ? Ueberspringe .env Konfiguration" -ForegroundColor DarkGray
                return
            }
        }
    }
    
    # Kopiere .env.example zu .env
    if (Test-Path $script:EnvExample) {
        Write-Log "Kopiere .env.example zu .env" -Level INFO
        Copy-Item $script:EnvExample $script:EnvFile -Force
        $envTemplate = Get-Content $script:EnvFile -Raw
    } else {
        Write-Log "Template nicht gefunden, verwende Standard" -Level WARN
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

# Ollama Configuration
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama2
"@
    }

    # Interaktive Konfiguration wichtiger Werte
    Write-Host "`n   Moechten Sie wichtige Werte jetzt konfigurieren?" -ForegroundColor Yellow
    if (Get-UserConfirmation "API-Keys und Ports anpassen?") {
        # Port
        $currentPort = if ($envTemplate -match "STREAMLIT_SERVER_PORT=(\d+)") { $Matches[1] } else { "8501" }
        Write-Host "   Aktueller Port: $currentPort" -ForegroundColor DarkGray
        $port = Read-Host "   Streamlit Port (Enter fuer $currentPort)"
        if ($port) {
            $envTemplate = $envTemplate -replace "STREAMLIT_SERVER_PORT=\d+", "STREAMLIT_SERVER_PORT=$port"
            Write-Log "Port geaendert auf: $port" -Level INFO
        }
        
        # OpenAI Key
        $openaiKey = Read-Host "   OpenAI API Key (optional, Enter fuer spaeter)"
        if ($openaiKey) {
            $envTemplate = $envTemplate -replace "OPENAI_API_KEY=.*", "OPENAI_API_KEY=$openaiKey"
            Write-Log "OpenAI API Key konfiguriert" -Level INFO
        }
        
        # Anthropic Key  
        $anthropicKey = Read-Host "   Anthropic API Key (optional, Enter fuer spaeter)"
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
    if ($script:SkipDependencies) {
        Write-Host "`n? Ueberspringe Dependency-Installation" -ForegroundColor DarkGray
        Write-Log "Dependency-Installation uebersprungen" -Level INFO
        return
    }
    
    Write-Host "`n? Installiere Python-Dependencies..." -ForegroundColor Cyan
    Write-Log "Starte Dependency-Installation" -Level INFO
    
    # Pruefe auf Virtual Environment
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
        Write-Host "   ?  requirements.txt nicht gefunden" -ForegroundColor Yellow
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

## Verfuegbare Module

### Core Tools
- **System Monitor**: Ueberwacht Systemressourcen und Performance
- **Log Analyzer**: Analysiert und visualisiert Log-Dateien
- **Config Manager**: Verwaltet Konfigurationsdateien zentral

### Network Tools  
- **Port Scanner**: Scannt Netzwerk-Ports und Services
- **DNS Resolver**: DNS-Lookup und Analyse-Tool
- **Network Monitor**: Ueberwacht Netzwerk-Traffic

### Automation Tools
- **Task Scheduler**: Plant und fuehrt automatisierte Tasks aus
- **Script Runner**: Fuehrt Skripte mit Monitoring aus
- **Backup Manager**: Automatisierte Backup-Verwaltung

### AI Tools
- **Ollama Integration**: Lokale LLM-Unterstuetzung
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

function Get-UserConfirmation {
    param([string]$Message)
    
    if ($script:ConfirmScript -and (Test-Path $script:ConfirmScript)) {
        # Nutze confirm.ps1 wenn verfuegbar
        return & $script:ConfirmScript -Message $Message
    } else {
        # Fallback
        $response = Read-Host "$Message (J/N)"
        return $response -match '^[jJyY]'
    }
}

# Export der Funktionen
Export-ModuleMember -Function Initialize-Directories, Initialize-EnvFile, Install-Dependencies, Initialize-Glossary, Get-UserConfirmation
