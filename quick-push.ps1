param (
    [Parameter(Mandatory=$false)]
    [string]$CommitMessage = "Auto-commit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
)

Write-Host "Adding changes..." -ForegroundColor Cyan
git add .

Write-Host "Committing changes with message: '$CommitMessage'" -ForegroundColor Cyan
git commit -m "$CommitMessage"

Write-Host "Pushing to remote repository..." -ForegroundColor Cyan
git push origin main

Write-Host "Done! Code is now on GitHub and CI pipeline should trigger." -ForegroundColor Green
