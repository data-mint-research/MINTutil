# NeoMINT Coding Practices - Deviations

## Purpose
This file documents all deliberate deviations from the NeoMINT Coding Practices in the MINTutil project.
Each deviation must be justified and should be temporary.

## Current Deviations

### 1. README.md in Root Directory
**Rule**: No distributed README.md - everything under /docs/
**Deviation**: README.md exists in root directory
**Justification**: GitHub and most Git platforms expect a README.md in root for project overview
**Action**: Keep README.md in root, but maintain all other documentation in /docs/
**Status**: PERMANENT (Platform requirement)

### 2. Exceeding 500 LOC Limit
**Rule**: Maximum length per unit: 500 LOC
**Affected Files**: 
- scripts/start_ui.ps1 (502 lines) 
- scripts/update.ps1 (564 lines)
**Justification**: Complex installation and setup routines
**Action**: Refactoring into modules planned for v0.2.0
**Status**: IN PROGRESS
**Update 2025-06-16**: 
- COMPLETE: init_project.ps1 was successfully split into modules
- COMPLETE: setup_windows.ps1 was revised and optimized

### 3. Encoding Issues
**Rule**: ASCII-compliant names and code
**Deviation**: German umlauts in some PowerShell scripts
**Justification**: Historically grown, German documentation
**Action**: Gradual cleanup
**Status**: FIXED (95%)
**Update 2025-06-16**: 
- COMPLETE: mint.ps1 cleaned
- COMPLETE: health_check.ps1 cleaned
- COMPLETE: init_project modules cleaned
- COMPLETE: setup_windows.ps1 cleaned
- COMPLETE: check-neomint-compliance.ps1 cleaned
- COMPLETE: main.py cleaned
- COMPLETE: All critical files are now UTF-8 compliant

### 4. File Names Not in kebab-case
**Rule**: kebab-case for files
**Affected Files**:
- HEALTH_CHECK_MODULES.md
- CODE_REVIEW_FIXES.md
- INSTALLATION_WINDOWS.md
- QUICK_START.md
- Dockerfile
- LICENSE
**Justification**: 
- Capital letters for Markdown files increase visibility
- Dockerfile and LICENSE are industry standards
**Action**: Gradually rename Markdown files
**Status**: PLANNED for v0.2.0

### 5. Missing Headers in Some PS1 Files
**Rule**: Every .ps1 contains header with purpose, author, date
**Affected Files**: Some scripts in scripts/
**Justification**: Time pressure during initial development
**Action**: Headers will be added retroactively
**Status**: FIXED (95%)
**Update 2025-06-16**:
- COMPLETE: mint.ps1 has complete header
- COMPLETE: health_check.ps1 has complete header
- COMPLETE: All init-project modules have headers
- COMPLETE: check-neomint-compliance.ps1 has header
- COMPLETE: setup_windows.ps1 has complete header
- COMPLETE: main.py has complete Python docstring

### 6. Documentation Design Standardization
**Rule**: Professional documentation without decorative emojis
**Deviation**: Historical use of emojis in headings and structure
**Justification**: Previous design decisions before professional standards
**Action**: Comprehensive emoji removal and professional formatting
**Status**: COMPLETE (2025-06-17)
**Update 2025-06-17**:
- COMPLETE: Documentation Design Standards created
- COMPLETE: NeoMINT Coding Practices updated to v0.3
- COMPLETE: All README files updated to professional format
- COMPLETE: UI elements updated to professional appearance
- COMPLETE: Tool metadata updated to professional standards

## History of Deviations

### 2025-06-17
- Applied professional documentation design standards
- Removed all decorative emojis from documentation
- Updated NeoMINT Coding Practices to v0.3
- Implemented Documentation Design Standards
- Completed German to English translation project

### 2025-06-16
- Updated NeoMINT Coding Practices to v0.2 (Metadata Blocks & Comments)
- Comprehensive encoding cleanup performed
- Added metadata blocks to all critical files
- Extended compliance checker for new standards
- Implemented 95% of all TODOs and open items

### 2025-06-15
- Created initial documentation of deviations
- Analyzed existing code
- Cleaned mint.ps1 of umlauts and added header
- Implemented NeoMINT Compliance Checker
- Added GitHub Action for automatic checking
- Cleaned health_check.ps1 and added header
- Split init_project.ps1 into compliant modules:
  - init-project-main.ps1 (147 LOC)
  - init-project-validation.ps1 (204 LOC)
  - init-project-setup.ps1 (349 LOC)
  - init_project.ps1 as lean wrapper (41 LOC)

## Process for New Deviations

1. Document deviation in this document
2. Provide justification and planned action
3. Mark in code with comment: `# DEVIATION: see /docs/deviations.md`
4. Team review
5. Set timeline for resolution

## Automatic Checking

The project uses the following tools for compliance checking:
- `scripts/check-neomint-compliance.ps1` - Local checking
- GitHub Action `.github/workflows/neomint-compliance.yml` - CI/CD Integration

Run before each commit:
```powershell
.\scripts\check-neomint-compliance.ps1
```

## Progress

### Already Compliant:
- Central logging function (Write-Log)
- Documentation under /docs/
- Security guidelines
- Version control
- AI compatibility
- mint.ps1 (main file)
- health_check.ps1
- init_project.ps1 (modularized)
- Compliance checker
- setup_windows.ps1
- Encoding issues fixed
- Metadata blocks implemented
- Comment standards implemented
- Professional documentation design

### Still To Do:
- start_ui.ps1 (502 LOC) - Modularization
- update.ps1 (564 LOC) - Modularization
- Align file naming conventions
- Develop additional tool modules

## Contact

For questions about the standards or deviations:
- Create issue in repository
- Tag: `neomint-compliance`

---

**Document Version**: 1.2
**Last Updated**: 2025-06-17
**Status**: Current and Complete
