"""
Fix names in transcripts using a glossary
"""
import json
import re
from pathlib import Path
from typing import Dict, List, Tuple


def load_glossary(glossary_path: str = None) -> Dict[str, str]:
    """
    Load name glossary from JSON file
    
    Args:
        glossary_path: Path to glossary JSON file
    
    Returns:
        Dictionary mapping incorrect names to correct names
    """
    if glossary_path is None:
        glossary_path = Path(__file__).parent.parent / "config" / "glossar.json"
    
    glossary_path = Path(glossary_path)
    
    if not glossary_path.exists():
        print(f"Glossary not found at {glossary_path}, using empty glossary")
        return {}
    
    try:
        with open(glossary_path, 'r', encoding='utf-8') as f:
            glossary = json.load(f)
        print(f"Loaded {len(glossary)} entries from glossary")
        return glossary
    except Exception as e:
        print(f"Error loading glossary: {e}")
        return {}


def create_replacement_patterns(glossary: Dict[str, str]) -> List[Tuple[re.Pattern, str]]:
    """
    Create regex patterns for name replacement
    
    Args:
        glossary: Dictionary of name mappings
    
    Returns:
        List of (pattern, replacement) tuples
    """
    patterns = []
    
    for incorrect, correct in glossary.items():
        # Create pattern that matches word boundaries
        # Case-insensitive matching
        pattern = re.compile(r'\b' + re.escape(incorrect) + r'\b', re.IGNORECASE)
        patterns.append((pattern, correct))
    
    return patterns


def fix_names_in_text(text: str, patterns: List[Tuple[re.Pattern, str]]) -> str:
    """
    Fix names in text using replacement patterns
    
    Args:
        text: Input text
        patterns: List of (pattern, replacement) tuples
    
    Returns:
        Text with fixed names
    """
    fixed_text = text
    replacements_made = 0
    
    for pattern, replacement in patterns:
        # Count replacements
        matches = pattern.findall(fixed_text)
        replacements_made += len(matches)
        
        # Replace all occurrences
        fixed_text = pattern.sub(replacement, fixed_text)
    
    if replacements_made > 0:
        print(f"Made {replacements_made} replacements")
    
    return fixed_text


def fix_names_in_transcript(transcript_path: str, glossary_path: str = None) -> str:
    """
    Fix names in a transcript file
    
    Args:
        transcript_path: Path to transcript file
        glossary_path: Optional path to glossary file
    
    Returns:
        Path to fixed transcript file
    """
    transcript_path = Path(transcript_path)
    
    if not transcript_path.exists():
        raise FileNotFoundError(f"Transcript not found: {transcript_path}")
    
    # Load glossary
    glossary = load_glossary(glossary_path)
    
    if not glossary:
        print("No glossary entries, returning original transcript")
        return str(transcript_path)
    
    # Create patterns
    patterns = create_replacement_patterns(glossary)
    
    # Read transcript
    with open(transcript_path, 'r', encoding='utf-8') as f:
        text = f.read()
    
    # Fix names
    fixed_text = fix_names_in_text(text, patterns)
    
    # Save fixed transcript
    output_dir = transcript_path.parent.parent / "fixed"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    output_path = output_dir / f"fixed_{transcript_path.name}"
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(fixed_text)
    
    print(f"Fixed transcript saved to: {output_path}")
    return str(output_path)


def batch_fix_transcripts(transcript_dir: str, glossary_path: str = None):
    """
    Fix names in all transcripts in a directory
    
    Args:
        transcript_dir: Directory containing transcript files
        glossary_path: Optional path to glossary file
    """
    transcript_dir = Path(transcript_dir)
    
    if not transcript_dir.exists():
        raise FileNotFoundError(f"Directory not found: {transcript_dir}")
    
    # Find all .txt files
    transcript_files = list(transcript_dir.glob("*.txt"))
    
    if not transcript_files:
        print(f"No transcript files found in {transcript_dir}")
        return
    
    print(f"Found {len(transcript_files)} transcript files")
    
    # Process each file
    for transcript_path in transcript_files:
        try:
            print(f"\nProcessing: {transcript_path.name}")
            fix_names_in_transcript(str(transcript_path), glossary_path)
        except Exception as e:
            print(f"Error processing {transcript_path.name}: {e}")


if __name__ == "__main__":
    # Example usage
    import sys
    
    if len(sys.argv) > 1:
        transcript_path = sys.argv[1]
        glossary_path = sys.argv[2] if len(sys.argv) > 2 else None
        
        try:
            fixed_path = fix_names_in_transcript(transcript_path, glossary_path)
            print(f"Success! Fixed transcript at: {fixed_path}")
        except Exception as e:
            print(f"Error: {e}")
    else:
        print("Usage: python fix_names.py <transcript_path> [glossary_path]")
