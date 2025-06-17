# NeoMINT Coding Practices (v0.3)

These rules apply without exception to all code units and documentation that you generate, review, or process:

---

## 1. Structure & Granularity
- Each file or function fulfills exactly **one task** (SRP)
- Maximum length per unit: **500 LOC** (LLM-compatible)
- Logic, UI, configuration are **modularly separated**
- No global state, no implicit dependencies

---

## 2. Naming
- Names are **descriptive**, consistent, and ASCII-compliant
- `PascalCase` for functions (e.g., `StartSessionLog`)
- `camelCase` for variables (e.g., `$userName`)
- `kebab-case` for files (e.g., `install-vscode.ps1`)
- No spaces, umlauts, emojis, or special characters

---

## 3. Logging & Errors
- Only one central logging function (e.g., `Write-Log`)
- New logs for each session, timestamp in the name
- Errors via `try/catch`, clearly distinguishable (`WARNING` vs `ERROR`)
- No silent error handling

---

## 4. Documentation & Comments
- Comments explain **intent**, not syntax
- Every `.ps1` contains header with purpose, author, date
- No distributed `README.md` ? everything under `/docs/`
- Deviations **always double documented** (in code + in `/docs/deviations.md`)
- **Professional documentation design** following [Documentation Design Standards](docs/documentation-design-standards.md)

---

## 5. Professional Documentation Standards

### Visual Design
- **No decorative emojis** in headings or technical content
- **Clean typography** with consistent markdown formatting
- **Professional appearance** suitable for enterprise environments
- **Status indicators** use text or minimal symbols (? ? ?? only)

### Structure Requirements
- **Consistent heading hierarchy** (H1 for title, H2 for major sections)
- **Descriptive section titles** without emoji decoration
- **Clear navigation** with logical content organization
- **Professional tone** throughout all documentation

### Content Standards
- **Code blocks** always specify language
- **Links** use descriptive text, not "here" or "click this"
- **Lists** maintain parallel structure
- **Tables** include headers and consistent formatting

### Enforcement
- Documentation must pass professional review standard
- Would this represent the project well to enterprise clients?
- All docs follow the [Documentation Design Standards](docs/documentation-design-standards.md)

---

## 6. Security
- Check OWASP + CIS Benchmark **before implementation**
- No security-relevant workarounds
- Logs **never** contain tokens or passwords
- Document security decisions ? but always with productivity considerations

---

## 7. Version Control
- Only working code is committed
- Temporary branches must be recognizable (`temp/debug-*`)
- Never secrets in repos
- `.gitignore` protects specifically, but doesn't block development work

---

## 8. Behavior
- Developers are responsible for comprehensibility
- Every `TODO` is concrete, visible, and actionable
- If you break a rule: **justify it visibly and in writing**

---

## 9. AI Compatibility
- You work for humans **and** machines
- Write everything so that other LLMs can analyze, modify, and correctly continue it
- Don't repeat information, but structure it so that it's **completely** readable

---

## 10. Metadata Blocks & Comments

### Metadata Block Standards
Every script MUST start with a proper metadata block following these industry standards:

#### PowerShell Scripts (.ps1)
```powershell
<#
.SYNOPSIS
    Brief one-line description of what the script does
.DESCRIPTION
    Detailed explanation of functionality, use cases, and behavior
.PARAMETER ParameterName
    Description of each parameter
.EXAMPLE
    PS> .\script.ps1 -Parameter "value"
    Shows how to use the script
.NOTES
    Author: Name/Team
    Date: YYYY-MM-DD
    Version: X.Y.Z
    Dependencies: List any requirements
.LINK
    https://github.com/repo/docs/relevant-documentation
#>
```

#### Python Scripts (.py)
```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module Name: Brief description

Detailed explanation of what this module does, its purpose,
and how it fits into the larger system.

Author: Name/Team
Date: YYYY-MM-DD
Version: X.Y.Z
Dependencies: List required packages
"""
```

#### Shell Scripts (.sh)
```bash
#!/bin/bash
#
# Script: script-name.sh
# Purpose: Brief description
# 
# Description:
#   Detailed explanation of functionality
#
# Usage: ./script-name.sh [options]
# 
# Author: Name/Team
# Date: YYYY-MM-DD
# Version: X.Y.Z
```

### Inline Comment Standards
- **Above complex logic**: Explain WHY, not WHAT
- **For workarounds**: Document the issue and link to ticket/issue if available
- **For magic numbers/values**: Explain their significance
- **Format**: Start with capital letter, end with period

#### Good Examples:
```python
# Calculate retry delay using exponential backoff to prevent server overload.
delay = min(300, (2 ** attempt) * 10)

# Workaround for Windows path limitation (260 chars). See issue #123.
if len(path) > 250:
    path = get_short_path(path)
```

#### Bad Examples:
```python
# increment counter
counter += 1

# set to 5
max_retries = 5
```

### Function/Method Documentation
Every function must have documentation explaining:
- Purpose (one line)
- Parameters with types
- Return value with type
- Exceptions that may be raised
- Example usage for complex functions

---

## Implementation in the MINTutil Project

### Code Review Checkpoints
1. **File length**: No file over 500 LOC
2. **Function names**: All PowerShell functions in PascalCase
3. **Variable names**: All variables in camelCase
4. **File names**: All files in kebab-case (exception: README.md)
5. **ASCII**: No umlauts or special characters in code
6. **Logging**: Use of the central Write-Log function
7. **Header**: Every script file has complete metadata block
8. **Comments**: All complex logic has explanatory comments
9. **TODOs**: All TODOs are concrete and traceable
10. **Documentation**: Follows professional design standards without decorative emojis

### Documentation Review Checkpoints
1. **Professional appearance**: No decorative emojis in headings
2. **Consistent structure**: Proper heading hierarchy
3. **Clear navigation**: Logical organization
4. **Professional tone**: Suitable for enterprise environments
5. **Code formatting**: All code blocks specify language
6. **Link quality**: Descriptive link text
7. **Table formatting**: Headers and consistent structure

### Verification Tools
- `scripts/check-neomint-compliance.ps1` - Automatic verification
- `docs/deviations.md` - Documented exceptions
- GitHub Actions for automatic validation
- Documentation design standards enforcement

### For Questions or Uncertainties
- Create issue in repository
- Reference [Documentation Design Standards](docs/documentation-design-standards.md)
- Convene team meeting
- Extend documentation

---

**Version**: 0.3  
**Last Updated**: 2025-06-17  
**Changes**: Added professional documentation standards and emoji restrictions
