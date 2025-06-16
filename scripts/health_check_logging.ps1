# MINTutil Health Check Logging Module
# Zentrale Logging-Funktionen f?r Health Check

# Logging-Funktionen
function Initialize-Logging {
    $logDir = Join-Path $script:MintUtilRoot "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $script:logFile = Join-Path $logDir "mintutil-cli.log"
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [HEALTH_CHECK] [$Level] $Message"
    
    # In Datei schreiben
    if ($script:logFile) {
        Add-Content -Path $script:logFile -Value $logEntry -Encoding UTF8
    }
    
    # Auf Konsole ausgeben (wenn nicht Silent)
    if (-not $Silent) {
        switch ($Level) {
            "ERROR" { Write-Host $Message -ForegroundColor Red }
            "WARNING" { Write-Host $Message -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $Message -ForegroundColor Green }
            "INFO" { Write-Host $Message -ForegroundColor Cyan }
            default { Write-Host $Message }
        }
    }
}

# UI Helfer
function Write-Header {
    param([string]$Title)
    if (-not $Silent) {
        Write-Host "`n$("=" * 60)" -ForegroundColor DarkGray
        Write-Host $Title -ForegroundColor White
        Write-Host "$("=" * 60)" -ForegroundColor DarkGray
    }
    Write-Log $Title "INFO"
}

function Write-CheckResult {
    param(
        [string]$Component,
        [bool]$Success,
        [string]$Message = "",
        [string]$Details = ""
    )
    
    if ($Success) {
        Write-Log "? $Component - OK $Message" "SUCCESS"
    } else {
        $script:hasErrors = $true
        Write-Log "? $Component - FEHLER: $Message" "ERROR"
        if ($Details) {
            Write-Log "  ? $Details" "WARNING"
        }
    }
}

# Legacy-Funktionen f?r Kompatibilit?t
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
    $script:hasErrors = $true
    Write-Log "[$Category] $Message" "ERROR"
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
    Write-Log "[$Category] $Message" "WARNING"
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
    Write-Log "[$Category] $Message" "INFO"
}

# Export der Funktionen
Export-ModuleMember -Function @(
    'Initialize-Logging',
    'Write-Log',
    'Write-Header',
    'Write-CheckResult',
    'Add-Issue',
    'Add-Warning',
    'Add-Info'
)