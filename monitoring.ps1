# Campus Complaint System - MONITORING INSTALL SCRIPT
# Run after deploy.ps1:  .\monitoring.ps1
# Installs Prometheus + Grafana via Helm into the monitoring namespace

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Campus Monitoring Stack - Prometheus + Grafana" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

# Step 1: Create monitoring namespace
Write-Host "[1/5] Creating monitoring namespace..." -ForegroundColor Yellow
kubectl apply -f "$ProjectRoot\k8s\monitoring\namespace.yaml"

# Step 2: Add Helm repo
Write-Host "[2/5] Adding Prometheus Community Helm repo..." -ForegroundColor Yellow
try {
    # Check connectivity to repo
    Test-Connection -ComputerName "prometheus-community.github.io" -Count 1 -ErrorAction Stop | Out-Null
    
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    Write-Host "  Helm repo ready." -ForegroundColor Green
} catch {
    Write-Host "  FAILED to reach Helm repo. Please check your internet connection." -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Install/Upgrade kube-prometheus-stack
Write-Host "[3/5] Installing/Updating kube-prometheus-stack (this takes 3-5 minutes)..." -ForegroundColor Yellow

# Use upgrade --install for idempotency. It won't fail if already installed.
# Increased timeout to 600s and added --atomic to handle slow cluster CRD installation
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
    -n monitoring `
    -f "$ProjectRoot\k8s\monitoring\prometheus-values.yaml" `
    --create-namespace `
    --atomic --wait --timeout=600s

if ($LASTEXITCODE -ne 0) {
    Write-Host "  Helm deployment failed." -ForegroundColor Red
    exit 1
}
Write-Host "  Prometheus + Grafana ready." -ForegroundColor Green

# Step 4: Apply Grafana dashboard ConfigMap
Write-Host "[4/5] Applying Grafana dashboard ConfigMap..." -ForegroundColor Yellow
kubectl apply -f "$ProjectRoot\k8s\monitoring\grafana-dashboard-configmap.yaml"
kubectl apply -f "$ProjectRoot\k8s\monitoring\servicemonitor.yaml"
Write-Host "  Dashboard and ServiceMonitor applied." -ForegroundColor Green

# Step 5: Print access info
Write-Host "[5/5] Getting monitoring access URLs..." -ForegroundColor Yellow

$MINIKUBE_IP = minikube ip

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  MONITORING INSTALLED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  GRAFANA" -ForegroundColor Cyan
Write-Host "  URL:      http://${MINIKUBE_IP}:32000" -ForegroundColor White
Write-Host "  Username: admin" -ForegroundColor White
Write-Host "  Password: campus-admin" -ForegroundColor White
Write-Host ""
Write-Host "  PROMETHEUS (port-forward required)" -ForegroundColor Cyan
Write-Host "  Run: kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring" -ForegroundColor White
Write-Host "  Then open: http://localhost:9090" -ForegroundColor White
Write-Host ""
Write-Host "  Monitoring Pods:" -ForegroundColor Yellow
kubectl get pods -n monitoring
Write-Host ""
Write-Host "  NOTE: Go to Grafana > Dashboards > Campus App > Campus Complaint System" -ForegroundColor DarkCyan
Write-Host "        Dashboard populates after traffic flows to the app." -ForegroundColor DarkCyan
Write-Host "============================================================" -ForegroundColor Green
