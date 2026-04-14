# ============================================================
#  fix-hosts.ps1  — Add/update campus.local hosts entries
#  Run as Administrator
# ============================================================
$hostsPath = 'C:\Windows\System32\drivers\etc\hosts'

# IMPORTANT: On Windows with Docker driver, minikube tunnel binds to 127.0.0.1
$targetIp = '127.0.0.1'

Write-Host "Target Tunnel IP: $targetIp" -ForegroundColor Cyan

$content = Get-Content $hostsPath -Raw

# ── Production: campus.local ──────────────────────────────────
if ($content -match 'campus\.local') {
    $content = $content -replace '\d+\.\d+\.\d+\.\d+\s+campus\.local', "$targetIp  campus.local"
    Write-Host "✅ Updated campus.local → $targetIp" -ForegroundColor Green
} else {
    $content += "`n$targetIp  campus.local"
    Write-Host "✅ Added campus.local → $targetIp" -ForegroundColor Green
}

# ── Staging: staging.campus.local ────────────────────────────
if ($content -match 'staging\.campus\.local') {
    $content = $content -replace '\d+\.\d+\.\d+\.\d+\s+staging\.campus\.local', "$targetIp  staging.campus.local"
    Write-Host "✅ Updated staging.campus.local → $targetIp" -ForegroundColor Green
} else {
    $content += "`n$targetIp  staging.campus.local"
    Write-Host "✅ Added staging.campus.local → $targetIp" -ForegroundColor Green
}

Set-Content -Path $hostsPath -Value $content -NoNewline
Write-Host ""
Write-Host "Hosts file updated! URLs available:" -ForegroundColor Green
Write-Host "  Production : http://campus.local" -ForegroundColor Cyan
Write-Host "  Staging    : http://staging.campus.local" -ForegroundColor DarkYellow
Write-Host ""
Write-Host "Make sure 'minikube tunnel' is running in another terminal." -ForegroundColor Yellow
