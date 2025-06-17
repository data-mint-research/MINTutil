# LLM Digest ? NeoMINT Coding Practices (v0.3)

These rules apply without exception to all code units that you generate, review, or process:

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

---

## 5. Security
- Check OWASP + CIS Benchmark **before implementation**
- No security-relevant workarounds
- Logs **never** contain tokens or passwords
- Document security decisions ? but always with productivity considerations

---

## 6. Version Control
- Only working code is committed
- Temporary branches must be recognizable (`temp/debug-*`)
- Never secrets in repos
- `.gitignore` protects specifically, but doesn't block development work

---

## 7. Behavior
- Developers are responsible for comprehensibility
- Every `TODO` is concrete, visible, and actionable
- If you break a rule: **justify it visibly and in writing**

---

## 8. AI Compatibility
- You work for humans **and** machines
- Write everything so that other LLMs can analyze, modify, and correctly continue it
- Don't repeat information, but structure it so that it's **completely** readable

---

## 9. Metadata Blocks & Comments

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

## 10. Problem Analysis & Solution Design (MECE Principle)

### MECE Requirement
All analysis, categorization, and architectural decisions must follow **MECE** principles:
- **Mutually Exclusive**: No overlap between categories/components
- **Collectively Exhaustive**: Complete coverage of the problem space

### Application Areas
- **Architecture design**: Component separation and responsibility allocation
- **Script organization**: Function grouping and module boundaries  
- **Problem analysis**: Issue categorization and solution approaches
- **Documentation structure**: Information organization and classification
- **Code reviews**: Systematic evaluation criteria

### MECE Implementation Standards

#### Good MECE Example - Script Categories:
```
Category A: Core Operations (Keep)
??? A1. Health Check System (4 scripts)
??? A2. Lifecycle Management (3 scripts)  
??? A3. Initialization System (3 scripts)

Category B: Obsolete Scripts (Delete)
??? B1. Migration Tools (2 scripts)
??? B2. Unnecessary Wrappers (1 script)

Category C: Conditional Scripts (Review)
??? C1. Standards Enforcement (1 script)
??? C2. Utility Functions (1 script)
```
? **MECE Compliant**: No script appears in multiple categories, all scripts covered

#### Bad Non-MECE Example:
```
- Important Scripts (5 scripts)
- PowerShell Scripts (12 scripts)  
- Old Scripts (3 scripts)
```
? **MECE Violation**: Overlapping categories (PowerShell scripts includes important scripts)

### Verification Requirements
- **Before implementation**: Create MECE analysis for complex designs
- **During code review**: Verify component boundaries don't overlap
- **In documentation**: Use MECE structure for categorization
- **For refactoring**: Apply MECE to identify consolidation opportunities

### MECE Documentation Template
```markdown
## Problem Analysis: [Problem Name]

### Categories (MECE):
| Category | Items | Criteria | Action |
|----------|-------|----------|--------|
| A: [Name] | X items | [Clear criteria] | [Decision] |
| B: [Name] | Y items | [Clear criteria] | [Decision] |
| C: [Name] | Z items | [Clear criteria] | [Decision] |

### Verification:
- ? Mutually Exclusive: No item appears in multiple categories
- ? Collectively Exhaustive: All items classified (Total: X+Y+Z)
```

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
10. **MECE**: All analysis and categorization follows MECE principles

### Verification Tools
- `scripts/check-neomint-compliance.ps1` - Automatic verification
- `docs/deviations.md` - Documented exceptions
- GitHub Actions for automatic validation

### For Questions or Uncertainties
- Create issue in repository
- Convene team meeting
- Extend documentation
