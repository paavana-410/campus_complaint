$json = Get-Content sonar_73_issues.json -Raw | ConvertFrom-Json
$medium = $json.issues | Where-Object { $_.severity -eq 'MEDIUM' -or $_.type -eq 'CODE_SMELL' }
Write-Output "Found $($medium.Count) issues."
$medium | Select-Object component, line, message | Format-Table -AutoSize -Wrap
