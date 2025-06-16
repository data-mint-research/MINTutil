import streamlit as st
from pathlib import Path
import sys
import os
from datetime import datetime

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

from streamlit_app.page_loader import PageLoader

def initialize_session_state():
    """Initialize session state variables"""
    if 'selected_tool' not in st.session_state:
        st.session_state.selected_tool = None
    if 'page_loader' not in st.session_state:
        st.session_state.page_loader = PageLoader()

def render_sidebar():
    """Render the sidebar with tool selection"""
    with st.sidebar:
        # Logo or header
        logo_path = Path(__file__).parent.parent / "assets" / "logo.png"
        if logo_path.exists():
            st.image(str(logo_path), use_column_width=True)
        else:
            st.markdown("# ? MINTutil")
        
        st.markdown("---")
        
        # Get available tools
        tools = st.session_state.page_loader.get_available_tools()
        
        if not tools:
            st.warning("Keine Tools gefunden")
            return None
        
        st.markdown("### ?? Verf?gbare Tools")
        
        # Tool selection
        selected = None
        for tool_id, tool_info in tools.items():
            icon = tool_info.get('icon', '?')
            name = tool_info.get('name', tool_id)
            description = tool_info.get('description', '')
            
            if st.button(
                f"{icon} {name}",
                key=f"tool_{tool_id}",
                help=description,
                use_container_width=True
            ):
                selected = tool_id
                
        # Footer
        st.markdown("---")
        st.markdown("### ? System")
        if st.button("? Health Check", use_container_width=True):
            selected = "__health_check__"
        if st.button("? Logs", use_container_width=True):
            selected = "__logs__"
        if st.button("?? Einstellungen", use_container_width=True):
            selected = "__settings__"
            
        st.markdown("---")
        st.caption("MINTutil v0.1.0")
        st.caption(f"? 2025 MINT-RESEARCH")
        
        return selected

def render_main_content():
    """Render the main content area"""
    if st.session_state.selected_tool is None:
        # Welcome screen
        st.title("? Willkommen bei MINTutil")
        st.markdown("""
        MINTutil ist Ihre zentrale Plattform f?r verschiedene Analyse- und Verarbeitungstools.
        
        ### ? Erste Schritte
        1. W?hlen Sie ein Tool aus der Sidebar
        2. Folgen Sie den Anweisungen des Tools
        3. Nutzen Sie die Ergebnisse f?r Ihre Arbeit
        
        ### ? Features
        - **Modulare Architektur**: Einfach neue Tools hinzuf?gen
        - **AI-Integration**: Optionale KI-Unterst?tzung
        - **Lokale Verarbeitung**: Ihre Daten bleiben bei Ihnen
        """)
        
        # Quick stats
        col1, col2, col3 = st.columns(3)
        with col1:
            st.metric("Verf?gbare Tools", len(st.session_state.page_loader.get_available_tools()))
        with col2:
            st.metric("System Status", "? Online")
        with col3:
            st.metric("Version", "0.1.0")
        
    elif st.session_state.selected_tool == "__health_check__":
        render_health_check()
        
    elif st.session_state.selected_tool == "__logs__":
        render_logs()
        
    elif st.session_state.selected_tool == "__settings__":
        render_settings()
        
    else:
        # Load and render selected tool
        try:
            success = st.session_state.page_loader.render_tool(st.session_state.selected_tool)
            if not success:
                st.error(f"Tool '{st.session_state.selected_tool}' konnte nicht geladen werden")
                st.session_state.selected_tool = None
        except Exception as e:
            st.error(f"Fehler beim Laden des Tools: {str(e)}")
            st.session_state.selected_tool = None

def render_health_check():
    """Render system health check"""
    st.title("? System Health Check")
    
    with st.spinner("F?hre Health Check durch..."):
        # Check Python version
        col1, col2 = st.columns(2)
        with col1:
            python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
            st.metric("Python Version", python_version, "?" if sys.version_info >= (3, 9) else "??")
        
        with col2:
            st.metric("Streamlit Version", st.__version__, "?")
        
        # Check directories
        st.subheader("? Verzeichnisse")
        dirs_to_check = ["tools", "data", "logs", "config"]
        for dir_name in dirs_to_check:
            dir_path = Path(__file__).parent.parent / dir_name
            if dir_path.exists():
                st.success(f"? {dir_name}/ - OK")
            else:
                st.error(f"? {dir_name}/ - Fehlt")
        
        # Check environment
        st.subheader("? Umgebungsvariablen")
        env_vars = ["APP_NAME", "APP_VERSION", "ENVIRONMENT"]
        for var in env_vars:
            value = os.getenv(var, "Nicht gesetzt")
            if value != "Nicht gesetzt":
                st.success(f"? {var}: {value}")
            else:
                st.warning(f"?? {var}: {value}")

def render_logs():
    """Render system logs"""
    st.title("? System Logs")
    
    log_dir = Path(__file__).parent.parent / "logs"
    if not log_dir.exists():
        st.warning("Kein Logs-Verzeichnis gefunden")
        return
    
    # Get log files
    log_files = list(log_dir.glob("*.log"))
    if not log_files:
        st.info("Keine Log-Dateien vorhanden")
        return
    
    # Select log file
    selected_log = st.selectbox(
        "Log-Datei ausw?hlen",
        log_files,
        format_func=lambda x: x.name
    )
    
    if selected_log:
        # Read and display log
        try:
            with open(selected_log, 'r', encoding='utf-8') as f:
                log_content = f.read()
            
            # Show last N lines
            lines = log_content.strip().split('\n')
            num_lines = st.slider("Anzahl Zeilen", 10, 100, 50)
            
            st.text_area(
                "Log-Inhalt",
                '\n'.join(lines[-num_lines:]),
                height=400
            )
            
            # Download button
            st.download_button(
                "?? Log herunterladen",
                log_content,
                file_name=f"{selected_log.name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
                mime="text/plain"
            )
            
        except Exception as e:
            st.error(f"Fehler beim Lesen der Log-Datei: {str(e)}")

def render_settings():
    """Render settings page"""
    st.title("?? Einstellungen")
    
    # Theme settings
    st.subheader("? Erscheinungsbild")
    theme = st.selectbox("Theme", ["Light", "Dark", "Auto"])
    
    # Language settings
    st.subheader("? Sprache")
    language = st.selectbox("Sprache", ["Deutsch", "English"])
    
    # Advanced settings
    with st.expander("? Erweiterte Einstellungen"):
        st.checkbox("Debug-Modus aktivieren")
        st.checkbox("Automatische Updates")
        st.number_input("Cache-Gr??e (MB)", min_value=100, max_value=10000, value=1000)
    
    # Save button
    if st.button("? Einstellungen speichern", type="primary"):
        st.success("Einstellungen gespeichert!")

def main():
    """Main application entry point"""
    st.set_page_config(
        page_title="MINTutil",
        page_icon="?",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    # Custom CSS
    st.markdown("""
    <style>
    .stButton > button {
        text-align: left;
        padding: 0.5rem 1rem;
    }
    .main > div {
        padding-top: 2rem;
    }
    </style>
    """, unsafe_allow_html=True)
    
    # Initialize session state
    initialize_session_state()
    
    # Render sidebar and get selection
    selected = render_sidebar()
    if selected is not None:
        st.session_state.selected_tool = selected
        st.rerun()
    
    # Render main content
    render_main_content()

if __name__ == "__main__":
    main()
