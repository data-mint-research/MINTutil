# MINTutil System Health Check - Aktualisierte Version
# Verwendet modulare Struktur f?r bessere Wartbarkeit

#Requires -Version 5.1

param(
    [ValidateSet('quick', 'full', 'network', 'dependencies', 'logs')]
    [string]$Mode = 'quick',
    [switch]$Fix,
    [switch]$Export,
    [switch]$Verbose,
    [switch]$Silent = $false,
    [switch]$AutoFix = $false
)

# Exit-Codes
$EXIT_SUCCESS = 0
$EXIT_ERROR = 1
$EXIT_CRITICAL = 2

# Globale Variablen
$script:MintUtilRoot = Split-Path $PSScriptRoot -Parent
$script:hasErrors = $false
$script:hasCriticalErrors = $false
$script:Issues = @()
$script:Warnings = @()
$script:Info = @()
$script:ReportFile = Join-Path $script:MintUtilRoot "logs\health_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Module laden
$modulePath = $PSScriptRoot
. "$modulePath\health_check_logging.ps1"
. "$modulePath\health_check_requirements.ps1"
. "$modulePath\health_check_environment.ps1"

# System-Info (Legacy)
function Test-SystemInfo {
    Write-Header "System-Informationen"
    
    # OS Info
    $os = Get-CimInstance Win32_OperatingSystem
    Add-Info "System" "OS: $($os.Caption) $($os.Version)"
    Add-Info "System" "Architektur: $($os.OSArchitecture)"
    
    # PowerShell Version
    Add-Info "System" "PowerShell: $($PSVersionTable.PSVersion)"
    
    # Speicher
    $memory = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    $memoryGB = [Math]::Round($memory.Sum / 1GB, 2)
    Add-Info "System" "RAM: $memoryGB GB"
    
    # Festplatte
    $disk = Get-PSDrive -Name (Split-Path $script:MintUtilRoot -Qualifier).TrimEnd(':')
    if ($disk) {
        $freeGB = [Math]::Round($disk.Free / 1GB, 2)
        $usedGB = [Math]::Round($disk.Used / 1GB, 2)
        Add-Info "System" "Festplatte: $usedGB GB belegt, $freeGB GB frei"
        
        if ($freeGB -lt 1) {
            Add-Warning "System" "Wenig Festplattenspeicher verf?gbar" "Speicherplatz freigeben"
        }
    }
}

# Log-Analyse
function Test-Logs {
    if ($Mode -ne 'full' -and $Mode -ne 'logs') { return }
    
    Write-Header "Log-Analyse"
    
    $logsDir = Join-Path $script:MintUtilRoot "logs"
    if (-not (Test-Path $logsDir)) {
        Add-Info "Logs" "Keine Logs vorhanden"
        return
    }
    
    $logFiles = Get-ChildItem -Path $logsDir -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    
    foreach ($logFile in $logFiles) {
        $errors = Select-String -Path $logFile.FullName -Pattern "ERROR|CRITICAL" -CaseSensitive
        $warnings = Select-String -Path $logFile.FullName -Pattern "WARNING|WARN" -CaseSensitive
        
        if ($errors.Count -gt 0) {
            Add-Warning "Logs" "$($errors.Count) Fehler in $($logFile.Name)" "Log-Datei pr?fen"
        }
        if ($warnings.Count -gt 0) {
            Add-Info "Logs" "$($warnings.Count) Warnungen in $($logFile.Name)"
        }
    }
}

# Zusammenfassung anzeigen
function Show-Summary {
    Write-Header "Zusammenfassung"
    
    if ($script:hasCriticalErrors) {
        Write-Log "? KRITISCHE FEHLER gefunden!" "ERROR"
        Write-Log "   MINTutil kann nicht gestartet werden." "ERROR"
        Write-Log "   Bitte beheben Sie zuerst die kritischen Fehler." "ERROR"
    } elseif ($script:hasErrors -or $script:Issues.Count -gt 0) {
        Write-Log "??  WARNUNGEN gefunden!" "WARNING"
        Write-Log "   MINTutil kann mit Einschr?nkungen gestartet werden." "WARNING"
        Write-Log "   Einige Features k?nnten nicht verf?gbar sein." "WARNING"
    } else {
        Write-Log "? Alle Checks erfolgreich!" "SUCCESS"
        Write-Log "   MINTutil ist bereit zur Verwendung." "SUCCESS"
    }
    
    # N?chste Schritte
    if (-not $script:hasCriticalErrors) {
        if (-not $Silent) {
            Write-Host "`nN?chste Schritte:" -ForegroundColor Cyan
            
            if (-not $env:VIRTUAL_ENV) {
                Write-Host "  1. Virtual Environment aktivieren: .\venv\Scripts\Activate.ps1" -ForegroundColor Yellow
            }
            
            if ($script:hasErrors -or $script:Issues.Count -gt 0) {
                Write-Host "  2. Beheben Sie die Warnungen f?r volle Funktionalit?t" -ForegroundColor Yellow
            }
            
            Write-Host "  3. MINTutil starten: .\mint.ps1 start" -ForegroundColor Green
        }
    }
    
    # Log-Hinweis
    if (-not $Silent) {
        Write-Host "`nDetaillierte Logs finden Sie in: $script:logFile" -ForegroundColor DarkGray
    }
}

