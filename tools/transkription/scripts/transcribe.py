#!/usr/bin/env python3
"""
Transkriptions-Script f?r MINTutil
Unterst?tzt YouTube-Videos und lokale Audio/Video-Dateien
"""

import os
import sys
import json
import subprocess
import argparse
import tempfile
from pathlib import Path
from typing import Dict, Optional, Union
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class TranscriptionError(Exception):
    """Custom exception for transcription errors"""
    pass


class Transcriber:
    """Handles audio/video transcription using Whisper"""
    
    def __init__(self, model: str = "base", language: str = "de"):
        self.model = model
        self.language = language
        self.whisper_available = self._check_whisper()
        self.ytdlp_available = self._check_ytdlp()
        
    def _check_whisper(self) -> bool:
        """Check if Whisper is available"""
        try:
            subprocess.run(["whisper", "--help"], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            logger.warning("Whisper is not installed. Install with: pip install openai-whisper")
            return False
            
    def _check_ytdlp(self) -> bool:
        """Check if yt-dlp is available"""
        try:
            subprocess.run(["yt-dlp", "--version"], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            logger.warning("yt-dlp is not installed. Install with: pip install yt-dlp")
            return False
    
    def download_youtube_audio(self, url: str, output_path: Path) -> Path:
        """Download audio from YouTube video"""
        if not self.ytdlp_available:
            raise TranscriptionError("yt-dlp is not available")
            
        logger.info(f"Downloading audio from: {url}")
        
        cmd = [
            "yt-dlp",
            "-x",  # Extract audio
            "--audio-format", "mp3",
            "--audio-quality", "0",
            "-o", str(output_path / "%(title)s.%(ext)s"),
            "--quiet",
            "--no-warnings",
            url
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            # Find the downloaded file
            for file in output_path.iterdir():
                if file.suffix == '.mp3':
                    logger.info(f"Downloaded: {file.name}")
                    return file
            raise TranscriptionError("No audio file found after download")
        except subprocess.CalledProcessError as e:
            raise TranscriptionError(f"Failed to download audio: {e.stderr}")
    
    def transcribe_audio(self, audio_path: Path, output_dir: Path) -> Dict:
        """Transcribe audio file using Whisper"""
        if not self.whisper_available:
            raise TranscriptionError("Whisper is not available")
            
        logger.info(f"Transcribing: {audio_path.name}")
        
        cmd = [
            "whisper",
            str(audio_path),
            "--model", self.model,
            "--language", self.language,
            "--output_dir", str(output_dir),
            "--output_format", "all",
            "--verbose", "False"
        ]
        
        try:
            subprocess.run(cmd, capture_output=True, text=True, check=True)
            
            # Read results
            base_name = audio_path.stem
            result_files = {
                'txt': output_dir / f"{base_name}.txt",
                'vtt': output_dir / f"{base_name}.vtt",
                'srt': output_dir / f"{base_name}.srt",
                'json': output_dir / f"{base_name}.json"
            }
            
            results = {}
            for fmt, file_path in result_files.items():
                if file_path.exists():
                    if fmt == 'json':
                        with open(file_path, 'r', encoding='utf-8') as f:
                            results[fmt] = json.load(f)
                    else:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            results[fmt] = f.read()
            
            return results
            
        except subprocess.CalledProcessError as e:
            raise TranscriptionError(f"Transcription failed: {e.stderr}")
    
    def transcribe(self, source: str, output_dir: Optional[Path] = None) -> Dict:
        """Main transcription method"""
        if output_dir is None:
            output_dir = Path.cwd() / "transcriptions"
        output_dir.mkdir(exist_ok=True)
        
        # Check if source is YouTube URL
        if source.startswith(('http://', 'https://', 'www.')):
            with tempfile.TemporaryDirectory() as temp_dir:
                temp_path = Path(temp_dir)
                audio_file = self.download_youtube_audio(source, temp_path)
                results = self.transcribe_audio(audio_file, output_dir)
        else:
            # Local file
            audio_path = Path(source)
            if not audio_path.exists():
                raise TranscriptionError(f"File not found: {source}")
            results = self.transcribe_audio(audio_path, output_dir)
        
        return results


def main():
    """CLI interface"""
    parser = argparse.ArgumentParser(
        description="Transcribe audio/video files or YouTube videos"
    )
    parser.add_argument(
        "source",
        help="Path to audio/video file or YouTube URL"
    )
    parser.add_argument(
        "-m", "--model",
        default="base",
        choices=["tiny", "base", "small", "medium", "large"],
        help="Whisper model size (default: base)"
    )
    parser.add_argument(
        "-l", "--language",
        default="de",
        help="Language code (default: de)"
    )
    parser.add_argument(
        "-o", "--output",
        type=Path,
        help="Output directory (default: ./transcriptions)"
    )
    parser.add_argument(
        "--check-deps",
        action="store_true",
        help="Check if dependencies are installed"
    )
    
    args = parser.parse_args()
    
    # Initialize transcriber
    transcriber = Transcriber(model=args.model, language=args.language)
    
    # Check dependencies
    if args.check_deps:
        print(f"Whisper available: {transcriber.whisper_available}")
        print(f"yt-dlp available: {transcriber.ytdlp_available}")
        if not (transcriber.whisper_available and transcriber.ytdlp_available):
            print("\nInstall missing dependencies:")
            if not transcriber.whisper_available:
                print("  pip install openai-whisper")
            if not transcriber.ytdlp_available:
                print("  pip install yt-dlp")
        sys.exit(0)
    
    # Perform transcription
    try:
        results = transcriber.transcribe(args.source, args.output)
        
        # Print summary
        print(f"\nTranscription complete!")
        if 'txt' in results:
            print(f"\nText output:\n{'-' * 40}")
            print(results['txt'][:500] + "..." if len(results['txt']) > 500 else results['txt'])
            print(f"{'-' * 40}")
        
        output_dir = args.output or Path.cwd() / "transcriptions"
        print(f"\nFiles saved to: {output_dir}")
        
    except TranscriptionError as e:
        logger.error(f"Error: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
