#Requires -Version 5.1
<#
.SYNOPSIS
    MINTutil Projekt-Initialisierung - Systemvalidierung
.DESCRIPTION
    Enthaelt alle Funktionen zur Validierung der Systemvoraussetzungen
    fuer MINTutil. Wird von init-project-main.ps1 verwendet.
.NOTES
    Autor: MINTutil Team
    Datum: 2024-01-01
    Version: 1.0.0
    Dies ist ein Modul von init_project.ps1 (NeoMINT-konform aufgeteilt)
#>

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
        if ($script:Verbose -and $Level -eq 'DEBUG') {
            Write-Host "[DEBUG] $Message" -ForegroundColor DarkGray
        }
    } catch {
        # Fehler beim Logging ignorieren
    }
}

function Test-SystemRequirements {
    <#
    .SYNOPSIS
        Prueft alle Systemvoraussetzungen
    #>
    Write-Host "? Pruefe Systemvoraussetzungen..." -ForegroundColor Cyan
    Write-Log "Starte Systempruefung" -Level INFO
    
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
                # Pruefe ob Docker laeuft
                $dockerPs = docker ps 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Log "Docker-Daemon laeuft nicht" -Level WARN
                    Write-Host "      ?  Docker ist installiert, aber der Daemon laeuft nicht" -ForegroundColor Yellow
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
                # Pruefe ob Ollama Service laeuft
                try {
                    $response = Invoke-WebRequest -Uri "http://localhost:11434" -TimeoutSec 2 -UseBasicParsing 2>&1
                    Write-Log "Ollama Service laeuft" -Level INFO
                } catch {
                    Write-Log "Ollama Service laeuft nicht - wird gestartet" -Level INFO
                    Write-Host "      ?  Starte Ollama Service..." -ForegroundColor Yellow
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
        Write-Host -NoNewline "   Pruefe $($req.Key)... "
        if (& $req.Value) {
            Write-Host "?" -ForegroundColor Green
        } else {
            Write-Host "?" -ForegroundColor Red
            if ($req.Key -notin $optional) {
                $failed += $req.Key
                Write-Host "      ? Installieren Sie $($req.Key)" -ForegroundColor Yellow
            } else {
                Write-Host "      ? Optional: $($req.Key) fuer erweiterte Features" -ForegroundColor DarkGray
            }
        }
    }
    
    # Port 8501 pruefen
    Write-Host -NoNewline "   Pruefe Port 8501... "
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

function Test-EnvironmentIntegrity {
    <#
    .SYNOPSIS
        Prueft die Integritaet der MINTutil-Umgebung
    #>
    Write-Log "Pruefe Umgebungsintegritaet" -Level INFO
    
    $issues = @()
    
    # Pruefe kritische Dateien
    $criticalFiles = @(
        "requirements.txt",
        ".gitignore",
        "README.md"
    )
    
    foreach ($file in $criticalFiles) {
        $path = Join-Path $script:MintUtilRoot $file
        if (-not (Test-Path $path)) {
            $issues += "Kritische Datei fehlt: $file"
            Write-Log "Kritische Datei fehlt: $file" -Level WARN
        }
    }
    
    # Pruefe Verzeichnisstruktur
    $requiredDirs = @("scripts", "docs")
    foreach ($dir in $requiredDirs) {
        $path = Join-Path $script:MintUtilRoot $dir
        if (-not (Test-Path $path)) {
            $issues += "Erforderliches Verzeichnis fehlt: $dir"
            Write-Log "Verzeichnis fehlt: $dir" -Level WARN
        }
    }
    
    return $issues
}

# Export der Funktionen
Export-ModuleMember -Function Test-SystemRequirements, Test-EnvironmentIntegrity, Write-Log
