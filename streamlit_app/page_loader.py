import importlib.util
import sys
from pathlib import Path
from typing import Dict, Any, Optional, Callable
import yaml
import streamlit as st
import traceback
import re

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
            
            # Skip hidden directories
            if tool_dir.name.startswith('.'):
                continue
                
            tool_id = tool_dir.name
            
            # Validate tool_id
            if not self._is_valid_tool_id(tool_id):
                continue
            
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
    
    def _is_valid_tool_id(self, tool_id: str) -> bool:
        """Validate tool ID format"""
        # Tool ID should only contain alphanumeric characters and underscores
        return bool(re.match(r'^[a-zA-Z0-9_]+$', tool_id))
    
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
                content = f.read()
                
            # Handle empty files
            if not content.strip():
                return default_metadata
                
            metadata = yaml.safe_load(content) or {}
            
            # Validate metadata types
            if not isinstance(metadata, dict):
                st.warning(f"Ung?ltige Metadaten f?r {tool_id}: Kein Dictionary")
                return default_metadata
            
            # Merge with defaults
            for key, value in default_metadata.items():
                if key not in metadata:
                    metadata[key] = value
                    
            return metadata
            
        except yaml.YAMLError as e:
            st.warning(f"YAML-Fehler in Metadaten f?r {tool_id}: {str(e)}")
            return default_metadata
        except Exception as e:
            st.warning(f"Fehler beim Laden der Metadaten f?r {tool_id}: {str(e)}")
            return default_metadata
    
    def render_tool(self, tool_id: str) -> bool:
        """Load and render a specific tool"""
        # Validate tool_id
        if not self._is_valid_tool_id(tool_id):
            st.error(f"Ung?ltige Tool-ID: {tool_id}")
            return False
            
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
            
            # Call render function with error handling
            try:
                render_func()
                return True
            except Exception as e:
                st.error(f"Fehler beim Ausf?hren von Tool '{tool_id}'")
                st.error(f"Details: {str(e)}")
                if st.checkbox("Stacktrace anzeigen", key=f"runtime_trace_{tool_id}"):
                    st.code(traceback.format_exc())
                return False
            
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
            module_name = f"tools.{tool_id}.ui"
            sys.modules[module_name] = module
            
            # Add tool path to sys.path for local imports
            tool_path = str(self.tools_path / tool_id)
            if tool_path not in sys.path:
                sys.path.insert(0, tool_path)
            
            # Also add parent paths for better import resolution
            parent_paths = [
                str(self.tools_path),
                str(self.root_path)
            ]
            for path in parent_paths:
                if path not in sys.path:
                    sys.path.insert(0, path)
            
            # Execute module
            spec.loader.exec_module(module)
            
            # Cache module
            self._modules_cache[tool_id] = module
            
            return module
            
        except SyntaxError as e:
            st.error(f"Syntax-Fehler in '{tool_id}': {str(e)}")
            if hasattr(e, 'filename') and hasattr(e, 'lineno') and hasattr(e, 'text'):
                st.code(f"Datei: {e.filename}\nZeile: {e.lineno}\nProblem: {e.text}")
            return None
        except ImportError as e:
            st.error(f"Import-Fehler in '{tool_id}': {str(e)}")
            st.info("Tipp: ?berpr?fen Sie, ob alle ben?tigten Pakete installiert sind")
            # Show specific missing module
            if hasattr(e, 'name'):
                st.error(f"Fehlendes Modul: {e.name}")
            return None
        except Exception as e:
            st.error(f"Fehler beim Importieren von '{tool_id}': {str(e)}")
            if st.checkbox("Import-Fehler Details", key=f"import_error_{tool_id}"):
                st.code(traceback.format_exc())
            return None
    
    def reload_tool(self, tool_id: str) -> bool:
        """Force reload a tool module (useful for development)"""
        # Validate tool_id
        if not self._is_valid_tool_id(tool_id):
            st.error(f"Ung?ltige Tool-ID: {tool_id}")
            return False
            
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
    
    def get_tool_metadata(self, tool_id: str) -> Optional[Dict[str, Any]]:
        """Get metadata for a specific tool"""
        tools = self.get_available_tools()
        return tools.get(tool_id)
    
    def validate_tool_structure(self, tool_id: str) -> Dict[str, bool]:
        """Validate tool structure and return status"""
        tool_dir = self.tools_path / tool_id
        
        checks = {
            'directory_exists': tool_dir.exists() and tool_dir.is_dir(),
            'ui_py_exists': (tool_dir / "ui.py").exists(),
            'meta_yaml_exists': (tool_dir / "tool.meta.yaml").exists(),
            'valid_tool_id': self._is_valid_tool_id(tool_id)
        }
        
        # Check if ui.py has render function
        if checks['ui_py_exists']:
            module = self._load_tool_module(tool_id)
            checks['has_render_function'] = module is not None and hasattr(module, 'render')
        else:
            checks['has_render_function'] = False
        
        return checks
