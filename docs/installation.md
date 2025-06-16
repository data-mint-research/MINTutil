# Installation Guide

This guide provides detailed instructions for installing MINTutil on various platforms.

## Table of Contents

- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
  - [Docker Installation](#docker-installation)
  - [PowerShell Installation](#powershell-installation)
  - [Manual Installation](#manual-installation)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## System Requirements

### Minimum Requirements

- **Operating System**: Windows 10/11, macOS 10.15+, Linux (Ubuntu 20.04+)
- **Python**: 3.11 or higher
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Storage**: 2GB free disk space
- **Network**: Internet connection for downloading dependencies

### Optional Requirements

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **PowerShell**: Version 5.1 or higher (Windows)

## Installation Methods

### Docker Installation

Docker provides the most consistent and isolated environment for running MINTutil.

1. **Install Docker**
   
   - **Windows/Mac**: Download [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - **Linux**: Follow the [official Docker installation guide](https://docs.docker.com/engine/install/)

2. **Clone the Repository**
   
   ```bash
   git clone https://github.com/data-mint-research/MINTutil.git
   cd MINTutil
   ```

3. **Configure Environment**
   
   ```bash
   # Copy the environment template
   cp .env.example .env
   
   # Edit the configuration
   nano .env  # or use your preferred editor
   ```

4. **Build and Start**
   
   ```bash
   # Build the Docker image
   docker-compose build
   
   # Start the services
   docker-compose up -d
   
   # View logs
   docker-compose logs -f
   ```

5. **Access the Application**
   
   Open your browser and navigate to: `http://localhost:8501`

### PowerShell Installation

For Windows users who prefer using PowerShell:

1. **Prerequisites**
   
   Ensure PowerShell 5.1 or higher is installed:
   ```powershell
   $PSVersionTable.PSVersion
   ```

2. **Clone the Repository**
   
   ```powershell
   git clone https://github.com/data-mint-research/MINTutil.git
   Set-Location MINTutil
   ```

3. **Configure Environment**
   
   ```powershell
   # Copy environment template
   Copy-Item .env.example .env
   
   # Edit configuration
   notepad .env
   ```

4. **Initialize Project**
   
   ```powershell
   # Run initialization
   .\mint.ps1 init
   ```

5. **Start Application**
   
   ```powershell
   .\mint.ps1 start
   ```

### Manual Installation

For users who prefer manual setup:

1. **Install Python**
   
   Download and install Python 3.11+ from [python.org](https://www.python.org/downloads/)

2. **Clone the Repository**
   
   ```bash
   git clone https://github.com/data-mint-research/MINTutil.git
   cd MINTutil
   ```

3. **Create Virtual Environment**
   
   ```bash
   # Create virtual environment
   python -m venv venv
   
   # Activate virtual environment
   # On Windows:
   venv\Scripts\activate
   # On Linux/Mac:
   source venv/bin/activate
   ```

4. **Install Dependencies**
   
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

5. **Configure Environment**
   
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

6. **Run Application**
   
   ```bash
   streamlit run streamlit_app/main.py
   ```

## Configuration

### Essential Configuration

Edit the `.env` file with your specific settings:

```env
# Application Settings
APP_NAME=MINTutil
APP_VERSION=0.1.0
ENVIRONMENT=development
DEBUG=True

# Streamlit Configuration
STREAMLIT_SERVER_PORT=8501
STREAMLIT_SERVER_ADDRESS=0.0.0.0

# API Keys (if using AI features)
OPENAI_API_KEY=your-key-here
ANTHROPIC_API_KEY=your-key-here
```

### Advanced Configuration

For production deployments:

```env
# Production Settings
ENVIRONMENT=production
DEBUG=False

# Security
SECRET_KEY=generate-a-secure-key
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

# Database (if needed)
DB_HOST=your-database-host
DB_PORT=5432
DB_NAME=mintutil_prod
DB_USER=mintutil_user
DB_PASSWORD=secure-password
```

## Verification

### Verify Installation

1. **Check System Health**
   
   ```bash
   # Using PowerShell
   .\mint.ps1 doctor
   
   # Or manually
   python scripts/health_check.py
   ```

2. **Access Web Interface**
   
   Open `http://localhost:8501` in your browser

3. **Run Tests**
   
   ```bash
   pytest tests/
   ```

### Expected Output

You should see:
- ? All system checks passing
- ? Web interface accessible
- ? No error messages in logs

## Troubleshooting

### Common Issues

#### Port Already in Use

**Error**: `Address already in use`

**Solution**:
```bash
# Find process using port 8501
# On Windows:
netstat -ano | findstr :8501
# On Linux/Mac:
lsof -i :8501

# Change port in .env file
STREAMLIT_SERVER_PORT=8502
```

#### Python Version Error

**Error**: `Python 3.11+ required`

**Solution**:
- Update Python to 3.11 or higher
- Use pyenv or conda to manage Python versions

#### Docker Permission Error

**Error**: `Permission denied`

**Solution**:
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
# Log out and back in
```

#### Module Import Error

**Error**: `ModuleNotFoundError`

**Solution**:
```bash
# Ensure virtual environment is activated
# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

### Getting Help

If you encounter issues not covered here:

1. Check the [troubleshooting guide](troubleshooting.md)
2. Search [existing issues](https://github.com/data-mint-research/MINTutil/issues)
3. Create a new issue with:
   - Error messages
   - System information
   - Steps to reproduce

## Next Steps

- Read the [User Guide](user-guide.md) to learn how to use MINTutil
- Explore the [Tool Development Guide](tool-development.md) to create custom tools
- Check the [API Reference](api-reference.md) for programmatic access
