"""MINTutil Streamlit Application Main Entry Point"""

import streamlit as st
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

from page_loader import PageLoader

# Configure Streamlit page
st.set_page_config(
    page_title="MINTutil",
    page_icon="?",
    layout="wide",
    initial_sidebar_state="expanded",
    menu_items={
        'Get Help': 'https://github.com/data-mint-research/MINTutil',
        'Report a bug': 'https://github.com/data-mint-research/MINTutil/issues',
        'About': 'MINTutil - Modular Infrastructure and Network Tools'
    }
)

def main():
    """Main application function"""
    st.title("? MINTutil")
    st.markdown("### Modular Infrastructure and Network Tools")
    
    # Initialize page loader
    page_loader = PageLoader()
    
    # Sidebar navigation
    with st.sidebar:
        st.header("Navigation")
        # TODO: Implement dynamic page loading based on available modules
        selected_page = st.selectbox(
            "Select Tool",
            ["Dashboard", "Tools", "Configuration", "Logs"]
        )
    
    # Main content area
    if selected_page == "Dashboard":
        st.info("Dashboard - Overview of all tools and systems")
        # TODO: Implement dashboard
    elif selected_page == "Tools":
        st.info("Tools - Available MINTutil modules")
        # TODO: Implement tools listing
    elif selected_page == "Configuration":
        st.info("Configuration - System settings")
        # TODO: Implement configuration management
    elif selected_page == "Logs":
        st.info("Logs - System and application logs")
        # TODO: Implement log viewer
    
    # Footer
    st.markdown("---")
    st.markdown(
        "<div style='text-align: center'>MINTutil v0.1.0 | "
        "<a href='https://github.com/data-mint-research/MINTutil'>GitHub</a></div>",
        unsafe_allow_html=True
    )

if __name__ == "__main__":
    main()
