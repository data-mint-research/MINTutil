# Scripts Directory

This directory contains all MINTutil operational scripts.

## Core Scripts

### Health Check System
- `health_check.ps1` - Main health check orchestrator
- `health_check_environment.ps1` - Environment validation
- `health_check_logging.ps1` - Centralized logging functions  
- `health_check_requirements.ps1` - Dependency validation
- `HEALTH_CHECK_MODULES.md` - Health check documentation

### Project Lifecycle
- `setup_windows.ps1` - One-click installation system
- `start_ui.ps1` - Streamlit UI launcher
- `update.ps1` - Update mechanism

### Project Initialization
- `init-project-main.ps1` - Main initialization orchestrator
- `init-project-setup.ps1` - Setup logic
- `init-project-validation.ps1` - Validation logic

### Standards & Utilities
- `check-neomint-compliance.ps1` - NeoMINT standards enforcement
- `confirm.ps1` - User confirmation utilities

### Archive
- `deleted/` - Contains obsolete scripts preserved for history

All scripts are called through the main `mint.ps1` CLI in the project root.
