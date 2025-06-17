#!/usr/bin/env python3
"""
MINTutil Code-Fix Anwendungs-Script
Wendet alle identifizierten Fixes automatisch an
"""

import os
import sys
import shutil
from pathlib import Path
from datetime import datetime
import json

class MINTutilFixer:
    def __init__(self):
        self.root_path = Path.cwd()
        self.backup_dir = self.root_path / f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.fixes_applied = []
        self.errors = []
        
    def create_backup(self):
        """Create backup of important files"""
        print("? Erstelle Backup...")
        files_to_backup = [
            "requirements.txt",
            "Dockerfile",
            "streamlit_app/main.py",
            "streamlit_app/page_loader.py",
            "tools/transkription/ui.py",
            "mint.ps1"
        ]
        
        self.backup_dir.mkdir(exist_ok=True)
        
        for file_path in files_to_backup:
            src = self.root_path / file_path
            if src.exists():
                dst = self.backup_dir / file_path
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
                print(f"  ? Backup: {file_path}")
    
    def fix_requirements(self):
        """Fix requirements.txt"""
        print("\n? Fixing requirements.txt...")
        try:
            req_path = self.root_path / "requirements.txt"
            with open(req_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # Remove pathlib line
            new_lines = []
            for line in lines:
                if not line.strip().startswith('pathlib'):
                    new_lines.append(line)
                else:
                    new_lines.append(f"# {line}")  # Comment out instead of removing
            
            with open(req_path, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            
            self.fixes_applied.append("requirements.txt - pathlib entfernt")
            print("  ? requirements.txt behoben")
        except Exception as e:
            self.errors.append(f"requirements.txt: {str(e)}")
            print(f"  ? Fehler: {str(e)}")
    
    def fix_encoding_in_file(self, file_path: Path):
        """Fix encoding issues in a file"""
        replacements = {
            'f?r': 'f?r',
            '?': '?',
            '?': '?',
            '?': '?',
            '?': '?',
            '?': '?',
            '?': '?',
            '?': '?',
            'Verf?gbare': 'Verf?gbare',
            'F?hre': 'F?hre',
            'Pr?fe': 'Pr?fe',
            'l?uft': 'l?uft',
            'hinzuf?gen': 'hinzuf?gen',
            'Unterst?tzung': 'Unterst?tzung',
            'W?hlen': 'W?hlen',
            'Beitr?ge': 'Beitr?ge',
            'Gr??ere': 'Gr??ere',
            'ausw?hlen': 'ausw?hlen',
            'Eintr?ge': 'Eintr?ge',
            'Abs?tze': 'Abs?tze',
            'W?rter': 'W?rter',
            'ben?tigt': 'ben?tigt',
            'Ung?ltige': 'Ung?ltige',
            'ge?ffnet': 'ge?ffnet',
            'k?nnen': 'k?nnen',
            'Schl?ssel': 'Schl?ssel',
        }
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            for old, new in replacements.items():
                content = content.replace(old, new)
            
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                return True
            return False
        except Exception as e:
            self.errors.append(f"Encoding fix for {file_path}: {str(e)}")
            return False
    
    def fix_all_encoding_issues(self):
        """Fix encoding in all Python and PowerShell files"""
        print("\n? Fixing encoding issues...")
        fixed_count = 0
        
        for ext in ['*.py', '*.ps1', '*.md']:
            for file_path in self.root_path.rglob(ext):
                if self.backup_dir.name in str(file_path):
                    continue
                if self.fix_encoding_in_file(file_path):
                    fixed_count += 1
                    print(f"  ? Encoding behoben: {file_path.relative_to(self.root_path)}")
        
        if fixed_count > 0:
            self.fixes_applied.append(f"Encoding in {fixed_count} Dateien behoben")
        print(f"  ? {fixed_count} Dateien korrigiert")
    
    def create_missing_directories(self):
        """Create missing directories"""
        print("\n? Erstelle fehlende Verzeichnisse...")
        dirs_to_create = [
            "logs",
            "data",
            "data/raw",
            "data/fixed", 
            "data/audio",
            "config",
            "shared",
            "assets",
            "tools/transkription/config"
        ]
        
        created = 0
        for dir_path in dirs_to_create:
            full_path = self.root_path / dir_path
            if not full_path.exists():
                full_path.mkdir(parents=True, exist_ok=True)
                created += 1
                print(f"  ? Erstellt: {dir_path}")
        
        if created > 0:
            self.fixes_applied.append(f"{created} Verzeichnisse erstellt")
    
    def create_gitkeep_files(self):
        """Create .gitkeep files in empty directories"""
        print("\n? Erstelle .gitkeep Dateien...")
        empty_dirs = ["logs", "data", "shared", "assets", "config"]
        created = 0
        
        for dir_name in empty_dirs:
            gitkeep_path = self.root_path / dir_name / ".gitkeep"
            if not gitkeep_path.exists() and gitkeep_path.parent.exists():
                gitkeep_path.touch()
                created += 1
                print(f"  ? .gitkeep erstellt in: {dir_name}")
        
        if created > 0:
            self.fixes_applied.append(f"{created} .gitkeep Dateien erstellt")
    
    def create_env_file(self):
        """Create .env file if missing"""
        print("\n? Pr?fe .env Datei...")
        env_path = self.root_path / ".env"
        example_path = self.root_path / ".env.example"
        
        if not env_path.exists() and example_path.exists():
            shutil.copy2(example_path, env_path)
            print("  ? .env aus .env.example erstellt")
            self.fixes_applied.append(".env Datei erstellt")
        elif not env_path.exists():
            # Create basic .env
            content = """# MINTutil Environment Configuration
APP_NAME=MINTutil
APP_VERSION=0.1.0
ENVIRONMENT=development

# Streamlit Configuration
STREAMLIT_SERVER_PORT=8501
STREAMLIT_SERVER_ADDRESS=localhost
STREAMLIT_SERVER_HEADLESS=false

# Logging
LOG_LEVEL=INFO
LOG_FILE=logs/mintutil.log

# Tool Configuration
WHISPER_MODEL=base
WHISPER_LANGUAGE=de

# Optional: AI Configuration
# OPENAI_API_KEY=your-api-key-here
# OLLAMA_HOST=http://localhost:11434
"""
            with open(env_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print("  ? Standard .env erstellt")
            self.fixes_applied.append(".env Datei mit Defaults erstellt")
    
    def generate_report(self):
        """Generate fix report"""
        print("\n" + "="*60)
        print("? FIX REPORT")
        print("="*60)
        
        print("\n? Erfolgreich angewendete Fixes:")
        for fix in self.fixes_applied:
            print(f"  ? {fix}")
        
        if self.errors:
            print("\n? Fehler:")
            for error in self.errors:
                print(f"  ? {error}")
        
        print(f"\n? Backup erstellt in: {self.backup_dir}")
        
        # Save report
        report = {
            "timestamp": datetime.now().isoformat(),
            "fixes_applied": self.fixes_applied,
            "errors": self.errors,
            "backup_location": str(self.backup_dir)
        }
        
        report_path = self.root_path / "fix_report.json"
        with open(report_path, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"? Report gespeichert: {report_path}")
    
    def run(self):
        """Run all fixes"""
        print("? MINTutil Code-Fix Tool")
        print("="*60)
        
        # Check if we're in MINTutil directory
        if not (self.root_path / "mint.ps1").exists():
            print("? Fehler: Dieses Script muss im MINTutil Root-Verzeichnis ausgef?hrt werden!")
            sys.exit(1)
        
        print(f"? Arbeitsverzeichnis: {self.root_path}")
        
        # Create backup
        self.create_backup()
        
        # Apply fixes
        self.fix_requirements()
        self.fix_all_encoding_issues()
        self.create_missing_directories()
        self.create_gitkeep_files()
        self.create_env_file()
        
        # Generate report
        self.generate_report()
        
        print("\n? Fixes abgeschlossen!")
        print("? F?hren Sie 'python -m pytest tests/' aus, um die Funktionalit?t zu ?berpr?fen.")
        print("? Starten Sie MINTutil mit: .\\mint.ps1 start")


if __name__ == "__main__":
    fixer = MINTutilFixer()
    fixer.run()
