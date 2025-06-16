#Requires -Version 5.1
<#
.SYNOPSIS
    MINTutil System Health Check (Doctor)
.DESCRIPTION
    F?hrt umfassende Systemdiagnose durch:
    - Systemvoraussetzungen
    - Konfigurationspr?fung  
    - Netzwerk und Ports
    - Dependencies
    - Container-Status
    - Log-Analyse
#>

[CmdletBinding()]
param(
    [ValidateSet('quick', 'full', 'network', 'dependencies', 'logs')]
    [string]$Mode = 'quick',
    [switch]$Fix,
    [switch]$Export,
    [switch]$Verbose
)

# Strikte Fehlerbehandlung
$ErrorActionPreference = 'Continue' # F?r Diagnose fortfahren bei Fehlern

# Globale Variablen
$script:MintUtilRoot = Split-Path $PSScriptRoot -Parent
$script:Issues = @()
$script:Warnings = @()
$script:Info = @()
$script:ReportFile = Join-Path $script:MintUtilRoot "logs\health_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Add-Issue {
    param(
        [string]$Category,
        [string]$Message,
        [string]$Solution = ""
    )
    $script:Issues += [PSCustomObject]@{
        Category = $Category
        Message = $Message
        Solution = $Solution
        Severity = "Error"
    }
}

function Add-Warning {
    param(
        [string]$Category,
        [string]$Message,
        [string]$Solution = ""
    )
    $script:Warnings += [PSCustomObject]@{
        Category = $Category
        Message = $Message
        Solution = $Solution
        Severity = "Warning"
    }
}

function Add-Info {
    param(
        [string]$Category,
        [string]$Message
    )
    $script:Info += [PSCustomObject]@{
        Category = $Category
        Message = $Message
        Severity = "Info"
    }
}

function Test-SystemInfo {
    <#
    .SYNOPSIS
        Sammelt Systeminformationen
    #>
    Write-Host "??  System-Informationen" -ForegroundColor Cyan
    
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

function Test-CoreRequirements {
    <#
    .SYNOPSIS
        Pr?ft Kernvoraussetzungen
    #>
    Write-Host "`n? Kernvoraussetzungen" -ForegroundColor Cyan
    
    # Python
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        if ($pythonVersion -match "Python (\d+)\.(\d+)") {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            if ($major -ge 3 -and $minor -ge 9) {
                Add-Info "Requirements" "Python: $pythonVersion ?"
            } else {
                Add-Issue "Requirements" "Python Version zu alt: $pythonVersion" "Python 3.9+ installieren"
            }
        }
    } else {
        Add-Issue "Requirements" "Python nicht gefunden" "Python 3.9+ installieren"
    }
    
    # Git
    $gitVersion = git --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Add-Info "Requirements" "Git: $gitVersion ?"
    } else {
        Add-Issue "Requirements" "Git nicht gefunden" "Git installieren"
    }
    
    # Docker (optional)
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Add-Info "Requirements" "Docker: $dockerVersion ?"
        
        # Docker l?uft?
        $dockerPs = docker ps 2>&1
        if ($LASTEXITCODE -ne 0) {
            Add-Warning "Requirements" "Docker-Daemon l?uft nicht" "Docker Desktop starten"
        }
    } else {
        Add-Warning "Requirements" "Docker nicht installiert (optional)" "Docker Desktop installieren f?r Container-Support"
    }
}

