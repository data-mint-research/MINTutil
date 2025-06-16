"""
Post-processing module for creating formatted output
"""
from pathlib import Path
from datetime import datetime
import re
from urllib.parse import urlparse, parse_qs


def extract_video_info(url: str) -> dict:
    """
    Extract video information from YouTube URL
    
    Args:
        url: YouTube video URL
    
    Returns:
        Dictionary with video information
    """
    parsed = urlparse(url)
    video_id = None
    
    # Extract video ID
    if parsed.hostname in ['www.youtube.com', 'youtube.com']:
        if parsed.path == '/watch':
            video_id = parse_qs(parsed.query).get('v', [None])[0]
    elif parsed.hostname == 'youtu.be':
        video_id = parsed.path.lstrip('/')
    
    return {
        'url': url,
        'video_id': video_id,
        'embed_url': f'https://www.youtube.com/embed/{video_id}' if video_id else None
    }


def format_transcript_as_markdown(text: str, video_info: dict = None) -> str:
    """
    Format transcript as Markdown with metadata
    
    Args:
        text: Transcript text
        video_info: Optional video information
    
    Returns:
        Formatted Markdown content
    """
    # Create header
    header = f"# Transkript\n\n"
    header += f"**Erstellt am:** {datetime.now().strftime('%d.%m.%Y %H:%M')}\n\n"
    
    if video_info:
        header += "## Video Information\n\n"
        if video_info.get('url'):
            header += f"**Original URL:** {video_info['url']}\n\n"
        if video_info.get('embed_url'):
            header += f"**Video ID:** {video_info.get('video_id', 'Unknown')}\n\n"
    
    header += "---\n\n"
    
    # Format transcript text
    # Split into paragraphs (assuming double newlines or long sentences)
    paragraphs = split_into_paragraphs(text)
    
    formatted_text = "## Transkript\n\n"
    for paragraph in paragraphs:
        formatted_text += f"{paragraph}\n\n"
    
    # Add footer
    footer = "\n---\n\n"
    footer += "*Dieses Transkript wurde automatisch erstellt und kann Fehler enthalten.*\n"
    
    return header + formatted_text + footer


def split_into_paragraphs(text: str, min_length: int = 200) -> list:
    """
    Split text into paragraphs based on sentence endings
    
    Args:
        text: Input text
        min_length: Minimum paragraph length
    
    Returns:
        List of paragraphs
    """
    # Clean text
    text = text.strip()
    
    # Split by sentence endings
    sentences = re.split(r'(?<=[.!?])\s+', text)
    
    paragraphs = []
    current_paragraph = ""
    
    for sentence in sentences:
        current_paragraph += sentence + " "
        
        # Create new paragraph if long enough
        if len(current_paragraph) >= min_length:
            paragraphs.append(current_paragraph.strip())
            current_paragraph = ""
    
    # Add remaining text
    if current_paragraph.strip():
        paragraphs.append(current_paragraph.strip())
    
    return paragraphs


def add_timestamps(text: str, duration: float = None) -> str:
    """
    Add estimated timestamps to transcript
    
    Args:
        text: Transcript text
        duration: Video duration in seconds
    
    Returns:
        Text with timestamps
    """
    if not duration:
        return text
    
    paragraphs = split_into_paragraphs(text)
    total_chars = sum(len(p) for p in paragraphs)
    
    timestamped_text = ""
    elapsed_chars = 0
    
    for paragraph in paragraphs:
        # Estimate timestamp based on character position
        timestamp_seconds = (elapsed_chars / total_chars) * duration
        timestamp = format_timestamp(timestamp_seconds)
        
        timestamped_text += f"**[{timestamp}]** {paragraph}\n\n"
        elapsed_chars += len(paragraph)
    
    return timestamped_text


def format_timestamp(seconds: float) -> str:
    """
    Format seconds as MM:SS or HH:MM:SS
    
    Args:
        seconds: Time in seconds
    
    Returns:
        Formatted timestamp string
    """
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    
    if hours > 0:
        return f"{hours:02d}:{minutes:02d}:{secs:02d}"
    else:
        return f"{minutes:02d}:{secs:02d}"


def create_markdown_output(transcript_path: str, video_url: str = None) -> str:
    """
    Create formatted Markdown output from transcript
    
    Args:
        transcript_path: Path to transcript file
        video_url: Optional YouTube video URL
    
    Returns:
        Path to Markdown file
    """
    transcript_path = Path(transcript_path)
    
    if not transcript_path.exists():
        raise FileNotFoundError(f"Transcript not found: {transcript_path}")
    
    # Read transcript
    with open(transcript_path, 'r', encoding='utf-8') as f:
        text = f.read()
    
    # Extract video info if URL provided
    video_info = extract_video_info(video_url) if video_url else None
    
    # Format as Markdown
    markdown_content = format_transcript_as_markdown(text, video_info)
    
    # Save Markdown file
    output_path = transcript_path.with_suffix('.md')
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(markdown_content)
    
    print(f"Markdown output saved to: {output_path}")
    return str(output_path)


def create_summary(text: str, max_sentences: int = 5) -> str:
    """
    Create a simple summary of the transcript
    
    Args:
        text: Transcript text
        max_sentences: Maximum number of sentences in summary
    
    Returns:
        Summary text
    """
    sentences = re.split(r'(?<=[.!?])\s+', text.strip())
    
    if len(sentences) <= max_sentences:
        return text
    
    # Simple extractive summary - take first and evenly distributed sentences
    indices = [0]  # Always include first sentence
    
    if max_sentences > 1:
        step = len(sentences) // (max_sentences - 1)
        for i in range(1, max_sentences - 1):
            indices.append(i * step)
        indices.append(len(sentences) - 1)  # Include last sentence
    
    summary_sentences = [sentences[i] for i in indices if i < len(sentences)]
    
    return ' '.join(summary_sentences)


if __name__ == "__main__":
    # Example usage
    import sys
    
    if len(sys.argv) > 1:
        transcript_path = sys.argv[1]
        video_url = sys.argv[2] if len(sys.argv) > 2 else None
        
        try:
            markdown_path = create_markdown_output(transcript_path, video_url)
            print(f"Success! Markdown at: {markdown_path}")
        except Exception as e:
            print(f"Error: {e}")
    else:
        print("Usage: python postprocess.py <transcript_path> [video_url]")
