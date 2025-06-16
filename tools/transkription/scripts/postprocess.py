#!/usr/bin/env python3
"""
Post-processing Module
Creates formatted Markdown output from transcripts
"""

import re
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, List
import logging
import requests

logger = logging.getLogger(__name__)

def create_markdown_output(transcript_path: Path, youtube_url: str) -> Path:
    """
    Create formatted Markdown file from transcript
    
    Args:
        transcript_path: Path to transcript file
        youtube_url: Original YouTube URL
        
    Returns:
        Path to Markdown file
    """
    logger.info(f"Creating Markdown output for: {transcript_path}")
    
    # Read transcript
    try:
        with open(transcript_path, 'r', encoding='utf-8') as f:
            transcript_text = f.read()
    except Exception as e:
        logger.error(f"Error reading transcript: {str(e)}")
        return transcript_path
    
    # Get video metadata
    metadata = get_video_metadata(youtube_url)
    
    # Format transcript
    formatted_text = format_transcript(transcript_text)
    
    # Create Markdown content
    markdown_content = create_markdown_content(
        formatted_text, 
        youtube_url, 
        metadata
    )
    
    # Save Markdown file
    markdown_path = save_markdown(markdown_content, transcript_path)
    
    return markdown_path

def get_video_metadata(youtube_url: str) -> Dict[str, str]:
    """
    Get video metadata (title, channel, etc.)
    
    Args:
        youtube_url: YouTube video URL
        
    Returns:
        Dictionary with metadata
    """
    metadata = {
        'title': 'YouTube Video Transkript',
        'channel': 'Unbekannt',
        'date': datetime.now().strftime('%d.%m.%Y'),
        'url': youtube_url
    }
    
    # Try to extract video ID and get basic info
    video_id_match = re.search(r'(?:v=|youtu\.be/)([^&\n?]+)', youtube_url)
    if video_id_match:
        video_id = video_id_match.group(1)
        metadata['video_id'] = video_id
        
        # Could use YouTube API here if available
        # For now, we'll just use the video ID
        logger.info(f"Video ID: {video_id}")
    
    return metadata

def format_transcript(text: str) -> str:
    """
    Format transcript text with paragraphs and punctuation
    
    Args:
        text: Raw transcript text
        
    Returns:
        Formatted text
    """
    # Remove extra whitespace
    text = ' '.join(text.split())
    
    # Split into sentences (simple approach)
    sentences = re.split(r'(?<=[.!?])\s+', text)
    
    # Group sentences into paragraphs (5-7 sentences each)
    paragraphs = []
    current_paragraph = []
    
    for sentence in sentences:
        current_paragraph.append(sentence)
        
        # Check for natural paragraph breaks
        if len(current_paragraph) >= 5 or (
            len(current_paragraph) >= 3 and 
            any(word in sentence.lower() for word in ['also', 'jedoch', 'aber', 'somit', 'daher'])
        ):
            paragraphs.append(' '.join(current_paragraph))
            current_paragraph = []
    
    # Add remaining sentences
    if current_paragraph:
        paragraphs.append(' '.join(current_paragraph))
    
    # Join paragraphs with double newline
    formatted_text = '\n\n'.join(paragraphs)
    
    return formatted_text

def create_markdown_content(text: str, url: str, metadata: Dict[str, str]) -> str:
    """
    Create complete Markdown content
    
    Args:
        text: Formatted transcript text
        url: YouTube URL
        metadata: Video metadata
        
    Returns:
        Markdown content
    """
    # Create timestamp
    timestamp = datetime.now().strftime('%d.%m.%Y %H:%M')
    
    # Build Markdown
    markdown = f"""# {metadata['title']}

**Quelle:** [{url}]({url})  
**Kanal:** {metadata['channel']}  
**Transkript erstellt:** {timestamp}  
**Tool:** MINTutil YouTube Transcriber

---

## Transkript

{text}

---

## Hinweise

- Dieses Transkript wurde automatisch mit OpenAI Whisper erstellt
- Namen und Begriffe wurden anhand eines Glossars korrigiert
- Die Formatierung wurde automatisch hinzugef?gt

## Metadaten

- **Video ID:** {metadata.get('video_id', 'N/A')}
- **Verarbeitungsdatum:** {timestamp}
- **Whisper Modell:** base
- **Glossar-Korrekturen:** Aktiviert

---

*Erstellt mit MINTutil - Lokale Transkription f?r YouTube-Videos*
"""
    
    return markdown

