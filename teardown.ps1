# Campus Complaint System - TEARDOWN SCRIPT
# Removes all Kubernetes resources and optionally stops Minikube
# Run:  .\teardown.ps1

param(
    [switch]$StopMinikube
)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Red
Write-Host "  Campus Complaint System - Teardown" -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Removing monitoring stack..." -ForegroundColor Yellow
helm uninstall prometheus -n monitoring 2>&1 | Out-Null
kubectl delete -f "$ProjectRoot\k8s\monitoring\" --ignore-not-found 2>&1 | Out-Null

Write-Host "Removing app manifests..." -ForegroundColor Yellow
kubectl delete -f "$ProjectRoot\k8s\ingress.yaml" --ignore-not-found 2>&1 | Out-Null
kubectl delete -f "$ProjectRoot\k8s\client-deployment.yaml" --ignore-not-found 2>&1 | Out-Null
kubectl delete -f "$ProjectRoot\k8s\client-service.yaml" --ignore-not-found 2>&1 | Out-Null
kubectl delete -f "$ProjectRoot\k8s\server-deployment.yaml" --ignore-not-found 2>&1 | Out-Null
kubectl delete -f "$ProjectRoot\k8s\server-service.yaml" --ignore-not-found 2>&1 | Out-Null
kubectl delete -f "$ProjectRoot\k8s\secret.yaml" --ignore-not-found 2>&1 | Out-Null

if ($StopMinikube) {
    Write-Host "Stopping Minikube..." -ForegroundColor Yellow
    minikube stop
    Write-Host "Minikube stopped." -ForegroundColor Green
}

Write-Host ""
Write-Host "  Teardown complete." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
