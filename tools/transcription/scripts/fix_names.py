#!/usr/bin/env python3
"""
Name fixing module for transcripts using glossary
"""

import json
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import difflib
from datetime import datetime


def load_glossary(glossary_path: Optional[str] = None) -> Dict[str, str]:
    """
    Load glossary from JSON file
    
    Args:
        glossary_path: Path to glossary file
        
    Returns:
        Dictionary mapping incorrect to correct spellings
    """
    if glossary_path is None:
        # Default glossary path
        glossary_path = Path(__file__).parent.parent / "config" / "glossary.json"
    
    glossary_path = Path(glossary_path)
    
    if not glossary_path.exists():
        print(f"Warning: Glossary file not found at {glossary_path}")
        return {}
    
    try:
        with open(glossary_path, 'r', encoding='utf-8') as f:
            glossary = json.load(f)
        
        print(f"Loaded {len(glossary)} entries from glossary")
        return glossary
        
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in glossary file: {e}")
        return {}
    except Exception as e:
        print(f"Error loading glossary: {e}")
        return {}


def create_regex_pattern(term: str) -> str:
    """
    Create a regex pattern for case-insensitive word matching
    
    Args:
        term: The term to create a pattern for
        
    Returns:
        Regex pattern string
    """
    # Escape special regex characters
    escaped = re.escape(term)
    
    # Create word boundary pattern
    # This ensures we match whole words only
    pattern = r'\b' + escaped + r'\b'
    
    return pattern


def fix_names_in_text(text: str, glossary: Dict[str, str]) -> Tuple[str, List[Dict[str, any]]]:
    """
    Fix names and terms in text using glossary
    
    Args:
        text: The text to fix
        glossary: Dictionary mapping incorrect to correct terms
        
    Returns:
        Tuple of (fixed_text, list_of_replacements)
    """
    if not glossary:
        return text, []
    
    fixed_text = text
    replacements = []
    
    # Sort by length (longest first) to avoid partial replacements
    sorted_terms = sorted(glossary.items(), key=lambda x: len(x[0]), reverse=True)
    
    for incorrect, correct in sorted_terms:
        pattern = create_regex_pattern(incorrect)
        
        # Find all matches
        matches = list(re.finditer(pattern, fixed_text, re.IGNORECASE))
        
        if matches:
            # Replace from end to beginning to maintain positions
            for match in reversed(matches):
                start, end = match.span()
                original = fixed_text[start:end]
                
                # Preserve original case pattern
                if original.isupper():
                    replacement = correct.upper()
                elif original[0].isupper():
                    replacement = correct[0].upper() + correct[1:]
                else:
                    replacement = correct.lower()
                
                fixed_text = fixed_text[:start] + replacement + fixed_text[end:]
                
                replacements.append({
                    'original': original,
                    'replacement': replacement,
                    'position': start,
                    'incorrect_term': incorrect,
                    'correct_term': correct
                })
    
    # Sort replacements by position
    replacements.sort(key=lambda x: x['position'])
    
    return fixed_text, replacements


def fix_names_in_transcript(
    transcript_path: str,
    glossary_path: Optional[str] = None,
    output_dir: Optional[str] = None
) -> Optional[str]:
    """
    Fix names in a transcript file using glossary
    
    Args:
        transcript_path: Path to transcript file
        glossary_path: Path to glossary file
        output_dir: Directory to save fixed transcript
        
    Returns:
        Path to fixed transcript file or None if failed
    """
    transcript_path = Path(transcript_path)
    
    if not transcript_path.exists():
        print(f"Error: Transcript file not found: {transcript_path}")
        return None
    
    # Load glossary
    glossary = load_glossary(glossary_path)
    
    if not glossary:
        print("No glossary entries found, returning original transcript")
        return str(transcript_path)
    
    try:
        # Read transcript
        with open(transcript_path, 'r', encoding='utf-8') as f:
            text = f.read()
        
        print(f"Processing transcript: {transcript_path}")
        print(f"Original length: {len(text)} characters")
        
        # Fix names
        fixed_text, replacements = fix_names_in_text(text, glossary)
        
        print(f"Made {len(replacements)} replacements")
        
        # Save fixed transcript
        if output_dir is None:
            output_dir = Path(__file__).parent.parent / "data" / "fixed"
        
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Generate output filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        fixed_file = output_dir / f"fixed_{timestamp}.txt"
        
        with open(fixed_file, 'w', encoding='utf-8') as f:
            f.write(fixed_text)
        
        print(f"Fixed transcript saved to: {fixed_file}")
        
        # Save replacement log
        if replacements:
            log_file = output_dir / f"replacements_{timestamp}.json"
            with open(log_file, 'w', encoding='utf-8') as f:
                json.dump(replacements, f, ensure_ascii=False, indent=2)
            print(f"Replacement log saved to: {log_file}")
        
        return str(fixed_file)
        
    except Exception as e:
        print(f"Error fixing names: {e}")
        return None


def suggest_corrections(text: str, glossary: Dict[str, str], threshold: float = 0.8) -> List[Dict[str, any]]:
    """
    Suggest potential corrections based on similarity
    
    Args:
        text: Text to analyze
        glossary: Dictionary of known correct terms
        threshold: Similarity threshold (0-1)
        
    Returns:
        List of suggested corrections
    """
    suggestions = []
    words = set(re.findall(r'\b\w+\b', text))
    correct_terms = list(glossary.values())
    
    for word in words:
        if len(word) < 3:  # Skip short words
            continue
        
        # Check if word is already in glossary (as incorrect or correct)
        if word in glossary or word in correct_terms:
            continue
        
        # Find similar terms
        matches = difflib.get_close_matches(word, correct_terms, n=3, cutoff=threshold)
        
        if matches:
            suggestions.append({
                'word': word,
                'suggestions': matches,
                'confidence': difflib.SequenceMatcher(None, word, matches[0]).ratio()
            })
    
    # Sort by confidence
    suggestions.sort(key=lambda x: x['confidence'], reverse=True)
    
    return suggestions


def main():
    """Main function for CLI usage"""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python fix_names.py <transcript_file> [glossary_file]")
        sys.exit(1)
    
    transcript_file = sys.argv[1]
    glossary_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    result = fix_names_in_transcript(transcript_file, glossary_file)
    
    if result:
        print(f"\nSuccess! Fixed transcript: {result}")
    else:
        print("\nError: Failed to fix transcript")
        sys.exit(1)


if __name__ == "__main__":
    main()
