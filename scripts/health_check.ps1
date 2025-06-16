#Requires -Version 5.1
<#
.SYNOPSIS
    MINTutil System Health Check - Checks system requirements and configuration
.DESCRIPTION
    Performs comprehensive system checks to ensure MINTutil works correctly.
    Supports various modes and automatic repair.
.PARAMETER Mode
    Check mode: quick, full, network, dependencies, logs
.PARAMETER Fix
    Enables automatic error correction (Legacy, uses AutoFix)
.PARAMETER AutoFix
    Enables automatic error correction
.PARAMETER Export
    Exports health report as file
.PARAMETER Verbose
    Shows detailed information
.PARAMETER Silent
    Suppresses console output
.EXAMPLE
    .\health_check.ps1
    .\health_check.ps1 -Mode full -AutoFix
    .\health_check.ps1 -Export
.NOTES
    Author: skr
    Date: 2024-01-01
    Version: 2.0.0
#>

param(
    [ValidateSet('quick', 'full', 'network', 'dependencies', 'logs')]
    [string]$Mode = 'quick',
    [switch]$Fix,
    [switch]$Export,
    [switch]$Verbose,
    [switch]$Silent = $false,
    [switch]$AutoFix = $false
)

# Exit codes
$EXIT_SUCCESS = 0
$EXIT_ERROR = 1
$EXIT_CRITICAL = 2

# Global variables
$script:MintUtilRoot = Split-Path $PSScriptRoot -Parent
$script:hasErrors = $false
$script:hasCriticalErrors = $false
$script:Issues = @()
$script:Warnings = @()
$script:Info = @()
$script:ReportFile = Join-Path $script:MintUtilRoot "logs\health_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Load modules
$modulePath = $PSScriptRoot
. "$modulePath\health_check_logging.ps1"
. "$modulePath\health_check_requirements.ps1"
. "$modulePath\health_check_environment.ps1"

# System info (Legacy)
function Test-SystemInfo {
    Write-Header "System Information"
    
    # OS Info
    $os = Get-CimInstance Win32_OperatingSystem
    Add-Info "System" "OS: $($os.Caption) $($os.Version)"
    Add-Info "System" "Architecture: $($os.OSArchitecture)"
    
    # PowerShell Version
    Add-Info "System" "PowerShell: $($PSVersionTable.PSVersion)"
    
    # Memory
    $memory = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    $memoryGB = [Math]::Round($memory.Sum / 1GB, 2)
    Add-Info "System" "RAM: $memoryGB GB"
    
    # Disk
    $disk = Get-PSDrive -Name (Split-Path $script:MintUtilRoot -Qualifier).TrimEnd(':')
    if ($disk) {
        $freeGB = [Math]::Round($disk.Free / 1GB, 2)
        $usedGB = [Math]::Round($disk.Used / 1GB, 2)
        Add-Info "System" "Disk: $usedGB GB used, $freeGB GB free"
        
        if ($freeGB -lt 1) {
            Add-Warning "System" "Low disk space available" "Free up disk space"
        }
    }
}

# Log analysis
function Test-Logs {
    if ($Mode -ne 'full' -and $Mode -ne 'logs') { return }
    
    Write-Header "Log Analysis"
    
    $logsDir = Join-Path $script:MintUtilRoot "logs"
    if (-not (Test-Path $logsDir)) {
        Add-Info "Logs" "No logs available"
        return
    }
    
    $logFiles = Get-ChildItem -Path $logsDir -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    
    foreach ($logFile in $logFiles) {
        $errors = Select-String -Path $logFile.FullName -Pattern "ERROR|CRITICAL" -CaseSensitive
        $warnings = Select-String -Path $logFile.FullName -Pattern "WARNING|WARN" -CaseSensitive
        
        if ($errors.Count -gt 0) {
            Add-Warning "Logs" "$($errors.Count) errors in $($logFile.Name)" "Check log file"
        }
        if ($warnings.Count -gt 0) {
            Add-Info "Logs" "$($warnings.Count) warnings in $($logFile.Name)"
        }
    }
}

# Show summary
function Show-Summary {
    Write-Header "Summary"
    
    if ($script:hasCriticalErrors) {
        Write-Log "? CRITICAL ERRORS found!" "ERROR"
        Write-Log "   MINTutil cannot be started." "ERROR"
        Write-Log "   Please fix critical errors first." "ERROR"
    } elseif ($script:hasErrors -or $script:Issues.Count -gt 0) {
        Write-Log "?  WARNINGS found!" "WARNING"
        Write-Log "   MINTutil can be started with limitations." "WARNING"
        Write-Log "   Some features might not be available." "WARNING"
    } else {
        Write-Log "? All checks passed!" "SUCCESS"
        Write-Log "   MINTutil is ready to use." "SUCCESS"
    }
    
    # Next steps
    if (-not $script:hasCriticalErrors) {
        if (-not $Silent) {
            Write-Host "`nNext steps:" -ForegroundColor Cyan
            
            if (-not $env:VIRTUAL_ENV) {
                Write-Host "  1. Activate virtual environment: .\venv\Scripts\Activate.ps1" -ForegroundColor Yellow
            }
            
            if ($script:hasErrors -or $script:Issues.Count -gt 0) {
                Write-Host "  2. Fix warnings for full functionality" -ForegroundColor Yellow
            }
            
            Write-Host "  3. Start MINTutil: .\mint.ps1 start" -ForegroundColor Green
        }
    }
    
    # Log note
    if (-not $Silent) {
        Write-Host "`nDetailed logs can be found in: $script:logFile" -ForegroundColor DarkGray
    }
}

