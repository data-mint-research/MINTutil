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

### 2. ?berschreitung der 500 LOC Grenze
**Regel**: Maximale L?nge pro Einheit: 500 LOC
**Betroffene Dateien**: Keine (aktuell eingehalten)
**Status**: ? Keine Abweichung

### 3. Encoding-Probleme
**Regel**: ASCII-konforme Namen und Code
**Abweichung**: Umlaute in Kommentaren und Strings
**Begr?ndung**: Historisch gewachsen, deutsche Dokumentation
**Ma?nahme**: Schrittweise Bereinigung geplant

## Historie der Abweichungen

### 2025-06-16
- Initiale Dokumentation der Abweichungen erstellt
- Analyse des bestehenden Codes durchgef?hrt

## Prozess f?r neue Abweichungen

1. Abweichung in diesem Dokument dokumentieren
2. Begr?ndung und geplante Ma?nahme angeben
3. Im Code mit Kommentar markieren: `# ABWEICHUNG: siehe /docs/abweichungen.md`
4. Review durch Team
5. Zeitplan f?r Behebung festlegen
