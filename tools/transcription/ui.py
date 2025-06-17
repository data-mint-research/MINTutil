import streamlit as st
from pathlib import Path
import subprocess
import json
import time
import re
import os
from datetime import datetime
import sys
import importlib.util

# Add tool scripts to path
tool_path = Path(__file__).parent
sys.path.insert(0, str(tool_path))

# Robust module import function
def import_module_from_path(module_name, file_path):
    """Import a module from a specific file path"""
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    if spec and spec.loader:
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    return None

def render():
    """Main UI render function for YouTube Transcription Tool"""
    st.title("? YouTube Transcription")
    st.markdown("""
    Transcribes YouTube videos with OpenAI Whisper and corrects names/terms using a glossary.
    
    ### Features:
    - ? Automatic video download
    - ? Audio extraction and transcription
    - ? Glossary-based correction
    - ? Export as Markdown
    """)
    
    # Initialize session state
    if 'transcription_status' not in st.session_state:
        st.session_state.transcription_status = None
    if 'current_transcript' not in st.session_state:
        st.session_state.current_transcript = None
    if 'fixed_transcript' not in st.session_state:
        st.session_state.fixed_transcript = None
    
    # Check dependencies
    if not check_dependencies():
        return
    
    # Main input section
    col1, col2 = st.columns([3, 1])
    with col1:
        youtube_url = st.text_input(
            "YouTube URL",
            placeholder="https://www.youtube.com/watch?v=...",
            help="Enter the URL of the YouTube video"
        )
    
    with col2:
        whisper_model = st.selectbox(
            "Whisper Model",
            ["tiny", "base", "small", "medium", "large"],
            index=1,
            help="Larger models are more accurate but slower"
        )
    
    # Process button
    if st.button("? Start Transcription", type="primary", disabled=not youtube_url):
        if validate_youtube_url(youtube_url):
            process_video(youtube_url, whisper_model)
        else:
            st.error("? Invalid YouTube URL")
    
    # Status display
    if st.session_state.transcription_status:
        display_status()
    
    # Results display
    if st.session_state.current_transcript:
        display_results()
    
    # Glossary management
    with st.expander("? Manage Glossary"):
        manage_glossary()
    
    # Recent transcriptions
    with st.expander("? Recent Transcriptions"):
        show_recent_transcriptions()

def check_dependencies():
    """Check if all required dependencies are installed"""
    missing_deps = []
    
    # Check Python packages
    try:
        import whisper
    except ImportError:
        missing_deps.append("openai-whisper")
    
    try:
        import yt_dlp
    except ImportError:
        missing_deps.append("yt-dlp")
    
    # Check FFmpeg
    try:
        result = subprocess.run(["ffmpeg", "-version"], capture_output=True, text=True)
        if result.returncode != 0:
            missing_deps.append("FFmpeg (System)")
    except FileNotFoundError:
        missing_deps.append("FFmpeg (System)")
    
    if missing_deps:
        st.error("? Missing dependencies:")
        for dep in missing_deps:
            st.write(f"- {dep}")
        st.info("? Install missing dependencies with: pip install -r requirements.txt")
        if "FFmpeg" in str(missing_deps):
            st.info("? Install FFmpeg: https://ffmpeg.org/download.html")
        return False
    
    return True

def validate_youtube_url(url):
    """Validate YouTube URL format"""
    youtube_regex = re.compile(
        r'^(https?://)?(www\.)?(youtube\.com/(watch\?v=|embed/)|youtu\.be/)[\w-]+(&[\w=]*)?$'
    )
    return youtube_regex.match(url) is not None

