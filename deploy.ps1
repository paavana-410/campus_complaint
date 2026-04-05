# Campus Complaint System - DEPLOY SCRIPT
# Run from project root: .\deploy.ps1
# Requirements: Docker Desktop, Minikube, kubectl installed

param(
    [switch]$Clean
)

$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Campus Complaint System - Kubernetes Deployment" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Start Minikube
Write-Host "[1/7] Checking Minikube status..." -ForegroundColor Yellow
$minikubeStatus = minikube status --format='{{.Host}}' 2>&1
if ($minikubeStatus -notmatch "Running") {
    Write-Host "  Starting Minikube..." -ForegroundColor White
    minikube start --driver=docker --memory=2500 --cpus=2 --docker-opt dns=8.8.8.8 --docker-opt dns=8.8.4.4
} else {
    Write-Host "  Minikube already running." -ForegroundColor Green
}

# Step 2: Enable Nginx Ingress addon
Write-Host "[2/7] Enabling Nginx Ingress addon..." -ForegroundColor Yellow
minikube addons enable ingress
Start-Sleep -Seconds 5
Write-Host "  Ingress addon enabled." -ForegroundColor Green

# Step 3: Set Docker to use Minikube's Docker daemon
Write-Host "[3/7] Pointing Docker to Minikube daemon..." -ForegroundColor Yellow
& minikube -p minikube docker-env --shell powershell | Invoke-Expression
Write-Host "  Docker now builds inside Minikube." -ForegroundColor Green

# Step 4: Build Docker images
Write-Host "[4/7] Building Docker images inside Minikube..." -ForegroundColor Yellow

Write-Host "  Building campus-server:latest..." -ForegroundColor White
docker build -t campus-server:latest "$ProjectRoot\server"

Write-Host "  Building campus-client:latest..." -ForegroundColor White
docker build -t campus-client:latest "$ProjectRoot\client"

Write-Host "  Images built successfully." -ForegroundColor Green

# Step 5: Apply Kubernetes manifests
Write-Host "[5/7] Applying Kubernetes manifests..." -ForegroundColor Yellow

if ($Clean) {
    Write-Host "  -Clean flag: deleting existing resources..." -ForegroundColor DarkYellow
    kubectl delete -f "$ProjectRoot\k8s\" --ignore-not-found --recursive 2>&1 | Out-Null
    Start-Sleep -Seconds 5
}

kubectl apply -f "$ProjectRoot\k8s\secret.yaml"
kubectl apply -f "$ProjectRoot\k8s\server-deployment.yaml"
kubectl apply -f "$ProjectRoot\k8s\server-service.yaml"
kubectl apply -f "$ProjectRoot\k8s\client-deployment.yaml"
kubectl apply -f "$ProjectRoot\k8s\client-service.yaml"
kubectl apply -f "$ProjectRoot\k8s\ingress.yaml"

Write-Host "  All manifests applied." -ForegroundColor Green

# Step 6: Wait for pods to be ready
Write-Host "[6/7] Waiting for pods to be ready (up to 3 minutes)..." -ForegroundColor Yellow
kubectl rollout status deployment/server-deployment --timeout=180s
kubectl rollout status deployment/client-deployment --timeout=180s
Write-Host "  All pods are running." -ForegroundColor Green

# Step 7: Print access info
Write-Host "[7/7] Getting access information..." -ForegroundColor Yellow

$MINIKUBE_IP = minikube ip

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Minikube IP:   $MINIKUBE_IP" -ForegroundColor Cyan
Write-Host "  App URL:       http://campus.local" -ForegroundColor Cyan
Write-Host "  Direct URL:    http://$MINIKUBE_IP" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ACTION REQUIRED - Add this line to your hosts file:" -ForegroundColor Yellow
Write-Host "  File: C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Yellow
Write-Host "  (Open Notepad as Administrator to edit it)" -ForegroundColor Yellow
Write-Host ""
Write-Host "    $MINIKUBE_IP  campus.local" -ForegroundColor White
Write-Host ""
Write-Host "  After editing hosts file, open: http://campus.local" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Pod Status:" -ForegroundColor Yellow
kubectl get pods
Write-Host ""
Write-Host "  Services:" -ForegroundColor Yellow
kubectl get services
Write-Host ""
Write-Host "  Ingress:" -ForegroundColor Yellow
kubectl get ingress
Write-Host ""
Write-Host "  Run .\monitoring.ps1 to install Prometheus + Grafana" -ForegroundColor DarkCyan
Write-Host "============================================================" -ForegroundColor Green
