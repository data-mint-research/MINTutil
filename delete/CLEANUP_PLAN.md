# MINTutil Cleanup - Obsolete Files and Folders

This document lists all files and folders identified as obsolete in the MINTutil project.
These items should be moved to a `/delete` folder or removed entirely.

## ?? Files to Delete/Move

### 1. `/shared/` (entire folder)
- **Status**: Empty folder with only `.gitkeep`
- **References**: Only mentioned in `scripts/init_project.ps1` line where directories are created
- **Reason**: No active use, appears to be leftover from previous architecture
- **Action**: Delete entire folder

### 2. `/config/system.env.template`
- **Status**: Redundant configuration template
- **References**: Only in `scripts/update.ps1`
- **Reason**: We already have `.env.example` in root directory
- **Action**: Delete file

### 3. `/scripts/fix_encoding.ps1`
- **Status**: One-time utility script
- **References**: None found in codebase
- **Reason**: Was used for fixing encoding issues, no longer needed
- **Action**: Move to `/delete` for reference

### 4. `/scripts/HEALTH_CHECK_MODULES.md`
- **Status**: Orphaned documentation
- **References**: None
- **Reason**: Documentation should be in `/docs`, not in scripts folder
- **Action**: Move to `/delete` or `/docs`

### 5. `/scripts/confirm.ps1`
- **Status**: Unused utility function
- **References**: None found in any scripts
- **Reason**: Helper script that was never integrated
- **Action**: Move to `/delete`

### 6. `/scripts/.gitkeep`
- **Status**: Unnecessary placeholder
- **References**: None
- **Reason**: Scripts folder has actual content, doesn't need .gitkeep
- **Action**: Delete

## ? Files to Keep

These files were verified as necessary:
- `/data/.gitkeep` - Needed as data folder is in .gitignore
- `/logs/.gitkeep` - Needed as logs folder is in .gitignore
- All other scripts in `/scripts/` - Referenced by mint.ps1 or other components

## ? Implementation Steps

1. Create `/delete` folder in project root
2. Move the identified files to `/delete`
3. Update `scripts/init_project.ps1` to remove reference to `/shared`
4. Update `scripts/update.ps1` to remove reference to `system.env.template`
5. Test all functionality to ensure nothing breaks
6. After verification, the `/delete` folder can be removed in a future cleanup

## ? Verification Commands Used

```bash
# Search for references
git grep -n "shared"
git grep -n "system.env.template"
git grep -n "fix_encoding"
git grep -n "confirm.ps1"
git grep -n "HEALTH_CHECK_MODULES"
```

## ?? Important Notes

- The `/shared` folder is only referenced in `init_project.ps1` where it creates directories
- No functional code depends on these files
- All core functionality remains intact after removal
