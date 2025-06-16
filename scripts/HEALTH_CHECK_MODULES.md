# Health Check Module Dokumentation

Die Health Check Funktionalit?t wurde in mehrere Module aufgeteilt f?r bessere Wartbarkeit und ?bersichtlichkeit.

## Module

### health_check.ps1 (Hauptskript)
- Haupteinstiegspunkt f?r alle Health Checks
- L?dt die anderen Module
- Koordiniert die Ausf?hrung der Tests
- Generiert Reports und Zusammenfassungen

### health_check_logging.ps1
- Zentrale Logging-Funktionen
- Konsolen- und Datei-Ausgabe
- Farbcodierte Ausgaben
- Legacy-Kompatibilit?t (Add-Issue, Add-Warning, Add-Info)

### health_check_requirements.ps1
- Python-Umgebung pr?fen (Version, pip, venv)
- Git-Installation und Repository-Status
- Docker-Verf?gbarkeit (optional)
- Ollama-Installation und Service (mit AutoFix)
- Python-Dependencies pr?fen

### health_check_environment.ps1
- Port-Verf?gbarkeit (8501, 8000, 11434)
- .env-Datei Validierung
- Verzeichnisstruktur pr?fen
- Internet-Verbindung testen

## Neue Features (Prompt 2.1)

1. **Fehlerbehandlung & Exit-Codes**
   - 0 = Erfolg
   - 1 = Fehler
   - 2 = Kritische Fehler

2. **Logging-Mechanismus**
   - Zentrale Log-Datei: `logs/mintutil-cli.log`
   - Format: `[TIMESTAMP] [HEALTH_CHECK] [LEVEL] <Nachricht>`

3. **AutoFix-Modus**
   - Parameter `-AutoFix` oder `-Fix`
   - Automatische Ollama-Installation
   - .env aus Template erstellen
   - Fehlende Verzeichnisse anlegen

4. **Silent-Modus**
   - Parameter `-Silent`
   - Keine Konsolen-Ausgabe
   - Nur Logging in Datei

5. **Erweiterte Checks**
   - Ollama Service Auto-Start
   - Port-Prozess-Identifikation
   - Template-basierte .env-Erg?nzung

## Verwendung

```powershell
# Quick Check (Standard)
.\scripts\health_check.ps1

# Vollst?ndiger Check
.\scripts\health_check.ps1 -Mode full

# Mit automatischen Korrekturen
.\scripts\health_check.ps1 -AutoFix

# Silent mit Export
.\scripts\health_check.ps1 -Silent -Export

# Nur Netzwerk-Checks
.\scripts\health_check.ps1 -Mode network
```

## Kompatibilit?t

Alle Legacy-Funktionen wurden beibehalten f?r R?ckw?rtskompatibilit?t:
- Test-SystemInfo
- Test-CoreRequirements
- Test-Configuration
- Test-Dependencies
- Test-Network
- Test-Logs
- Show-Report
- Export-Report
- Invoke-AutoFix