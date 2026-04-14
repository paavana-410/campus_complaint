param (
    [string]$CommitMessage = ""
)

Write-Host "Starting Auto Git Push..." -ForegroundColor Cyan

# If no commit message is provided, generate one with the current timestamp
if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $CommitMessage = "Auto-commit on $timestamp"
    Write-Host "No commit message provided. Using: '$CommitMessage'" -ForegroundColor Yellow
}

# 1. Add all changes
Write-Host "Adding changes to staging area..." -ForegroundColor Green
git add .

# 2. Commit changes
Write-Host "Committing changes..." -ForegroundColor Green
git commit -m "$CommitMessage"

# 3. Push to remote
Write-Host "Pushing to remote repository..." -ForegroundColor Green
git push

Write-Host "Git operations completed successfully!" -ForegroundColor Cyan
