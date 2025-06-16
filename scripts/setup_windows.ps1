#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Automatisches Setup-Script f?r MINTutil auf Windows
.DESCRIPTION
    Installiert alle Abh?ngigkeiten und richtet MINTutil komplett ein.
    Dieses Script installiert Python, Git, FFmpeg und alle Python-Pakete.
.EXAMPLE
    .\setup_windows.ps1
.NOTES
    Autor: MINT-RESEARCH
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [string]$InstallPath = "C:\MINTutil",
    [switch]$SkipPython,
    [switch]$SkipGit,
    [switch]$SkipFFmpeg,
    [switch]$UseDocker
)

# Farben f?r Output
$SuccessColor = "Green"
$ErrorColor = "Red"
$WarningColor = "Yellow"
$InfoColor = "Cyan"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Python {
    Write-ColorOutput "`n? Python Installation..." $InfoColor
    
    if (Test-CommandExists "python") {
        $pythonVersion = python --version 2>&1
        Write-ColorOutput "? Python bereits installiert: $pythonVersion" $SuccessColor
        return
    }
    
    Write-ColorOutput "Lade Python 3.11 herunter..." $InfoColor
    $pythonUrl = "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe"
    $pythonInstaller = "$env:TEMP\python-installer.exe"
    
    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller -UseBasicParsing
        Write-ColorOutput "Installiere Python..." $InfoColor
        
        $arguments = @(
            "/quiet",
            "InstallAllUsers=1",
            "PrependPath=1",
            "Include_test=0",
            "Include_pip=1",
            "Include_launcher=1"
        )
        
        Start-Process -FilePath $pythonInstaller -ArgumentList $arguments -Wait -NoNewWindow
        
        # PATH aktualisieren
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-ColorOutput "? Python erfolgreich installiert!" $SuccessColor
    }
    catch {
        Write-ColorOutput "? Fehler bei Python-Installation: $_" $ErrorColor
        exit 1
    }
    finally {
        Remove-Item $pythonInstaller -Force -ErrorAction SilentlyContinue
    }
}

function Install-Git {
    Write-ColorOutput "`n? Git Installation..." $InfoColor
    
    if (Test-CommandExists "git") {
        $gitVersion = git --version
        Write-ColorOutput "? Git bereits installiert: $gitVersion" $SuccessColor
        return
    }
    
    Write-ColorOutput "Lade Git herunter..." $InfoColor
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"
    $gitInstaller = "$env:TEMP\git-installer.exe"
    
    try {
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
        Write-ColorOutput "Installiere Git..." $InfoColor
        
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait -NoNewWindow
        
        # PATH aktualisieren
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-ColorOutput "? Git erfolgreich installiert!" $SuccessColor
    }
    catch {
        Write-ColorOutput "? Fehler bei Git-Installation: $_" $ErrorColor
        exit 1
    }
    finally {
        Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
    }
}

function Install-FFmpeg {
    Write-ColorOutput "`n? FFmpeg Installation..." $InfoColor
    
    if (Test-CommandExists "ffmpeg") {
        Write-ColorOutput "? FFmpeg bereits installiert" $SuccessColor
        return
    }
    
    Write-ColorOutput "Lade FFmpeg herunter..." $InfoColor
    $ffmpegUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    $ffmpegZip = "$env:TEMP\ffmpeg.zip"
    $ffmpegPath = "C:\ffmpeg"
    
    try {
        Invoke-WebRequest -Uri $ffmpegUrl -OutFile $ffmpegZip -UseBasicParsing
        Write-ColorOutput "Entpacke FFmpeg..." $InfoColor
        
        # Alte Installation entfernen
        if (Test-Path $ffmpegPath) {
            Remove-Item $ffmpegPath -Recurse -Force
        }
        
        # Entpacken
        Expand-Archive -Path $ffmpegZip -DestinationPath $ffmpegPath -Force
        
        # Unterordner finden
        $ffmpegBin = Get-ChildItem -Path $ffmpegPath -Filter "bin" -Recurse | Select-Object -First 1
        
        if ($ffmpegBin) {
            $binPath = $ffmpegBin.FullName
            
            # Zu PATH hinzuf?gen
            $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($currentPath -notlike "*$binPath*") {
                [Environment]::SetEnvironmentVariable("Path", "$currentPath;$binPath", "User")
                $env:Path += ";$binPath"
            }
            
            Write-ColorOutput "? FFmpeg erfolgreich installiert!" $SuccessColor
        }
        else {
            Write-ColorOutput "?? FFmpeg bin-Ordner nicht gefunden" $WarningColor
        }
    }
    catch {
        Write-ColorOutput "? Fehler bei FFmpeg-Installation: $_" $ErrorColor
    }
    finally {
        Remove-Item $ffmpegZip -Force -ErrorAction SilentlyContinue
    }
}

