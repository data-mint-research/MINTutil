import streamlit as st
from pathlib import Path
import sys

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
        st.image("https://via.placeholder.com/300x100.png?text=MINTutil", use_column_width=True)
        st.markdown("---")
        
        # Get available tools
        tools = st.session_state.page_loader.get_available_tools()
        
        if not tools:
            st.warning("Keine Tools gefunden")
            return None
        
        st.markdown("### ? Verf?gbare Tools")
        
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
        
    elif st.session_state.selected_tool == "__health_check__":
        st.title("? System Health Check")
        st.info("Health Check wird implementiert...")
        
    elif st.session_state.selected_tool == "__logs__":
        st.title("? System Logs")
        st.info("Log-Viewer wird implementiert...")
        
    elif st.session_state.selected_tool == "__settings__":
        st.title("?? Einstellungen")
        st.info("Einstellungen werden implementiert...")
        
    else:
        # Load and render selected tool
        success = st.session_state.page_loader.render_tool(st.session_state.selected_tool)
        if not success:
            st.error(f"Tool '{st.session_state.selected_tool}' konnte nicht geladen werden")
            st.session_state.selected_tool = None

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
