#Requires -Version 5.1
<#
.SYNOPSIS
    MINTutil Update-Manager
.DESCRIPTION
    Aktualisiert MINTutil-Komponenten:
    - Git Pull f?r Code-Updates
    - Python Dependencies
    - Docker Images
    - Tool-Module
    - Konfigurationsmigration
#>

[CmdletBinding()]
param(
    [ValidateSet('all', 'code', 'dependencies', 'docker', 'tools')]
    [string]$Component = 'all',
    [switch]$Force,
    [switch]$DryRun,
    [switch]$Backup,
    [switch]$Verbose
)

# Strikte Fehlerbehandlung
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# Globale Variablen
$script:MintUtilRoot = Split-Path $PSScriptRoot -Parent
$script:BackupDir = Join-Path $script:MintUtilRoot "backup"
$script:RequirementsFile = Join-Path $script:MintUtilRoot "requirements.txt"
$script:VenvPath = Join-Path $script:MintUtilRoot "venv"
$script:ConfirmScript = Join-Path $PSScriptRoot "confirm.ps1"
$script:LogsPath = Join-Path $script:MintUtilRoot "logs"
$script:LogFile = Join-Path $script:LogsPath "mintutil-cli.log"
$script:UpdateLog = Join-Path $script:LogsPath "update_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Importiere Hilfsfunktionen
if (Test-Path $script:ConfirmScript) {
    . $script:ConfirmScript
}

# Exit-Code Variable
$script:ExitCode = 0

function Write-Log {
    <#
    .SYNOPSIS
        Schreibt eine Nachricht in beide Log-Dateien
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
        
        # In Update-Log schreiben
        if (Test-Path $script:UpdateLog) {
            $logEntry | Out-File -FilePath $script:UpdateLog -Append -Encoding UTF8
        }
        
        # In zentrales Log schreiben
        if (Test-Path $script:LogFile) {
            "[$timestamp] [UPDATE] [$Level] $Message" | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
        }
        
        # Konsolen-Ausgabe mit Farbe
        switch ($Level) {
            'ERROR' { 
                Write-Host $Message -ForegroundColor Red
                $script:ExitCode = 1
            }
            'WARN'  { Write-Host $Message -ForegroundColor Yellow }
            'DEBUG' { if ($VerbosePreference -eq 'Continue') { Write-Host $Message -ForegroundColor DarkGray } }
            default { Write-Verbose $Message }
        }
    } catch {
        # Fehler beim Logging ignorieren
    }
}

function Initialize-UpdateLog {
    <#
    .SYNOPSIS
        Initialisiert das Update-Log
    #>
    try {
        if (-not (Test-Path $script:LogsPath)) {
            New-Item -ItemType Directory -Path $script:LogsPath -Force | Out-Null
        }
        
        $header = @"
================================================================================
MINTutil Update Log - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Component: $Component | Force: $Force | DryRun: $DryRun | Backup: $Backup
================================================================================
"@
        $header | Out-File $script:UpdateLog -Encoding UTF8
        
        Write-Log "Update-Prozess gestartet" -Level INFO
    } catch {
        Write-Warning "Update-Log konnte nicht initialisiert werden: $_"
    }
}

function Test-SystemRequirements {
    <#
    .SYNOPSIS
        Pr?ft Systemvoraussetzungen f?r Update
    #>
    Write-Log "Pr?fe Systemvoraussetzungen..." -Level INFO
    
    # Python
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Python gefunden: $pythonVersion" -Level INFO
        } else {
            throw "Python nicht gefunden"
        }
    } catch {
        Write-Log "Python nicht verf?gbar - Dependencies-Update wird fehlschlagen" -Level WARN
    }
    
    # Git (f?r Code-Updates)
    if ($Component -eq 'all' -or $Component -eq 'code') {
        try {
            $gitVersion = git --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Git gefunden: $gitVersion" -Level INFO
            } else {
                throw "Git nicht gefunden"
            }
        } catch {
            Write-Log "Git nicht verf?gbar - Code-Updates nicht m?glich" -Level ERROR
            return $false
        }
    }
    
    # Docker (optional)
    if ($Component -eq 'all' -or $Component -eq 'docker') {
        try {
            $dockerVersion = docker --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Docker gefunden: $dockerVersion" -Level INFO
            }
        } catch {
            Write-Log "Docker nicht verf?gbar - Docker-Updates werden ?bersprungen" -Level WARN
        }
    }
    
    return $true
}

