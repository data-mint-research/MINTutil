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

# Globale Variablen
$script:MintUtilRoot = Split-Path $PSScriptRoot -Parent
$script:BackupDir = Join-Path $script:MintUtilRoot "backup"
$script:RequirementsFile = Join-Path $script:MintUtilRoot "requirements.txt"
$script:VenvPath = Join-Path $script:MintUtilRoot "venv"
$script:ConfirmScript = Join-Path $PSScriptRoot "confirm.ps1"
$script:UpdateLog = Join-Path $script:MintUtilRoot "logs\update_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Importiere Hilfsfunktionen
if (Test-Path $script:ConfirmScript) {
    . $script:ConfirmScript
}

function Initialize-UpdateLog {
    <#
    .SYNOPSIS
        Initialisiert das Update-Log
    #>
    $logDir = Split-Path $script:UpdateLog -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    "MINTutil Update Log - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $script:UpdateLog
    "=" * 50 | Out-File $script:UpdateLog -Append
}

function Write-UpdateLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] [$Level] $Message" | Out-File $script:UpdateLog -Append
    
    if ($Verbose) {
        Write-Host "[$Level] $Message" -ForegroundColor DarkGray
    }
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
        return Get-Content $versionFile -Raw
    }
    
    # Fallback: Git Tag
    if (Test-GitRepository) {
        $gitTag = git describe --tags --abbrev=0 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $gitTag
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
        Write-UpdateLog "Backup ?bersprungen (nicht angefordert)"
        return
    }
    
    Write-Host "? Erstelle Backup..." -ForegroundColor Cyan
    
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
            Write-UpdateLog "Backup: $pattern"
        }
    }
    
    Write-Host "   ? Backup erstellt: $backupPath" -ForegroundColor Green
}

function Update-Code {
    <#
    .SYNOPSIS
        Aktualisiert den Code via Git
    #>
    Write-Host "`n? Aktualisiere Code..." -ForegroundColor Cyan
    
    if (-not (Test-GitRepository)) {
        Write-Host "   ??  Kein Git-Repository gefunden" -ForegroundColor Yellow
        Write-UpdateLog "Git-Repository nicht gefunden" "WARN"
        return
    }
    
    # Pr?fe auf lokale ?nderungen
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        Write-Host "   ??  Lokale ?nderungen gefunden:" -ForegroundColor Yellow
        $gitStatus | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkYellow }
        
        if (-not $Force) {
            if (-not (Get-UserConfirmation "Trotzdem fortfahren? (?nderungen werden ?berschrieben)")) {
                Write-Host "   ? Update abgebrochen" -ForegroundColor Red
                return
            }
        }
    }
    
    # Git Pull
    if ($DryRun) {
        Write-Host "   [DRY RUN] W?rde ausf?hren: git pull origin main" -ForegroundColor DarkGray
    } else {
        Write-Host "   Hole Updates..." -ForegroundColor Yellow
        $pullResult = git pull origin main 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ? Code aktualisiert" -ForegroundColor Green
            Write-UpdateLog "Git pull erfolgreich: $pullResult"
        } else {
            Write-Host "   ? Git pull fehlgeschlagen: $pullResult" -ForegroundColor Red
            throw "Code-Update fehlgeschlagen"
        }
    }
}

function Update-Dependencies {
    <#
    .SYNOPSIS
        Aktualisiert Python-Dependencies
    #>
    Write-Host "`n? Aktualisiere Dependencies..." -ForegroundColor Cyan
    
    # Aktiviere venv
    $activateScript = Join-Path $script:VenvPath "Scripts\Activate.ps1"
    if (Test-Path $activateScript) {
        Write-Host "   Aktiviere Virtual Environment..." -ForegroundColor DarkGray
        & $activateScript
    }
    
    if (-not (Test-Path $script:RequirementsFile)) {
        Write-Host "   ??  requirements.txt nicht gefunden" -ForegroundColor Yellow
        return
    }
    
    if ($DryRun) {
        Write-Host "   [DRY RUN] W?rde ausf?hren: pip install -r requirements.txt --upgrade" -ForegroundColor DarkGray
    } else {
        Write-Host "   Aktualisiere Python-Packages..." -ForegroundColor Yellow
        pip install -r $script:RequirementsFile --upgrade
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ? Dependencies aktualisiert" -ForegroundColor Green
            Write-UpdateLog "Pip upgrade erfolgreich"
        } else {
            Write-Host "   ? Dependency-Update fehlgeschlagen" -ForegroundColor Red
            throw "Dependency-Update fehlgeschlagen"
        }
    }
}

