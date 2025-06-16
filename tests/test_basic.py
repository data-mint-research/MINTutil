"""
Test suite for MINTutil
"""
import pytest
from pathlib import Path
import sys

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


class TestProjectStructure:
    """Test project structure and basic requirements"""
    
    def test_required_directories_exist(self):
        """Test that all required directories exist"""
        required_dirs = [
            'streamlit_app',
            'tools',
            'scripts',
            'config',
            'docs',
            'tests'
        ]
        
        for dir_name in required_dirs:
            dir_path = project_root / dir_name
            assert dir_path.exists(), f"Required directory '{dir_name}' does not exist"
            assert dir_path.is_dir(), f"'{dir_name}' is not a directory"
    
    def test_required_files_exist(self):
        """Test that all required files exist"""
        required_files = [
            'mint.ps1',
            'requirements.txt',
            'docker-compose.yml',
            'Dockerfile',
            '.gitignore',
            'README.md'
        ]
        
        for file_name in required_files:
            file_path = project_root / file_name
            assert file_path.exists(), f"Required file '{file_name}' does not exist"
            assert file_path.is_file(), f"'{file_name}' is not a file"
    
    def test_env_example_exists(self):
        """Test that .env.example exists (not .env)"""
        env_example = project_root / '.env.example'
        assert env_example.exists(), ".env.example file does not exist"
        
        # Ensure .env is not in repository
        env_file = project_root / '.env'
        if env_file.exists():
            # Check if it's in .gitignore
            gitignore = project_root / '.gitignore'
            with open(gitignore, 'r') as f:
                assert '.env' in f.read(), ".env file exists but is not in .gitignore"


class TestStreamlitApp:
    """Test Streamlit application components"""
    
    def test_main_py_exists(self):
        """Test that main.py exists in streamlit_app"""
        main_py = project_root / 'streamlit_app' / 'main.py'
        assert main_py.exists(), "streamlit_app/main.py does not exist"
    
    def test_page_loader_exists(self):
        """Test that page_loader.py exists"""
        page_loader = project_root / 'streamlit_app' / 'page_loader.py'
        assert page_loader.exists(), "streamlit_app/page_loader.py does not exist"
    
    def test_can_import_main(self):
        """Test that main.py can be imported without errors"""
        try:
            from streamlit_app import main
            assert hasattr(main, 'main'), "main.py should have a main() function"
        except ImportError as e:
            pytest.fail(f"Failed to import main.py: {e}")
    
    def test_can_import_page_loader(self):
        """Test that page_loader.py can be imported"""
        try:
            from streamlit_app.page_loader import PageLoader
            assert PageLoader is not None
        except ImportError as e:
            pytest.fail(f"Failed to import PageLoader: {e}")


class TestTools:
    """Test tools directory structure"""
    
    def test_tools_directory_exists(self):
        """Test that tools directory exists"""
        tools_dir = project_root / 'tools'
        assert tools_dir.exists()
        assert tools_dir.is_dir()
    
    def test_transkription_tool_structure(self):
        """Test that transkription tool has correct structure"""
        tool_dir = project_root / 'tools' / 'transkription'
        
        if tool_dir.exists():
            # Check required files
            assert (tool_dir / 'ui.py').exists(), "transkription tool missing ui.py"
            assert (tool_dir / 'tool.meta.yaml').exists(), "transkription tool missing tool.meta.yaml"


class TestDocumentation:
    """Test documentation"""
    
    def test_docs_directory_has_content(self):
        """Test that docs directory has documentation files"""
        docs_dir = project_root / 'docs'
        assert docs_dir.exists()
        
        # Check for at least one .md file
        md_files = list(docs_dir.glob('*.md'))
        assert len(md_files) > 0, "No markdown files found in docs directory"
    
    def test_readme_has_content(self):
        """Test that README.md has substantial content"""
        readme = project_root / 'README.md'
        assert readme.exists()
        
        with open(readme, 'r', encoding='utf-8') as f:
            content = f.read()
            assert len(content) > 1000, "README.md seems too short"
            assert '# MINTutil' in content, "README.md missing main title"


class TestConfiguration:
    """Test configuration files"""
    
    def test_requirements_txt_valid(self):
        """Test that requirements.txt is valid"""
        req_file = project_root / 'requirements.txt'
        assert req_file.exists()
        
        with open(req_file, 'r') as f:
            lines = f.readlines()
            # Check for essential packages
            packages = ''.join(lines).lower()
            assert 'streamlit' in packages, "streamlit not in requirements.txt"
            assert 'pandas' in packages, "pandas not in requirements.txt"
    
    def test_docker_files_valid(self):
        """Test Docker configuration files"""
        dockerfile = project_root / 'Dockerfile'
        docker_compose = project_root / 'docker-compose.yml'
        
        assert dockerfile.exists(), "Dockerfile missing"
        assert docker_compose.exists(), "docker-compose.yml missing"
        
        # Check Dockerfile content
        with open(dockerfile, 'r') as f:
            content = f.read()
            assert 'FROM python:' in content, "Dockerfile missing Python base image"
            assert 'streamlit' in content.lower(), "Dockerfile doesn't mention streamlit"


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