def process_video(url, model):
    """Process video transcription"""
    st.session_state.transcription_status = "starting"
    st.session_state.current_transcript = None
    st.session_state.fixed_transcript = None
    
    # Create necessary directories
    create_directories()
    
    # Start transcription process
    with st.spinner("Processing in progress..."):
        try:
            # Step 1: Download audio
            update_status("downloading", "Video is being downloaded...")
            audio_path = download_audio(url)
            
            if not audio_path:
                st.error("? Error during download")
                st.session_state.transcription_status = None
                return
            
            # Step 2: Transcribe
            update_status("transcribing", "Audio is being transcribed...")
            transcript_path = transcribe_audio(audio_path, model)
            
            if not transcript_path:
                st.error("? Error during transcription")
                st.session_state.transcription_status = None
                return
            
            # Step 3: Fix names
            update_status("fixing", "Names are being corrected...")
            fixed_path = fix_transcript(transcript_path)
            
            # Step 4: Create markdown
            update_status("formatting", "Markdown is being created...")
            markdown_path = create_markdown(fixed_path, url)
            
            # Load results
            with open(transcript_path, 'r', encoding='utf-8') as f:
                st.session_state.current_transcript = f.read()
            
            with open(markdown_path, 'r', encoding='utf-8') as f:
                st.session_state.fixed_transcript = f.read()
            
            update_status("complete", "? Transcription completed!")
            
        except Exception as e:
            st.error(f"? Error: {str(e)}")
            st.session_state.transcription_status = None
            log_error(f"Process error: {str(e)}")

def create_directories():
    """Create necessary directories"""
    dirs = [
        "data/raw",
        "data/fixed",
        "data/audio",
        "logs"
    ]
    for dir_path in dirs:
        Path(tool_path / dir_path).mkdir(parents=True, exist_ok=True)

def download_audio(url):
    """Download audio from YouTube video"""
    try:
        # Import module dynamically
        transcribe_module = import_module_from_path(
            "transcribe", 
            tool_path / "scripts" / "transcribe.py"
        )
        if transcribe_module:
            return transcribe_module.download_youtube_audio(url)
        else:
            raise ImportError("Could not import transcribe module")
    except Exception as e:
        log_error(f"Download error: {str(e)}")
        return None

def transcribe_audio(audio_path, model):
    """Transcribe audio using Whisper"""
    try:
        transcribe_module = import_module_from_path(
            "transcribe", 
            tool_path / "scripts" / "transcribe.py"
        )
        if transcribe_module:
            return transcribe_module.transcribe_with_whisper(audio_path, model)
        else:
            raise ImportError("Could not import transcribe module")
    except Exception as e:
        log_error(f"Transcription error: {str(e)}")
        return None

def fix_transcript(transcript_path):
    """Fix names in transcript using glossary"""
    try:
        fix_names_module = import_module_from_path(
            "fix_names", 
            tool_path / "scripts" / "fix_names.py"
        )
        if fix_names_module:
            return fix_names_module.fix_names_in_transcript(transcript_path)
        else:
            raise ImportError("Could not import fix_names module")
    except Exception as e:
        log_error(f"Fix names error: {str(e)}")
        return transcript_path

def create_markdown(transcript_path, url):
    """Create markdown file from transcript"""
    try:
        postprocess_module = import_module_from_path(
            "postprocess", 
            tool_path / "scripts" / "postprocess.py"
        )
        if postprocess_module:
            return postprocess_module.create_markdown_output(transcript_path, url)
        else:
            raise ImportError("Could not import postprocess module")
    except Exception as e:
        log_error(f"Markdown creation error: {str(e)}")
        return transcript_path

def update_status(status, message):
    """Update processing status"""
    st.session_state.transcription_status = {
        "status": status,
        "message": message,
        "timestamp": datetime.now().strftime("%H:%M:%S")
    }

def display_status():
    """Display current processing status"""
    status = st.session_state.transcription_status
    
    if isinstance(status, dict):
        status_icons = {
            "starting": "?",
            "downloading": "?",
            "transcribing": "?",
            "fixing": "?",
            "formatting": "?",
            "complete": "?"
        }
        
        icon = status_icons.get(status["status"], "?")
        st.info(f"{icon} {status['message']} ({status['timestamp']})")

