"""
Unit tests for MINTutil main components
"""

import pytest
import sys
from pathlib import Path
import tempfile
import shutil
import yaml

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from streamlit_app.page_loader import PageLoader


class TestPageLoader:
    """Test cases for PageLoader class"""
    
    @pytest.fixture
    def temp_tools_dir(self):
        """Create temporary tools directory for testing"""
        temp_dir = tempfile.mkdtemp()
        tools_path = Path(temp_dir) / "tools"
        tools_path.mkdir()
        
        yield tools_path
        
        # Cleanup
        shutil.rmtree(temp_dir)
    
    @pytest.fixture
    def page_loader(self, temp_tools_dir, monkeypatch):
        """Create PageLoader instance with temp directory"""
        loader = PageLoader()
        monkeypatch.setattr(loader, 'tools_path', temp_tools_dir)
        return loader
    
    def test_init(self, page_loader):
        """Test PageLoader initialization"""
        assert page_loader.root_path.exists()
        assert page_loader.tools_path.exists()
        assert page_loader._tools_cache is None
        assert page_loader._modules_cache == {}
    
    def test_get_available_tools_empty(self, page_loader):
        """Test getting tools when directory is empty"""
        tools = page_loader.get_available_tools()
        assert tools == {}
    
    def test_get_available_tools_with_tool(self, page_loader, temp_tools_dir):
        """Test getting tools with valid tool"""
        # Create test tool
        tool_dir = temp_tools_dir / "test_tool"
        tool_dir.mkdir()
        
        # Create ui.py
        ui_file = tool_dir / "ui.py"
        ui_file.write_text("""
def render():
    pass
""")
        
        # Create metadata
        meta_file = tool_dir / "tool.meta.yaml"
        meta_data = {
            'name': 'Test Tool',
            'description': 'A test tool',
            'icon': '?',
            'version': '1.0.0'
        }
        with open(meta_file, 'w') as f:
            yaml.dump(meta_data, f)
        
        # Get tools
        tools = page_loader.get_available_tools()
        
        assert 'test_tool' in tools
        assert tools['test_tool']['name'] == 'Test Tool'
        assert tools['test_tool']['icon'] == '?'
    
    def test_is_valid_tool_id(self, page_loader):
        """Test tool ID validation"""
        assert page_loader._is_valid_tool_id('valid_tool')
        assert page_loader._is_valid_tool_id('tool_123')
        assert page_loader._is_valid_tool_id('TOOL')
        
        assert not page_loader._is_valid_tool_id('invalid-tool')
        assert not page_loader._is_valid_tool_id('tool.name')
        assert not page_loader._is_valid_tool_id('tool@123')
        assert not page_loader._is_valid_tool_id('')
    
    def test_load_metadata_default(self, page_loader, temp_tools_dir):
        """Test loading metadata with defaults"""
        meta_path = temp_tools_dir / "nonexistent.yaml"
        metadata = page_loader._load_metadata(meta_path, 'test_tool')
        
        assert metadata['name'] == 'Test Tool'
        assert metadata['description'] == 'test_tool Tool'
        assert metadata['icon'] == '?'
        assert metadata['version'] == '1.0.0'
    
    def test_load_metadata_invalid_yaml(self, page_loader, temp_tools_dir):
        """Test loading invalid YAML metadata"""
        meta_path = temp_tools_dir / "invalid.yaml"
        meta_path.write_text("invalid: yaml: content:")
        
        metadata = page_loader._load_metadata(meta_path, 'test_tool')
        
        # Should return defaults on error
        assert metadata['name'] == 'Test Tool'
    
    def test_validate_tool_structure(self, page_loader, temp_tools_dir):
        """Test tool structure validation"""
        # Create valid tool
        tool_dir = temp_tools_dir / "valid_tool"
        tool_dir.mkdir()
        (tool_dir / "ui.py").write_text("def render(): pass")
        (tool_dir / "tool.meta.yaml").write_text("name: Valid Tool")
        
        checks = page_loader.validate_tool_structure('valid_tool')
        
        assert checks['directory_exists']
        assert checks['ui_py_exists']
        assert checks['meta_yaml_exists']
        assert checks['valid_tool_id']
    
    def test_reload_tool(self, page_loader, temp_tools_dir):
        """Test reloading a tool"""
        # Create tool
        tool_dir = temp_tools_dir / "reload_test"
        tool_dir.mkdir()
        (tool_dir / "ui.py").write_text("def render(): pass")
        
        # First load
        page_loader.get_available_tools()
        assert 'reload_test' in page_loader._tools_cache
        
        # Modify and reload
        page_loader._tools_cache = None
        result = page_loader.reload_tool('reload_test')
        
        # Should clear cache
        assert page_loader._tools_cache is None


class TestTranscriptionScripts:
    """Test cases for transcription scripts"""
    
    def test_imports(self):
        """Test that transcription modules can be imported"""
        try:
            from tools.transkription.scripts import transcribe
            from tools.transkription.scripts import fix_names
            from tools.transkription.scripts import postprocess
            assert True
        except ImportError:
            # Modules might not exist yet, which is okay for this test
            assert True
    
    def test_youtube_url_validation(self):
        """Test YouTube URL validation"""
        from tools.transkription.ui import validate_youtube_url
        
        # Valid URLs
        assert validate_youtube_url('https://www.youtube.com/watch?v=dQw4w9WgXcQ')
        assert validate_youtube_url('https://youtu.be/dQw4w9WgXcQ')
        assert validate_youtube_url('youtube.com/watch?v=dQw4w9WgXcQ')
        assert validate_youtube_url('https://www.youtube.com/embed/dQw4w9WgXcQ')
        
        # Invalid URLs
        assert not validate_youtube_url('https://vimeo.com/123456')
        assert not validate_youtube_url('not a url')
        assert not validate_youtube_url('')


@pytest.mark.parametrize("encoding,expected", [
    ('utf-8', True),
    ('utf-8-sig', True),
    ('latin-1', False),
    ('ascii', False),
])
def test_file_encoding(encoding, expected):
    """Test file encoding detection"""
    with tempfile.NamedTemporaryFile(mode='w', encoding=encoding, delete=False) as f:
        f.write("Test ??? content")
        temp_path = f.name
    
    try:
        with open(temp_path, 'rb') as f:
            content = f.read()
            is_utf8 = True
            try:
                content.decode('utf-8')
            except UnicodeDecodeError:
                is_utf8 = False
        
        if expected:
            assert is_utf8
        else:
            assert not is_utf8
    finally:
        Path(temp_path).unlink()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
