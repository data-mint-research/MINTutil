# NeoMINT Coding Practices - Abweichungen

## Zweck
Diese Datei dokumentiert alle bewussten Abweichungen von den NeoMINT Coding Practices im MINTutil-Projekt.
Jede Abweichung muss begr?ndet werden und sollte tempor?r sein.

## Aktuelle Abweichungen

### 1. README.md im Root-Verzeichnis
**Regel**: Keine verteilten README.md ? alles unter /docs/
**Abweichung**: README.md existiert im Root-Verzeichnis
**Begr?ndung**: GitHub und die meisten Git-Plattformen erwarten eine README.md im Root f?r die Projekt-?bersicht
**Ma?nahme**: README.md im Root belassen, aber alle anderen Dokumentationen in /docs/ pflegen
**Status**: ?? Dauerhaft (Platform-Anforderung)

### 2. ?berschreitung der 500 LOC Grenze
**Regel**: Maximale L?nge pro Einheit: 500 LOC
**Betroffene Dateien**: 
- scripts/setup_windows.ps1 (516 Zeilen)
- scripts/start_ui.ps1 (502 Zeilen) 
- scripts/update.ps1 (564 Zeilen)
**Begr?ndung**: Komplexe Installations- und Setup-Routinen
**Ma?nahme**: Refactoring in Module geplant f?r v0.2.0
**Status**: ? In Bearbeitung
**Update 2025-06-16**: init_project.ps1 wurde erfolgreich in Module aufgeteilt

### 3. Encoding-Probleme
**Regel**: ASCII-konforme Namen und Code
**Abweichung**: Umlaute in einigen PowerShell-Skripten
**Begr?ndung**: Historisch gewachsen, deutsche Dokumentation
**Ma?nahme**: Schrittweise Bereinigung
**Status**: ? Teilweise behoben
**Update 2025-06-16**: 
- ? mint.ps1 bereinigt
- ? health_check.ps1 bereinigt
- ? init_project Module bereinigt
- Weitere Dateien folgen

### 4. Dateinamen nicht in kebab-case
**Regel**: kebab-case f?r Dateien
**Betroffene Dateien**:
- HEALTH_CHECK_MODULES.md
- CODE_REVIEW_FIXES.md
- INSTALLATION_WINDOWS.md
- QUICK_START.md
- Dockerfile
- LICENSE
**Begr?ndung**: 
- Gro?buchstaben f?r Markdown-Dateien erh?hen Sichtbarkeit
- Dockerfile und LICENSE sind Industriestandards
**Ma?nahme**: Markdown-Dateien schrittweise umbenennen
**Status**: ? Geplant

### 5. Fehlende Header in einigen PS1-Dateien
**Regel**: Jede .ps1 enth?lt Header mit Zweck, Autor, Datum
**Betroffene Dateien**: Mehrere Skripte in scripts/
**Begr?ndung**: Zeitdruck bei initialer Entwicklung
**Ma?nahme**: Header werden nachgetragen
**Status**: ? In Bearbeitung
**Update 2025-06-16**:
- ? mint.ps1 hat vollst?ndigen Header
- ? health_check.ps1 hat vollst?ndigen Header
- ? Alle init-project Module haben Header
- ? check-neomint-compliance.ps1 hat Header

## Historie der Abweichungen

### 2025-06-16
- Initiale Dokumentation der Abweichungen erstellt
- Analyse des bestehenden Codes durchgef?hrt
- mint.ps1 von Umlauten bereinigt und Header erg?nzt
- NeoMINT Compliance Checker implementiert
- GitHub Action f?r automatische Pr?fung hinzugef?gt
- health_check.ps1 bereinigt und Header erg?nzt
- init_project.ps1 in konforme Module aufgeteilt:
  - init-project-main.ps1 (147 LOC)
  - init-project-validation.ps1 (204 LOC)
  - init-project-setup.ps1 (349 LOC)
  - init_project.ps1 als schlanker Wrapper (41 LOC)

## Prozess f?r neue Abweichungen

1. Abweichung in diesem Dokument dokumentieren
2. Begr?ndung und geplante Ma?nahme angeben
3. Im Code mit Kommentar markieren: `# ABWEICHUNG: siehe /docs/abweichungen.md`
4. Review durch Team
5. Zeitplan f?r Behebung festlegen

## Automatische Pr?fung

Das Projekt verwendet folgende Tools zur Compliance-Pr?fung:
- `scripts/check-neomint-compliance.ps1` - Lokale Pr?fung
- GitHub Action `.github/workflows/neomint-compliance.yml` - CI/CD Integration

F?hren Sie vor jedem Commit aus:
```powershell
.\scripts\check-neomint-compliance.ps1
```

## Fortschritt

### Bereits konform:
- ? Zentrale Logging-Funktion (Write-Log)
- ? Dokumentation unter /docs/
- ? Sicherheitsrichtlinien
- ? Versionskontrolle
- ? KI-Kompatibilit?t
- ? mint.ps1 (Hauptdatei)
- ? health_check.ps1
- ? init_project.ps1 (modularisiert)
- ? Compliance-Checker

### Noch zu erledigen:
- ? setup_windows.ps1 (516 LOC) - Modularisierung
- ? start_ui.ps1 (502 LOC) - Modularisierung
- ? update.ps1 (564 LOC) - Modularisierung
- ? Umlaute in weiteren Dateien entfernen
- ? Header in allen PS1-Dateien erg?nzen
- ? Dateinamen-Konventionen angleichen

## Kontakt

Bei Fragen zu den Standards oder Abweichungen:
- Issue im Repository erstellen
- Tag: `neomint-compliance`
