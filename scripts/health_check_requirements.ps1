# MINTutil Health Check Requirements Module
# Pr?ft System-Voraussetzungen (Python, Git, Docker, Ollama)

# Python-Umgebung pr?fen
function Test-PythonEnvironment {
    Write-Header "Python-Umgebung"
    
    # Python installiert?
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCmd) {
        Write-CheckResult "Python" $false "Python ist nicht installiert oder nicht im PATH" `
            "Bitte installieren Sie Python 3.9+ von https://python.org"
        $script:hasCriticalErrors = $true
        return
    }
    
    # Python-Version pr?fen
    try {
        $versionOutput = python --version 2>&1
        if ($versionOutput -match "Python (\d+)\.(\d+)\.(\d+)") {
            $major = [int]$matches[1]
            $minor = [int]$matches[2]
            $patch = [int]$matches[3]
            $version = "$major.$minor.$patch"
            
            if ($major -eq 3 -and $minor -ge 9) {
                Write-CheckResult "Python-Version" $true "Version $version gefunden"
                Add-Info "Requirements" "Python: $version ?"
            } else {
                Write-CheckResult "Python-Version" $false "Version $version ist zu alt" `
                    "MINTutil ben?tigt Python 3.9 oder h?her"
                Add-Issue "Requirements" "Python Version zu alt: $version" "Python 3.9+ installieren"
                $script:hasCriticalErrors = $true
            }
        }
    } catch {
        Write-CheckResult "Python-Version" $false "Konnte Version nicht ermitteln: $_"
        $script:hasCriticalErrors = $true
    }
    
    # Pip pr?fen
    $pipCmd = Get-Command pip -ErrorAction SilentlyContinue
    if ($pipCmd) {
        Write-CheckResult "pip" $true "pip ist verf?gbar"
    } else {
        Write-CheckResult "pip" $false "pip ist nicht installiert" `
            "F?hren Sie 'python -m ensurepip' aus"
    }
    
    # Virtual Environment pr?fen
    $venvPath = Join-Path $script:MintUtilRoot "venv"
    if (Test-Path $venvPath) {
        Write-CheckResult "Virtual Environment" $true "venv vorhanden"
        
        # Pr?fen ob aktiviert
        if ($env:VIRTUAL_ENV) {
            Write-CheckResult "venv aktiviert" $true "Virtual Environment ist aktiv"
        } else {
            Write-CheckResult "venv aktiviert" $false "Virtual Environment ist nicht aktiv" `
                "Aktivieren Sie es mit: .\venv\Scripts\Activate.ps1"
        }
    } else {
        Write-CheckResult "Virtual Environment" $false "venv nicht gefunden" `
            "F?hren Sie 'python -m venv venv' aus"
    }
}

# Git-Umgebung pr?fen
function Test-GitEnvironment {
    Write-Header "Git-Umgebung"
    
    # Git installiert?
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        Write-CheckResult "Git" $false "Git ist nicht installiert oder nicht im PATH" `
            "Bitte installieren Sie Git von https://git-scm.com"
        Add-Issue "Requirements" "Git nicht gefunden" "Git installieren"
        return
    }
    
    # Git-Version pr?fen
    try {
        $gitVersion = git --version
        Write-CheckResult "Git" $true $gitVersion
        Add-Info "Requirements" "Git: $gitVersion ?"
    } catch {
        Write-CheckResult "Git-Version" $false "Konnte Version nicht ermitteln: $_"
    }
    
    # Repository-Status pr?fen
    $gitDir = Join-Path $script:MintUtilRoot ".git"
    if (Test-Path $gitDir) {
        Write-CheckResult "Git-Repository" $true "Repository vorhanden"
        
        # Remote pr?fen
        try {
            $remotes = git remote -v 2>&1
            if ($remotes) {
                Write-CheckResult "Git-Remote" $true "Remote(s) konfiguriert"
            } else {
                Write-CheckResult "Git-Remote" $false "Keine Remotes konfiguriert" `
                    "F?gen Sie ein Remote hinzu mit: git remote add origin <URL>"
            }
        } catch {
            Write-CheckResult "Git-Remote" $false "Fehler beim Pr?fen der Remotes: $_"
        }
    } else {
        Write-CheckResult "Git-Repository" $false "Kein Git-Repository gefunden" `
            "Initialisieren Sie mit: git init"
    }
}

# Docker-Umgebung pr?fen (optional)
function Test-DockerEnvironment {
    Write-Header "Docker-Umgebung (Optional)"
    
    # Docker installiert?
    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerCmd) {
        Write-CheckResult "Docker" $false "Docker ist nicht installiert" `
            "Docker ist optional. Installieren Sie Docker Desktop von https://docker.com"
        Add-Warning "Requirements" "Docker nicht installiert (optional)" "Docker Desktop installieren f?r Container-Support"
        return
    }
    
    # Docker l?uft?
    try {
        $dockerVersion = docker version --format '{{.Server.Version}}' 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-CheckResult "Docker" $true "Version $dockerVersion - Docker l?uft"
            Add-Info "Requirements" "Docker: $dockerVersion ?"
            
            # Docker Compose pr?fen
            $composeVersion = docker compose version --short 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-CheckResult "Docker Compose" $true "Version $composeVersion"
            } else {
                Write-CheckResult "Docker Compose" $false "Docker Compose nicht verf?gbar"
            }
        } else {
            Write-CheckResult "Docker-Daemon" $false "Docker-Daemon l?uft nicht" `
                "Starten Sie Docker Desktop"
            Add-Warning "Requirements" "Docker-Daemon l?uft nicht" "Docker Desktop starten"
        }
    } catch {
        Write-CheckResult "Docker" $false "Fehler beim Pr?fen: $_"
    }
}

