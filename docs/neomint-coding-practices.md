# LLM Digest ? NeoMINT Coding Practices (v0.1)

Diese Regeln gelten uneingeschr?nkt f?r alle Codeeinheiten, die du generierst, pr?fst oder verarbeitest:

---

## 1. Struktur & Granularit?t
- Jede Datei oder Funktion erf?llt genau **eine Aufgabe** (SRP)
- Maximale L?nge pro Einheit: **500 LOC** (LLM-kompatibel)
- Logik, UI, Konfiguration sind **modular getrennt**
- Kein globaler Zustand, keine impliziten Abh?ngigkeiten

---

## 2. Benennung
- Namen sind **sprechend**, konsistent und ASCII-konform
- `PascalCase` f?r Funktionen (z. B. `StartSessionLog`)
- `camelCase` f?r Variablen (z. B. `$userName`)
- `kebab-case` f?r Dateien (z. B. `install-vscode.ps1`)
- Keine Leerzeichen, Umlaute, Emojis oder Sonderzeichen

---

## 3. Logging & Fehler
- Nur eine zentrale Logging-Funktion (z. B. `Write-Log`)
- Neue Logs bei jeder Session, Zeitstempel im Namen
- Fehler via `try/catch`, klar unterscheidbar (`WARNING` vs `ERROR`)
- Keine stillen Fehlerbehandlungen

---

## 4. Dokumentation & Kommentare
- Kommentare erkl?ren **Absicht**, nicht Syntax
- Jede `.ps1` enth?lt Header mit Zweck, Autor, Datum
- Keine verteilten `README.md` ? alles unter `/docs/`
- Abweichungen **immer doppelt dokumentiert** (im Code + in `/docs/abweichungen.md`)

---

## 5. Sicherheit
- OWASP + CIS Benchmark pr?fen **vor Implementierung**
- Keine sicherheitsrelevanten Workarounds
- Logs enthalten **nie** Tokens oder Passw?rter
- Sicherheitsentscheidungen dokumentieren ? aber immer mit Produktivit?tsabw?gung

---

## 6. Versionskontrolle
- Nur funktionierender Code wird committed
- Tempor?re Branches m?ssen erkennbar sein (`temp/debug-*`)
- Niemals Secrets in Repos
- `.gitignore` sch?tzt gezielt, aber blockiert keine Entwicklungsarbeit

---

## 7. Verhalten
- Entwickler:innen tragen Verantwortung f?r Verst?ndlichkeit
- Jeder `TODO` ist konkret, sichtbar und umsetzbar
- Wenn du eine Regel brichst: **begr?nde sie sichtbar und schriftlich**

---

## 8. KI-Kompatibilit?t
- Du arbeitest f?r Menschen **und** Maschinen
- Schreibe alles so, dass andere LLMs es analysieren, modifizieren und korrekt fortf?hren k?nnen
- Wiederhole keine Information, aber strukturiere sie so, dass sie **vollst?ndig** lesbar ist

---

## Umsetzung im MINTutil-Projekt

### Pr?fpunkte f?r Code-Reviews
1. **Dateil?nge**: Keine Datei ?ber 500 LOC
2. **Funktionsnamen**: Alle PowerShell-Funktionen in PascalCase
3. **Variablennamen**: Alle Variablen in camelCase
4. **Dateinamen**: Alle Dateien in kebab-case (Ausnahme: README.md)
5. **ASCII**: Keine Umlaute oder Sonderzeichen im Code
6. **Logging**: Verwendung der zentralen Write-Log Funktion
7. **Header**: Jede .ps1 Datei hat vollst?ndigen Header
8. **TODOs**: Alle TODOs sind konkret und nachvollziehbar

### Tools zur ?berpr?fung
- `scripts/check-neomint-compliance.ps1` - Automatische ?berpr?fung
- `docs/abweichungen.md` - Dokumentierte Ausnahmen
- GitHub Actions f?r automatische Validierung

### Bei Fragen oder Unklarheiten
- Issue im Repository erstellen
- Team-Meeting einberufen
- Dokumentation erweitern