def display_results():
    """Display transcription results"""
    st.markdown("---")
    st.subheader("? Results")
    
    tab1, tab2, tab3 = st.tabs(["Original", "Corrected", "Markdown"])
    
    with tab1:
        st.text_area(
            "Original Transcript",
            st.session_state.current_transcript,
            height=400,
            key="original_transcript"
        )
        if st.button("? Copy", key="copy_original"):
            st.code(st.session_state.current_transcript)
    
    with tab2:
        if st.session_state.fixed_transcript:
            # Extract text from markdown
            text_only = re.sub(r'^#.*\n', '', st.session_state.fixed_transcript, flags=re.MULTILINE)
            text_only = re.sub(r'\*\*.*?\*\*', '', text_only)
            text_only = re.sub(r'---.*?---', '', text_only, flags=re.DOTALL)
            
            st.text_area(
                "Corrected Transcript",
                text_only.strip(),
                height=400,
                key="fixed_transcript"
            )
    
    with tab3:
        if st.session_state.fixed_transcript:
            st.markdown(st.session_state.fixed_transcript)
            
            # Download button
            st.download_button(
                label="? Download Markdown",
                data=st.session_state.fixed_transcript,
                file_name=f"transcript_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md",
                mime="text/markdown"
            )

def manage_glossary():
    """Manage glossary entries"""
    glossary_path = tool_path / "config" / "glossary.json"
    
    # Ensure config directory exists
    glossary_path.parent.mkdir(exist_ok=True)
    
    # Load glossary
    if glossary_path.exists():
        try:
            with open(glossary_path, 'r', encoding='utf-8') as f:
                glossary = json.load(f)
        except json.JSONDecodeError:
            glossary = {}
            st.warning("?? Glossary file is corrupted, creating new one...")
    else:
        glossary = {}
    
    # Display current entries
    if glossary:
        st.markdown("**Current Entries:**")
        for key, value in glossary.items():
            col1, col2, col3 = st.columns([2, 2, 1])
            with col1:
                st.text(key)
            with col2:
                st.text(value)
            with col3:
                if st.button("??", key=f"del_{key}"):
                    del glossary[key]
                    save_glossary(glossary)
                    st.rerun()
    
    # Add new entry
    st.markdown("**New Entry:**")
    col1, col2, col3 = st.columns([2, 2, 1])
    with col1:
        new_key = st.text_input("Incorrect Spelling", key="new_key")
    with col2:
        new_value = st.text_input("Correct Spelling", key="new_value")
    with col3:
        if st.button("? Add") and new_key and new_value:
            glossary[new_key] = new_value
            save_glossary(glossary)
            st.success("? Entry added")
            st.rerun()

def save_glossary(glossary):
    """Save glossary to file"""
    glossary_path = tool_path / "config" / "glossary.json"
    glossary_path.parent.mkdir(exist_ok=True)
    
    with open(glossary_path, 'w', encoding='utf-8') as f:
        json.dump(glossary, f, ensure_ascii=False, indent=2)

def show_recent_transcriptions():
    """Show recent transcription files"""
    fixed_dir = tool_path / "data" / "fixed"
    
    if not fixed_dir.exists():
        st.info("No transcriptions available yet")
        return
    
    # Get recent files
    files = sorted(fixed_dir.glob("*.md"), key=lambda x: x.stat().st_mtime, reverse=True)[:10]
    
    if not files:
        st.info("No transcriptions available yet")
        return
    
    for file in files:
        col1, col2 = st.columns([3, 1])
        with col1:
            st.text(file.name)
        with col2:
            if st.button("? Open", key=f"open_{file.name}"):
                with open(file, 'r', encoding='utf-8') as f:
                    st.session_state.fixed_transcript = f.read()
                st.rerun()

def log_error(message):
    """Log error message"""
    log_path = tool_path / "logs" / "transcription.log"
    log_path.parent.mkdir(exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(log_path, 'a', encoding='utf-8') as f:
        f.write(f"[{timestamp}] ERROR: {message}\n")
