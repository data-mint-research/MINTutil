#!/usr/bin/env python3
"""
Post-processing module for creating formatted output from transcripts
"""

import re
from pathlib import Path
from datetime import datetime
from typing import Optional, List, Dict, Any
import json
import textwrap


def extract_video_id(url: str) -> Optional[str]:
    """
    Extract video ID from YouTube URL
    
    Args:
        url: YouTube URL
        
    Returns:
        Video ID or None
    """
    patterns = [
        r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\n]+)',
        r'youtube\.com\/embed\/([^&\n]+)',
        r'youtube\.com\/v\/([^&\n]+)',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    
    return None


def format_timestamp(seconds: int) -> str:
    """
    Format seconds to HH:MM:SS
    
    Args:
        seconds: Time in seconds
        
    Returns:
        Formatted time string
    """
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    seconds = seconds % 60
    
    if hours > 0:
        return f"{hours:02d}:{minutes:02d}:{seconds:02d}"
    else:
        return f"{minutes:02d}:{seconds:02d}"


def clean_text(text: str) -> str:
    """
    Clean and format transcript text
    
    Args:
        text: Raw transcript text
        
    Returns:
        Cleaned text
    """
    # Remove multiple spaces
    text = re.sub(r'\s+', ' ', text)
    
    # Fix spacing around punctuation
    text = re.sub(r'\s+([.,!?;:])', r'\1', text)
    text = re.sub(r'([.,!?;:])\s*', r'\1 ', text)
    
    # Remove trailing spaces
    text = text.strip()
    
    # Ensure sentences end with proper punctuation
    if text and text[-1] not in '.!?':
        text += '.'
    
    return text


def split_into_paragraphs(text: str, words_per_paragraph: int = 100) -> List[str]:
    """
    Split text into paragraphs
    
    Args:
        text: The text to split
        words_per_paragraph: Approximate words per paragraph
        
    Returns:
        List of paragraphs
    """
    sentences = re.split(r'(?<=[.!?])\s+', text)
    paragraphs = []
    current_paragraph = []
    current_word_count = 0
    
    for sentence in sentences:
        word_count = len(sentence.split())
        
        if current_word_count + word_count > words_per_paragraph and current_paragraph:
            paragraphs.append(' '.join(current_paragraph))
            current_paragraph = [sentence]
            current_word_count = word_count
        else:
            current_paragraph.append(sentence)
            current_word_count += word_count
    
    if current_paragraph:
        paragraphs.append(' '.join(current_paragraph))
    
    return paragraphs


