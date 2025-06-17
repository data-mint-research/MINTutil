# Transcription Tool

Automatic transcription of audio and video files as well as YouTube videos with OpenAI Whisper.

## Features

- ? YouTube video transcription
- ? Local audio/video file transcription  
- ? Multi-language support (default: German)
- ? Multiple output formats (TXT, SRT, VTT, JSON)
- ? CLI and Streamlit UI

## Installation

### 1. Basic Requirements
```bash
pip install -r ../../requirements.txt
```

### 2. Transcription Dependencies
```bash
# Required for transcription:
pip install openai-whisper yt-dlp

# Optional for better performance:
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

## Usage

### CLI (Command Line)

#### Transcribe YouTube video:
```bash
python scripts/transcribe.py "https://www.youtube.com/watch?v=VIDEO_ID"
```

#### Transcribe local file:
```bash
python scripts/transcribe.py "path/to/audio.mp3"
```

#### With options:
```bash
# Larger model for better quality
python scripts/transcribe.py "video.mp4" --model medium

# Different language
python scripts/transcribe.py "audio.wav" --language en

# Set output directory
python scripts/transcribe.py "file.mp3" --output ./my_transcriptions
```

#### Check dependencies:
```bash
python scripts/transcribe.py --check-deps
```

### Streamlit UI

Start MINTutil and select the Transcription Tool from the sidebar.

## Whisper Models

| Model  | Parameters | Relative Speed | Quality |
|--------|------------|----------------|---------|
| tiny   | 39M        | ~32x          | ??    |
| base   | 74M        | ~16x          | ???   |
| small  | 244M       | ~6x           | ????  |
| medium | 769M       | ~2x           | ????? |
| large  | 1550M      | 1x            | ????? |

**Recommendation**: 
- For fast transcriptions: `base`
- For best quality: `medium` or `large`

## Output Formats

- **TXT**: Plain text without timestamps
- **SRT**: SubRip subtitle format
- **VTT**: WebVTT subtitle format  
- **JSON**: Complete data with timestamps and confidence

## Troubleshooting

### "Whisper is not installed"
```bash
pip install openai-whisper
```

### "yt-dlp is not installed"
```bash
pip install yt-dlp
```

### Memory errors with large files
Use a smaller model:
```bash
python scripts/transcribe.py "large_file.mp4" --model tiny
```

### YouTube download failed
- Check the URL
- Make sure the video is public
- Update yt-dlp: `pip install --upgrade yt-dlp`

## Notes

- First use of a model downloads it (~50MB-1.5GB)
- GPU acceleration is automatically used if available
- Long videos can take several minutes
- Transcription quality depends on audio quality

## Scripts

- `transcribe.py` - Main transcription script
- `postprocess.py` - Post-processing of transcripts
- `fix_names.py` - Correction of proper names in transcripts
