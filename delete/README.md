# Delete - Obsolete Files

This directory contains files and folders that were identified as obsolete or unused in the MINTutil project.
These files have been moved here for review before permanent deletion.

## Moved Files:

### From `/shared/`
- **Entire folder** - Empty folder with only .gitkeep, referenced only in init_project.ps1 but not actively used

### From `/config/`
- **system.env.template** - Redundant template file (we use .env.example in root)

### From `/scripts/`
- **fix_encoding.ps1** - One-time fix script, no longer referenced or needed
- **HEALTH_CHECK_MODULES.md** - Orphaned documentation, should be in /docs if needed
- **confirm.ps1** - Unused utility script for confirmation dialogs
- **.gitkeep** - Unnecessary as the scripts folder has content

## Analysis Date: 2025-06-16

These files were analyzed and found to have:
- No active references in the codebase (except minimal references)
- No functional purpose in the current architecture
- Redundancy with other files

## Recommendation:
After review, these files can be permanently deleted from the repository.
