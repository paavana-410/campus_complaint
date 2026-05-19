$ErrorActionPreference = "Stop"
Write-Host "1. Deleting old Minikube cluster completely..."
minikube delete --all --purge

Write-Host "2. Starting fresh Minikube with 4 CPUs and 3400MB RAM..."
minikube start --driver=docker --cpus=4 --memory=3400

Write-Host "3. Enabling Ingress addon..."
minikube addons enable ingress

Write-Host "3.5 Building Docker images inside Minikube..."
minikube image build -t docker.io/paavana26/campus-server:latest ./server
minikube image build -t docker.io/paavana26/campus-client:latest ./client

Write-Host "4. Applying Secrets..."
kubectl apply -f k8s/secret.yaml

Write-Host "5. Installing ArgoCD (this might take a moment)..."
kubectl create namespace argocd
kubectl apply -n argocd --server-side=true -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host "6. Waiting for ArgoCD server to be created before applying the App..."
Start-Sleep -Seconds 15

Write-Host "7. Registering the Campus Complaint App in ArgoCD..."
kubectl apply -f argocd-app.yaml

Write-Host "=========================================="
Write-Host "FRESH START COMPLETE! CLUSTER IS READY!"
Write-Host "=========================================="
