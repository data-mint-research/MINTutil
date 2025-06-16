# Fix Encoding Issues in MINTutil Files
# This script converts all files to UTF-8 without BOM

Write-Host "MINTutil Encoding Fix Script" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

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
    Write-Host "Error: Please run this script from the MINTutil root directory" -ForegroundColor Red
    exit 1
}

Write-Host "`nChecking and fixing encoding issues..." -ForegroundColor Yellow

$fixedCount = 0
$errorCount = 0

foreach ($file in $filesToFix) {
    if (Test-Path $file) {
        try {
            Write-Host "Processing: $file" -NoNewline
            
            # Read with automatic encoding detection
            $content = Get-Content $file -Raw -Encoding Default
            
            # Check if file contains typical encoding issues (? instead of umlauts)
            if ($content -match '\?') {
                # Try to read with specific encodings
                $encodings = @('UTF8', 'Default', 'Unicode', 'ASCII')
                $bestContent = $null
                
                foreach ($encoding in $encodings) {
                    try {
                        $testContent = Get-Content $file -Raw -Encoding $encoding
                        # Check if this encoding produces fewer question marks
                        if (($testContent -split '\?' | Measure-Object).Count -lt ($bestContent -split '\?' | Measure-Object).Count) {
                            $bestContent = $testContent
                        }
                    } catch {
                        # Skip encoding if it fails
                    }
                }
                
                if ($bestContent) {
                    $content = $bestContent
                }
            }
            
            # Write as UTF-8 without BOM
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($file, $content, $utf8NoBom)
            
            Write-Host " - Fixed!" -ForegroundColor Green
            $fixedCount++
        } catch {
            Write-Host " - Error: $_" -ForegroundColor Red
            $errorCount++
        }
    } else {
        Write-Host "Skipping: $file (not found)" -ForegroundColor DarkGray
    }
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Files processed: $fixedCount" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "  Errors: $errorCount" -ForegroundColor Red
}

Write-Host "`nAll files have been converted to UTF-8 without BOM." -ForegroundColor Green
Write-Host "Please commit these changes to fix the encoding issues." -ForegroundColor Yellow

# Optional: Show git status
Write-Host "`nGit status:" -ForegroundColor Cyan
git status --short

Write-Host "`nTo commit these fixes:" -ForegroundColor Yellow
Write-Host "  git add -A" -ForegroundColor White
Write-Host "  git commit -m 'Fix encoding issues - convert to UTF-8 without BOM'" -ForegroundColor White
