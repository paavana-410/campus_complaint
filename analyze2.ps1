$json = Get-Content sonar_issues.json -Raw | ConvertFrom-Json
$realIssues = $json.issues | Where-Object { $_.component -notmatch 'coverage' -and $_.component -notmatch 'node_modules' }
Write-Host "Real issues: $($realIssues.Count)"
$realIssues | Group-Object rule | Sort-Object Count -Descending | Select-Object Count, Name | Select -First 15 | Format-Table -AutoSize
