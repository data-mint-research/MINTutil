<div align="center">

# MINTutil

### Modular Infrastructure and Network Tools

[![Python](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](https://github.com/data-mint-research/MINTutil)
[![NeoMINT](https://img.shields.io/badge/NeoMINT-compliant-brightgreen.svg)](docs/neomint-coding-practices.md)
[![GitHub Issues](https://img.shields.io/github/issues/data-mint-research/MINTutil)](https://github.com/data-mint-research/MINTutil/issues)

[Features](#key-features) ? [Quick Start](#quick-start) ? [Documentation](#documentation) ? [Contributing](#contributing)

</div>

---

## Quick Start

**Install MINTutil in one line** - Open PowerShell as Administrator:

```powershell
irm https://raw.githubusercontent.com/data-mint-research/MINTutil/main/scripts/setup_windows.ps1 | iex
```

That's it! The installer handles everything automatically.

<details>
<summary>Alternative: Use Chocolatey package manager</summary>

```powershell
irm https://raw.githubusercontent.com/data-mint-research/MINTutil/main/scripts/setup_windows.ps1 | iex -UseChocolatey
```
</details>

---

## Overview

MINTutil is a **modular platform** for utility and analysis tools with optional AI integration. Built with a modern **Streamlit UI**, it provides a unified interface for various tools while keeping your data local and secure.

### Key Features

- **Modular Architecture** - Easy to extend with new tools
- **AI Integration** - Optional Ollama support for local LLMs
- **Web Interface** - Clean, modern Streamlit UI
- **Privacy First** - All processing happens locally
- **One-Click Install** - Automated setup for Windows
- **Docker Ready** - Container deployment support

---

## Available Tools

### Transcription Tool
- Transcribe YouTube videos with OpenAI Whisper
- Process local audio/video files
- Automatic name correction with glossary
- Export to Markdown format

### More Tools Coming Soon
- Data analysis and visualization
- Network utilities
- API testing suite
- Custom tool development framework

---

## System Requirements

The installer automatically handles all dependencies:

- **Python 3.9+** (installs 3.11 if needed)
- **Git** (for version control)
- **FFmpeg** (for media processing)
- **8GB RAM** recommended
- **2GB free disk space**

---

## Getting Started

### After Installation

1. **Start MINTutil**
   ```powershell
   C:\MINTutil\mint.ps1 start
   ```

2. **Open your browser** to `http://localhost:8501`

3. **Select a tool** from the sidebar and start using it!

### Configuration

Edit your settings:
```powershell
notepad C:\MINTutil\.env
```

---

## Documentation

### Installation Options

<details>
<summary>Linux/macOS Installation</summary>

```bash
# Clone and setup
git clone https://github.com/data-mint-research/MINTutil.git
cd MINTutil
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
streamlit run streamlit_app/main.py
```
</details>

<details>
<summary>Docker Installation</summary>

```bash
# Using Docker Compose
git clone https://github.com/data-mint-research/MINTutil.git
cd MINTutil
docker-compose up -d
```
</details>

<details>
<summary>Development Setup</summary>

```bash
# Clone repository
git clone https://github.com/data-mint-research/MINTutil.git
cd MINTutil

# Setup development environment
python -m venv venv
.\venv\Scripts\Activate.ps1  # Windows
source venv/bin/activate     # Linux/macOS

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Install pre-commit hooks
pre-commit install
```
</details>

### Project Structure

```
MINTutil/
??? streamlit_app/      # Main UI application
??? tools/              # Modular tools
?   ??? transcription/  # Transcription tool
??? scripts/            # Setup & utility scripts
??? config/             # Configuration files
??? tests/              # Test suite
??? docs/               # Documentation
```

---

## Development

### Adding a New Tool

1. Create a folder under `tools/`
2. Add `tool.meta.yaml` with metadata
3. Create `ui.py` with a `render()` function
4. Your tool appears automatically in the UI!

### Code Quality

```bash
# Check NeoMINT compliance
.\scripts\check-neomint-compliance.ps1

# Run tests
pytest tests/ -v

# Format code
black .

# Lint
flake8 .
```

### NeoMINT Coding Standards

This project follows [NeoMINT Coding Practices](docs/neomint-coding-practices.md) for optimal LLM compatibility:
- Maximum 500 lines per file
- Central logging functions
- Complete documentation
- ASCII-only codebase
- Professional documentation design

---

## Troubleshooting

### Common Issues

<details>
<summary>Setup fails?</summary>

```powershell
# Skip already installed components
.\scripts\setup_windows.ps1 -SkipPython
.\scripts\setup_windows.ps1 -SkipGit

# Force Chocolatey installation
.\scripts\setup_windows.ps1 -ForceChocolatey
```
</details>

<details>
<summary>Port 8501 in use?</summary>

```powershell
# Find process
netstat -ano | findstr :8501

# Change port in .env
STREAMLIT_SERVER_PORT=8502
```
</details>

<details>
<summary>Module not found?</summary>

```powershell
# Activate virtual environment
C:\MINTutil\venv\Scripts\Activate.ps1

# Reinstall requirements
pip install -r requirements.txt --force-reinstall
```
</details>

### System Diagnostics

```powershell
# Run health check
C:\MINTutil\mint.ps1 doctor

# Check logs
Get-Content C:\MINTutil\logs\mintutil-cli.log -Tail 50
```

---

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md).

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

All contributions must comply with [NeoMINT Coding Practices](docs/neomint-coding-practices.md).

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright ? 2025 MINT-RESEARCH

---

## Support

- **Issues**: [GitHub Issues](https://github.com/data-mint-research/MINTutil/issues)
- **Email**: mint-research@neomint.com
- **Documentation**: [Project Documentation](docs/)

---

<div align="center">

**Built with precision by MINT-RESEARCH**

Star us on GitHub if you find this useful!

</div>