function Test-GitRepository {
    <#
    .SYNOPSIS
        Pr?ft ob wir in einem Git-Repository sind
    #>
    try {
        $gitStatus = git status 2>&1
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Get-CurrentVersion {
    <#
    .SYNOPSIS
        Ermittelt die aktuelle Version
    #>
    $versionFile = Join-Path $script:MintUtilRoot "VERSION"
    if (Test-Path $versionFile) {
        return (Get-Content $versionFile -Raw).Trim()
    }
    
    # Fallback: Git Tag
    if (Test-GitRepository) {
        $gitTag = git describe --tags --abbrev=0 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $gitTag.Trim()
        }
    }
    
    return "0.1.0"
}

function Backup-Current {
    <#
    .SYNOPSIS
        Erstellt Backup der aktuellen Installation
    #>
    if (-not $Backup) {
        Write-Log "Backup ?bersprungen (nicht angefordert)" -Level INFO
        return
    }
    
    Write-Host "? Erstelle Backup..." -ForegroundColor Cyan
    Write-Log "Starte Backup-Prozess..." -Level INFO
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = Join-Path $script:BackupDir "mintutil_backup_$timestamp"
        
        if (-not (Test-Path $script:BackupDir)) {
            New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
        }
        
        # Wichtige Dateien f?r Backup
        $filesToBackup = @(
            ".env",
            "config\*",
            "data\*",
            "tools\*"
        )
        
        foreach ($pattern in $filesToBackup) {
            $source = Join-Path $script:MintUtilRoot $pattern
            if (Test-Path $source) {
                $dest = Join-Path $backupPath (Split-Path $pattern -Parent)
                if (-not (Test-Path $dest)) {
                    New-Item -ItemType Directory -Path $dest -Force | Out-Null
                }
                Copy-Item -Path $source -Destination $dest -Recurse -Force
                Write-Log "Backup: $pattern" -Level INFO
            }
        }
        
        Write-Host "   ? Backup erstellt: $backupPath" -ForegroundColor Green
        Write-Log "Backup erfolgreich erstellt: $backupPath" -Level INFO
    } catch {
        Write-Log "Backup fehlgeschlagen: $_" -Level ERROR
        throw
    }
}

function Update-Code {
    <#
    .SYNOPSIS
        Aktualisiert den Code via Git
    #>
    Write-Host "`n? Aktualisiere Code..." -ForegroundColor Cyan
    Write-Log "Starte Code-Update..." -Level INFO
    
    if (-not (Test-GitRepository)) {
        Write-Host "   ??  Kein Git-Repository gefunden" -ForegroundColor Yellow
        Write-Log "Git-Repository nicht gefunden" -Level WARN
        return
    }
    
    try {
        # Pr?fe auf lokale ?nderungen
        $gitStatus = git status --porcelain
        if ($gitStatus) {
            Write-Host "   ??  Lokale ?nderungen gefunden:" -ForegroundColor Yellow
            $gitStatus | ForEach-Object { 
                Write-Host "      $_" -ForegroundColor DarkYellow 
                Write-Log "Lokale ?nderung: $_" -Level WARN
            }
            
            if (-not $Force) {
                if (-not (Get-UserConfirmation "Trotzdem fortfahren? (?nderungen werden ?berschrieben)")) {
                    Write-Host "   ? Update abgebrochen" -ForegroundColor Red
                    Write-Log "Update durch Benutzer abgebrochen" -Level WARN
                    return
                }
            }
        }
        
        # Git Pull
        if ($DryRun) {
            Write-Host "   [DRY RUN] W?rde ausf?hren: git pull origin main" -ForegroundColor DarkGray
            Write-Log "[DRY RUN] git pull origin main" -Level INFO
        } else {
            Write-Host "   Hole Updates..." -ForegroundColor Yellow
            $pullResult = git pull origin main 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ? Code aktualisiert" -ForegroundColor Green
                Write-Log "Git pull erfolgreich: $pullResult" -Level INFO
            } else {
                Write-Host "   ? Git pull fehlgeschlagen: $pullResult" -ForegroundColor Red
                Write-Log "Git pull fehlgeschlagen: $pullResult" -Level ERROR
                throw "Code-Update fehlgeschlagen"
            }
        }
    } catch {
        Write-Log "Code-Update Fehler: $_" -Level ERROR
        throw
    }
}