function Install-Docker {
    Write-ColorOutput "`n? Docker Desktop Installation..." $InfoColor
    
    if (Test-CommandExists "docker") {
        $dockerVersion = docker --version
        Write-ColorOutput "? Docker bereits installiert: $dockerVersion" $SuccessColor
        return
    }
    
    Write-ColorOutput "Lade Docker Desktop herunter..." $InfoColor
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $dockerInstaller = "$env:TEMP\docker-installer.exe"
    
    try {
        Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller -UseBasicParsing
        Write-ColorOutput "Installiere Docker Desktop..." $InfoColor
        
        Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet", "--accept-license" -Wait -NoNewWindow
        
        Write-ColorOutput "? Docker Desktop installiert! Neustart erforderlich." $SuccessColor
        Write-ColorOutput "?? Bitte starten Sie den Computer neu und f?hren Sie das Script erneut aus." $WarningColor
        exit 0
    }
    catch {
        Write-ColorOutput "? Fehler bei Docker-Installation: $_" $ErrorColor
        exit 1
    }
    finally {
        Remove-Item $dockerInstaller -Force -ErrorAction SilentlyContinue
    }
}

function Install-MINTutil {
    Write-ColorOutput "`n? MINTutil Installation..." $InfoColor
    
    # Verzeichnis erstellen
    if (!(Test-Path $InstallPath)) {
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
    }
    
    Set-Location $InstallPath
    
    # Repository klonen oder aktualisieren
    if (Test-Path "$InstallPath\.git") {
        Write-ColorOutput "Aktualisiere MINTutil..." $InfoColor
        git pull origin main
    }
    else {
        Write-ColorOutput "Klone MINTutil Repository..." $InfoColor
        git clone https://github.com/data-mint-research/MINTutil.git .
    }
    
    # Virtual Environment
    Write-ColorOutput "Erstelle Python Virtual Environment..." $InfoColor
    python -m venv venv
    
    # Aktivieren
    & ".\venv\Scripts\Activate.ps1"
    
    # pip upgrade
    Write-ColorOutput "Aktualisiere pip..." $InfoColor
    python -m pip install --upgrade pip
    
    # Requirements installieren
    Write-ColorOutput "Installiere Python-Pakete..." $InfoColor
    pip install -r requirements.txt
    
    # .env erstellen
    if (!(Test-Path ".env")) {
        Write-ColorOutput "Erstelle Konfigurationsdatei..." $InfoColor
        Copy-Item .env.example .env
    }
    
    Write-ColorOutput "? MINTutil erfolgreich installiert!" $SuccessColor
}

function Create-DesktopShortcut {
    Write-ColorOutput "`n? Erstelle Desktop-Verkn?pfung..." $InfoColor
    
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\MINTutil.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-NoExit -ExecutionPolicy Bypass -Command `"cd '$InstallPath'; & '.\venv\Scripts\Activate.ps1'; streamlit run streamlit_app/main.py`""
    $Shortcut.WorkingDirectory = $InstallPath
    $Shortcut.Save()
    
    Write-ColorOutput "? Desktop-Verkn?pfung erstellt!" $SuccessColor
}

function Show-Summary {
    Write-ColorOutput "`n========================================" $InfoColor
    Write-ColorOutput "       MINTutil Setup abgeschlossen!" $SuccessColor
    Write-ColorOutput "========================================" $InfoColor
    Write-ColorOutput "`nInstallationsverzeichnis: $InstallPath" $InfoColor
    Write-ColorOutput "`nStarten Sie MINTutil mit einer der folgenden Methoden:" $InfoColor
    Write-ColorOutput "1. Doppelklick auf die Desktop-Verkn?pfung" $InfoColor
    Write-ColorOutput "2. PowerShell: cd $InstallPath; .\mint.ps1 start" $InfoColor
    
    if ($UseDocker) {
        Write-ColorOutput "3. Docker: cd $InstallPath; docker-compose up" $InfoColor
    }
    
    Write-ColorOutput "`nMINTutil l?uft unter: http://localhost:8501" $SuccessColor
    Write-ColorOutput "`n? Dokumentation: https://github.com/data-mint-research/MINTutil" $InfoColor
}

# Main
Clear-Host
Write-ColorOutput @"
?????????????????????????????????????????
?       MINTutil Windows Setup          ?
?   Automatische Installation v1.0      ?
?????????????????????????????????????????
"@ $InfoColor

# Admin-Check
if (!(Test-Administrator)) {
    Write-ColorOutput "?? Dieses Script ben?tigt Administrator-Rechte!" $WarningColor
    Write-ColorOutput "Bitte als Administrator ausf?hren." $ErrorColor
    exit 1
}

# Execution Policy pr?fen
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted") {
    Write-ColorOutput "Setze Execution Policy..." $InfoColor
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

# Installationen
try {
    if ($UseDocker) {
        Install-Docker
    }
    else {
        if (!$SkipPython) { Install-Python }
        if (!$SkipGit) { Install-Git }
        if (!$SkipFFmpeg) { Install-FFmpeg }
    }
    
    Install-MINTutil
    Create-DesktopShortcut
    Show-Summary
    
    # Angebot zum direkten Start
    Write-Host "`nM?chten Sie MINTutil jetzt starten? (J/N): " -NoNewline
    $response = Read-Host
    if ($response -match '^[Jj]') {
        Set-Location $InstallPath
        & ".\venv\Scripts\Activate.ps1"
        streamlit run streamlit_app/main.py
    }
}
catch {
    Write-ColorOutput "`n? Fehler w?hrend der Installation: $_" $ErrorColor
    Write-ColorOutput "Stacktrace: $($_.ScriptStackTrace)" $ErrorColor
    exit 1
}
