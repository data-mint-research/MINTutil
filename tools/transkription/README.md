# YouTube Transkription Tool

Ein lokales Tool zur Transkription von YouTube-Videos mit OpenAI Whisper und automatischer Namenskorrektur.

## Features

- ? Automatischer Download von YouTube-Videos (nur Audio)
- ?? Transkription mit OpenAI Whisper (verschiedene Modellgr??en)
- ? Glossar-basierte Korrektur von Namen und Begriffen
- ? Export als formatiertes Markdown
- ? Optional: Container-basierte Ausf?hrung mit Docker
- ? Vollst?ndig lokal - keine Daten verlassen Ihr System

## Verzeichnisstruktur

```
tools/transkription/
??? ui.py                  # Streamlit UI
??? scripts/
?   ??? transcribe.py      # YouTube Download & Whisper
?   ??? fix_names.py       # Glossar-Korrektur
?   ??? postprocess.py     # Markdown-Export
??? containers/
?   ??? yt-dlp.Dockerfile
?   ??? whisper.Dockerfile
??? config/
?   ??? glossar.json       # Korrektur-W?rterbuch
??? data/
?   ??? raw/              # Original-Transkripte
?   ??? fixed/            # Korrigierte Markdown-Dateien
?   ??? audio/            # Heruntergeladene Audio-Dateien
??? logs/
    ??? transkription.log
```

## Verwendung

### ?ber MINTutil GUI

1. Starten Sie MINTutil: `streamlit run streamlit_app/main.py`
2. W?hlen Sie "YouTube Transkription" aus der Sidebar
3. Geben Sie eine YouTube-URL ein
4. W?hlen Sie ein Whisper-Modell (tiny, base, small, medium, large)
5. Klicken Sie auf "Transkription starten"

### Standalone (Kommandozeile)

```bash
# Audio herunterladen und transkribieren
python scripts/transcribe.py "https://www.youtube.com/watch?v=..."

# Namen korrigieren
python scripts/fix_names.py data/raw/transcript_*.txt

# Markdown erstellen
python scripts/postprocess.py data/fixed/fixed_*.txt "https://www.youtube.com/watch?v=..."
```

## Glossar verwalten

Das Glossar (`config/glossar.json`) enth?lt Korrekturen f?r h?ufig falsch transkribierte Begriffe:

```json
{
  "chat gpt": "ChatGPT",
  "open ai": "OpenAI",
  "youtube": "YouTube"
}
```

Sie k?nnen das Glossar ?ber die UI oder direkt in der JSON-Datei bearbeiten.

## Docker-Unterst?tzung

Das Tool kann optional Docker-Container verwenden:

```bash
# Container bauen
docker build -f containers/yt-dlp.Dockerfile -t mintutil-ytdlp .
docker build -f containers/whisper.Dockerfile -t mintutil-whisper .

# Verwenden
docker run --rm -v $(pwd)/data/audio:/downloads mintutil-ytdlp [URL]
```

## Whisper-Modelle

- **tiny**: Schnellste, geringste Genauigkeit (~1GB)
- **base**: Gute Balance (empfohlen) (~1GB)
- **small**: Bessere Genauigkeit (~2GB)
- **medium**: Hohe Genauigkeit (~5GB)
- **large**: Beste Genauigkeit (~10GB)

## Anforderungen

- Python 3.9+
- ffmpeg
- ~2-10 GB Speicher (je nach Modell)
- Optional: Docker

## Troubleshooting

### "yt-dlp nicht gefunden"
```bash
pip install yt-dlp
```

### "Whisper nicht gefunden"
```bash
pip install openai-whisper
```

### "ffmpeg nicht gefunden"
- Windows: Download von https://ffmpeg.org
- Linux: `sudo apt install ffmpeg`
- Mac: `brew install ffmpeg`

### Speicherprobleme
Verwenden Sie ein kleineres Modell (tiny oder base).

## Logs

Alle Aktivit?ten werden in `logs/transkription.log` protokolliert.