function Update-Dependencies {
    <#
    .SYNOPSIS
        Aktualisiert Python-Dependencies
    #>
    Write-Host "`n? Aktualisiere Dependencies..." -ForegroundColor Cyan
    Write-Log "Starte Dependencies-Update..." -Level INFO
    
    try {
        # Aktiviere venv
        $activateScript = Join-Path $script:VenvPath "Scripts\Activate.ps1"
        if (Test-Path $activateScript) {
            Write-Host "   Aktiviere Virtual Environment..." -ForegroundColor DarkGray
            Write-Log "Aktiviere Virtual Environment" -Level INFO
            & $activateScript
        }
        
        if (-not (Test-Path $script:RequirementsFile)) {
            Write-Host "   ??  requirements.txt nicht gefunden" -ForegroundColor Yellow
            Write-Log "requirements.txt nicht gefunden" -Level WARN
            return
        }
        
        if ($DryRun) {
            Write-Host "   [DRY RUN] W?rde ausf?hren: pip install -r requirements.txt --upgrade" -ForegroundColor DarkGray
            Write-Log "[DRY RUN] pip install -r requirements.txt --upgrade" -Level INFO
        } else {
            Write-Host "   Aktualisiere Python-Packages..." -ForegroundColor Yellow
            $pipOutput = pip install -r $script:RequirementsFile --upgrade 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ? Dependencies aktualisiert" -ForegroundColor Green
                Write-Log "Pip upgrade erfolgreich" -Level INFO
            } else {
                Write-Host "   ? Dependency-Update fehlgeschlagen" -ForegroundColor Red
                Write-Log "Pip upgrade fehlgeschlagen: $pipOutput" -Level ERROR
                throw "Dependency-Update fehlgeschlagen"
            }
        }
    } catch {
        Write-Log "Dependencies-Update Fehler: $_" -Level ERROR
        throw
    }
}

function Update-Docker {
    <#
    .SYNOPSIS
        Aktualisiert Docker-Images
    #>
    Write-Host "`n? Aktualisiere Docker..." -ForegroundColor Cyan
    Write-Log "Starte Docker-Update..." -Level INFO
    
    try {
        # Pr?fe Docker
        $dockerVersion = docker --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   ??  Docker nicht verf?gbar" -ForegroundColor Yellow
            Write-Log "Docker nicht verf?gbar - ?berspringe Docker-Update" -Level WARN
            return
        }
        
        $composeFile = Join-Path $script:MintUtilRoot "docker-compose.yml"
        if (-not (Test-Path $composeFile)) {
            Write-Host "   ??  docker-compose.yml nicht gefunden" -ForegroundColor Yellow
            Write-Log "docker-compose.yml nicht gefunden" -Level WARN
            return
        }
        
        if ($DryRun) {
            Write-Host "   [DRY RUN] W?rde ausf?hren: docker-compose pull && docker-compose build" -ForegroundColor DarkGray
            Write-Log "[DRY RUN] docker-compose pull && docker-compose build" -Level INFO
        } else {
            Write-Host "   Hole neue Images..." -ForegroundColor Yellow
            $pullOutput = docker-compose pull 2>&1
            Write-Log "Docker pull: $pullOutput" -Level INFO
            
            Write-Host "   Baue Container neu..." -ForegroundColor Yellow
            $buildOutput = docker-compose build --no-cache 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ? Docker-Images aktualisiert" -ForegroundColor Green
                Write-Log "Docker update erfolgreich" -Level INFO
            } else {
                Write-Host "   ? Docker-Update fehlgeschlagen" -ForegroundColor Red
                Write-Log "Docker build fehlgeschlagen: $buildOutput" -Level ERROR
                throw "Docker-Update fehlgeschlagen"
            }
        }
    } catch {
        Write-Log "Docker-Update Fehler: $_" -Level ERROR
        throw
    }
}

function Update-Tools {
    <#
    .SYNOPSIS
        Aktualisiert Tool-Module
    #>
    Write-Host "`n? Aktualisiere Tools..." -ForegroundColor Cyan
    Write-Log "Starte Tools-Update..." -Level INFO
    
    $toolsDir = Join-Path $script:MintUtilRoot "tools"
    if (-not (Test-Path $toolsDir)) {
        Write-Host "   ??  Tools-Verzeichnis nicht gefunden" -ForegroundColor Yellow
        Write-Log "Tools-Verzeichnis nicht gefunden" -Level WARN
        return
    }
    
    # Suche nach Tool-Manifesten
    $manifests = Get-ChildItem -Path $toolsDir -Filter "tool.json" -Recurse -ErrorAction SilentlyContinue
    
    if ($manifests.Count -eq 0) {
        Write-Host "   ??  Keine Tools zum Aktualisieren gefunden" -ForegroundColor DarkGray
        Write-Log "Keine Tool-Manifeste gefunden" -Level INFO
        return
    }
    
    foreach ($manifest in $manifests) {
        try {
            $toolData = Get-Content $manifest.FullName | ConvertFrom-Json
            Write-Host "   Pr?fe Tool: $($toolData.name)..." -ForegroundColor Yellow
            Write-Log "Pr?fe Tool: $($toolData.name)" -Level INFO
            
            # TODO: Implementiere Tool-spezifische Update-Logik
            Write-Host "      ? Tool-Updates noch nicht implementiert" -ForegroundColor DarkGray
            Write-Log "Tool-Update f?r $($toolData.name) noch nicht implementiert" -Level INFO
        } catch {
            Write-Log "Fehler beim Lesen von $($manifest.Name): $_" -Level WARN
        }
    }
}

