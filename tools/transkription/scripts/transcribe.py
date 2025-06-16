"""
YouTube audio download and transcription module
"""
import os
import subprocess
from pathlib import Path
import whisper
import yt_dlp
from datetime import datetime


def download_youtube_audio(url: str, output_dir: str = None) -> str:
    """
    Download audio from YouTube video
    
    Args:
        url: YouTube video URL
        output_dir: Output directory for audio file
    
    Returns:
        Path to downloaded audio file
    """
    if output_dir is None:
        output_dir = Path(__file__).parent.parent / "data" / "audio"
    
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate unique filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = output_dir / f"audio_{timestamp}.mp3"
    
    # yt-dlp options
    ydl_opts = {
        'format': 'bestaudio/best',
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
            'preferredquality': '192',
        }],
        'outtmpl': str(output_path.with_suffix('')),
        'quiet': True,
        'no_warnings': True,
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            print(f"Downloaded: {info.get('title', 'Unknown')}")
        
        return str(output_path)
    
    except Exception as e:
        print(f"Error downloading audio: {e}")
        raise


def transcribe_with_whisper(audio_path: str, model_name: str = "base") -> str:
    """
    Transcribe audio using OpenAI Whisper
    
    Args:
        audio_path: Path to audio file
        model_name: Whisper model name (tiny, base, small, medium, large)
    
    Returns:
        Path to transcript file
    """
    audio_path = Path(audio_path)
    if not audio_path.exists():
        raise FileNotFoundError(f"Audio file not found: {audio_path}")
    
    # Output path
    output_dir = audio_path.parent.parent / "raw"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = output_dir / f"transcript_{timestamp}.txt"
    
    try:
        # Load model
        print(f"Loading Whisper model: {model_name}")
        model = whisper.load_model(model_name)
        
        # Transcribe
        print(f"Transcribing audio...")
        result = model.transcribe(str(audio_path))
        
        # Save transcript
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(result["text"])
        
        print(f"Transcript saved to: {output_path}")
        return str(output_path)
    
    except Exception as e:
        print(f"Error during transcription: {e}")
        raise


def transcribe_youtube(url: str, model_name: str = "base") -> dict:
    """
    Complete pipeline: download and transcribe YouTube video
    
    Args:
        url: YouTube video URL
        model_name: Whisper model name
    
    Returns:
        Dictionary with paths to audio and transcript
    """
    try:
        # Download audio
        audio_path = download_youtube_audio(url)
        
        # Transcribe
        transcript_path = transcribe_with_whisper(audio_path, model_name)
        
        return {
            "audio_path": audio_path,
            "transcript_path": transcript_path,
            "success": True
        }
    
    except Exception as e:
        return {
            "error": str(e),
            "success": False
        }


if __name__ == "__main__":
    # Example usage
    import sys
    
    if len(sys.argv) > 1:
        url = sys.argv[1]
        model = sys.argv[2] if len(sys.argv) > 2 else "base"
        
        result = transcribe_youtube(url, model)
        if result["success"]:
            print(f"Success! Transcript at: {result['transcript_path']}")
        else:
            print(f"Error: {result['error']}")
    else:
        print("Usage: python transcribe.py <youtube_url> [model_name]")