# Report anzeigen (Legacy)
function Show-Report {
    $totalIssues = $script:Issues.Count + $script:Warnings.Count
    
    if (-not $Silent) {
        Write-Host "`n" -NoNewline
        Write-Host "?" * 50 -ForegroundColor Blue
        Write-Host "? MINTutil Health Report" -ForegroundColor Blue
        Write-Host "?" * 50 -ForegroundColor Blue
    }
    
    if ($script:Issues.Count -eq 0 -and $script:Warnings.Count -eq 0) {
        if (-not $Silent) {
            Write-Host "`n? System ist gesund!" -ForegroundColor Green
            Write-Host "   Keine Probleme gefunden." -ForegroundColor Green
        }
    } else {
        if ($script:Issues.Count -gt 0) {
            if (-not $Silent) {
                Write-Host "`n? Fehler: $($script:Issues.Count)" -ForegroundColor Red
            }
        }
        if ($script:Warnings.Count -gt 0) {
            if (-not $Silent) {
                Write-Host "?  Warnungen: $($script:Warnings.Count)" -ForegroundColor Yellow
            }
        }
    }
    
    # Details
    if ($script:Issues.Count -gt 0 -and -not $Silent) {
        Write-Host "`n? Fehler:" -ForegroundColor Red
        foreach ($issue in $script:Issues) {
            Write-Host "   [$($issue.Category)] $($issue.Message)" -ForegroundColor Red
            if ($issue.Solution) {
                Write-Host "      ? L?sung: $($issue.Solution)" -ForegroundColor DarkGray
            }
        }
    }
    
    if ($script:Warnings.Count -gt 0 -and -not $Silent) {
        Write-Host "`n? Warnungen:" -ForegroundColor Yellow  
        foreach ($warning in $script:Warnings) {
            Write-Host "   [$($warning.Category)] $($warning.Message)" -ForegroundColor Yellow
            if ($warning.Solution) {
                Write-Host "      ? Empfehlung: $($warning.Solution)" -ForegroundColor DarkGray
            }
        }
    }
    
    if ($Verbose -and $script:Info.Count -gt 0 -and -not $Silent) {
        Write-Host "`n? Informationen:" -ForegroundColor Cyan
        foreach ($info in $script:Info) {
            Write-Host "   [$($info.Category)] $($info.Message)" -ForegroundColor Cyan
        }
    }
    
    # Export
    if ($Export) {
        Export-Report
    }
}

# Report exportieren
function Export-Report {
    $report = @()
    $report += "MINTutil Health Report"
    $report += "=" * 50
    $report += "Datum: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $report += "Modus: $Mode"
    $report += ""
    
    # Alle Eintr?ge
    $allEntries = $script:Issues + $script:Warnings + $script:Info | Sort-Object Severity, Category
    
    foreach ($entry in $allEntries) {
        $report += "[$($entry.Severity)] [$($entry.Category)] $($entry.Message)"
        if ($entry.Solution) {
            $report += "    L?sung: $($entry.Solution)"
        }
    }
    
    # Speichern
    $logDir = Split-Path $script:ReportFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $report | Out-File -FilePath $script:ReportFile -Encoding UTF8
    Write-Log "Report exportiert: $script:ReportFile" "SUCCESS"
}

# AutoFix (Legacy)
function Invoke-AutoFix {
    # Bereits in einzelnen Check-Funktionen integriert
    if (-not ($Fix -or $AutoFix)) { return }
    if ($script:Issues.Count -eq 0) { return }
    
    Write-Header "Automatische Fehlerbehebung"
    Write-Log "AutoFix ist in die einzelnen Check-Funktionen integriert" "INFO"
}

# Hauptfunktion
function Start-HealthCheck {
    Initialize-Logging
    Write-Log "=== MINTutil Health Check gestartet ===" "INFO"
    
    if (-not $Silent) {
        Write-Host "? MINTutil System Health Check" -ForegroundColor Cyan
        Write-Host "?" * 50 -ForegroundColor DarkGray
        Write-Host "Modus: $Mode" -ForegroundColor DarkGray
        if ($AutoFix -or $Fix) {
            Write-Host "AutoFix: Aktiviert" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    # F?hre Tests durch
    Test-SystemInfo
    
    if ($Mode -eq 'quick' -or $Mode -eq 'full') {
        Test-PythonEnvironment
        Test-GitEnvironment
        Test-DockerEnvironment
        Test-OllamaEnvironment
        Test-PortAvailability
        Test-EnvironmentFile
        Test-DirectoryStructure
    }
    
    if ($Mode -eq 'dependencies' -or $Mode -eq 'full') {
        Test-Dependencies
    }
    
    if ($Mode -eq 'network' -or $Mode -eq 'full') {
        Test-Network
    }
    
    if ($Mode -eq 'logs' -or $Mode -eq 'full') {
        Test-Logs
    }
    
    # Zeige Report
    Show-Report
    Show-Summary
    
    # Exit-Code bestimmen
    if ($script:hasCriticalErrors) {
        Write-Log "Health Check mit kritischen Fehlern beendet" "ERROR"
        exit $EXIT_CRITICAL
    } elseif ($script:hasErrors -or $script:Issues.Count -gt 0) {
        Write-Log "Health Check mit Fehlern beendet" "WARNING"
        exit $EXIT_ERROR
    } else {
        Write-Log "Health Check erfolgreich beendet" "SUCCESS"
        exit $EXIT_SUCCESS
    }
}

# Hauptprogramm
try {
    # F?r Kompatibilit?t mit Legacy-Code
    if ($Fix) { $AutoFix = $true }
    
    Start-HealthCheck
} catch {
    Write-Log "Fehler w?hrend der Diagnose: $($_.Exception.Message)" "ERROR"
    
    if ($Verbose -and -not $Silent) {
        Write-Host "`nDetails:" -ForegroundColor DarkGray
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    
    exit $EXIT_CRITICAL
}