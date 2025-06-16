# MINTutil - Modular Infrastructure and Network Tools

## ? Overview
MINTutil is a modular toolkit for infrastructure and network operations, designed with AI-friendly code organization and containerization in mind.

## ? Quick Start

### Using Docker
```bash
docker-compose up -d
```

### Using PowerShell
```powershell
.\mint.ps1 -Command start
```

### Manual Installation
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
streamlit run streamlit_app/main.py
```

## ? Project Structure
```
mintutil/
??? mint.ps1              # PowerShell orchestration script
??? requirements.txt      # Python dependencies
??? docker-compose.yml    # Docker composition
??? .env                  # Environment configuration
??? tools/               # Modular tools directory
??? streamlit_app/       # Streamlit web interface
??? scripts/             # Utility scripts
??? shared/              # Shared libraries and utilities
??? config/              # Configuration files
??? logs/                # Application logs
??? data/                # Data storage
??? tests/               # Test suite
??? docs/                # Documentation
```

## ? Configuration
1. Copy `.env.example` to `.env`
2. Update configuration values
3. For system-level config, copy `config/system.env.template` to `config/system.env`

## ? Modules
MINTutil uses a modular architecture. Each tool in the `tools/` directory is a self-contained module.

## ? Testing
```bash
pytest tests/
```

## ? License
MIT License - see LICENSE file for details

## ? Contributing
Contributions are welcome! Please read our contributing guidelines.

## ? Support
For issues and questions, please use the GitHub issue tracker.