function Validate-Environment {
    <#
    .SYNOPSIS
        Validiert .env Datei nach Update
    #>
    Write-Log "Validiere Umgebung nach Update..." -Level INFO
    
    $envFile = Join-Path $script:MintUtilRoot ".env"
    $templateFile = Join-Path $script:MintUtilRoot "config\system.env.template"
    
    if (-not (Test-Path $envFile)) {
        if (Test-Path $templateFile) {
            Write-Host "   ??  .env fehlt - erstelle aus Template..." -ForegroundColor Yellow
            Copy-Item $templateFile $envFile
            Write-Log ".env aus Template erstellt" -Level WARN
        }
    }
}

function Show-UpdateSummary {
    <#
    .SYNOPSIS
        Zeigt Update-Zusammenfassung
    #>
    param(
        [string]$OldVersion,
        [string]$NewVersion
    )
    
    Write-Host "`n" -NoNewline
    Write-Host "?" * 50 -ForegroundColor Green
    Write-Host "? Update abgeschlossen!" -ForegroundColor Green
    Write-Host "?" * 50 -ForegroundColor Green
    
    if ($OldVersion -ne $NewVersion) {
        Write-Host "`nVersion: $OldVersion ? $NewVersion" -ForegroundColor Cyan
        Write-Log "Version aktualisiert: $OldVersion ? $NewVersion" -Level INFO
    }
    
    Write-Host "`nUpdate-Log: $script:UpdateLog" -ForegroundColor DarkGray
    
    Write-Host "`nN?chste Schritte:" -ForegroundColor Yellow
    Write-Host "1. Pr?fen Sie die ?nderungen mit: git log --oneline -5"
    Write-Host "2. Starten Sie MINTutil neu: .\mint.ps1 start"
    Write-Host "3. F?hren Sie einen Health-Check aus: .\mint.ps1 doctor"
    
    if ($script:ExitCode -ne 0) {
        Write-Host "`n??  Es gab Warnungen oder Fehler w?hrend des Updates" -ForegroundColor Yellow
        Write-Host "   Pr?fen Sie das Log f?r Details: $script:UpdateLog" -ForegroundColor Yellow
    }
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
    Write-Host "? MINTutil Update-Manager" -ForegroundColor Cyan
    Write-Host "?" * 50 -ForegroundColor DarkGray
    
    # Initialisiere Log
    Initialize-UpdateLog
    
    # Pr?fe Systemvoraussetzungen
    if (-not (Test-SystemRequirements)) {
        Write-Log "Systemvoraussetzungen nicht erf?llt" -Level ERROR
        exit 1
    }
    
    # Erfasse aktuelle Version
    $oldVersion = Get-CurrentVersion
    Write-Host "Aktuelle Version: $oldVersion" -ForegroundColor DarkGray
    Write-Log "Aktuelle Version: $oldVersion" -Level INFO
    
    # Backup wenn gew?nscht
    if ($Backup) {
        Backup-Current
    }
    
    # F?hre Updates durch
    switch ($Component) {
        'all' {
            Update-Code
            Update-Dependencies
            Update-Docker
            Update-Tools
        }
        'code' { Update-Code }
        'dependencies' { Update-Dependencies }
        'docker' { Update-Docker }
        'tools' { Update-Tools }
    }
    
    # Validiere Umgebung
    Validate-Environment
    
    # Erfasse neue Version
    $newVersion = Get-CurrentVersion
    
    # Zeige Zusammenfassung
    Show-UpdateSummary -OldVersion $oldVersion -NewVersion $newVersion
    
    Write-Log "Update-Prozess abgeschlossen (Exit-Code: $script:ExitCode)" -Level INFO
    
} catch {
    Write-Host "`n? Update fehlgeschlagen:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Log "KRITISCHER FEHLER: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    
    if ($Verbose) {
        Write-Host "`nDetails:" -ForegroundColor DarkGray
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    
    Write-Host "`n? Tipp: Pr?fen Sie das Update-Log f?r Details" -ForegroundColor Yellow
    Write-Host "   Log: $script:UpdateLog" -ForegroundColor Yellow
    
    $script:ExitCode = 1
} finally {
    # Session-Ende markieren
    Write-Log "=== Update-Session Ende (Exit-Code: $script:ExitCode) ===" -Level INFO
}

# Beende mit korrektem Exit-Code
exit $script:ExitCode
