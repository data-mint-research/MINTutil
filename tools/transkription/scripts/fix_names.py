#!/usr/bin/env python3
"""
Name Fixing Module
Corrects names and terms in transcript based on glossary
"""

import json
import re
from pathlib import Path
from typing import Dict, Optional
import logging

logger = logging.getLogger(__name__)

def load_glossary() -> Dict[str, str]:
    """
    Load glossary from JSON file
    
    Returns:
        Dictionary mapping incorrect spellings to correct ones
    """
    glossary_path = Path(__file__).parent.parent / "config" / "glossar.json"
    
    if not glossary_path.exists():
        logger.warning(f"Glossary not found at {glossary_path}, creating empty glossary")
        glossary_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Create default glossary
        default_glossary = {
            # Common AI/Tech terms
            "chat gpt": "ChatGPT",
            "chat-gpt": "ChatGPT",
            "open ai": "OpenAI",
            "open-ai": "OpenAI",
            "hugging face": "Hugging Face",
            "huggingface": "Hugging Face",
            "github": "GitHub",
            "git hub": "GitHub",
            "google": "Google",
            "microsoft": "Microsoft",
            "meta": "Meta",
            "anthropic": "Anthropic",
            
            # Common German terms
            "ki": "KI",
            "k?nstliche intelligenz": "K?nstliche Intelligenz",
            
            # Programming terms
            "python": "Python",
            "java script": "JavaScript",
            "javascript": "JavaScript",
            "type script": "TypeScript",
            "typescript": "TypeScript",
            "docker": "Docker",
            "kubernetes": "Kubernetes",
            "k8s": "Kubernetes",
            
            # Social Media
            "youtube": "YouTube",
            "you tube": "YouTube",
            "twitter": "Twitter",
            "x.com": "X.com",
            "linkedin": "LinkedIn",
            "linked in": "LinkedIn",
            "instagram": "Instagram",
            "tiktok": "TikTok",
            "tik tok": "TikTok"
        }
        
        with open(glossary_path, 'w', encoding='utf-8') as f:
            json.dump(default_glossary, f, ensure_ascii=False, indent=2)
        
        return default_glossary
    
    try:
        with open(glossary_path, 'r', encoding='utf-8') as f:
            glossary = json.load(f)
        logger.info(f"Loaded glossary with {len(glossary)} entries")
        return glossary
    except Exception as e:
        logger.error(f"Error loading glossary: {str(e)}")
        return {}

def fix_names_in_transcript(transcript_path: Path) -> Path:
    """
    Fix names and terms in transcript using glossary
    
    Args:
        transcript_path: Path to original transcript
        
    Returns:
        Path to fixed transcript
    """
    logger.info(f"Fixing names in transcript: {transcript_path}")
    
    # Load glossary
    glossary = load_glossary()
    
    if not glossary:
        logger.warning("No glossary entries found, returning original transcript")
        return transcript_path
    
    # Read transcript
    try:
        with open(transcript_path, 'r', encoding='utf-8') as f:
            text = f.read()
    except Exception as e:
        logger.error(f"Error reading transcript: {str(e)}")
        return transcript_path
    
    # Apply fixes
    fixed_text = apply_glossary_fixes(text, glossary)
    
    # Save fixed transcript
    fixed_dir = Path(__file__).parent.parent / "data" / "fixed"
    fixed_dir.mkdir(parents=True, exist_ok=True)
    
    fixed_path = fixed_dir / f"fixed_{transcript_path.name}"
    
    try:
        with open(fixed_path, 'w', encoding='utf-8') as f:
            f.write(fixed_text)
        logger.info(f"Saved fixed transcript to: {fixed_path}")
        return fixed_path
    except Exception as e:
        logger.error(f"Error saving fixed transcript: {str(e)}")
        return transcript_path

def apply_glossary_fixes(text: str, glossary: Dict[str, str]) -> str:
    """
    Apply glossary fixes to text
    
    Args:
        text: Original text
        glossary: Dictionary of replacements
        
    Returns:
        Fixed text
    """
    fixed_text = text
    replacements_made = 0
    
    # Sort glossary by key length (longest first) to avoid partial replacements
    sorted_glossary = sorted(glossary.items(), key=lambda x: len(x[0]), reverse=True)
    
    for incorrect, correct in sorted_glossary:
        # Create case-insensitive pattern with word boundaries
        # This ensures we match whole words/phrases only
        pattern = r'\b' + re.escape(incorrect) + r'\b'
        
        # Count replacements
        matches = re.findall(pattern, fixed_text, re.IGNORECASE)
        if matches:
            replacements_made += len(matches)
            logger.debug(f"Replacing {len(matches)} instances of '{incorrect}' with '{correct}'")
        
        # Perform replacement preserving case where possible
        def replace_preserve_case(match):
            original = match.group(0)
            
            # If original is all uppercase, return correct in uppercase
            if original.isupper():
                return correct.upper()
            
            # If original is title case, return correct in title case
            if original[0].isupper() and original[1:].islower():
                return correct[0].upper() + correct[1:]
            
            # Otherwise return correct as-is
            return correct
        
        fixed_text = re.sub(pattern, replace_preserve_case, fixed_text, flags=re.IGNORECASE)
    
    logger.info(f"Made {replacements_made} replacements")
    return fixed_text

def add_to_glossary(incorrect: str, correct: str) -> bool:
    """
    Add entry to glossary
    
    Args:
        incorrect: Incorrect spelling
        correct: Correct spelling
        
    Returns:
        True if successful
    """
    glossary = load_glossary()
    glossary[incorrect] = correct
    
    glossary_path = Path(__file__).parent.parent / "config" / "glossar.json"
    
    try:
        with open(glossary_path, 'w', encoding='utf-8') as f:
            json.dump(glossary, f, ensure_ascii=False, indent=2)
        logger.info(f"Added to glossary: '{incorrect}' -> '{correct}'")
        return True
    except Exception as e:
        logger.error(f"Error saving glossary: {str(e)}")
        return False

def remove_from_glossary(incorrect: str) -> bool:
    """
    Remove entry from glossary
    
    Args:
        incorrect: Key to remove
        
    Returns:
        True if successful
    """
    glossary = load_glossary()
    
    if incorrect in glossary:
        del glossary[incorrect]
        
        glossary_path = Path(__file__).parent.parent / "config" / "glossar.json"
        
        try:
            with open(glossary_path, 'w', encoding='utf-8') as f:
                json.dump(glossary, f, ensure_ascii=False, indent=2)
            logger.info(f"Removed from glossary: '{incorrect}'")
            return True
        except Exception as e:
            logger.error(f"Error saving glossary: {str(e)}")
            return False
    else:
        logger.warning(f"Entry not found in glossary: '{incorrect}'")
        return False

if __name__ == "__main__":
    # Test with sample transcript
    import sys
    if len(sys.argv) > 1:
        transcript_path = Path(sys.argv[1])
        if transcript_path.exists():
            fixed_path = fix_names_in_transcript(transcript_path)
            print(f"Fixed transcript saved to: {fixed_path}")
        else:
            print(f"File not found: {transcript_path}")
    else:
        print("Usage: python fix_names.py <transcript_path>")