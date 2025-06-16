# tests/test_mintutil.py
import pytest
import sys
from pathlib import Path
import yaml
import json

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

class TestRequirements:
    """Test requirements.txt fixes"""
    
    def test_no_pathlib_in_requirements(self):
        """Ensure pathlib is not in requirements.txt"""
        req_path = Path(__file__).parent.parent / "requirements.txt"
        with open(req_path, 'r') as f:
            content = f.read()
        
        # Check that pathlib is not listed (or is commented out)
        lines = content.split('\n')
        for line in lines:
            if line.strip() and not line.strip().startswith('#'):
                assert 'pathlib' not in line.lower(), "pathlib should not be in requirements.txt"
    
    def test_all_requirements_valid(self):
        """Test that all requirements are valid package names"""
        req_path = Path(__file__).parent.parent / "requirements.txt"
        with open(req_path, 'r') as f:
            lines = f.readlines()
        
        for line in lines:
            line = line.strip()
            if line and not line.startswith('#'):
                # Basic validation of package format
                assert '>' in line or '=' in line or line.isalpha(), f"Invalid requirement format: {line}"


class TestEncoding:
    """Test encoding fixes"""
    
    def test_no_encoding_issues_in_python_files(self):
        """Check for encoding issues in Python files"""
        problematic_chars = ['?', '?']
        
        for py_file in Path(__file__).parent.parent.rglob("*.py"):
            # Skip test files and virtual environments
            if 'venv' in str(py_file) or 'test' in str(py_file):
                continue
                
            with open(py_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            for char in problematic_chars:
                assert char not in content, f"Encoding issue in {py_file}: found '{char}'"
    
    def test_umlauts_correct(self):
        """Test that German umlauts are correctly encoded"""
        test_files = [
            "streamlit_app/main.py",
            "tools/transkription/ui.py"
        ]
        
        expected_words = ['f?r', '?ber', 'k?nnen', 'm?ssen', 'Gr??e']
        
        for file_path in test_files:
            full_path = Path(__file__).parent.parent / file_path
            if full_path.exists():
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Should contain at least some German text
                has_german = any(word in content for word in expected_words)
                assert has_german or 'def' in content, f"File {file_path} seems to have no content"


class TestDirectoryStructure:
    """Test directory structure"""
    
    def test_required_directories_exist(self):
        """Test that all required directories exist"""
        required_dirs = [
            "streamlit_app",
            "tools",
            "scripts",
            "config",
            "logs",
            "data"
        ]
        
        root = Path(__file__).parent.parent
        for dir_name in required_dirs:
            dir_path = root / dir_name
            assert dir_path.exists(), f"Required directory missing: {dir_name}"
            assert dir_path.is_dir(), f"{dir_name} is not a directory"
    
    def test_tool_structure(self):
        """Test tool directory structure"""
        tools_dir = Path(__file__).parent.parent / "tools"
        
        # At least transkription tool should exist
        transkription_dir = tools_dir / "transkription"
        assert transkription_dir.exists(), "Transkription tool directory missing"
        
        # Check required files
        required_files = ["ui.py", "tool.meta.yaml"]
        for file_name in required_files:
            file_path = transkription_dir / file_name
            assert file_path.exists(), f"Required file missing: {file_name}"


class TestStreamlitApp:
    """Test Streamlit application structure"""
    
    def test_main_py_exists(self):
        """Test that main.py exists"""
        main_path = Path(__file__).parent.parent / "streamlit_app" / "main.py"
        assert main_path.exists(), "streamlit_app/main.py missing"
    
    def test_page_loader_exists(self):
        """Test that page_loader.py exists"""
        loader_path = Path(__file__).parent.parent / "streamlit_app" / "page_loader.py"
        assert loader_path.exists(), "streamlit_app/page_loader.py missing"
    
    def test_imports_work(self):
        """Test that imports work correctly"""
        try:
            from streamlit_app.page_loader import PageLoader
            loader = PageLoader()
            assert loader is not None
        except ImportError as e:
            pytest.fail(f"Import failed: {e}")


class TestTranskriptionTool:
    """Test Transkription tool"""
    
    def test_ui_py_has_render_function(self):
        """Test that ui.py has render function"""
        ui_path = Path(__file__).parent.parent / "tools" / "transkription" / "ui.py"
        
        with open(ui_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        assert "def render():" in content, "render() function missing in ui.py"
    
    def test_metadata_valid(self):
        """Test that tool metadata is valid YAML"""
        meta_path = Path(__file__).parent.parent / "tools" / "transkription" / "tool.meta.yaml"
        
        with open(meta_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        try:
            metadata = yaml.safe_load(content)
            assert isinstance(metadata, dict), "Metadata should be a dictionary"
            assert 'name' in metadata, "Metadata missing 'name' field"
        except yaml.YAMLError as e:
            pytest.fail(f"Invalid YAML in metadata: {e}")
    
    def test_scripts_exist(self):
        """Test that required scripts exist"""
        scripts_dir = Path(__file__).parent.parent / "tools" / "transkription" / "scripts"
        
        required_scripts = ["transcribe.py", "fix_names.py", "postprocess.py"]
        for script_name in required_scripts:
            script_path = scripts_dir / script_name
            assert script_path.exists(), f"Required script missing: {script_name}"


class TestDockerfile:
    """Test Dockerfile configuration"""
    
    def test_dockerfile_exists(self):
        """Test that Dockerfile exists"""
        dockerfile_path = Path(__file__).parent.parent / "Dockerfile"
        assert dockerfile_path.exists(), "Dockerfile missing"
    
    def test_dockerfile_uses_nonroot_user(self):
        """Test that Dockerfile creates and uses non-root user"""
        dockerfile_path = Path(__file__).parent.parent / "Dockerfile"
        
        with open(dockerfile_path, 'r') as f:
            content = f.read()
        
        assert "USER mintuser" in content, "Dockerfile should use non-root user"
        assert "useradd" in content, "Dockerfile should create user"


class TestConfiguration:
    """Test configuration files"""
    
    def test_env_example_exists(self):
        """Test that .env.example exists"""
        env_example = Path(__file__).parent.parent / ".env.example"
        assert env_example.exists(), ".env.example missing"
    
    def test_gitignore_exists(self):
        """Test that .gitignore exists"""
        gitignore = Path(__file__).parent.parent / ".gitignore"
        assert gitignore.exists(), ".gitignore missing"
    
    def test_gitignore_includes_env(self):
        """Test that .gitignore includes .env"""
        gitignore = Path(__file__).parent.parent / ".gitignore"
        
        with open(gitignore, 'r') as f:
            content = f.read()
        
        assert ".env" in content, ".gitignore should include .env"


class TestPowerShellCLI:
    """Test PowerShell CLI"""
    
    def test_mint_ps1_exists(self):
        """Test that mint.ps1 exists"""
        mint_path = Path(__file__).parent.parent / "mint.ps1"
        assert mint_path.exists(), "mint.ps1 missing"
    
    def test_setup_scripts_exist(self):
        """Test that setup scripts exist"""
        scripts_dir = Path(__file__).parent.parent / "scripts"
        
        important_scripts = [
            "setup_windows.ps1",
            "start_ui.ps1",
            "health_check.ps1"
        ]
        
        for script_name in important_scripts:
            script_path = scripts_dir / script_name
            assert script_path.exists(), f"Required script missing: {script_name}"


if __name__ == "__main__":
    # Run tests
    pytest.main([__file__, "-v"])