# Show report (Legacy)
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
            Write-Host "`n? System is healthy!" -ForegroundColor Green
            Write-Host "   No issues found." -ForegroundColor Green
        }
    } else {
        if ($script:Issues.Count -gt 0) {
            if (-not $Silent) {
                Write-Host "`n? Errors: $($script:Issues.Count)" -ForegroundColor Red
            }
        }
        if ($script:Warnings.Count -gt 0) {
            if (-not $Silent) {
                Write-Host "?  Warnings: $($script:Warnings.Count)" -ForegroundColor Yellow
            }
        }
    }
    
    # Details
    if ($script:Issues.Count -gt 0 -and -not $Silent) {
        Write-Host "`n? Errors:" -ForegroundColor Red
        foreach ($issue in $script:Issues) {
            Write-Host "   [$($issue.Category)] $($issue.Message)" -ForegroundColor Red
            if ($issue.Solution) {
                Write-Host "      ? Solution: $($issue.Solution)" -ForegroundColor DarkGray
            }
        }
    }
    
    if ($script:Warnings.Count -gt 0 -and -not $Silent) {
        Write-Host "`n? Warnings:" -ForegroundColor Yellow  
        foreach ($warning in $script:Warnings) {
            Write-Host "   [$($warning.Category)] $($warning.Message)" -ForegroundColor Yellow
            if ($warning.Solution) {
                Write-Host "      ? Recommendation: $($warning.Solution)" -ForegroundColor DarkGray
            }
        }
    }
    
    if ($Verbose -and $script:Info.Count -gt 0 -and -not $Silent) {
        Write-Host "`n? Information:" -ForegroundColor Cyan
        foreach ($info in $script:Info) {
            Write-Host "   [$($info.Category)] $($info.Message)" -ForegroundColor Cyan
        }
    }
    
    # Export
    if ($Export) {
        Export-Report
    }
}

# Export report
function Export-Report {
    $report = @()
    $report += "MINTutil Health Report"
    $report += "=" * 50
    $report += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $report += "Mode: $Mode"
    $report += ""
    
    # All entries
    $allEntries = $script:Issues + $script:Warnings + $script:Info | Sort-Object Severity, Category
    
    foreach ($entry in $allEntries) {
        $report += "[$($entry.Severity)] [$($entry.Category)] $($entry.Message)"
        if ($entry.Solution) {
            $report += "    Solution: $($entry.Solution)"
        }
    }
    
    # Save
    $logDir = Split-Path $script:ReportFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $report | Out-File -FilePath $script:ReportFile -Encoding UTF8
    Write-Log "Report exported: $script:ReportFile" "SUCCESS"
}

# AutoFix (Legacy)
function Invoke-AutoFix {
    # Already integrated into individual check functions
    if (-not ($Fix -or $AutoFix)) { return }
    if ($script:Issues.Count -eq 0) { return }
    
    Write-Header "Automatic Error Correction"
    Write-Log "AutoFix is integrated into individual check functions" "INFO"
}

# Main function
function Start-HealthCheck {
    Initialize-Logging
    Write-Log "=== MINTutil Health Check started ===" "INFO"
    
    if (-not $Silent) {
        Write-Host "? MINTutil System Health Check" -ForegroundColor Cyan
        Write-Host "?" * 50 -ForegroundColor DarkGray
        Write-Host "Mode: $Mode" -ForegroundColor DarkGray
        if ($AutoFix -or $Fix) {
            Write-Host "AutoFix: Enabled" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    # Run tests
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
    
    # Show report
    Show-Report
    Show-Summary
    
    # Determine exit code
    if ($script:hasCriticalErrors) {
        Write-Log "Health Check ended with critical errors" "ERROR"
        exit $EXIT_CRITICAL
    } elseif ($script:hasErrors -or $script:Issues.Count -gt 0) {
        Write-Log "Health Check ended with errors" "WARNING"
        exit $EXIT_ERROR
    } else {
        Write-Log "Health Check completed successfully" "SUCCESS"
        exit $EXIT_SUCCESS
    }
}

# Main program
try {
    # For compatibility with legacy code
    if ($Fix) { $AutoFix = $true }
    
    Start-HealthCheck
} catch {
    Write-Log "Error during diagnostics: $($_.Exception.Message)" "ERROR"
    
    if ($Verbose -and -not $Silent) {
        Write-Host "`nDetails:" -ForegroundColor DarkGray
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    
    exit $EXIT_CRITICAL
}
