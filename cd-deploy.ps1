# ============================================================
#  Campus Complaint System - LOCAL CD SCRIPT  (with Staging)
#  Supports:  staging namespace  and  production namespace
# ============================================================
#
#  USAGE:
#    .\cd-deploy.ps1                          # -> production
#    .\cd-deploy.ps1 -Namespace staging       # -> staging
#    .\cd-deploy.ps1 -Namespace production    # -> production
#    .\cd-deploy.ps1 -DockerUser yourname     # custom Docker Hub user
#
#  STAGES:
#    staging    -> http://staging.campus.local   (test here first)
#    production -> http://campus.local           (live)
# ============================================================

param(
    [string]$DockerUser = 'paavana26',
    [ValidateSet('staging','production')]
    [string]$Namespace  = 'production'
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Namespace-specific settings
if ($Namespace -eq 'staging') {
    $AppUrl    = 'http://staging.campus.local'
    $BgColor   = 'DarkYellow'
    $EnvLabel  = 'STAGING'
} else {
    $AppUrl    = 'http://campus.local'
    $BgColor   = 'Green'
    $EnvLabel  = 'PRODUCTION'
}

# -- Banner ----------------------------------------------------
Write-Host ''
Write-Host '============================================================' -ForegroundColor $BgColor
Write-Host "   Campus Complaint System  ---  CD Deploy  [$EnvLabel]" -ForegroundColor $BgColor
Write-Host "   Namespace: $Namespace" -ForegroundColor $BgColor
Write-Host '============================================================' -ForegroundColor $BgColor
Write-Host ''

# -- Step 1: Verify Minikube is running -----------------------
Write-Host '[1/6] Checking Minikube status...' -ForegroundColor Yellow
$ErrorActionPreference = 'Continue'
$minikubeStatus = minikube status --format='{{.Host}}' 2>&1
$ErrorActionPreference = 'Stop'
if ($minikubeStatus -notmatch 'Running') {
    Write-Host '  Minikube is NOT running. Starting it...' -ForegroundColor Red
    minikube start --memory=2500 --cpus=2
    if ($LASTEXITCODE -ne 0) { Write-Host '  ERROR: Could not start Minikube.' -ForegroundColor Red; exit 1 }
} else {
    Write-Host '  Minikube is running.' -ForegroundColor Green
}

# -- Step 2: Ensure namespace exists --------------------------
Write-Host ''
Write-Host "[2/6] Ensuring namespace '$Namespace' exists..." -ForegroundColor Yellow
$nsExists = kubectl get namespace $Namespace 2>&1
if ($LASTEXITCODE -ne 0) {
    kubectl create namespace $Namespace
    Write-Host "  Namespace '$Namespace' created." -ForegroundColor Green
} else {
    Write-Host "  Namespace '$Namespace' already exists." -ForegroundColor Green
}

# -- Step 3: Pull latest images from Docker Hub ---------------
Write-Host ''
Write-Host '[3/6] Pulling latest images from Docker Hub into Minikube...' -ForegroundColor Yellow
Write-Host "  -> $DockerUser/campus-server:latest" -ForegroundColor White
Write-Host "  -> $DockerUser/campus-client:latest" -ForegroundColor White

# Pull into Minikube's docker daemon
$dockerEnvOut = minikube -p minikube docker-env --shell powershell 2>&1
$dockerEnvOut | Invoke-Expression

docker pull "$DockerUser/campus-server:latest"
if ($LASTEXITCODE -ne 0) { Write-Host '  ERROR: Failed to pull campus-server.' -ForegroundColor Red; exit 1 }

docker pull "$DockerUser/campus-client:latest"
if ($LASTEXITCODE -ne 0) { Write-Host '  ERROR: Failed to pull campus-client.' -ForegroundColor Red; exit 1 }

Write-Host '  Images pulled.' -ForegroundColor Green

# -- Step 4: Apply K8s manifests to the namespace -------------
Write-Host ''
Write-Host "[4/6] Applying Kubernetes manifests to namespace '$Namespace'..." -ForegroundColor Yellow
kubectl apply -f "$ProjectRoot\k8s\secret.yaml"          -n $Namespace
kubectl apply -f "$ProjectRoot\k8s\server-deployment.yaml" -n $Namespace
kubectl apply -f "$ProjectRoot\k8s\server-service.yaml"    -n $Namespace
kubectl apply -f "$ProjectRoot\k8s\client-deployment.yaml" -n $Namespace
kubectl apply -f "$ProjectRoot\k8s\client-service.yaml"    -n $Namespace

# Apply namespace-specific ingress
if ($Namespace -eq 'staging') {
    kubectl apply -f "$ProjectRoot\k8s\ingress-staging.yaml" -n $Namespace
} else {
    kubectl apply -f "$ProjectRoot\k8s\ingress.yaml" -n $Namespace
}
Write-Host '  Manifests applied.' -ForegroundColor Green

# -- Step 5: Rolling restart -----------------------------------
Write-Host ''
Write-Host "[5/6] Triggering rolling restart in '$Namespace'..." -ForegroundColor Yellow
kubectl rollout restart deployment/server-deployment -n $Namespace
kubectl rollout restart deployment/client-deployment -n $Namespace

Write-Host '  Waiting for server rollout...' -ForegroundColor White
kubectl rollout status deployment/server-deployment -n $Namespace --timeout=180s
if ($LASTEXITCODE -ne 0) {
    Write-Host '  ERROR: Server rollout failed.' -ForegroundColor Red
    Write-Host "    kubectl logs -l app=server -n $Namespace --tail=50" -ForegroundColor DarkRed
    exit 1
}

Write-Host '  Waiting for client rollout...' -ForegroundColor White
kubectl rollout status deployment/client-deployment -n $Namespace --timeout=180s
if ($LASTEXITCODE -ne 0) {
    Write-Host '  ERROR: Client rollout failed.' -ForegroundColor Red
    Write-Host "    kubectl logs -l app=client -n $Namespace --tail=50" -ForegroundColor DarkRed
    exit 1
}
Write-Host '  Rolling update complete --- new pods are live.' -ForegroundColor Green

# -- Step 6: Summary ------------------------------------------
Write-Host ''
$MINIKUBE_IP = minikube ip

Write-Host '============================================================' -ForegroundColor $BgColor
Write-Host "  DEPLOYED TO $($Namespace.ToUpper()) SUCCESSFULLY!" -ForegroundColor $BgColor
Write-Host '============================================================' -ForegroundColor $BgColor
Write-Host ''
Write-Host '  Images deployed:' -ForegroundColor Cyan
Write-Host "    $DockerUser/campus-server:latest" -ForegroundColor White
Write-Host "    $DockerUser/campus-client:latest" -ForegroundColor White
Write-Host ''
Write-Host "  Namespace   : $Namespace" -ForegroundColor Cyan
Write-Host "  Minikube IP : $MINIKUBE_IP" -ForegroundColor Cyan
Write-Host "  App URL     : $AppUrl" -ForegroundColor Cyan
Write-Host ''

if ($Namespace -eq 'staging') {
    Write-Host "  TEST YOUR CHANGES AT: $AppUrl" -ForegroundColor DarkYellow
    Write-Host '  Then promote to production with:' -ForegroundColor Yellow
    Write-Host '    .\cd-deploy.ps1 -Namespace production' -ForegroundColor White
} else {
    Write-Host '  If minikube tunnel is not running, open a new' -ForegroundColor Yellow
    Write-Host '     terminal and run:  minikube tunnel' -ForegroundColor Yellow
}

Write-Host ''
Write-Host "  Pod Status (namespace: $Namespace):" -ForegroundColor Yellow
kubectl get pods -n $Namespace -o wide
Write-Host ''
Write-Host '============================================================' -ForegroundColor $BgColor
