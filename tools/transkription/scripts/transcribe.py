#!/usr/bin/env python3
"""
YouTube Audio Download and Transcription Module
Handles downloading audio from YouTube and transcribing with Whisper
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from datetime import datetime
import logging
import re
from typing import Optional

# Setup logging
log_dir = Path(__file__).parent.parent / "logs"
log_dir.mkdir(exist_ok=True)
log_file = log_dir / "transkription.log"

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

def download_youtube_audio(url: str) -> Optional[Path]:
    """
    Download audio from YouTube video using yt-dlp container
    
    Args:
        url: YouTube video URL
        
    Returns:
        Path to downloaded audio file or None if failed
    """
    logger.info(f"Starting download for URL: {url}")
    
    # Create audio directory
    audio_dir = Path(__file__).parent.parent / "data" / "audio"
    audio_dir.mkdir(parents=True, exist_ok=True)
    
    # Extract video ID from URL
    video_id = extract_video_id(url)
    if not video_id:
        logger.error(f"Could not extract video ID from URL: {url}")
        return None
    
    # Define output path
    output_path = audio_dir / f"{video_id}.mp3"
    
    # Check if already downloaded
    if output_path.exists():
        logger.info(f"Audio already exists: {output_path}")
        return output_path
    
    # Check if Docker is available
    docker_available = check_docker()
    
    if docker_available:
        # Use Docker container
        logger.info("Using Docker container for yt-dlp")
        success = download_with_docker(url, output_path)
    else:
        # Use local yt-dlp
        logger.info("Using local yt-dlp installation")
        success = download_with_local_ytdlp(url, output_path)
    
    if success and output_path.exists():
        logger.info(f"Successfully downloaded audio to: {output_path}")
        return output_path
    else:
        logger.error("Failed to download audio")
        return None

def extract_video_id(url: str) -> Optional[str]:
    """Extract video ID from YouTube URL"""
    patterns = [
        r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([^&\n?]+)',
        r'youtube\.com/watch\?.*v=([^&\n?]+)'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    
    return None

def check_docker() -> bool:
    """Check if Docker is available"""
    try:
        result = subprocess.run(
            ["docker", "--version"],
            capture_output=True,
            text=True,
            timeout=5
        )
        return result.returncode == 0
    except:
        return False

def download_with_docker(url: str, output_path: Path) -> bool:
    """Download using Docker container"""
    try:
        # Build Docker image if needed
        dockerfile_path = Path(__file__).parent.parent / "containers" / "yt-dlp.Dockerfile"
        if dockerfile_path.exists():
            logger.info("Building yt-dlp Docker image...")
            build_cmd = [
                "docker", "build",
                "-f", str(dockerfile_path),
                "-t", "mintutil-ytdlp",
                str(dockerfile_path.parent)
            ]
            subprocess.run(build_cmd, check=True)
        
        # Run download in container
        cmd = [
            "docker", "run", "--rm",
            "-v", f"{output_path.parent}:/downloads",
            "mintutil-ytdlp",
            "-x",  # Extract audio
            "--audio-format", "mp3",
            "--audio-quality", "0",
            "-o", f"/downloads/{output_path.name}",
            url
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.returncode == 0
        
    except Exception as e:
        logger.error(f"Docker download failed: {str(e)}")
        return False

def download_with_local_ytdlp(url: str, output_path: Path) -> bool:
    """Download using local yt-dlp installation"""
    try:
        cmd = [
            "yt-dlp",
            "-x",  # Extract audio
            "--audio-format", "mp3",
            "--audio-quality", "0",
            "-o", str(output_path),
            url
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            logger.error(f"yt-dlp error: {result.stderr}")
            
            # Try installing yt-dlp if not found
            if "yt-dlp" not in result.stderr:
                logger.info("Installing yt-dlp...")
                subprocess.run([sys.executable, "-m", "pip", "install", "yt-dlp"], check=True)
                # Retry download
                result = subprocess.run(cmd, capture_output=True, text=True)
        
        return result.returncode == 0
        
    except Exception as e:
        logger.error(f"Local download failed: {str(e)}")
        return False

def transcribe_with_whisper(audio_path: Path, model: str = "base") -> Optional[Path]:
    """
    Transcribe audio file using Whisper
    
    Args:
        audio_path: Path to audio file
        model: Whisper model size
        
    Returns:
        Path to transcript file or None if failed
    """
    logger.info(f"Starting transcription with model: {model}")
    
    # Create output directory
    raw_dir = Path(__file__).parent.parent / "data" / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    
    # Define output path
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = raw_dir / f"transcript_{audio_path.stem}_{timestamp}.txt"
    
    # Check if Docker is available
    docker_available = check_docker()
    
    if docker_available:
        # Use Docker container
        logger.info("Using Docker container for Whisper")
        success = transcribe_with_docker(audio_path, output_path, model)
    else:
        # Use local Whisper
        logger.info("Using local Whisper installation")
        success = transcribe_with_local_whisper(audio_path, output_path, model)
    
    if success and output_path.exists():
        logger.info(f"Successfully transcribed to: {output_path}")
        return output_path
    else:
        logger.error("Failed to transcribe audio")
        return None

def transcribe_with_docker(audio_path: Path, output_path: Path, model: str) -> bool:
    """Transcribe using Docker container"""
    try:
        # Build Docker image if needed
        dockerfile_path = Path(__file__).parent.parent / "containers" / "whisper.Dockerfile"
        if dockerfile_path.exists():
            logger.info("Building Whisper Docker image...")
            build_cmd = [
                "docker", "build",
                "-f", str(dockerfile_path),
                "-t", "mintutil-whisper",
                str(dockerfile_path.parent)
            ]
            subprocess.run(build_cmd, check=True)
        
        # Run transcription in container
        cmd = [
            "docker", "run", "--rm",
            "-v", f"{audio_path.parent}:/audio",
            "-v", f"{output_path.parent}:/output",
            "mintutil-whisper",
            "python", "-c",
            f"""
import whisper
model = whisper.load_model('{model}')
result = model.transcribe('/audio/{audio_path.name}')
with open('/output/{output_path.name}', 'w', encoding='utf-8') as f:
    f.write(result['text'])
"""
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.returncode == 0
        
    except Exception as e:
        logger.error(f"Docker transcription failed: {str(e)}")
        return False

def transcribe_with_local_whisper(audio_path: Path, output_path: Path, model: str) -> bool:
    """Transcribe using local Whisper installation"""
    try:
        # Try importing whisper
        try:
            import whisper
        except ImportError:
            logger.info("Installing openai-whisper...")
            subprocess.run([sys.executable, "-m", "pip", "install", "openai-whisper"], check=True)
            import whisper
        
        # Load model and transcribe
        logger.info(f"Loading Whisper model: {model}")
        whisper_model = whisper.load_model(model)
        
        logger.info(f"Transcribing audio file: {audio_path}")
        result = whisper_model.transcribe(str(audio_path))
        
        # Save transcript
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(result['text'])
        
        return True
        
    except Exception as e:
        logger.error(f"Local transcription failed: {str(e)}")
        return False

if __name__ == "__main__":
    # Test with sample URL
    if len(sys.argv) > 1:
        url = sys.argv[1]
        audio_path = download_youtube_audio(url)
        if audio_path:
            transcript_path = transcribe_with_whisper(audio_path)
            if transcript_path:
                print(f"Success! Transcript saved to: {transcript_path}")
            else:
                print("Transcription failed")
        else:
            print("Download failed")