# Ollama-Umgebung pr?fen
function Test-OllamaEnvironment {
    Write-Header "Ollama-Umgebung (f?r AI-Features)"
    
    # Ollama installiert?
    $ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
    if (-not $ollamaCmd) {
        Write-CheckResult "Ollama" $false "Ollama ist nicht installiert" `
            "F?r AI-Features installieren Sie Ollama von https://ollama.ai"
        
        if ($AutoFix -or $Fix) {
            Write-Log "Versuche Ollama zu installieren..." "INFO"
            # Windows-Installation
            if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT' -or $null -eq $PSVersionTable.Platform) {
                try {
                    # Download Ollama installer
                    $installerUrl = "https://ollama.ai/download/OllamaSetup.exe"
                    $installerPath = Join-Path $env:TEMP "OllamaSetup.exe"
                    
                    Write-Log "Lade Ollama-Installer herunter..." "INFO"
                    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
                    
                    Write-Log "Starte Installation..." "INFO"
                    Start-Process -FilePath $installerPath -Wait
                    
                    # Pfad aktualisieren
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                    
                    $ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
                    if ($ollamaCmd) {
                        Write-CheckResult "Ollama-Installation" $true "Ollama wurde installiert"
                    }
                } catch {
                    Write-Log "Automatische Installation fehlgeschlagen: $_" "ERROR"
                }
            }
        }
        return
    }
    
    # Ollama-Version pr?fen
    try {
        $ollamaVersion = ollama version 2>&1
        Write-CheckResult "Ollama" $true "Version $ollamaVersion installiert"
    } catch {
        Write-CheckResult "Ollama-Version" $false "Konnte Version nicht ermitteln"
    }
    
    # Ollama-Service l?uft?
    try {
        $ollamaList = ollama list 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-CheckResult "Ollama-Service" $true "Service l?uft"
            
            # Verf?gbare Modelle pr?fen
            if ($ollamaList -match "llama|mistral|codellama") {
                Write-CheckResult "Ollama-Modelle" $true "AI-Modelle verf?gbar"
            } else {
                Write-CheckResult "Ollama-Modelle" $false "Keine AI-Modelle installiert" `
                    "Installieren Sie ein Modell mit: ollama pull llama2"
            }
        } else {
            Write-CheckResult "Ollama-Service" $false "Service l?uft nicht"
            
            if ($AutoFix -or $Fix) {
                Write-Log "Starte Ollama-Service..." "INFO"
                try {
                    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
                    Start-Sleep -Seconds 3
                    
                    $retryList = ollama list 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-CheckResult "Ollama-Service-Start" $true "Service wurde gestartet"
                    }
                } catch {
                    Write-Log "Konnte Ollama-Service nicht starten: $_" "ERROR"
                }
            } else {
                Write-Log "  ? Starten Sie Ollama mit: ollama serve" "WARNING"
            }
        }
    } catch {
        Write-CheckResult "Ollama-Service" $false "Fehler beim Pr?fen: $_"
    }
}

# Dependencies pr?fen
function Test-Dependencies {
    if ($Mode -eq 'quick') { return }
    
    Write-Header "Python Dependencies"
    
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
                Write-CheckResult "$package" $true "Version $($Matches[1])"
                Add-Info "Dependencies" "$package $($Matches[1]) ?"
            }
        } else {
            Write-CheckResult "$package" $false "nicht installiert"
            Add-Issue "Dependencies" "Package $package nicht installiert" "pip install $package"
            if ($AutoFix -or $Fix) {
                Write-Log "Installiere $package..." "INFO"
                pip install $package
            }
        }
    }
    
    # Outdated packages
    if ($Mode -eq 'full') {
        Write-Log "Pr?fe auf Updates..." "INFO"
        try {
            $outdated = pip list --outdated --format=json | ConvertFrom-Json
            if ($outdated.Count -gt 0) {
                Add-Warning "Dependencies" "$($outdated.Count) Packages haben Updates verf?gbar" "F?hren Sie '.\mint.ps1 update' aus"
            }
        } catch {
            Write-Log "Konnte Updates nicht pr?fen" "WARNING"
        }
    }
}

# Legacy-Funktion f?r Kompatibilit?t
function Test-CoreRequirements {
    Test-PythonEnvironment
    Test-GitEnvironment
    Test-DockerEnvironment
}

# Export der Funktionen
Export-ModuleMember -Function @(
    'Test-PythonEnvironment',
    'Test-GitEnvironment',
    'Test-DockerEnvironment',
    'Test-OllamaEnvironment',
    'Test-Dependencies',
    'Test-CoreRequirements'
)