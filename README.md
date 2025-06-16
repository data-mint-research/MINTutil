# MINTutil - Modular Infrastructure and Network Tools

## ? Overview

MINTutil is a modular toolkit for infrastructure and network operations, designed with AI-friendly code organization and containerization in mind. It provides a flexible platform for various analysis and processing tools with a user-friendly web interface.

## ? Features

- **Modular Architecture**: Easy to add new tools and functionalities
- **Web Interface**: Built with Streamlit for intuitive interaction
- **Docker Support**: Containerized deployment for consistency
- **AI Integration**: Optional AI assistance for various tasks
- **Extensible**: Plugin-based system for custom tools

## ? Quick Start

### Prerequisites

- Python 3.11 or higher
- PowerShell 5.1 or higher (for Windows users)
- Docker and Docker Compose (optional)

### Installation

#### Option 1: Using Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/data-mint-research/MINTutil.git
cd MINTutil

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env  # or use your preferred editor

# Start with Docker
docker-compose up -d
```

#### Option 2: Using PowerShell

```powershell
# Clone the repository
git clone https://github.com/data-mint-research/MINTutil.git
cd MINTutil

# Copy environment template
Copy-Item .env.example .env

# Edit .env with your configuration
notepad .env

# Initialize the project
.\mint.ps1 init

# Start the application
.\mint.ps1 start
```

#### Option 3: Manual Installation

```bash
# Clone the repository
git clone https://github.com/data-mint-research/MINTutil.git
cd MINTutil

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Linux/Mac:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env

# Run the application
streamlit run streamlit_app/main.py
```

## ? Project Structure

```
mintutil/
??? mint.ps1              # PowerShell orchestration script
??? requirements.txt      # Python dependencies
??? docker-compose.yml    # Docker composition
??? Dockerfile           # Docker image definition
??? .env.example         # Environment configuration template
??? .gitignore          # Git ignore rules
??? tools/              # Modular tools directory
?   ??? transkription/  # Example tool: YouTube transcription
??? streamlit_app/      # Streamlit web interface
?   ??? main.py        # Main application entry
?   ??? page_loader.py # Dynamic tool loader
??? scripts/           # Utility scripts
?   ??? health_check.ps1
?   ??? init_project.ps1
?   ??? start_ui.ps1
?   ??? update.ps1
??? shared/            # Shared libraries and utilities
??? config/            # Configuration files
??? logs/              # Application logs
??? data/              # Data storage
??? tests/             # Test suite
??? docs/              # Documentation
```

## ? Available Commands

The `mint.ps1` script provides the following commands:

- `.\mint.ps1 init` - Initialize the project (first-time setup)
- `.\mint.ps1 start` - Start the web interface
- `.\mint.ps1 update` - Update MINTutil components
- `.\mint.ps1 doctor` - Run system diagnostics
- `.\mint.ps1 help` - Show help information

## ? Available Tools

### YouTube Transcription
- Automatically downloads and transcribes YouTube videos
- Uses OpenAI Whisper for accurate transcription
- Includes glossary-based name correction
- Exports transcripts as Markdown

## ?? Configuration

1. Copy `.env.example` to `.env`
2. Update the following key configurations:
   - `APP_NAME` - Application name
   - `APP_VERSION` - Application version
   - `STREAMLIT_SERVER_PORT` - Web interface port (default: 8501)
   - API keys (if using AI features)
   - Database settings (if required)

## ? Adding New Tools

To add a new tool to MINTutil:

1. Create a new directory under `tools/`
2. Add a `ui.py` file with a `render()` function
3. Create a `tool.meta.yaml` file with metadata:

```yaml
name: "My Tool"
description: "Tool description"
icon: "?"
version: "1.0.0"
author: "Your Name"
```

4. Implement your tool logic in the `render()` function
5. The tool will automatically appear in the web interface

## ? Testing

Run the test suite:

```bash
pytest tests/
```

With coverage:

```bash
pytest tests/ --cov=mintutil --cov-report=html
```

## ? Troubleshooting

If you encounter issues:

1. Check system diagnostics: `.\mint.ps1 doctor`
2. Review logs in the `logs/` directory
3. Ensure all prerequisites are installed
4. Verify environment configuration in `.env`

## ? License

MIT License - see LICENSE file for details

## ? Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## ? Support

For issues and questions:
- Open an issue on [GitHub](https://github.com/data-mint-research/MINTutil/issues)
- Check the [documentation](https://github.com/data-mint-research/MINTutil/tree/main/docs)

## ? Acknowledgments

- Built with [Streamlit](https://streamlit.io/)
- Uses [OpenAI Whisper](https://github.com/openai/whisper) for transcription
- Containerized with [Docker](https://www.docker.com/)

---

Made with ?? by the MINTutil team
