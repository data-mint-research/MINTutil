# MINTutil

![Python](https://img.shields.io/badge/python-3.9+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Status](https://img.shields.io/badge/status-development-yellow.svg)

? **MINTutil** - Modulare, intelligente Netzwerk-Tools f?r Utility und Analyse

## ?? WICHTIGER SICHERHEITSHINWEIS

**NIEMALS** die `.env` Datei ins Repository committen! Diese enth?lt sensible Konfigurationsdaten wie API-Keys und Passw?rter.

### Erste Einrichtung:
```bash
# Kopieren Sie die Beispiel-Konfiguration
cp .env.example .env

# Bearbeiten Sie die .env mit Ihren eigenen Werten
# WICHTIG: Ersetzen Sie alle Platzhalter-Werte!
```

### Falls Sie versehentlich Secrets committed haben:
1. ?ndern Sie SOFORT alle betroffenen API-Keys und Passw?rter
2. Entfernen Sie die Datei aus der Git-Historie (siehe unten)
3. F?gen Sie die Datei zu .gitignore hinzu

### Git-Historie bereinigen:
```bash
# WARNUNG: Dies ?ndert die Git-Historie!
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (koordinieren Sie sich mit anderen Entwicklern!)
git push origin --force --all
```

## ? ?bersicht

MINTutil ist eine modulare Plattform f?r verschiedene Analyse- und Verarbeitungstools mit optionaler KI-Integration. Das System bietet eine einheitliche Streamlit-basierte Benutzeroberfl?che f?r alle Tools.

## ? Features

- **? Modulare Architektur**: Einfaches Hinzuf?gen neuer Tools
- **? KI-Integration**: Optionale Unterst?tzung durch Ollama
- **? Web-Interface**: Moderne Streamlit-UI
- **? Lokale Verarbeitung**: Ihre Daten bleiben bei Ihnen
- **? Vielseitige Tools**: Von Transkription bis Datenanalyse
- **? Docker-Support**: Einfaches Deployment

## ? Schnellstart

### Voraussetzungen

- Python 3.9 oder h?her
- PowerShell 5.1+ (Windows) oder bash (Linux/Mac)
- Git
- Optional: Docker & Docker Compose

### Installation

1. **Repository klonen**
   ```bash
   git clone https://github.com/data-mint-research/MINTutil.git
   cd MINTutil
   ```

2. **Umgebung einrichten**
   ```bash
   # Windows
   .\mint.ps1 init
   
   # Linux/Mac
   ./mint.sh init
   ```

3. **Konfiguration anpassen**
   ```bash
   cp .env.example .env
   # Bearbeiten Sie .env mit Ihren Einstellungen
   ```

4. **Anwendung starten**
   ```bash
   # Windows
   .\mint.ps1 start
   
   # Linux/Mac
   ./mint.sh start
   ```

5. **Browser ?ffnen**
   
   Navigieren Sie zu: `http://localhost:8501`

## ? Verf?gbare Tools

### ? Transkription
- YouTube-Videos transkribieren
- Lokale Audio/Video-Dateien verarbeiten
- Automatische Textnachbearbeitung

### ? Datenanalyse (geplant)
- CSV/Excel-Verarbeitung
- Datenvisualisierung
- Statistische Auswertungen

### ? Weitere Tools
- Erweiterbar durch Plugin-System
- Eigene Tools einfach integrierbar

## ? Projektstruktur

```
MINTutil/
??? streamlit_app/      # Haupt-UI Anwendung
??? tools/              # Modulare Tools
?   ??? transkription/  # Transkriptions-Tool
??? scripts/            # Utility-Scripts
??? config/             # Konfigurationsdateien
??? tests/              # Test-Suite
??? docs/               # Dokumentation
```

## ? Verwendung

### Health Check durchf?hren
```bash
# Vollst?ndiger System-Check
.\mint.ps1 check

# Nur bestimmte Bereiche pr?fen
.\mint.ps1 check -Mode minimal
```

### Logs anzeigen
```bash
# Aktuelle Logs
.\mint.ps1 logs

# Logs verfolgen
.\mint.ps1 logs -f
```

### Docker-Deployment
```bash
# Container erstellen und starten
docker-compose up -d

# Status pr?fen
docker-compose ps

# Logs anzeigen
docker-compose logs -f
```

## ? Entwicklung

### Neues Tool hinzuf?gen

1. Erstellen Sie einen Ordner unter `tools/`
2. Implementieren Sie `__init__.py` mit Tool-Metadaten
3. Erstellen Sie `ui.py` mit Streamlit-Interface
4. Registrierung erfolgt automatisch

### Tests ausf?hren
```bash
python -m pytest tests/
```

### Code-Stil
```bash
# Formatierung pr?fen
black --check .

# Linting
pylint streamlit_app tools
```

## ? Konfiguration

### Umgebungsvariablen (.env)

```env
# Basis-Konfiguration
APP_NAME=MINTutil
APP_VERSION=0.1.0
ENVIRONMENT=development

# Streamlit
STREAMLIT_SERVER_PORT=8501
STREAMLIT_SERVER_ADDRESS=0.0.0.0

# KI-Features (optional)
ENABLE_AI_FEATURES=false
OLLAMA_BASE_URL=http://localhost:11434
```

## ? Fehlerbehebung

### H?ufige Probleme

1. **Port bereits belegt**
   ```bash
   # Windows: Prozess finden
   netstat -ano | findstr :8501
   
   # Prozess beenden oder anderen Port in .env setzen
   ```

2. **Module nicht gefunden**
   ```bash
   # Virtuelle Umgebung aktivieren
   .\venv\Scripts\Activate.ps1
   
   # Requirements neu installieren
   pip install -r requirements.txt
   ```

3. **Encoding-Probleme**
   - Stelle sicher, dass alle Dateien UTF-8 kodiert sind
   - Verwende `chcp 65001` in der Windows-Konsole

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
- ? Dokumentation: [docs.mintutil.dev](https://docs.mintutil.dev)

---

<p align="center">
  Made with ?? by MINT-RESEARCH
</p>
