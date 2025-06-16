# MINTutil

![Python](https://img.shields.io/badge/python-3.9+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Status](https://img.shields.io/badge/status-active-success.svg)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)

? **MINTutil** - Modulare, intelligente Netzwerk-Tools f?r Utility und Analyse

## ? Installation in 30 Sekunden

?ffnen Sie **PowerShell als Administrator** und f?hren Sie aus:

```powershell
irm https://raw.githubusercontent.com/data-mint-research/MINTutil/main/scripts/setup_windows.ps1 | iex
```

Das war's! ? Das Setup-Script installiert automatisch alle Abh?ngigkeiten und startet MINTutil.

> **Hinweis**: F?r Linux/macOS oder erweiterte Installationsoptionen siehe [Erweiterte Installation](#-erweiterte-installation).

## ? Was wird installiert?

Das automatische Setup installiert:
- ? Python 3.11 (falls nicht vorhanden)
- ? Git (falls nicht vorhanden)
- ? FFmpeg (f?r Transkriptionen)
- ? Alle Python-Abh?ngigkeiten
- ? MINTutil nach `C:\MINTutil`
- ? Desktop-Verkn?pfung

## ? ?bersicht

MINTutil ist eine modulare Plattform f?r verschiedene Analyse- und Verarbeitungstools mit optionaler KI-Integration. Das System bietet eine einheitliche Streamlit-basierte Benutzeroberfl?che f?r alle Tools.

## ? Features

- **? Ein-Klick-Installation**: Vollautomatisches Setup f?r Windows
- **? Modulare Architektur**: Einfaches Hinzuf?gen neuer Tools
- **? KI-Integration**: Optionale Unterst?tzung durch Ollama
- **? Web-Interface**: Moderne Streamlit-UI
- **? Lokale Verarbeitung**: Ihre Daten bleiben bei Ihnen
- **?? Vielseitige Tools**: Von Transkription bis Datenanalyse
- **? Docker-Support**: Einfaches Deployment

## ? Erste Schritte nach der Installation

1. **MINTutil starten**:
   - Doppelklick auf die Desktop-Verkn?pfung, oder
   - PowerShell: `C:\MINTutil\mint.ps1 start`

2. **Browser ?ffnet sich automatisch** bei `http://localhost:8501`

3. **Tool ausw?hlen** aus der Sidebar und loslegen!

## ?? Verf?gbare Tools

### ?? Transkription
- YouTube-Videos transkribieren mit OpenAI Whisper
- Lokale Audio/Video-Dateien verarbeiten
- Automatische Namenskorrektur mit Glossar
- Export als Markdown

### ? Weitere Tools (in Entwicklung)
- Datenanalyse und Visualisierung
- Netzwerk-Utilities
- API-Testing Tools
- Und mehr...

## ? Sicherheitshinweis

**WICHTIG**: Die `.env` Datei enth?lt sensible Daten und darf **niemals** ins Repository committed werden!

Nach der Installation:
```powershell
# Konfiguration anpassen
notepad C:\MINTutil\.env
```

## ? Erweiterte Installation

<details>
<summary>? Linux/macOS Installation</summary>

```bash
# Automatisches Setup-Script (in Entwicklung)
curl -sSL https://raw.githubusercontent.com/data-mint-research/MINTutil/main/scripts/setup_unix.sh | bash

# Oder manuell:
git clone https://github.com/data-mint-research/MINTutil.git
cd MINTutil
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
streamlit run streamlit_app/main.py
```
</details>

<details>
<summary>? Docker Installation</summary>

```bash
# Mit Docker Compose
git clone https://github.com/data-mint-research/MINTutil.git
cd MINTutil
docker-compose up -d

# Oder mit dem Setup-Script
irm https://raw.githubusercontent.com/data-mint-research/MINTutil/main/scripts/setup_windows.ps1 | iex -UseDocker
```
</details>

<details>
<summary>??? Entwickler-Installation</summary>

```bash
# Repository klonen
git clone https://github.com/data-mint-research/MINTutil.git
cd MINTutil

# Development-Umgebung
python -m venv venv
.\venv\Scripts\Activate.ps1  # Windows
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Pre-commit hooks
pre-commit install
```
</details>

## ?? Projektstruktur

```
MINTutil/
??? streamlit_app/      # Haupt-UI Anwendung
??? tools/              # Modulare Tools
?   ??? transkription/  # Transkriptions-Tool
??? scripts/            # Setup & Utility-Scripts
??? config/             # Konfigurationsdateien
??? tests/              # Test-Suite
??? docs/               # Dokumentation
```

## ? Entwicklung

### Neues Tool hinzuf?gen

1. Erstellen Sie einen Ordner unter `tools/`
2. Implementieren Sie `tool.meta.yaml` mit Metadaten
3. Erstellen Sie `ui.py` mit `render()` Funktion
4. Tool erscheint automatisch in der UI

Beispiel-Struktur:
```
tools/
??? mein_tool/
    ??? tool.meta.yaml
    ??? ui.py
    ??? scripts/
```

### Tests ausf?hren
```bash
pytest tests/ -v
```

### Code-Qualit?t
```bash
# Formatierung
black .

# Linting
flake8 .
pylint streamlit_app tools
```

## ? Fehlerbehebung

### Automatisches Setup schl?gt fehl
```powershell
# Manuell einzelne Komponenten installieren
.\scripts\setup_windows.ps1 -SkipPython  # Wenn Python schon installiert
.\scripts\setup_windows.ps1 -SkipGit     # Wenn Git schon installiert
```

### Health Check ausf?hren
```powershell
C:\MINTutil\mint.ps1 doctor
```

### Logs pr?fen
```powershell
Get-Content C:\MINTutil\logs\mintutil-cli.log -Tail 50
```

### H?ufige Probleme

<details>
<summary>Port 8501 bereits belegt</summary>

```powershell
# Prozess finden
netstat -ano | findstr :8501

# In .env anderen Port setzen
STREAMLIT_SERVER_PORT=8502
```
</details>

<details>
<summary>Module nicht gefunden</summary>

```powershell
# Virtual Environment aktivieren
C:\MINTutil\venv\Scripts\Activate.ps1

# Requirements neu installieren
pip install -r requirements.txt --force-reinstall
```
</details>

## ? Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe [LICENSE](LICENSE) Datei f?r Details.

Copyright ? 2025 MINT-RESEARCH

## ? Beitr?ge

Beitr?ge sind willkommen! Bitte beachten Sie:

1. Forken Sie das Repository
2. Erstellen Sie einen Feature-Branch (`git checkout -b feature/AmazingFeature`)
3. Committen Sie Ihre ?nderungen (`git commit -m 'Add some AmazingFeature'`)
4. Pushen Sie zum Branch (`git push origin feature/AmazingFeature`)
5. ?ffnen Sie einen Pull Request

## ? Support

- ? Email: mint-research@neomint.com
- ? Discord: [MINTutil Community](https://discord.gg/mintutil)
- ? Wiki: [GitHub Wiki](https://github.com/data-mint-research/MINTutil/wiki)
- ? Issues: [GitHub Issues](https://github.com/data-mint-research/MINTutil/issues)

---

<p align="center">
  <strong>MINTutil</strong> - Made with ?? by MINT-RESEARCH<br>
  <sub>Stern ? uns auf GitHub wenn es dir gef?llt!</sub>
</p>