def save_markdown(content: str, original_path: Path) -> Path:
    """
    Save Markdown content to file
    
    Args:
        content: Markdown content
        original_path: Path to original transcript
        
    Returns:
        Path to saved Markdown file
    """
    # Create output directory
    output_dir = Path(__file__).parent.parent / "data" / "fixed"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"transcript_{timestamp}.md"
    output_path = output_dir / filename
    
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(content)
        logger.info(f"Saved Markdown to: {output_path}")
        return output_path
    except Exception as e:
        logger.error(f"Error saving Markdown: {str(e)}")
        return original_path

def add_timestamps(text: str, duration: Optional[int] = None) -> str:
    """
    Add timestamps to transcript (if timing information available)
    
    Args:
        text: Transcript text
        duration: Video duration in seconds
        
    Returns:
        Text with timestamps
    """
    if not duration:
        return text
    
    # This is a simplified version
    # Real implementation would use actual timing data from Whisper
    lines = text.split('\n')
    timestamped_lines = []
    
    for i, line in enumerate(lines):
        if line.strip():
            # Estimate timestamp based on position
            timestamp = int((i / len(lines)) * duration)
            minutes = timestamp // 60
            seconds = timestamp % 60
            timestamped_lines.append(f"[{minutes:02d}:{seconds:02d}] {line}")
        else:
            timestamped_lines.append(line)
    
    return '\n'.join(timestamped_lines)

def create_summary(text: str, max_sentences: int = 5) -> str:
    """
    Create a summary of the transcript
    
    Args:
        text: Full transcript text
        max_sentences: Maximum sentences in summary
        
    Returns:
        Summary text
    """
    # Simple extractive summary
    sentences = re.split(r'(?<=[.!?])\s+', text)
    
    if len(sentences) <= max_sentences:
        return text
    
    # Take first and last sentences, and some from middle
    summary_sentences = []
    
    # First sentence
    summary_sentences.append(sentences[0])
    
    # Middle sentences (evenly distributed)
    if max_sentences > 2:
        step = len(sentences) // (max_sentences - 2)
        for i in range(1, max_sentences - 1):
            idx = i * step
            if idx < len(sentences) - 1:
                summary_sentences.append(sentences[idx])
    
    # Last sentence
    if len(sentences) > 1:
        summary_sentences.append(sentences[-1])
    
    return ' '.join(summary_sentences)

def split_into_chapters(text: str, chapter_length: int = 1000) -> List[Dict[str, str]]:
    """
    Split transcript into chapters
    
    Args:
        text: Full transcript text
        chapter_length: Approximate length of each chapter in characters
        
    Returns:
        List of chapters with titles and content
    """
    chapters = []
    current_chapter = []
    current_length = 0
    chapter_num = 1
    
    paragraphs = text.split('\n\n')
    
    for para in paragraphs:
        current_chapter.append(para)
        current_length += len(para)
        
        if current_length >= chapter_length:
            # Create chapter
            chapter_text = '\n\n'.join(current_chapter)
            
            # Generate title from first sentence
            first_sentence = re.split(r'[.!?]', chapter_text)[0]
            title = first_sentence[:50] + "..." if len(first_sentence) > 50 else first_sentence
            
            chapters.append({
                'number': chapter_num,
                'title': title,
                'content': chapter_text
            })
            
            current_chapter = []
            current_length = 0
            chapter_num += 1
    
    # Add remaining content
    if current_chapter:
        chapter_text = '\n\n'.join(current_chapter)
        first_sentence = re.split(r'[.!?]', chapter_text)[0]
        title = first_sentence[:50] + "..." if len(first_sentence) > 50 else first_sentence
        
        chapters.append({
            'number': chapter_num,
            'title': title,
            'content': chapter_text
        })
    
    return chapters

if __name__ == "__main__":
    # Test with sample transcript
    import sys
    if len(sys.argv) > 2:
        transcript_path = Path(sys.argv[1])
        youtube_url = sys.argv[2]
        
        if transcript_path.exists():
            markdown_path = create_markdown_output(transcript_path, youtube_url)
            print(f"Markdown saved to: {markdown_path}")
        else:
            print(f"File not found: {transcript_path}")
    else:
        print("Usage: python postprocess.py <transcript_path> <youtube_url>")