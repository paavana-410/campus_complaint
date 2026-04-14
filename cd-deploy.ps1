# ============================================================
#  Campus Complaint System - LOCAL CD SCRIPT
#  Continuous Deployment: Pull latest images → Rolling update
# ============================================================
#
#  WHEN TO RUN THIS:
#    After GitHub Actions (deploy.yml) pushes new images to
#    Docker Hub, run this script to deploy them to Minikube.
#
#  USAGE:
#    .\cd-deploy.ps1
#    .\cd-deploy.ps1 -DockerUser yourDockerHubUsername
#
#  REQUIREMENTS:
#    - Minikube running  (minikube start)
#    - kubectl configured
#    - minikube tunnel running in a separate terminal
# ============================================================

param(
    [string]$DockerUser = "paavana26"   # ← Your Docker Hub username
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── Banner ────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "   Campus Complaint System  —  CD Rolling Update" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

# ── Step 1: Verify Minikube is running ───────────────────────
Write-Host "[1/5] Checking Minikube status..." -ForegroundColor Yellow
$minikubeStatus = minikube status --format='{{.Host}}' 2>&1
if ($minikubeStatus -notmatch "Running") {
    Write-Host "  Minikube is NOT running. Starting it..." -ForegroundColor Red
    minikube start --driver=docker --memory=2500 --cpus=2
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Could not start Minikube. Exiting." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  ✅ Minikube is running." -ForegroundColor Green
}

# ── Step 2: Pull latest images from Docker Hub ───────────────
Write-Host ""
Write-Host "[2/5] Pulling latest images from Docker Hub..." -ForegroundColor Yellow
Write-Host "  → $DockerUser/campus-server:latest" -ForegroundColor White
Write-Host "  → $DockerUser/campus-client:latest" -ForegroundColor White

# We need to pull inside Minikube's Docker daemon so that k8s can use them
$dockerEnvOut = minikube -p minikube docker-env --shell powershell 2>&1
$dockerEnvOut | Invoke-Expression

docker pull "$DockerUser/campus-server:latest"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to pull campus-server image." -ForegroundColor Red
    exit 1
}

docker pull "$DockerUser/campus-client:latest"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to pull campus-client image." -ForegroundColor Red
    exit 1
}

Write-Host "  ✅ Images pulled successfully." -ForegroundColor Green

# ── Step 3: Apply latest K8s manifests (in case they changed) ─
Write-Host ""
Write-Host "[3/5] Applying Kubernetes manifests..." -ForegroundColor Yellow
kubectl apply -f "$ProjectRoot\k8s\secret.yaml"
kubectl apply -f "$ProjectRoot\k8s\server-deployment.yaml"
kubectl apply -f "$ProjectRoot\k8s\server-service.yaml"
kubectl apply -f "$ProjectRoot\k8s\client-deployment.yaml"
kubectl apply -f "$ProjectRoot\k8s\client-service.yaml"
kubectl apply -f "$ProjectRoot\k8s\ingress.yaml"
Write-Host "  ✅ Manifests applied." -ForegroundColor Green

# ── Step 4: Force rolling restart to pick up new images ──────
Write-Host ""
Write-Host "[4/5] Triggering rolling restart of deployments..." -ForegroundColor Yellow
kubectl rollout restart deployment/server-deployment
kubectl rollout restart deployment/client-deployment

Write-Host "  Waiting for server rollout..." -ForegroundColor White
kubectl rollout status deployment/server-deployment --timeout=180s
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Server deployment rollout failed. Check logs:" -ForegroundColor Red
    Write-Host "    kubectl logs -l app=server --tail=50" -ForegroundColor DarkRed
    exit 1
}

Write-Host "  Waiting for client rollout..." -ForegroundColor White
kubectl rollout status deployment/client-deployment --timeout=180s
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Client deployment rollout failed. Check logs:" -ForegroundColor Red
    Write-Host "    kubectl logs -l app=client --tail=50" -ForegroundColor DarkRed
    exit 1
}

Write-Host "  ✅ Rolling update complete — new pods are live." -ForegroundColor Green

# ── Step 5: Summary ──────────────────────────────────────────
Write-Host ""
$MINIKUBE_IP = minikube ip

Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ✅  DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Images deployed:" -ForegroundColor Cyan
Write-Host "    $DockerUser/campus-server:latest" -ForegroundColor White
Write-Host "    $DockerUser/campus-client:latest" -ForegroundColor White
Write-Host ""
Write-Host "  Minikube IP : $MINIKUBE_IP" -ForegroundColor Cyan
Write-Host "  App URL     : http://campus.local" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ⚡ If minikube tunnel is not running, open a new" -ForegroundColor Yellow
Write-Host "     terminal and run:  minikube tunnel" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Pod Status:" -ForegroundColor Yellow
kubectl get pods -o wide
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
