# Campus Complaint System — DevOps Deployment Walkthrough

## What Was Built

A complete DevOps deployment stack on **Minikube** with:

| Component | Technology | Access |
|-----------|-----------|--------|
| Frontend | React → Nginx (multi-stage Docker) | `http://campus.local` |
| Backend | Express.js + Node.js | Via Ingress `/api/` |
| Database | MongoDB Atlas (unchanged) | Atlas cloud |
| Ingress | Nginx Ingress Controller | Minikube IP:80 |
| Metrics | Prometheus (`prom-client`) | `/metrics` endpoint |
| Monitoring | Prometheus + Grafana (Helm) | `http://<MINIKUBE_IP>:32000` |
| Deployment | Kubernetes (Minikube) | kubectl |

---

## Files Created / Modified

### Modified (no logic changes)
| File | Change |
|------|--------|
| [server/app.js](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/server/app.js) | Added `prom-client` metrics endpoint at `/metrics` |
| [server/package.json](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/server/package.json) | Added `prom-client: ^15.1.0` dependency |
| [server/Dockerfile](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/server/Dockerfile) | Production mode: `--production` install, no .env |
| [client/Dockerfile](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/client/Dockerfile) | **Multi-stage**: React build → Nginx serve |
| [docker-compose.yml](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/docker-compose.yml) | Health checks, shared network, client on port 80 |
| [k8s/server-deployment.yaml](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/k8s/server-deployment.yaml) | Added probes, resources, Prometheus annotations |
| [k8s/server-service.yaml](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/k8s/server-service.yaml) | Changed to ClusterIP |
| [k8s/client-deployment.yaml](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/k8s/client-deployment.yaml) | Port 80 (Nginx), added probes/resources |
| [k8s/client-service.yaml](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/k8s/client-service.yaml) | Changed to ClusterIP, port 80 |

### New Files
| File | Purpose |
|------|---------|
| [client/nginx.conf](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/client/nginx.conf) | Nginx SPA routing + API proxy to server-service |
| [server/.dockerignore](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/server/.dockerignore) | Excludes node_modules, .env |
| [client/.dockerignore](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/client/.dockerignore) | Excludes node_modules, build/ |
| [k8s/ingress.yaml](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/k8s/ingress.yaml) | Nginx Ingress: routes `campus.local` to client |
| [k8s/monitoring/namespace.yaml](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/k8s/monitoring/namespace.yaml) | `monitoring` namespace |
| [k8s/monitoring/servicemonitor.yaml](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/k8s/monitoring/servicemonitor.yaml) | Prometheus scrape config for server |
| [k8s/monitoring/prometheus-values.yaml](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/k8s/monitoring/prometheus-values.yaml) | Helm values for kube-prometheus-stack |
| [k8s/monitoring/grafana-dashboard-configmap.yaml](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/k8s/monitoring/grafana-dashboard-configmap.yaml) | Pre-built Grafana dashboard (6 panels) |
| [deploy.ps1](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/deploy.ps1) | One-click full deployment script |
| [monitoring.ps1](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/monitoring.ps1) | Prometheus + Grafana install via Helm |
| [teardown.ps1](file:///c:/Users/MyPC/OneDrive/Documents/Campus_Complaint_System-main%20-%20Copy/teardown.ps1) | Clean up all resources |

---

## How to Deploy (Step by Step)

### Prerequisites
- Docker Desktop running ✅
- Minikube installed ✅
- kubectl installed ✅
- Helm installed ✅

### Step 1 — Run the deploy script

Open **PowerShell as Administrator** in the project root:

```powershell
cd "C:\Users\MyPC\OneDrive\Documents\Campus_Complaint_System-main - Copy"
.\deploy.ps1
```

This will:
1. Start Minikube (if not running)
2. Enable Nginx Ingress addon
3. Switch Docker to Minikube's daemon
4. Build `campus-server:latest` and `campus-client:latest`
5. Apply all k8s manifests
6. Wait for pods to be ready
7. Print the Minikube IP

### Step 2 — Add hosts file entry

The script prints something like:
```
192.168.49.2  campus.local
```

Open **Notepad as Administrator** → Open [C:\Windows\System32\drivers\etc\hosts](file:///Windows/System32/drivers/etc/hosts) → Add that line → Save.

### Step 3 — Access the application

Open browser: **http://campus.local**

- **Student login**: Register, submit complaints
- **Admin login**: `admin@msrit.edu` / `admin123`
- **Staff login**: Staff credentials

### Step 4 — Install Prometheus + Grafana

```powershell
.\monitoring.ps1
```

This installs `kube-prometheus-stack` via Helm and loads the pre-built dashboard.

---

## Access URLs Summary

| Service | URL | Credentials |
|---------|-----|-------------|
| **App** | `http://campus.local` | See above |
| **App (direct IP)** | `http://<MINIKUBE_IP>` | — |
| **Grafana** | `http://<MINIKUBE_IP>:32000` | admin / campus-admin |
| **Prometheus** | port-forward 9090 (see below) | — |

```powershell
# To access Prometheus UI:
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
# Then open: http://localhost:9090
```

---

## Grafana Dashboard

**Location**: Dashboards → Campus App → "Campus Complaint System"

**Panels included:**
- Total HTTP Requests (5-min window)
- HTTP Request Rate by route
- HTTP Response Time (p95 percentile)
- Error Rate (5xx)
- Node.js Heap Memory Used vs Total
- Active Handles & Event Loop Lag

---

## Verification Commands

```powershell
# Check all pods are Running
kubectl get pods

# Check ingress has an IP
kubectl get ingress

# Check server health directly
kubectl exec -it $(kubectl get pod -l app=server -o name | head -1) -- wget -qO- http://localhost:5000/api/test

# Check metrics endpoint
kubectl exec -it $(kubectl get pod -l app=server -o name | head -1) -- wget -qO- http://localhost:5000/metrics | head -20

# Check via browser/curl
curl http://campus.local/api/test
```

---

## Teardown

```powershell
# Remove everything (keep Minikube running)
.\teardown.ps1

# Remove everything AND stop Minikube
.\teardown.ps1 -StopMinikube
```