def create_markdown_output(
    transcript_path: str,
    video_url: Optional[str] = None,
    video_info: Optional[Dict[str, Any]] = None,
    output_dir: Optional[str] = None
) -> Optional[str]:
    """
    Create formatted markdown output from transcript
    
    Args:
        transcript_path: Path to transcript file
        video_url: Original video URL
        video_info: Video metadata
        output_dir: Directory to save markdown file
        
    Returns:
        Path to markdown file or None if failed
    """
    transcript_path = Path(transcript_path)
    
    if not transcript_path.exists():
        print(f"Error: Transcript file not found: {transcript_path}")
        return None
    
    try:
        # Read transcript
        with open(transcript_path, 'r', encoding='utf-8') as f:
            text = f.read()
        
        # Clean text
        text = clean_text(text)
        
        # Create markdown content
        md_lines = []
        
        # Header
        title = "YouTube Transcript"
        if video_info and 'title' in video_info:
            title = video_info['title']
        
        md_lines.append(f"# {title}")
        md_lines.append("")
        
        # Metadata
        md_lines.append("---")
        md_lines.append(f"**Created on:** {datetime.now().strftime('%m/%d/%Y %H:%M')}")
        
        if video_url:
            md_lines.append(f"**Video URL:** {video_url}")
            video_id = extract_video_id(video_url)
            if video_id:
                md_lines.append(f"**Video ID:** {video_id}")
        
        if video_info:
            if 'uploader' in video_info:
                md_lines.append(f"**Channel:** {video_info['uploader']}")
            if 'duration' in video_info:
                duration = format_timestamp(video_info['duration'])
                md_lines.append(f"**Duration:** {duration}")
            if 'view_count' in video_info:
                views = f"{video_info['view_count']:,}"
                md_lines.append(f"**Views:** {views}")
        
        md_lines.append("---")
        md_lines.append("")
        
        # Table of contents
        md_lines.append("## Content")
        md_lines.append("")
        
        # Split into paragraphs
        paragraphs = split_into_paragraphs(text)
        
        # Add paragraphs with headers
        for i, paragraph in enumerate(paragraphs, 1):
            if len(paragraphs) > 1:
                md_lines.append(f"### Part {i}")
                md_lines.append("")
            
            # Wrap long lines
            wrapped = textwrap.fill(paragraph, width=80, break_long_words=False)
            md_lines.append(wrapped)
            md_lines.append("")
        
        # Statistics
        md_lines.append("---")
        md_lines.append("## Statistics")
        md_lines.append("")
        word_count = len(text.split())
        char_count = len(text)
        md_lines.append(f"- **Words:** {word_count:,}")
        md_lines.append(f"- **Characters:** {char_count:,}")
        md_lines.append(f"- **Paragraphs:** {len(paragraphs)}")
        
        # Join lines
        markdown_content = '\n'.join(md_lines)
        
        # Save markdown file
        if output_dir is None:
            output_dir = transcript_path.parent
        
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Generate filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        if video_info and 'title' in video_info:
            # Sanitize title for filename
            safe_title = re.sub(r'[^\w\s-]', '', video_info['title'])
            safe_title = re.sub(r'[-\s]+', '-', safe_title)[:50]
            md_file = output_dir / f"{safe_title}_{timestamp}.md"
        else:
            md_file = output_dir / f"transcript_{timestamp}.md"
        
        with open(md_file, 'w', encoding='utf-8') as f:
            f.write(markdown_content)
        
        print(f"Markdown file saved to: {md_file}")
        return str(md_file)
        
    except Exception as e:
        print(f"Error creating markdown: {e}")
        return None


def create_srt_output(
    segments_path: str,
    output_dir: Optional[str] = None
) -> Optional[str]:
    """
    Create SRT subtitle file from segments
    
    Args:
        segments_path: Path to segments JSON file
        output_dir: Directory to save SRT file
        
    Returns:
        Path to SRT file or None if failed
    """
    segments_path = Path(segments_path)
    
    if not segments_path.exists():
        print(f"Error: Segments file not found: {segments_path}")
        return None
    
    try:
        # Load segments
        with open(segments_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        if 'segments' not in data:
            print("Error: No segments found in file")
            return None
        
        segments = data['segments']
        
        # Create SRT content
        srt_lines = []
        
        for i, segment in enumerate(segments, 1):
            # Index
            srt_lines.append(str(i))
            
            # Timestamps
            start = format_srt_timestamp(segment['start'])
            end = format_srt_timestamp(segment['end'])
            srt_lines.append(f"{start} --> {end}")
            
            # Text
            text = segment['text'].strip()
            srt_lines.append(text)
            srt_lines.append("")  # Empty line between entries
        
        srt_content = '\n'.join(srt_lines)
        
        # Save SRT file
        if output_dir is None:
            output_dir = segments_path.parent
        
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        srt_file = output_dir / f"subtitles_{timestamp}.srt"
        
        with open(srt_file, 'w', encoding='utf-8') as f:
            f.write(srt_content)
        
        print(f"SRT file saved to: {srt_file}")
        return str(srt_file)
        
    except Exception as e:
        print(f"Error creating SRT: {e}")
        return None


def format_srt_timestamp(seconds: float) -> str:
    """
    Format seconds to SRT timestamp format (HH:MM:SS,mmm)
    
    Args:
        seconds: Time in seconds
        
    Returns:
        SRT formatted timestamp
    """
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int((seconds % 1) * 1000)
    
    return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"


def main():
    """Main function for CLI usage"""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python postprocess.py <transcript_file> [video_url]")
        sys.exit(1)
    
    transcript_file = sys.argv[1]
    video_url = sys.argv[2] if len(sys.argv) > 2 else None
    
    result = create_markdown_output(transcript_file, video_url)
    
    if result:
        print(f"\nSuccess! Markdown file: {result}")
    else:
        print("\nError: Failed to create markdown")
        sys.exit(1)


if __name__ == "__main__":
    main()
