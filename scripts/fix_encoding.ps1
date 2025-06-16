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

# Check if we're in the right directory
if (-not (Test-Path "mint.ps1")) {
    Write-Host "Error: Not in MINTutil root directory" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "`nSearching for all text files to fix encoding issues..." -ForegroundColor Yellow

# Define file extensions to process
$fileExtensions = @(
    "*.ps1",    # PowerShell scripts
    "*.py",     # Python files
    "*.txt",    # Text files
    "*.md",     # Markdown files
    "*.yml",    # YAML files
    "*.yaml",   # YAML files
    "*.json",   # JSON files
    "*.xml",    # XML files
    "*.html",   # HTML files
    "*.css",    # CSS files
    "*.js",     # JavaScript files
    "*.ts",     # TypeScript files
    "*.jsx",    # React JSX
    "*.tsx",    # React TSX
    "*.sh",     # Shell scripts
    "*.bat",    # Batch files
    "*.cmd",    # Command files
    "*.ini",    # INI files
    "*.cfg",    # Config files
    "*.conf",   # Config files
    "*.log",    # Log files (if not too large)
    "*.csv",    # CSV files
    "*.sql",    # SQL files
    "*.r",      # R scripts
    "*.R"       # R scripts
)

# Directories to exclude
$excludeDirs = @(
    ".git",
    ".venv",
    "venv",
    "node_modules",
    "__pycache__",
    ".pytest_cache",
    "dist",
    "build",
    "*.egg-info",
    ".vs",
    ".vscode",
    ".idea"
)

# Function to check if path should be excluded
function Should-Exclude {
    param($Path)
    
    foreach ($exclude in $excludeDirs) {
        if ($Path -like "*\$exclude\*" -or $Path -like "*/$exclude/*") {
            return $true
        }
    }
    return $false
}

# Find all files to process
$allFiles = @()
foreach ($pattern in $fileExtensions) {
    $files = Get-ChildItem -Path $projectRoot -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        if (-not (Should-Exclude $file.FullName)) {
            $allFiles += $file
        }
    }
}

Write-Host "Found $($allFiles.Count) files to check" -ForegroundColor Cyan

$fixedCount = 0
$errorCount = 0
$skippedCount = 0
$checkedCount = 0

foreach ($file in $allFiles) {
    $relativePath = $file.FullName.Replace($projectRoot + "\", "").Replace($projectRoot + "/", "")
    $checkedCount++
    
    # Skip very large files (>10MB)
    if ($file.Length -gt 10MB) {
        Write-Host "[$checkedCount/$($allFiles.Count)] Skipping large file: $relativePath ($([math]::Round($file.Length/1MB, 2))MB)" -ForegroundColor DarkGray
        $skippedCount++
        continue
    }
    
    try {
        # Read file content
        $content = Get-Content $file.FullName -Raw -Encoding Default -ErrorAction Stop
        
        if ([string]::IsNullOrEmpty($content)) {
            $skippedCount++
            continue
        }
        
        # Check if file contains typical encoding issues
        $questionMarkCount = ([regex]::Matches($content, '\?')).Count
        $hasUmlautIssues = $content -match '[???????]' -and $questionMarkCount -gt 0
        
        # Check for BOM
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $hasBOM = $false
        if ($bytes.Length -ge 3) {
            $hasBOM = $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        }
        
        if ($hasUmlautIssues -or $hasBOM -or $questionMarkCount -gt 5) {
            Write-Host "[$checkedCount/$($allFiles.Count)] Processing: $relativePath" -NoNewline
            
            if ($hasBOM) {
                Write-Host " - Has BOM" -ForegroundColor Yellow -NoNewline
            }
            if ($questionMarkCount -gt 0) {
                Write-Host " - Found $questionMarkCount '?' chars" -ForegroundColor Yellow -NoNewline
            }
            
            # Try different encodings to find the best one
            $encodings = @('UTF8', 'Default', 'Unicode', 'UTF7', 'UTF32', 'ASCII')
            $bestContent = $content
            $lowestQuestionCount = $questionMarkCount
            $bestEncoding = "Default"
            
            foreach ($encoding in $encodings) {
                try {
                    $testContent = Get-Content $file.FullName -Raw -Encoding $encoding -ErrorAction SilentlyContinue
                    if ($testContent) {
                        $testQuestionCount = ([regex]::Matches($testContent, '\?')).Count
                        
                        # Prefer content with fewer question marks and valid German umlauts
                        if ($testQuestionCount -lt $lowestQuestionCount -or 
                            ($testContent -match '[???????]' -and -not ($bestContent -match '[???????]'))) {
                            $bestContent = $testContent
                            $lowestQuestionCount = $testQuestionCount
                            $bestEncoding = $encoding
                        }
                    }
                } catch {
                    # Skip encoding if it fails
                }
            }
            
            # Write as UTF-8 without BOM
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($file.FullName, $bestContent, $utf8NoBom)
            
            Write-Host " - Fixed! (used $bestEncoding)" -ForegroundColor Green
            $fixedCount++
        } else {
            # File seems OK, but ensure it's UTF-8 without BOM
            if ($hasBOM) {
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
                Write-Host "[$checkedCount/$($allFiles.Count)] Removed BOM from: $relativePath" -ForegroundColor Green
                $fixedCount++
            }
        }
    } catch {
        Write-Host "[$checkedCount/$($allFiles.Count)] Error processing: $relativePath - $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Files checked: $checkedCount" -ForegroundColor White
Write-Host "  Files fixed: $fixedCount" -ForegroundColor Green
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
    Set-Location $projectRoot
    git status --short
    
    Write-Host "`nTo commit these fixes:" -ForegroundColor Yellow
    Write-Host "  git add -A" -ForegroundColor White
    Write-Host "  git commit -m 'Fix encoding issues - convert all files to UTF-8 without BOM'" -ForegroundColor White
}
