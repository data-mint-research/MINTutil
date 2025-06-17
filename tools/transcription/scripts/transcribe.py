#!/usr/bin/env python3
"""
Transcription module for YouTube videos using Whisper
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from datetime import datetime
import re
import tempfile
import shutil
from typing import Optional, Dict, Any

# Try to import optional dependencies
try:
    import whisper
    WHISPER_AVAILABLE = True
except ImportError:
    WHISPER_AVAILABLE = False
    print("Warning: whisper not installed. Install with: pip install openai-whisper")

try:
    import yt_dlp
    YTDLP_AVAILABLE = True
except ImportError:
    YTDLP_AVAILABLE = False
    print("Warning: yt-dlp not installed. Install with: pip install yt-dlp")


def get_video_info(url: str) -> Optional[Dict[str, Any]]:
    """Extract video information from YouTube URL"""
    if not YTDLP_AVAILABLE:
        raise ImportError("yt-dlp is required but not installed")
    
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            return {
                'title': info.get('title', 'Unknown'),
                'duration': info.get('duration', 0),
                'uploader': info.get('uploader', 'Unknown'),
                'upload_date': info.get('upload_date', ''),
                'description': info.get('description', ''),
                'view_count': info.get('view_count', 0),
            }
    except Exception as e:
        print(f"Error getting video info: {e}")
        return None


def download_youtube_audio(url: str, output_dir: Optional[str] = None) -> Optional[str]:
    """
    Download audio from YouTube video
    
    Args:
        url: YouTube video URL
        output_dir: Directory to save audio file
        
    Returns:
        Path to downloaded audio file or None if failed
    """
    if not YTDLP_AVAILABLE:
        raise ImportError("yt-dlp is required but not installed")
    
    if output_dir is None:
        output_dir = Path(__file__).parent.parent / "data" / "audio"
    
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate unique filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_template = str(output_dir / f"audio_{timestamp}.%(ext)s")
    
    ydl_opts = {
        'format': 'bestaudio/best',
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
            'preferredquality': '192',
        }],
        'outtmpl': output_template,
        'quiet': True,
        'no_warnings': True,
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            print(f"Downloading audio from: {url}")
            ydl.download([url])
            
            # Find the downloaded file
            audio_file = output_template.replace('%(ext)s', 'mp3')
            if Path(audio_file).exists():
                print(f"Audio saved to: {audio_file}")
                return audio_file
            else:
                # Try to find any audio file that was created
                for ext in ['mp3', 'mp4', 'm4a', 'webm']:
                    test_file = output_template.replace('%(ext)s', ext)
                    if Path(test_file).exists():
                        return test_file
                
                print("Error: Audio file not found after download")
                return None
                
    except Exception as e:
        print(f"Error downloading audio: {e}")
        return None


def transcribe_with_whisper(
    audio_path: str,
    model_name: str = "base",
    language: str = "de",
    output_dir: Optional[str] = None
) -> Optional[str]:
    """
    Transcribe audio file using Whisper
    
    Args:
        audio_path: Path to audio file
        model_name: Whisper model to use (tiny, base, small, medium, large)
        language: Language code for transcription
        output_dir: Directory to save transcript
        
    Returns:
        Path to transcript file or None if failed
    """
    if not WHISPER_AVAILABLE:
        raise ImportError("whisper is required but not installed")
    
    audio_path = Path(audio_path)
    if not audio_path.exists():
        print(f"Error: Audio file not found: {audio_path}")
        return None
    
    if output_dir is None:
        output_dir = Path(__file__).parent.parent / "data" / "raw"
    
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    try:
        print(f"Loading Whisper model: {model_name}")
        model = whisper.load_model(model_name)
        
        print(f"Transcribing audio file: {audio_path}")
        result = model.transcribe(
            str(audio_path),
            language=language,
            verbose=True,
            fp16=False  # Disable FP16 for compatibility
        )
        
        # Save transcript
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        transcript_file = output_dir / f"transcript_{timestamp}.txt"
        
        with open(transcript_file, 'w', encoding='utf-8') as f:
            f.write(result['text'])
        
        print(f"Transcript saved to: {transcript_file}")
        
        # Also save detailed segments
        segments_file = output_dir / f"segments_{timestamp}.json"
        segments_data = {
            'text': result['text'],
            'segments': [
                {
                    'start': seg['start'],
                    'end': seg['end'],
                    'text': seg['text']
                }
                for seg in result['segments']
            ],
            'language': result.get('language', language)
        }
        
        with open(segments_file, 'w', encoding='utf-8') as f:
            json.dump(segments_data, f, ensure_ascii=False, indent=2)
        
        return str(transcript_file)
        
    except Exception as e:
        print(f"Error during transcription: {e}")
        return None


def transcribe_youtube(
    url: str,
    model_name: str = "base",
    language: str = "de",
    keep_audio: bool = False
) -> Optional[Dict[str, str]]:
    """
    Complete pipeline to transcribe a YouTube video
    
    Args:
        url: YouTube video URL
        model_name: Whisper model to use
        language: Language code for transcription
        keep_audio: Whether to keep the audio file after transcription
        
    Returns:
        Dictionary with paths to audio and transcript files
    """
    try:
        # Get video info
        video_info = get_video_info(url)
        if video_info:
            print(f"Video: {video_info['title']}")
            print(f"Duration: {video_info['duration']}s")
        
        # Download audio
        audio_path = download_youtube_audio(url)
        if not audio_path:
            return None
        
        # Transcribe
        transcript_path = transcribe_with_whisper(audio_path, model_name, language)
        if not transcript_path:
            return None
        
        # Clean up audio if requested
        if not keep_audio and audio_path:
            try:
                os.remove(audio_path)
                print(f"Removed audio file: {audio_path}")
            except Exception as e:
                print(f"Warning: Could not remove audio file: {e}")
        
        return {
            'audio': audio_path if keep_audio else None,
            'transcript': transcript_path,
            'video_info': video_info
        }
        
    except Exception as e:
        print(f"Error in transcription pipeline: {e}")
        return None


def main():
    """Main function for CLI usage"""
    if len(sys.argv) < 2:
        print("Usage: python transcribe.py <youtube_url> [model] [language]")
        print("Models: tiny, base, small, medium, large")
        print("Example: python transcribe.py https://youtube.com/watch?v=... base de")
        sys.exit(1)
    
    url = sys.argv[1]
    model = sys.argv[2] if len(sys.argv) > 2 else "base"
    language = sys.argv[3] if len(sys.argv) > 3 else "de"
    
    # Check dependencies
    if not YTDLP_AVAILABLE:
        print("Error: yt-dlp is not installed. Run: pip install yt-dlp")
        sys.exit(1)
    
    if not WHISPER_AVAILABLE:
        print("Error: whisper is not installed. Run: pip install openai-whisper")
        sys.exit(1)
    
    # Run transcription
    result = transcribe_youtube(url, model, language, keep_audio=True)
    
    if result:
        print("\nTranscription completed successfully!")
        print(f"Transcript: {result['transcript']}")
        if result['audio']:
            print(f"Audio: {result['audio']}")
    else:
        print("\nTranscription failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