function Test-Configuration {
    <#
    .SYNOPSIS
        Pr?ft Konfigurationsdateien
    #>
    Write-Host "`n??  Konfiguration" -ForegroundColor Cyan
    
    # .env Datei
    $envFile = Join-Path $script:MintUtilRoot ".env"
    if (Test-Path $envFile) {
        Add-Info "Config" ".env Datei vorhanden ?"
        
        # Pr?fe wichtige Variablen
        $envContent = Get-Content $envFile
        $requiredVars = @(
            "APP_NAME",
            "STREAMLIT_SERVER_PORT",
            "LOG_LEVEL"
        )
        
        foreach ($var in $requiredVars) {
            if ($envContent -match "^$var=") {
                Add-Info "Config" "$var definiert ?"
            } else {
                Add-Warning "Config" "$var nicht in .env definiert" "Variable in .env erg?nzen"
            }
        }
    } else {
        Add-Issue "Config" ".env Datei fehlt" "F?hren Sie '.\mint.ps1 init' aus"
    }
    
    # Verzeichnisstruktur
    $requiredDirs = @("tools", "scripts", "streamlit_app", "logs", "data")
    foreach ($dir in $requiredDirs) {
        $path = Join-Path $script:MintUtilRoot $dir
        if (Test-Path $path) {
            Add-Info "Config" "Verzeichnis $dir vorhanden ?"
        } else {
            Add-Issue "Config" "Verzeichnis $dir fehlt" "F?hren Sie '.\mint.ps1 init' aus"
        }
    }
}

function Test-Dependencies {
    <#
    .SYNOPSIS
        Pr?ft Python-Dependencies
    #>
    if ($Mode -eq 'quick') { return }
    
    Write-Host "`n? Dependencies" -ForegroundColor Cyan
    
    # Aktiviere venv wenn vorhanden
    $venvPath = Join-Path $script:MintUtilRoot "venv"
    $activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
    if (Test-Path $activateScript) {
        & $activateScript
    }
    
    # Pr?fe wichtige Packages
    $packages = @("streamlit", "pandas", "python-dotenv")
    foreach ($package in $packages) {
        $pkgInfo = pip show $package 2>&1
        if ($LASTEXITCODE -eq 0) {
            if ($pkgInfo -match "Version: (.+)") {
                Add-Info "Dependencies" "$package $($Matches[1]) ?"
            }
        } else {
            Add-Issue "Dependencies" "Package $package nicht installiert" "pip install $package"
        }
    }
    
    # Outdated packages
    if ($Mode -eq 'full') {
        Write-Host "   Pr?fe auf Updates..." -ForegroundColor DarkGray
        $outdated = pip list --outdated --format=json | ConvertFrom-Json
        if ($outdated.Count -gt 0) {
            Add-Warning "Dependencies" "$($outdated.Count) Packages haben Updates verf?gbar" "F?hren Sie '.\mint.ps1 update' aus"
        }
    }
}

function Test-Network {
    <#
    .SYNOPSIS
        Pr?ft Netzwerk und Ports
    #>
    if ($Mode -ne 'full' -and $Mode -ne 'network') { return }
    
    Write-Host "`n? Netzwerk" -ForegroundColor Cyan
    
    # Streamlit Port
    $streamlitPort = 8501
    $envFile = Join-Path $script:MintUtilRoot ".env"
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile | Where-Object { $_ -match "STREAMLIT_SERVER_PORT=(\d+)" }
        if ($Matches[1]) {
            $streamlitPort = [int]$Matches[1]
        }
    }
    
    # Port-Verf?gbarkeit
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $streamlitPort)
        $listener.Start()
        $listener.Stop()
        Add-Info "Network" "Port $streamlitPort verf?gbar ?"
    } catch {
        Add-Warning "Network" "Port $streamlitPort belegt" "Anderen Port in .env konfigurieren oder Prozess beenden"
    }
    
    # Internet-Verbindung
    try {
        $response = Invoke-WebRequest -Uri "https://api.github.com" -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Add-Info "Network" "Internet-Verbindung OK ?"
        }
    } catch {
        Add-Warning "Network" "Keine Internet-Verbindung" "Netzwerkverbindung pr?fen"
    }
}

