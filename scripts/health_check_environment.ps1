# MINTutil Health Check Environment Module
# Pr?ft Umgebungs-Konfiguration (.env, Ports, Verzeichnisse)

# Port-Verf?gbarkeit pr?fen
function Test-PortAvailability {
    Write-Header "Port-Verf?gbarkeit"
    
    $portsToCheck = @(
        @{Port = 8501; Service = "Streamlit UI"},
        @{Port = 8000; Service = "API Server"},
        @{Port = 11434; Service = "Ollama API"}
    )
    
    # Streamlit Port aus .env lesen
    $envFile = Join-Path $script:MintUtilRoot ".env"
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile | Where-Object { $_ -match "STREAMLIT_SERVER_PORT=(\d+)" }
        if ($Matches[1]) {
            $portsToCheck[0].Port = [int]$Matches[1]
        }
    }
    
    foreach ($portInfo in $portsToCheck) {
        $port = $portInfo.Port
        $service = $portInfo.Service
        
        try {
            $connection = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue -InformationLevel Quiet
            
            if ($connection) {
                # Port ist belegt - herausfinden von wem
                $tcpConnections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
                if ($tcpConnections) {
                    $process = Get-Process -Id $tcpConnections[0].OwningProcess -ErrorAction SilentlyContinue
                    
                    if ($process) {
                        # Spezielle Behandlung f?r erwartete Prozesse
                        if ($port -eq 11434 -and $process.ProcessName -like "*ollama*") {
                            Write-CheckResult "Port $port ($service)" $true "Ollama-Service l?uft bereits"
                        } elseif ($port -eq 8501 -and $process.ProcessName -like "*python*") {
                            Write-CheckResult "Port $port ($service)" $false "Port ist belegt von: $($process.ProcessName) (PID: $($process.Id))" `
                                "M?glicherweise l?uft bereits eine MINTutil-Instanz"
                            Add-Warning "Network" "Port $port belegt" "Anderen Port in .env konfigurieren oder Prozess beenden"
                        } else {
                            Write-CheckResult "Port $port ($service)" $false "Port ist belegt von: $($process.ProcessName) (PID: $($process.Id))"
                            Add-Warning "Network" "Port $port belegt von $($process.ProcessName)" "Prozess beenden oder anderen Port verwenden"
                        }
                    } else {
                        Write-CheckResult "Port $port ($service)" $false "Port ist belegt (Prozess unbekannt)"
                    }
                } else {
                    Write-CheckResult "Port $port ($service)" $false "Port ist belegt"
                }
            } else {
                Write-CheckResult "Port $port ($service)" $true "Port ist frei"
                Add-Info "Network" "Port $port verf?gbar ?"
            }
        } catch {
            # Fallback f?r ?ltere Windows-Versionen ohne Test-NetConnection
            try {
                $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
                $listener.Start()
                $listener.Stop()
                Write-CheckResult "Port $port ($service)" $true "Port ist frei"
                Add-Info "Network" "Port $port verf?gbar ?"
            } catch {
                Write-CheckResult "Port $port ($service)" $false "Port ist belegt oder nicht pr?fbar"
                Add-Warning "Network" "Port $port belegt" "Anderen Port in .env konfigurieren oder Prozess beenden"
            }
        }
    }
}

# .env-Datei pr?fen
function Test-EnvironmentFile {
    Write-Header "Umgebungskonfiguration (.env)"
    
    $envPath = Join-Path $script:MintUtilRoot ".env"
    $templatePath = Join-Path $script:MintUtilRoot "config" "system.env.template"
    
    # .env existiert?
    if (-not (Test-Path $envPath)) {
        Write-CheckResult ".env-Datei" $false "Datei nicht gefunden"
        Add-Issue "Config" ".env Datei fehlt" "F?hren Sie '.\mint.ps1 init' aus"
        
        # Template vorhanden?
        if (Test-Path $templatePath) {
            if ($AutoFix -or $Fix) {
                Write-Log "Erstelle .env aus Template..." "INFO"
                Copy-Item $templatePath $envPath
                Write-CheckResult ".env-Erstellung" $true ".env wurde aus Template erstellt"
            } else {
                Write-Log "  ? Erstellen Sie .env mit: copy config\system.env.template .env" "WARNING"
            }
        } else {
            Write-CheckResult ".env-Template" $false "Template nicht gefunden"
            $script:hasCriticalErrors = $true
        }
        return
    }
    
    Write-CheckResult ".env-Datei" $true "Datei existiert"
    Add-Info "Config" ".env Datei vorhanden ?"
    
    # Erforderliche Variablen pr?fen
    $requiredVars = @(
        "APP_NAME",
        "APP_VERSION",
        "LOG_LEVEL",
        "LOG_FORMAT",
        "STREAMLIT_SERVER_PORT",
        "STREAMLIT_SERVER_ADDRESS",
        "ENABLE_AI_FEATURES",
        "OLLAMA_BASE_URL",
        "DEFAULT_AI_MODEL"
    )
    
    # Aus Legacy-Gr?nden auch die alten Variablen pr?fen
    $legacyVars = @(
        "STREAMLIT_PORT",
        "STREAMLIT_SERVER_PORT"
    )
    
    # .env laden
    $envContent = Get-Content $envPath -ErrorAction SilentlyContinue
    $envVars = @{}
    
    foreach ($line in $envContent) {
        if ($line -match '^([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $envVars[$key] = $value
        }
    }
    
    $missingVars = @()
    $emptyVars = @()
    
    foreach ($var in $requiredVars) {
        if (-not $envVars.ContainsKey($var)) {
            # Check legacy names
            $found = $false
            foreach ($legacy in $legacyVars) {
                if ($envVars.ContainsKey($legacy)) {
                    $found = $true
                    break
                }
            }
            if (-not $found) {
                $missingVars += $var
            }
        } elseif ([string]::IsNullOrWhiteSpace($envVars[$var])) {
            $emptyVars += $var
        } else {
            Add-Info "Config" "$var definiert ?"
        }
    }
    
    if ($missingVars.Count -gt 0) {
        Write-CheckResult "Fehlende Variablen" $false "$($missingVars.Count) Variable(n) fehlen"
        Write-Log "  ? Fehlende Variablen: $($missingVars -join ', ')" "WARNING"
        
        if (($AutoFix -or $Fix) -and (Test-Path $templatePath)) {
            Write-Log "Erg?nze fehlende Variablen aus Template..." "INFO"
            # Template-Variablen laden und fehlende erg?nzen
            $templateContent = Get-Content $templatePath
            $addedVars = @()
            
            foreach ($line in $templateContent) {
                if ($line -match '^([^#][^=]+)=(.*)$') {
                    $key = $matches[1].Trim()
                    if ($key -in $missingVars) {
                        Add-Content -Path $envPath -Value $line
                        $addedVars += $key
                    }
                }
            }
            
            if ($addedVars.Count -gt 0) {
                Write-CheckResult "Variable erg?nzt" $true "$($addedVars.Count) Variable(n) wurden erg?nzt"
            }
        } else {
            foreach ($var in $missingVars) {
                Add-Warning "Config" "$var nicht in .env definiert" "Variable in .env erg?nzen"
            }
        }
    } else {
        Write-CheckResult "Erforderliche Variablen" $true "Alle Variablen vorhanden"
    }
    
    if ($emptyVars.Count -gt 0) {
        Write-CheckResult "Leere Variablen" $false "$($emptyVars.Count) Variable(n) haben keinen Wert"
        Write-Log "  ? Leere Variablen: $($emptyVars -join ', ')" "WARNING"
        Write-Log "  ? Bitte setzen Sie Werte in der .env-Datei" "WARNING"
    }
}

# Verzeichnisstruktur pr?fen
function Test-DirectoryStructure {
    Write-Header "Verzeichnisstruktur"
    
    $requiredDirs = @("tools", "scripts", "streamlit_app", "logs", "data")
    foreach ($dir in $requiredDirs) {
        $path = Join-Path $script:MintUtilRoot $dir
        if (Test-Path $path) {
            Write-CheckResult "Verzeichnis $dir" $true "vorhanden"
            Add-Info "Config" "Verzeichnis $dir vorhanden ?"
        } else {
            Write-CheckResult "Verzeichnis $dir" $false "fehlt"
            Add-Issue "Config" "Verzeichnis $dir fehlt" "F?hren Sie '.\mint.ps1 init' aus"
            
            if ($AutoFix -or $Fix) {
                New-Item -ItemType Directory -Path $path -Force | Out-Null
                Write-Log "Verzeichnis $dir erstellt" "SUCCESS"
            }
        }
    }
}

# Internet-Verbindung pr?fen
function Test-InternetConnection {
    if ($Mode -ne 'full' -and $Mode -ne 'network') { return }
    
    Write-Header "Internet-Verbindung"
    try {
        $response = Invoke-WebRequest -Uri "https://api.github.com" -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-CheckResult "Internet-Verbindung" $true "OK"
            Add-Info "Network" "Internet-Verbindung OK ?"
        }
    } catch {
        Write-CheckResult "Internet-Verbindung" $false "Keine Verbindung"
        Add-Warning "Network" "Keine Internet-Verbindung" "Netzwerkverbindung pr?fen"
    }
}

# Legacy-Funktionen f?r Kompatibilit?t
function Test-Configuration {
    Test-EnvironmentFile
    Test-DirectoryStructure
}

function Test-Network {
    if ($Mode -ne 'full' -and $Mode -ne 'network') { return }
    Test-PortAvailability
    Test-InternetConnection
}

# Export der Funktionen
Export-ModuleMember -Function @(
    'Test-PortAvailability',
    'Test-EnvironmentFile',
    'Test-DirectoryStructure',
    'Test-InternetConnection',
    'Test-Configuration',
    'Test-Network'
)