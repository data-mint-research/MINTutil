#Requires -Version 5.1
<#
.SYNOPSIS
    MINTutil CLI - Central control console for modular infrastructure tools
.DESCRIPTION
    Main entry point for MINTutil. Provides subcommands for initialization,
    start, update and system diagnostics. Supports one-click installation.
.PARAMETER Command
    Available commands: install, init, start, stop, update, doctor, help
.PARAMETER Args
    Additional arguments for the selected command
.EXAMPLE
    .\mint.ps1 install    # One-click installation
    .\mint.ps1 start      # Start MINTutil
    .\mint.ps1 doctor     # System check
.NOTES
    Author: skr
    Date: 2024-01-01
    Version: 0.1.0
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('install', 'init', 'start', 'stop', 'update', 'doctor', 'help', '')]
    [string]$Command = '',
    
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Args = @()
)

# Set strict error handling
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# Global variables
$script:MintUtilRoot = $PSScriptRoot
$script:ScriptsPath = Join-Path $MintUtilRoot "scripts"
$script:LogsPath = Join-Path $MintUtilRoot "logs"
$script:LogFile = Join-Path $script:LogsPath "mintutil-cli.log"
$script:Version = "0.1.0"

# Logging functions
function Initialize-Logging {
    <#
    .SYNOPSIS
        Initializes the logging system
    #>
    try {
        if (-not (Test-Path $script:LogsPath)) {
            New-Item -ItemType Directory -Path $script:LogsPath -Force | Out-Null
        }
        
        # Mark session start in log
        $sessionStart = "`n" + "=" * 80 + "`n"
        $sessionStart += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [INFO] === MINTutil Session Start ===`n"
        $sessionStart += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [INFO] Version: $script:Version`n"
        $sessionStart += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [INFO] Command: $Command $($Args -join ' ')`n"
        $sessionStart += "=" * 80
        
        $sessionStart | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
    } catch {
        Write-Warning "Could not initialize logging: $_"
    }
}

function Write-Log {
    <#
    .SYNOPSIS
        Writes a message to the log
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
        
        # Write to file
        if (Test-Path $script:LogFile) {
            $logEntry | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
        }
        
        # Console output with color
        switch ($Level) {
            'ERROR' { Write-Host $Message -ForegroundColor Red }
            'WARN'  { Write-Host $Message -ForegroundColor Yellow }
            'DEBUG' { if ($VerbosePreference -eq 'Continue') { Write-Host $Message -ForegroundColor DarkGray } }
            default { Write-Verbose $Message }
        }
    } catch {
        # Ignore logging errors to not disrupt main program
    }
}

function Write-MintHeader {
    <#
    .SYNOPSIS
        Shows the MINTutil ASCII header
    #>
    Write-Host ""
    Write-Host "  __  __ ___ _   _ _____ _   _ _   _ _ " -ForegroundColor Cyan
    Write-Host " |  \/  |_ _| \ | |_   _| | | | |_(_) |" -ForegroundColor Cyan
    Write-Host " | |\/| || ||  \| | | | | | | | __| | |" -ForegroundColor Cyan
    Write-Host " | |  | || || |\  | | | | |_| | |_| | |" -ForegroundColor Cyan
    Write-Host " |_|  |_|___|_| \_| |_|  \___/ \__|_|_|" -ForegroundColor Cyan
    Write-Host "" 
    Write-Host " Modular Infrastructure and Network Tools v$script:Version" -ForegroundColor DarkGray
    Write-Host " ========================================" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Log "MINTutil started - v$script:Version" -Level INFO
}

function Test-Prerequisites {
    <#
    .SYNOPSIS
        Checks minimal prerequisites for MINTutil
    #>
    Write-Log "Checking system prerequisites..." -Level INFO
    $issues = @()
    
    # PowerShell Version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $msg = "PowerShell 5.1 or higher required (current: $($PSVersionTable.PSVersion))"
        $issues += $msg
        Write-Log $msg -Level ERROR
    } else {
        Write-Log "PowerShell version OK: $($PSVersionTable.PSVersion)" -Level INFO
    }
    
    # Scripts directory
    if (-not (Test-Path $script:ScriptsPath)) {
        $msg = "Scripts directory missing: $script:ScriptsPath"
        $issues += $msg
        Write-Log $msg -Level ERROR
    } else {
        Write-Log "Scripts directory present" -Level INFO
    }
    
    return $issues
}

function Invoke-MintCommand {
    <#
    .SYNOPSIS
        Executes the selected command
    #>
    param(
        [string]$Command,
        [string[]]$Arguments
    )
    
    Write-Log "Executing command: $Command" -Level INFO
    
    $exitCode = 0
    
    switch ($Command) {
        'install' {
            # One-click installation
            Write-Host "? Starting one-click installation..." -ForegroundColor Green
            Write-Host ""
            
            # Check if already installed
            if (Test-Path "$script:MintUtilRoot\venv") {
                Write-Host "? MINTutil is already installed!" -ForegroundColor Green
                Write-Host "   Use 'mint start' to launch." -ForegroundColor DarkGray
                $exitCode = 0
            } else {
                # Run setup
                $setupScript = Join-Path $script:ScriptsPath "setup_windows.ps1"
                if (Test-Path $setupScript) {
                    & $setupScript -InstallPath $script:MintUtilRoot @Arguments
                    $exitCode = $LASTEXITCODE
                } else {
                    Write-Error "Setup script not found. Please download MINTutil again."
                    $exitCode = 1
                }
            }
        }
        
        'init' {
            $scriptPath = Join-Path $script:ScriptsPath "init-project-main.ps1"
            if (Test-Path $scriptPath) {
                Write-Log "Starting initialization..." -Level INFO
                & $scriptPath @Arguments
                $exitCode = $LASTEXITCODE
            } else {
                Write-Log "Initialization script not found: $scriptPath" -Level ERROR
                Write-Error "Initialization script not found: $scriptPath"
                $exitCode = 1
            }
        }
        
        'start' {
            # Check if installation is complete
            if (-not (Test-Path "$script:MintUtilRoot\venv")) {
                Write-Host "??  MINTutil is not installed yet!" -ForegroundColor Yellow
                Write-Host "   Run 'mint install' first." -ForegroundColor DarkGray
                $exitCode = 1
            } else {
                $scriptPath = Join-Path $script:ScriptsPath "start_ui.ps1"
                if (Test-Path $scriptPath) {
                    Write-Log "Starting Web UI..." -Level INFO
                    & $scriptPath @Arguments
                    $exitCode = $LASTEXITCODE
                } else {
                    Write-Log "Start script not found: $scriptPath" -Level ERROR
                    Write-Error "Start script not found: $scriptPath"
                    $exitCode = 1
                }
            }
        }
        
        'stop' {
            Write-Host "? Stopping MINTutil..." -ForegroundColor Yellow
            # Find Streamlit processes
            $processes = Get-Process | Where-Object { $_.ProcessName -like "*streamlit*" -or $_.CommandLine -like "*streamlit*" }
            if ($processes) {
                $processes | Stop-Process -Force
                Write-Host "? MINTutil stopped." -ForegroundColor Green
            } else {
                Write-Host "??  MINTutil is not running." -ForegroundColor DarkGray
            }
            $exitCode = 0
        }
        
        'update' {
            $scriptPath = Join-Path $script:ScriptsPath "update.ps1"
            if (Test-Path $scriptPath) {
                Write-Log "Starting update process..." -Level INFO
                & $scriptPath @Arguments
                $exitCode = $LASTEXITCODE
            } else {
                Write-Log "Update script not found: $scriptPath" -Level ERROR
                Write-Error "Update script not found: $scriptPath"
                $exitCode = 1
            }
        }
        
        'doctor' {
            $scriptPath = Join-Path $script:ScriptsPath "health_check.ps1"
            if (Test-Path $scriptPath) {
                Write-Log "Starting system diagnostics..." -Level INFO
                & $scriptPath @Arguments
                $exitCode = $LASTEXITCODE
            } else {
                Write-Log "Diagnostics script not found: $scriptPath" -Level ERROR
                Write-Error "Diagnostics script not found: $scriptPath"
                $exitCode = 1
            }
        }
        
        'help' {
            Show-Help
            $exitCode = 0
        }
        
        default {
            Show-Help
            $exitCode = 0
        }
    }
    
    return $exitCode
}

function Show-Help {
    <#
    .SYNOPSIS
        Shows help for MINTutil
    #>
    Write-Host "Usage: .\mint.ps1 <command> [args]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available commands:" -ForegroundColor Green
    Write-Host "  install   ? One-click installation (recommended for new users)"
    Write-Host "  start     ??  Start the MINTutil web interface"
    Write-Host "  stop      ??  Stop MINTutil"
    Write-Host "  doctor    ? Run system diagnostics"
    Write-Host "  update    ? Update MINTutil components"
    Write-Host "  init      ?? Initialize project (for developers)"
    Write-Host "  help      ? Show this help"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  .\mint.ps1 install       # Install MINTutil completely"
    Write-Host "  .\mint.ps1 start         # Start Web UI"
    Write-Host "  .\mint.ps1 doctor        # Check system status"
    Write-Host ""
    Write-Host "Quick Start:" -ForegroundColor Cyan
    Write-Host "  New here? Just run: .\mint.ps1 install"
    Write-Host ""
    Write-Host "More information:" -ForegroundColor Blue
    Write-Host "  GitHub: https://github.com/data-mint-research/MINTutil"
    Write-Host "  Docs:   https://github.com/data-mint-research/MINTutil/tree/main/docs"
    Write-Host "  Logs:   $script:LogFile"
    
    Write-Log "Help displayed" -Level INFO
}

# Main program
$exitCode = 0

try {
    # Initialize logging
    Initialize-Logging
    
    # Show header
    Write-MintHeader
    
    # Check prerequisites
    $prerequisites = Test-Prerequisites
    if ($prerequisites.Count -gt 0) {
        Write-Host "?  Prerequisites not met:" -ForegroundColor Red
        $prerequisites | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
        Write-Log "Prerequisites not met. Exiting with error." -Level ERROR
        exit 1
    }
    
    # Execute command
    if ([string]::IsNullOrWhiteSpace($Command)) {
        Show-Help
        $exitCode = 0
    } else {
        Write-Host "? Executing: $Command" -ForegroundColor Green
        Write-Host ""
        $exitCode = Invoke-MintCommand -Command $Command -Arguments $Args
    }
    
    Write-Log "Command completed with exit code: $exitCode" -Level INFO
    
} catch {
    $errorMsg = $_.Exception.Message
    Write-Host ""
    Write-Host "? Error occurred:" -ForegroundColor Red
    Write-Host "   $errorMsg" -ForegroundColor Red
    Write-Host ""
    Write-Host "For details: .\mint.ps1 doctor" -ForegroundColor Yellow
    Write-Host "Log file: $script:LogFile" -ForegroundColor Yellow
    
    Write-Log "Critical error: $errorMsg" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
    
    $exitCode = 1
} finally {
    # Mark session end
    Write-Log "=== MINTutil session end (exit code: $exitCode) ===" -Level INFO
}

# Exit with correct exit code
exit $exitCode
