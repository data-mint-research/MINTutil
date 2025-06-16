# MINTutil Quick Start Guide

## ? 30-Sekunden-Installation f?r Windows

### Der schnellste Weg zu MINTutil:

1. **PowerShell als Administrator ?ffnen**
   - Windows-Taste dr?cken
   - "PowerShell" eingeben
   - Rechtsklick ? "Als Administrator ausf?hren"

2. **Diesen Befehl kopieren und einf?gen:**
   ```powershell
   irm https://raw.githubusercontent.com/data-mint-research/MINTutil/main/scripts/setup_windows.ps1 | iex
   ```

3. **Enter dr?cken und zur?cklehnen!** ?

Das automatische Setup erledigt alles f?r Sie:
- ? Installiert Python (falls ben?tigt)
- ? Installiert Git (falls ben?tigt)
- ? Installiert FFmpeg f?r Transkriptionen
- ? L?dt MINTutil herunter
- ? Installiert alle Abh?ngigkeiten
- ? Erstellt eine Desktop-Verkn?pfung
- ? Startet MINTutil automatisch

## ? Nach der Installation

- **Desktop-Verkn?pfung**: Doppelklick auf "MINTutil" auf Ihrem Desktop
- **Browser**: ?ffnet sich automatisch bei `http://localhost:8501`
- **Installationsort**: `C:\MINTutil`

## ? H?ufige Fragen

### "Ich bekomme eine Sicherheitswarnung"
Das ist normal bei PowerShell-Scripts. Das Script ist sicher und Open Source. Falls Windows Defender warnt:
1. Klicken Sie auf "Weitere Informationen"
2. Dann auf "Trotzdem ausf?hren"

### "Die Installation schl?gt fehl"
Stellen Sie sicher, dass:
- PowerShell als Administrator l?uft
- Sie eine Internetverbindung haben
- Windows Defender das Script nicht blockiert

### "Ich habe bereits Python/Git installiert"
Kein Problem! Das Setup-Script erkennt das und ?berspringt diese Schritte automatisch.

## ? Alternative Installationsmethoden

### F?r erfahrene Nutzer:
```powershell
# Mit spezifischen Optionen
.\scripts\setup_windows.ps1 -InstallPath "D:\Tools\MINTutil" -SkipFFmpeg
```

### Mit Docker:
```powershell
# Docker-basierte Installation
irm https://raw.githubusercontent.com/data-mint-research/MINTutil/main/scripts/setup_windows.ps1 | iex -UseDocker
```

## ? Weitere Dokumentation

- [Vollst?ndige Windows-Installationsanleitung](INSTALLATION_WINDOWS.md)
- [Linux/macOS Installation](INSTALLATION_UNIX.md)
- [Docker Deployment](DOCKER_GUIDE.md)
- [Entwickler-Dokumentation](DEVELOPMENT.md)

## ? Hilfe

Wenn etwas nicht funktioniert:
1. F?hren Sie den Health Check aus: `C:\MINTutil\mint.ps1 doctor`
2. Schauen Sie in die Logs: `C:\MINTutil\logs\`
3. Erstellen Sie ein [GitHub Issue](https://github.com/data-mint-research/MINTutil/issues)

---

**MINTutil** - Die einfachste Art, leistungsstarke Tools zu nutzen! ?
