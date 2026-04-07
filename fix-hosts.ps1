$hostsPath = 'C:\Windows\System32\drivers\etc\hosts'
$content = Get-Content $hostsPath -Raw
$content = $content -replace '192\.168\.49\.2\s+campus\.local', '127.0.0.1  campus.local'
Set-Content -Path $hostsPath -Value $content
Write-Host 'Hosts file fixed! Minikube Tunnel is now starting...' -ForegroundColor Green
Start-Sleep -Seconds 2
