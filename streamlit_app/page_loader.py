import importlib.util
import sys
from pathlib import Path
from typing import Dict, Any, Optional, Callable
import yaml
import streamlit as st
import traceback

class PageLoader:
    """Dynamic page loader for MINTutil tools"""
    
    def __init__(self):
        self.root_path = Path(__file__).parent.parent
        self.tools_path = self.root_path / "tools"
        self._tools_cache: Optional[Dict[str, Dict[str, Any]]] = None
        self._modules_cache: Dict[str, Any] = {}
    
    def get_available_tools(self) -> Dict[str, Dict[str, Any]]:
        """Scan tools directory and return available tools with metadata"""
        if self._tools_cache is not None:
            return self._tools_cache
        
        tools = {}
        
        if not self.tools_path.exists():
            return tools
        
        # Scan all subdirectories in tools/
        for tool_dir in self.tools_path.iterdir():
            if not tool_dir.is_dir():
                continue
                
            tool_id = tool_dir.name
            
            # Check if ui.py exists
            ui_path = tool_dir / "ui.py"
            if not ui_path.exists():
                continue
            
            # Load metadata
            meta_path = tool_dir / "tool.meta.yaml"
            metadata = self._load_metadata(meta_path, tool_id)
            
            tools[tool_id] = metadata
        
        # Sort tools by name
        sorted_tools = dict(sorted(
            tools.items(),
            key=lambda x: x[1].get('name', x[0]).lower()
        ))
        
        self._tools_cache = sorted_tools
        return sorted_tools
    
    def _load_metadata(self, meta_path: Path, tool_id: str) -> Dict[str, Any]:
        """Load tool metadata from YAML file"""
        default_metadata = {
            'name': tool_id.replace('_', ' ').title(),
            'description': f'{tool_id} Tool',
            'icon': '?',
            'version': '1.0.0',
            'author': 'Unknown'
        }
        
        if not meta_path.exists():
            return default_metadata
        
        try:
            with open(meta_path, 'r', encoding='utf-8') as f:
                metadata = yaml.safe_load(f) or {}
            
            # Merge with defaults
            for key, value in default_metadata.items():
                if key not in metadata:
                    metadata[key] = value
                    
            return metadata
            
        except Exception as e:
            st.warning(f"Fehler beim Laden der Metadaten f?r {tool_id}: {str(e)}")
            return default_metadata
    
    def render_tool(self, tool_id: str) -> bool:
        """Load and render a specific tool"""
        try:
            # Get module
            module = self._load_tool_module(tool_id)
            if module is None:
                return False
            
            # Check for render function
            if not hasattr(module, 'render'):
                st.error(f"Tool '{tool_id}' hat keine render() Funktion")
                return False
            
            # Get render function
            render_func = getattr(module, 'render')
            if not callable(render_func):
                st.error(f"render in Tool '{tool_id}' ist keine Funktion")
                return False
            
            # Call render function
            render_func()
            return True
            
        except Exception as e:
            st.error(f"Fehler beim Laden des Tools '{tool_id}'")
            st.error(f"Details: {str(e)}")
            if st.checkbox("Stacktrace anzeigen", key=f"error_trace_{tool_id}"):
                st.code(traceback.format_exc())
            return False
    
    def _load_tool_module(self, tool_id: str) -> Optional[Any]:
        """Dynamically load a tool module"""
        # Check cache first
        if tool_id in self._modules_cache:
            return self._modules_cache[tool_id]
        
        ui_path = self.tools_path / tool_id / "ui.py"
        
        if not ui_path.exists():
            st.error(f"UI-Datei nicht gefunden: {ui_path}")
            return None
        
        try:
            # Create module spec
            spec = importlib.util.spec_from_file_location(
                f"tools.{tool_id}.ui",
                ui_path
            )
            
            if spec is None or spec.loader is None:
                st.error(f"Konnte Modul-Spec f?r '{tool_id}' nicht erstellen")
                return None
            
            # Load module
            module = importlib.util.module_from_spec(spec)
            
            # Add to sys.modules to handle imports
            sys.modules[f"tools.{tool_id}.ui"] = module
            
            # Execute module
            spec.loader.exec_module(module)
            
            # Cache module
            self._modules_cache[tool_id] = module
            
            return module
            
        except Exception as e:
            st.error(f"Fehler beim Importieren von '{tool_id}': {str(e)}")
            if st.checkbox("Import-Fehler Details", key=f"import_error_{tool_id}"):
                st.code(traceback.format_exc())
            return None
    
    def reload_tool(self, tool_id: str) -> bool:
        """Force reload a tool module (useful for development)"""
        # Remove from caches
        if tool_id in self._modules_cache:
            del self._modules_cache[tool_id]
        
        module_name = f"tools.{tool_id}.ui"
        if module_name in sys.modules:
            del sys.modules[module_name]
        
        # Clear tools cache to reload metadata
        self._tools_cache = None
        
        # Try to load again
        return self.render_tool(tool_id)