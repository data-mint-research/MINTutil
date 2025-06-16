# MINTutil Documentation

Welcome to the MINTutil documentation. This directory contains comprehensive guides and references for using and extending MINTutil.

## ? Documentation Structure

### Core Documentation
- [Installation Guide](installation.md) - Detailed installation instructions
- [Quick Start](QUICK_START.md) - Get started quickly
- [Tool Development](tool-development.md) - How to create new tools
- [Windows Installation](INSTALLATION_WINDOWS.md) - Windows-specific setup

### Standards & Compliance
- [NeoMINT Coding Practices](neomint-coding-practices.md) - Our coding standards
- [Abweichungen (Deviations)](abweichungen.md) - Documented deviations from standards
- [Code Review Fixes](CODE_REVIEW_FIXES.md) - Code review documentation

## ? Development Standards

This project follows the NeoMINT Coding Practices v0.1:
- Maximum 500 LOC per file
- PascalCase for functions
- kebab-case for filenames
- Central logging with Write-Log
- No umlauts or special characters in code
- Complete documentation in /docs/

Run compliance check before committing:
```powershell
.\scripts\check-neomint-compliance.ps1
```

## ? Quick Links

- [GitHub Repository](https://github.com/data-mint-research/MINTutil)
- [Issue Tracker](https://github.com/data-mint-research/MINTutil/issues)
- [Contributing Guidelines](../CONTRIBUTING.md)

## ? Version

This documentation is for MINTutil version 0.1.0.

Last updated: June 2025
