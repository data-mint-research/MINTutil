# Transkriptions-Tool

Automatische Transkription von Audio- und Video-Dateien sowie YouTube-Videos mit OpenAI Whisper.

## Features

- ? YouTube-Video Transkription
- ? Lokale Audio/Video-Datei Transkription  
- ? Mehrsprachige Unterst?tzung (Standard: Deutsch)
- ? Multiple Ausgabeformate (TXT, SRT, VTT, JSON)
- ? CLI und Streamlit UI

## Installation

### 1. Basis-Requirements
```bash
pip install -r ../../requirements.txt
```

### 2. Transkriptions-Dependencies
```bash
# F?r Transkription erforderlich:
pip install openai-whisper yt-dlp

# Optional f?r bessere Performance:
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

## Verwendung

### CLI (Command Line)

#### YouTube-Video transkribieren:
```bash
python scripts/transcribe.py "https://www.youtube.com/watch?v=VIDEO_ID"
```

#### Lokale Datei transkribieren:
```bash
python scripts/transcribe.py "path/to/audio.mp3"
```

#### Mit Optionen:
```bash
# Gr??eres Modell f?r bessere Qualit?t
python scripts/transcribe.py "video.mp4" --model medium

# Andere Sprache
python scripts/transcribe.py "audio.wav" --language en

# Ausgabe-Verzeichnis festlegen
python scripts/transcribe.py "file.mp3" --output ./meine_transkriptionen
```

#### Dependencies pr?fen:
```bash
python scripts/transcribe.py --check-deps
```

### Streamlit UI

Starten Sie MINTutil und w?hlen Sie das Transkriptions-Tool aus der Sidebar.

## Whisper Modelle

| Modell | Parameter | Relative Geschwindigkeit | Qualit?t |
|--------|-----------|-------------------------|----------|
| tiny   | 39M       | ~32x                   | ?????    |
| base   | 74M       | ~16x                   | ?????    |
| small  | 244M      | ~6x                    | ?????    |
| medium | 769M      | ~2x                    | ?????    |
| large  | 1550M     | 1x                     | ?????    |

**Empfehlung**: 
- F?r schnelle Transkriptionen: `base`
- F?r beste Qualit?t: `medium` oder `large`

## Ausgabeformate

- **TXT**: Reiner Text ohne Zeitstempel
- **SRT**: SubRip Untertitel-Format
- **VTT**: WebVTT Untertitel-Format  
- **JSON**: Vollst?ndige Daten mit Zeitstempeln und Konfidenz

## Troubleshooting

### "Whisper is not installed"
```bash
pip install openai-whisper
```

### "yt-dlp is not installed"
```bash
pip install yt-dlp
```

### Speicherfehler bei gro?en Dateien
Verwenden Sie ein kleineres Modell:
```bash
python scripts/transcribe.py "large_file.mp4" --model tiny
```

### YouTube-Download fehlgeschlagen
- Pr?fen Sie die URL
- Stellen Sie sicher, dass das Video ?ffentlich ist
- Aktualisieren Sie yt-dlp: `pip install --upgrade yt-dlp`

## Hinweise

- Die erste Verwendung eines Modells l?dt es herunter (~50MB-1.5GB)
- GPU-Beschleunigung wird automatisch verwendet, wenn verf?gbar
- Lange Videos k?nnen mehrere Minuten dauern
- Die Transkriptionsqualit?t h?ngt von der Audioqualit?t ab

## Skripte

- `transcribe.py` - Haupt-Transkriptionsskript
- `postprocess.py` - Nachbearbeitung von Transkripten
- `fix_names.py` - Korrektur von Eigennamen in Transkripten