function Test-Logs {
    <#
    .SYNOPSIS
        Analysiert Log-Dateien
    #>
    if ($Mode -ne 'full' -and $Mode -ne 'logs') { return }
    
    Write-Host "`n? Log-Analyse" -ForegroundColor Cyan
    
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

function Show-Report {
    <#
    .SYNOPSIS
        Zeigt den Diagnose-Report
    #>
    Write-Host "`n" -NoNewline
    Write-Host "?" * 50 -ForegroundColor Blue
    Write-Host "? MINTutil Health Report" -ForegroundColor Blue
    Write-Host "?" * 50 -ForegroundColor Blue
    
    # Zusammenfassung
    $totalIssues = $script:Issues.Count + $script:Warnings.Count
    
    if ($script:Issues.Count -eq 0 -and $script:Warnings.Count -eq 0) {
        Write-Host "`n? System ist gesund!" -ForegroundColor Green
        Write-Host "   Keine Probleme gefunden." -ForegroundColor Green
    } else {
        if ($script:Issues.Count -gt 0) {
            Write-Host "`n? Fehler: $($script:Issues.Count)" -ForegroundColor Red
        }
        if ($script:Warnings.Count -gt 0) {
            Write-Host "??  Warnungen: $($script:Warnings.Count)" -ForegroundColor Yellow
        }
    }
    
    # Details
    if ($script:Issues.Count -gt 0) {
        Write-Host "`n? Fehler:" -ForegroundColor Red
        foreach ($issue in $script:Issues) {
            Write-Host "   [$($issue.Category)] $($issue.Message)" -ForegroundColor Red
            if ($issue.Solution) {
                Write-Host "      ? L?sung: $($issue.Solution)" -ForegroundColor DarkGray
            }
        }
    }
    
    if ($script:Warnings.Count -gt 0) {
        Write-Host "`n? Warnungen:" -ForegroundColor Yellow  
        foreach ($warning in $script:Warnings) {
            Write-Host "   [$($warning.Category)] $($warning.Message)" -ForegroundColor Yellow
            if ($warning.Solution) {
                Write-Host "      ? Empfehlung: $($warning.Solution)" -ForegroundColor DarkGray
            }
        }
    }
    
    if ($Verbose -and $script:Info.Count -gt 0) {
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

function Export-Report {
    <#
    .SYNOPSIS
        Exportiert Report in Datei
    #>
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
    Write-Host "`n? Report exportiert: $script:ReportFile" -ForegroundColor Green
}

function Invoke-AutoFix {
    <#
    .SYNOPSIS
        Versucht automatische Fehlerbehebung
    #>
    if (-not $Fix) { return }
    if ($script:Issues.Count -eq 0) { return }
    
    Write-Host "`n? Automatische Fehlerbehebung..." -ForegroundColor Cyan
    
    foreach ($issue in $script:Issues) {
        Write-Host "   Behebe: $($issue.Message)..." -ForegroundColor Yellow
        
        # Implementiere spezifische Fixes
        switch -Regex ($issue.Message) {
            "Verzeichnis .* fehlt" {
                # Erstelle fehlendes Verzeichnis
                if ($issue.Message -match "Verzeichnis (\w+) fehlt") {
                    $dir = $Matches[1]
                    $path = Join-Path $script:MintUtilRoot $dir
                    New-Item -ItemType Directory -Path $path -Force | Out-Null
                    Write-Host "      ? Verzeichnis erstellt" -ForegroundColor Green
                }
            }
            ".env Datei fehlt" {
                Write-Host "      ? F?hren Sie '.\mint.ps1 init' aus" -ForegroundColor DarkGray
            }
            default {
                Write-Host "      ? Keine automatische L?sung verf?gbar" -ForegroundColor DarkGray
            }
        }
    }
}

# Hauptprogramm
try {
    Write-Host "? MINTutil System Health Check" -ForegroundColor Cyan
    Write-Host "?" * 50 -ForegroundColor DarkGray
    Write-Host "Modus: $Mode" -ForegroundColor DarkGray
    Write-Host ""
    
    # F?hre Tests durch
    Test-SystemInfo
    Test-CoreRequirements
    Test-Configuration
    Test-Dependencies
    Test-Network
    Test-Logs
    
    # Auto-Fix wenn gew?nscht
    if ($Fix) {
        Invoke-AutoFix
    }
    
    # Zeige Report
    Show-Report
    
    # Exit-Code basierend auf Fehlern
    if ($script:Issues.Count -gt 0) {
        exit 1
    } else {
        exit 0
    }
    
} catch {
    Write-Host "`n? Fehler w?hrend der Diagnose:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    
    if ($Verbose) {
        Write-Host "`nDetails:" -ForegroundColor DarkGray
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    
    exit 2
}