function Update-Docker {
    <#
    .SYNOPSIS
        Aktualisiert Docker-Images
    #>
    Write-Host "`n? Aktualisiere Docker..." -ForegroundColor Cyan
    
    # Pr?fe Docker
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ??  Docker nicht verf?gbar" -ForegroundColor Yellow
        return
    }
    
    $composeFile = Join-Path $script:MintUtilRoot "docker-compose.yml"
    if (-not (Test-Path $composeFile)) {
        Write-Host "   ??  docker-compose.yml nicht gefunden" -ForegroundColor Yellow
        return
    }
    
    if ($DryRun) {
        Write-Host "   [DRY RUN] W?rde ausf?hren: docker-compose pull && docker-compose build" -ForegroundColor DarkGray
    } else {
        Write-Host "   Hole neue Images..." -ForegroundColor Yellow
        docker-compose pull
        
        Write-Host "   Baue Container neu..." -ForegroundColor Yellow
        docker-compose build --no-cache
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ? Docker-Images aktualisiert" -ForegroundColor Green
            Write-UpdateLog "Docker update erfolgreich"
        } else {
            Write-Host "   ? Docker-Update fehlgeschlagen" -ForegroundColor Red
        }
    }
}

function Update-Tools {
    <#
    .SYNOPSIS
        Aktualisiert Tool-Module
    #>
    Write-Host "`n? Aktualisiere Tools..." -ForegroundColor Cyan
    
    $toolsDir = Join-Path $script:MintUtilRoot "tools"
    if (-not (Test-Path $toolsDir)) {
        Write-Host "   ??  Tools-Verzeichnis nicht gefunden" -ForegroundColor Yellow
        return
    }
    
    # Suche nach Tool-Manifesten
    $manifests = Get-ChildItem -Path $toolsDir -Filter "tool.json" -Recurse
    
    if ($manifests.Count -eq 0) {
        Write-Host "   ??  Keine Tools zum Aktualisieren gefunden" -ForegroundColor DarkGray
        return
    }
    
    foreach ($manifest in $manifests) {
        $toolData = Get-Content $manifest.FullName | ConvertFrom-Json
        Write-Host "   Pr?fe Tool: $($toolData.name)..." -ForegroundColor Yellow
        
        # TODO: Implementiere Tool-spezifische Update-Logik
        Write-Host "      ? Tool-Updates noch nicht implementiert" -ForegroundColor DarkGray
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
    }
    
    Write-Host "`nUpdate-Log: $script:UpdateLog" -ForegroundColor DarkGray
    
    Write-Host "`nN?chste Schritte:" -ForegroundColor Yellow
    Write-Host "1. Pr?fen Sie die ?nderungen mit: git log --oneline -5"
    Write-Host "2. Starten Sie MINTutil neu: .\mint.ps1 start"
    Write-Host "3. F?hren Sie einen Health-Check aus: .\mint.ps1 doctor"
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
    
    # Erfasse aktuelle Version
    $oldVersion = Get-CurrentVersion
    Write-Host "Aktuelle Version: $oldVersion" -ForegroundColor DarkGray
    
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
    
    # Erfasse neue Version
    $newVersion = Get-CurrentVersion
    
    # Zeige Zusammenfassung
    Show-UpdateSummary -OldVersion $oldVersion -NewVersion $newVersion
    
} catch {
    Write-Host "`n? Update fehlgeschlagen:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-UpdateLog "FEHLER: $($_.Exception.Message)" "ERROR"
    
    if ($Verbose) {
        Write-Host "`nDetails:" -ForegroundColor DarkGray
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    
    Write-Host "`n? Tipp: Pr?fen Sie das Update-Log f?r Details" -ForegroundColor Yellow
    exit 1
}
