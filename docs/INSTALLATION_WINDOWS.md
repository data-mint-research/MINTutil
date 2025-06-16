# MINTutil Installation Guide - Von Null auf Hundert

Diese Anleitung zeigt Ihnen, wie Sie MINTutil auf einem Windows-System installieren, auf dem nur PowerShell vorhanden ist.

## ? Voraussetzungen

- Windows 10/11 mit PowerShell 5.1 oder h?her
- Administratorrechte (f?r einige Installationen)
- Internetverbindung

## ? Schnellstart (Automatisiert)

?ffnen Sie PowerShell als Administrator und f?hren Sie aus:

```powershell
# Standard-Installation
irm https://raw.githubusercontent.com/data-mint-research/MINTutil/main/scripts/setup_windows.ps1 | iex

# Mit Chocolatey (empfohlen f?r einfachere Updates)
irm https://raw.githubusercontent.com/data-mint-research/MINTutil/main/scripts/setup_windows.ps1 | iex -UseChocolatey
```

## ? Was ist Chocolatey?

[Chocolatey](https://chocolatey.org/) ist ein Package Manager f?r Windows (wie apt-get f?r Linux). Das Setup-Script kann Chocolatey automatisch installieren und nutzen, was folgende Vorteile bietet:

- ? Einfachere Installation von Software
- ? Automatische Updates mit `choco upgrade all`
- ? ?ber 8000 verf?gbare Pakete
- ? Keine manuelle Suche nach Download-Links

### Chocolatey-Installation erzwingen:
```powershell
# Installiert definitiv Chocolatey und nutzt es f?r alle Pakete
.\scripts\setup_windows.ps1 -ForceChocolatey
```

## ? Manuelle Installation (Schritt f?r Schritt)

### 1. Python installieren

#### Option A: Mit Chocolatey (empfohlen)
```powershell
# Chocolatey installieren (falls noch nicht vorhanden)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Python installieren
choco install python311 -y
```

#### Option B: ?ber Microsoft Store
1. ?ffnen Sie PowerShell
2. Geben Sie ein: `python`
3. Windows ?ffnet automatisch den Microsoft Store
4. Klicken Sie auf "Installieren" bei Python 3.11

#### Option C: Manueller Download
```powershell
# Python Installer herunterladen
Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe" -OutFile "$env:TEMP\python-installer.exe"

# Installation starten (Silent Install)
Start-Process -FilePath "$env:TEMP\python-installer.exe" -ArgumentList "/quiet", "PrependPath=1" -Wait

# PowerShell neu starten nach Installation
```

### 2. Git installieren

#### Mit Chocolatey:
```powershell
choco install git -y
```

#### Manuell:
```powershell
# Git Installer herunterladen
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe" -OutFile "$env:TEMP\git-installer.exe"

# Installation starten
Start-Process -FilePath "$env:TEMP\git-installer.exe" -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
```

### 3. FFmpeg installieren (f?r Transkription)

#### Mit Chocolatey:
```powershell
choco install ffmpeg -y
```

#### Manuell:
```powershell
# FFmpeg herunterladen
Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile "$env:TEMP\ffmpeg.zip"

# Entpacken
Expand-Archive -Path "$env:TEMP\ffmpeg.zip" -DestinationPath "C:\ffmpeg" -Force

# Zu PATH hinzuf?gen
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\ffmpeg\ffmpeg-6.1-essentials_build\bin", [EnvironmentVariableTarget]::User)
```

### 4. MINTutil herunterladen und installieren

```powershell
# Arbeitsverzeichnis erstellen
New-Item -Path "C:\MINTutil" -ItemType Directory -Force
Set-Location "C:\MINTutil"

# Repository klonen
git clone https://github.com/data-mint-research/MINTutil.git .

# Python Virtual Environment erstellen
python -m venv venv

# Virtual Environment aktivieren
.\venv\Scripts\Activate.ps1

# Abh?ngigkeiten installieren
pip install --upgrade pip
pip install -r requirements.txt
```

### 5. Konfiguration

```powershell
# .env Datei erstellen
Copy-Item .env.example .env

# .env Datei bearbeiten (?ffnet in Notepad)
notepad .env
```

### 6. MINTutil starten

```powershell
# Virtual Environment aktivieren (falls nicht aktiv)
.\venv\Scripts\Activate.ps1

# MINTutil starten
streamlit run streamlit_app/main.py
```

## ? Alternative: Docker Installation

Falls Sie Docker bevorzugen:

### 1. Docker Desktop mit Chocolatey installieren

```powershell
# Chocolatey installieren (falls nicht vorhanden)
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Docker Desktop installieren
choco install docker-desktop -y

# Neustart erforderlich!
Restart-Computer
```

### 2. MINTutil mit Docker starten

```powershell
# Nach Neustart
cd C:\MINTutil
docker-compose up -d
```

## ? Fehlerbehebung

### Python wird nicht gefunden
```powershell
# PATH manuell aktualisieren
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Python-Pfad ?berpr?fen
where.exe python

# Oder mit Chocolatey neu installieren
choco install python311 -y --force
refreshenv
```

### Execution Policy Fehler
```powershell
# Als Administrator ausf?hren
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### pip nicht gefunden
```powershell
# pip manuell installieren
python -m ensurepip --upgrade

# Oder Python mit Chocolatey neu installieren
choco install python311 -y --force
```

### SSL-Zertifikatsfehler
```powershell
# Trusted hosts hinzuf?gen
pip config set global.trusted-host "pypi.org files.pythonhosted.org"
```

### Chocolatey-Probleme
```powershell
# Chocolatey neu installieren
Remove-Item -Path "$env:ChocolateyInstall" -Recurse -Force
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Installierte Pakete anzeigen
choco list --local-only

# Alle Pakete updaten
choco upgrade all -y
```

## ? Verifikation

Nach erfolgreicher Installation:

```powershell
# Versionen pr?fen
python --version     # Sollte Python 3.11.x zeigen
pip --version        # Sollte pip 23.x zeigen
git --version        # Sollte git version 2.x zeigen
ffmpeg -version      # Sollte ffmpeg version zeigen
choco --version      # Sollte Chocolatey version zeigen (falls installiert)

# MINTutil testen
.\mint.ps1 doctor
```

## ? Desktop-Verkn?pfung erstellen

```powershell
# PowerShell-Script f?r Desktop-Verkn?pfung
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\MINTutil.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-NoExit -Command `"cd C:\MINTutil; .\venv\Scripts\Activate.ps1; streamlit run streamlit_app/main.py`""
$Shortcut.WorkingDirectory = "C:\MINTutil"
$Shortcut.IconLocation = "C:\MINTutil\assets\icon.ico"
$Shortcut.Save()
```

## ? N?tzliche Chocolatey-Befehle

Nach der Installation von Chocolatey k?nnen Sie weitere Software einfach installieren:

```powershell
# Weitere n?tzliche Tools
choco install vscode -y           # Visual Studio Code
choco install notepadplusplus -y  # Notepad++
choco install 7zip -y             # 7-Zip
choco install vlc -y              # VLC Media Player

# Alle installierten Pakete updaten
choco upgrade all -y

# Paket suchen
choco search <paketname>

# Paket-Info anzeigen
choco info <paketname>
```

## ? Support

Bei Problemen:
1. ?berpr?fen Sie die Logs: `C:\MINTutil\logs\`
2. F?hren Sie aus: `.\mint.ps1 doctor`
3. Erstellen Sie ein Issue auf GitHub

## ? Fertig!

MINTutil sollte jetzt unter http://localhost:8501 verf?gbar sein.

**Tipp**: Mit Chocolatey installierte Software kann jederzeit mit `choco upgrade all -y` aktualisiert werden!
