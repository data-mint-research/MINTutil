# Fix Encoding Issues in MINTutil Files
# This script converts all files to UTF-8 without BOM

Write-Host "MINTutil Encoding Fix Script" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

# Get the script's directory and move to project root
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

# Change to project root directory
Push-Location $projectRoot
Write-Host "Working directory: $projectRoot" -ForegroundColor Yellow

# Files with known encoding issues
$filesToFix = @(
    "scripts/confirm.ps1",
    "scripts/health_check_environment.ps1",
    "scripts/health_check_logging.ps1",
    "scripts/health_check_requirements.ps1",
    "scripts/init_project.ps1",
    "scripts/start_ui.ps1",
    "streamlit_app/main.py",
    "streamlit_app/page_loader.py",
    "tools/transkription/ui.py"
)

# Check if we're in the right directory
if (-not (Test-Path "mint.ps1")) {
    Write-Host "Error: Not in MINTutil root directory" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "`nChecking and fixing encoding issues..." -ForegroundColor Yellow

$fixedCount = 0
$errorCount = 0
$skippedCount = 0

foreach ($file in $filesToFix) {
    # Build absolute path
    $fullPath = Join-Path $projectRoot $file
    
    if (Test-Path $fullPath) {
        try {
            Write-Host "Processing: $file" -NoNewline
            
            # Read with automatic encoding detection
            $content = Get-Content $fullPath -Raw -Encoding Default
            
            # Check if file contains typical encoding issues (? instead of umlauts)
            $questionMarkCount = ([regex]::Matches($content, '\?')).Count
            if ($questionMarkCount -gt 0) {
                Write-Host " - Found $questionMarkCount encoding issues" -ForegroundColor Yellow -NoNewline
                
                # Try to read with specific encodings
                $encodings = @('UTF8', 'Default', 'Unicode', 'ASCII')
                $bestContent = $content
                $lowestQuestionCount = $questionMarkCount
                
                foreach ($encoding in $encodings) {
                    try {
                        $testContent = Get-Content $fullPath -Raw -Encoding $encoding -ErrorAction SilentlyContinue
                        if ($testContent) {
                            $testQuestionCount = ([regex]::Matches($testContent, '\?')).Count
                            
                            if ($testQuestionCount -lt $lowestQuestionCount) {
                                $bestContent = $testContent
                                $lowestQuestionCount = $testQuestionCount
                            }
                        }
                    } catch {
                        # Skip encoding if it fails
                    }
                }
                
                $content = $bestContent
            }
            
            # Write as UTF-8 without BOM
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($fullPath, $content, $utf8NoBom)
            
            Write-Host " - Fixed!" -ForegroundColor Green
            $fixedCount++
        } catch {
            Write-Host " - Error: $_" -ForegroundColor Red
            $errorCount++
        }
    } else {
        Write-Host "Skipping: $file (not found)" -ForegroundColor DarkGray
        $skippedCount++
    }
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Files processed: $fixedCount" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "  Errors: $errorCount" -ForegroundColor Red
}
if ($skippedCount -gt 0) {
    Write-Host "  Skipped: $skippedCount" -ForegroundColor DarkGray
}

if ($fixedCount -gt 0) {
    Write-Host "`nFiles have been converted to UTF-8 without BOM." -ForegroundColor Green
    Write-Host "Please review and commit these changes." -ForegroundColor Yellow
}

# Restore original location
Pop-Location

# Optional: Show git status
if ($fixedCount -gt 0) {
    Write-Host "`nGit status:" -ForegroundColor Cyan
    git status --short
    
    Write-Host "`nTo commit these fixes:" -ForegroundColor Yellow
    Write-Host "  git add -A" -ForegroundColor White
    Write-Host "  git commit -m 'Fix encoding issues - convert to UTF-8 without BOM'" -ForegroundColor White
}
