$json = Get-Content sonar_issues.json -Raw | ConvertFrom-Json
Write-Host "Total issues: $($json.total)"
$json.issues | Group-Object component | Sort-Object Count -Descending | Select-Object Count, Name | Select -First 30 | Format-Table -AutoSize
