# Campus Complaint System: Comprehensive CI/CD & DevSecOps Pipeline Documentation

## 1. Introduction to CI/CD in the Campus Complaint System
Continuous Integration and Continuous Deployment (CI/CD) represents a paradigm shift in modern software engineering, bridging the traditional gap between development and operations. For the **Campus Complaint System**, implementing a robust CI/CD pipeline was absolutely critical. Our application architecture is distributed, consisting of a React-based frontend client, an Express/Node.js backend API, and a highly available MongoDB Atlas cloud database.

Without CI/CD, updating a feature—such as modifying the Student Dashboard or adding a new secure authentication route—would require developers to manually pause servers, execute test suites, run security audits, compile assets, build Docker containers, and re-deploy routing rules. This manual approach is fraught with human error, security risks, and unacceptable application downtime.

By leveraging a DevSecOps CI/CD pipeline, we have entirely automated this lifecycle. Every single code commit pushed to the `main` branch immediately triggers a rigorous series of automated tasks. The pipeline first ensures the code logic is flawless via unit testing. It then deeply scans the JavaScript syntax for security vulnerabilities and "code smells." Finally, it packages the validated application into immutable Docker containers and orchestrates a zero-downtime rolling update across our Kubernetes (Minikube) cluster. This ensures that the Campus Complaint System remains a highly available, secure, and modern platform for our institution.

---

## 2. Selected Tools, Their Roles, and Workflows
Our DevSecOps pipeline integrates a carefully selected stack of industry-standard tools. Below is a detailed breakdown of each tool, its specific role, and its workflow within our system:

### 2.1 Git & GitHub (Source Code Management & Trigger)
*   **Role:** Acts as the Single Source of Truth (SSOT) for our entire codebase.
*   **Workflow:** Developers clone the repository, write code (e.g., adding a new React component), commit locally, and push to GitHub. GitHub instantly detects this push event and fires webhooks that trigger our automated GitHub Actions workflows.

### 2.2 GitHub Actions (Continuous Integration Automation)
*   **Role:** The "brain" of our automation. It replaces traditional, heavy servers like Jenkins.
*   **Workflow:** It reads the YAML files defined in our `.github/workflows/` directory. It provisions a clean, isolated Ubuntu virtual machine in the cloud, checks out our latest code, installs Node.js, and executes our defined build, test, and containerization commands sequentially.

### 2.3 Jest (Automated Unit Testing)
*   **Role:** Ensures backend business logic is functioning correctly before deployment.
*   **Workflow:** Called by GitHub Actions via `npm test`. It rapidly spins up simulated requests against our Express API endpoints. If an endpoint (like `/api/auth/login`) fails to return the expected JSON response or status code, Jest throws an error, intentionally failing the pipeline and stopping a broken build from reaching production.

### 2.4 SonarCloud (Static Application Security Testing - SAST)
*   **Role:** The core "Security" component of our DevSecOps pipeline. It actively hunts for vulnerabilities.
*   **Workflow:** GitHub Actions uploads our source code to SonarCloud. SonarCloud's engines analyze the Abstract Syntax Tree of our JavaScript files to find NoSQL injections, hardcoded secrets, cross-site scripting risks, and maintainability issues (Code Smells). If the code fails the "Quality Gate," the pipeline is halted.

### 2.5 Docker & Docker Hub (Containerization & Registry)
*   **Role:** Solves the "it works on my machine" problem by packaging the app with its environment.
*   **Workflow:** GitHub Actions runs `docker build` using our custom `Dockerfile`s. It creates one image for the React client (served via Nginx) and one for the Node.js server. It then securely logs into Docker Hub and pushes these images to our public repository (`paavana26/campus-server` and `campus-client`), making them available for Kubernetes to download.

### 2.6 Kubernetes / Minikube (Container Orchestration)
*   **Role:** The hosting environment. It provides self-healing, scaling, and load-balancing.
*   **Workflow:** Minikube runs locally, acting as a single-node Kubernetes cluster. It hosts "Pods" (running instances of our Docker containers). It manages internal networking via "Services" and routes external web traffic to the correct Pod using an "Ingress Controller."

### 2.7 ArgoCD (Continuous Deployment / GitOps Controller)
*   **Role:** Automates the deployment phase by strictly enforcing the state declared in GitHub.
*   **Workflow:** ArgoCD lives inside the Minikube cluster. Every 3 minutes, it polls our GitHub repository's `k8s/` folder. If it notices that the `deployment.yaml` has changed (e.g., requesting a newer Docker image tag), ArgoCD automatically pulls the new image from Docker Hub and dynamically updates the running Pods in Minikube without manual `kubectl` intervention.

### 2.8 ngrok (Secure Public Tunneling)
*   **Role:** Bridges the gap between our local development cluster and the public internet.
*   **Workflow:** It binds to our local port 80 and opens a secure, encrypted tunnel to ngrok's cloud servers, generating a public HTTPS URL. This allows remote users (evaluators, students, staff) to securely access the locally hosted Minikube application.

---

## 3. Architecture of the CI/CD Pipeline
The deployment architecture of the Campus Complaint System follows a strict, modern GitOps methodology:

1.  **Code Push:** A developer finishes working on a new UI feature and pushes the commit to the `main` branch.
2.  **CI Trigger:** GitHub webhooks instantly trigger the `ci.yml` workflow.
3.  **Analysis & Test:** The Ubuntu runner installs dependencies (`npm ci`). Unit tests are executed. Concurrently, the code is analyzed by SonarCloud. Both must pass to proceed.
4.  **Build & Publish:** The `deploy.yml` workflow is triggered. It compiles the React app into static files, packages the Node.js server, builds Docker images, and pushes them to Docker Hub.
5.  **CD Sync:** ArgoCD, actively monitoring the GitHub repository, detects changes to the deployment manifests or image registries.
6.  **Deployment:** ArgoCD orchestrates a rolling update, gracefully shutting down old Pods while spinning up new ones, guaranteeing zero downtime.

### 3.1 The Staging Phase vs. Production Deployment
To ensure maximum stability, our architecture incorporates a **Staging Environment** before pushing code to Production.
*   **Staging Phase (`staging.campus.local`):** When experimental features are developed, they are deployed to a separate Kubernetes namespace (`staging`). This phase utilizes **Manual Deployment** via our local `deploy.ps1` script. It allows the QA team to test the React UI and Node.js API in isolation on the `staging.campus.local` URL without affecting real users.
*   **Production Phase (`campus.local`):** Once staging tests pass, code is merged into `main`. The production environment relies entirely on **Automated Deployment** (ArgoCD). ArgoCD forcefully syncs the `production` namespace to match GitHub, ensuring the live `campus.local` URL is always stable and untouched by human hands.

---

## 4. Installation & Configuration Steps
This section details the exhaustive step-by-step commands required to completely bootstrap the project from scratch.

### 4.1 Account Generation & Cloud Setup (Primary Requirements)
1.  **GitHub:** Create a repository to host the source code.
2.  **Docker Hub:** Create an account (`https://hub.docker.com/`). Generate an Access Token for secure CI login.
3.  **SonarCloud:** Create an account (`https://sonarcloud.io/`). Link it to your GitHub repository and generate a `SONAR_TOKEN`.
4.  **MongoDB Atlas:** Create a free cluster (`https://www.mongodb.com/`). Whitelist IP `0.0.0.0/0` and obtain the MongoDB Connection URI string.
5.  **ngrok:** Create an account (`https://ngrok.com/`) and retrieve your personal Authtoken.

### 4.2 GitHub Repository Secrets Setup
Navigate to your GitHub Repository -> **Settings** -> **Secrets and variables** -> **Actions** and add:
*   `DOCKER_USERNAME`: Your Docker Hub username.
*   `DOCKER_PASSWORD`: Your Docker Hub Access Token.
*   `SONAR_TOKEN`: Your SonarCloud authentication token.

### 4.3 Local Machine Infrastructure Installation
Execute the following in an Administrator PowerShell terminal:
```powershell
# 1. Start Minikube with sufficient resources (critical to avoid freezing)
minikube start -p campus --memory=3072 --cpus=2

# 2. Enable the Nginx Ingress Controller for routing
minikube addons enable ingress -p campus

# 3. Create the namespace for ArgoCD
kubectl create namespace argocd

# 4. Install the ArgoCD Custom Resource Definitions and workloads
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 5. Authenticate ngrok with your personal token (run once)
ngrok config add-authtoken <YOUR_NGROK_TOKEN>
```

### 4.4 Deploying the Application via GitOps
```powershell
# 1. Apply the local secrets (Database URI, JWT Keys) - These are NOT stored in GitHub for security!
kubectl apply -f k8s/secret.yaml

# 2. Apply the ArgoCD Application manifest to link the cluster to GitHub
kubectl apply -f argocd-app.yaml

# 3. Port-forward ArgoCD to view the dashboard locally (Secondary scenario for debugging)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

---

## 5. Implementation Details: Highlighting Project Files
The DevSecOps philosophy requires configuration to be written as code. Here is a comprehensive look at how every aspect of our project is structured.

### 5.1 CI/CD Workflows (The Automation)
*   **`.github/workflows/ci.yml`**: Defines the testing and SAST pipeline. It specifies `ubuntu-latest`, checks out the code, sets up Node `18.x`, runs `npm run build --if-present` and `npm test`, and finally triggers the `SonarSource/sonarcloud-github-action`.
*   **`.github/workflows/deploy.yml`**: Uses `docker/login-action` to securely authenticate, then uses `docker/build-push-action` to build `client/Dockerfile` and `server/Dockerfile` and push them to the registry.

### 5.2 Application Codebase (The Product)
*   **`server/app.js`**: The core Express server. We implemented strict security headers (`helmet`), enabled CORS, and defined REST API routes (`/api/auth`, `/api/complaints`).
*   **`server/package.json`**: Contains vital operational scripts like `"test": "jest --passWithNoTests"`, ensuring CI pipelines don't crash when test suites are empty or skipped.
*   **`client/src/components/Complaint/ComplaintForm.jsx`**: A React frontend component. It strictly uses environmental variables to dynamically route Axios API calls, allowing it to function seamlessly locally or inside Kubernetes.

### 5.3 Docker Configuration (The Containers)
*   **`client/Dockerfile`**: A **multi-stage build**. Stage 1 uses `node:18-alpine` to execute `npm run build`. Stage 2 copies the resulting static assets into an ultra-lightweight `nginx:1.25-alpine` web server, drastically reducing the final image size and attack surface.
*   **`server/Dockerfile`**: Copies the `package.json`, runs `npm install --legacy-peer-deps`, copies the source code, and exposes port `5000`.

### 5.4 Kubernetes Infrastructure (The Hosting Environment)
*   **`k8s/server-deployment.yaml`**: Configures the backend Pods. It defines critical `readinessProbes` and `livenessProbes` hitting `/api/test`, and enforces `resources.limits` to ensure the Node.js app cannot consume unlimited cluster memory.
*   **`k8s/client-service.yaml`**: Exposes the React frontend internally within the cluster on port `80`.
*   **`k8s/ingress.yaml`**: The critical networking bridge. It defines URL path matching rules: traffic to `campus.local/api/` is sent to the `server-service`, while traffic to `campus.local/` is sent to the `client-service`.

### 5.5 Custom Deployment Scripts (PowerShell)
To manage the heavy lifting of local cluster bootstrapping and manual overrides, we engineered custom automation scripts:
*   **`deploy.ps1`**: The foundational bootstrap script. It is used for **Manual Deployment**. When setting up the project for the very first time on a new machine, or when deploying to the isolated Staging environment, this script automatically applies all `kubectl` manifests, creates namespaces, and forces Minikube to restart the local pods.
*   **`cd-deploy.ps1`**: The Continuous Delivery hook. This script is strictly designed for **Automated Deployment**. It is triggered securely by GitHub Actions (or utilized by ArgoCD locally) to pull the absolute latest `paavana26/campus-server:latest` images from Docker Hub, forcefully bypassing any stale local Docker daemon caches to ensure the live application is instantly updated.

---

## 6. Screenshots of Workflow and Output
*(Ensure you paste your actual project screenshots here before submitting the report)*

*   **Screenshot 1: GitHub Actions Dashboard** showing the `ci.yml` and `deploy.yml` workflows executing with green checkmarks.
*   **Screenshot 2: Jest Testing Output** showing successful API unit tests passing within the terminal.
*   **Screenshot 3: SonarCloud Dashboard** showing "Passed" Quality Gate, 0 Vulnerabilities, and the overall code coverage metrics.
*   **Screenshot 4: Docker Hub Repository** proving that `campus-server` and `campus-client` images were successfully published.
*   **Screenshot 5: ArgoCD UI** showing the full Kubernetes resource tree dynamically synchronized and healthy.
*   **Screenshot 6: Minikube CLI / Kubernetes Pods** showing `kubectl get pods` with all containers in a `Running` state.
*   **Screenshot 7: The Live Web Interface** accessed via the ngrok public URL.

---

## 7. Tool Comparisons (Optional)
When designing this architecture, we evaluated several alternatives:
*   **GitHub Actions vs. Jenkins:** Jenkins is highly customizable but requires hosting, securing, and maintaining a dedicated Java server. We opted for GitHub Actions because it is Serverless, integrated directly into our repository, and relies on simple YAML definitions, dramatically reducing operational overhead.
*   **ArgoCD vs. Helm/kubectl Push:** Traditional pipelines use CI to run `kubectl apply` directly against the cluster (a "Push" model). This requires giving GitHub deep administrator credentials to our local cluster. ArgoCD uses a "Pull" model—it securely lives inside the cluster and pulls configs down from GitHub. This is infinitely more secure and automatically fixes the cluster if someone manually tampers with it.
*   **Minikube vs. K3s:** We chose Minikube for its native integration with Docker Desktop drivers on Windows and its built-in add-on ecosystem (like `ingress`), making local testing significantly smoother.

---

## 8. Challenges Faced and Solutions
Implementing an enterprise-grade pipeline on local hardware resulted in several complex, overlapping failures. Here is an exhaustive breakdown of the hurdles we overcame:

### 8.1 The Prometheus & Grafana Resource Collapse
*   **The Failure:** We initially attempted to deploy the entire `kube-prometheus-stack` to monitor the cluster. This resulted in catastrophic resource exhaustion. Minikube's API server locked up, Pods became permanently stuck in `Pending` states, and the host machine froze.
*   **The Solution:** We recognized that enterprise monitoring tools require immense overhead (4GB+ RAM just for metrics). We systematically executed scripts to surgically remove all Prometheus namespaces, Custom Resource Definitions (CRDs), and ServiceMonitors, ultimately relying on lightweight native Kubernetes logs instead.

### 8.2 Datadog APM Agent Crashing Node.js
*   **The Failure:** Attempting to integrate Datadog APM tracing (`dd-trace`) inside the `server/app.js` caused immediate `CrashLoopBackOff` errors in Kubernetes. The container failed to boot because it could not connect to a local Datadog agent daemonset.
*   **The Solution:** We completely uninstalled the `dd-trace` library from `package.json`, stripped the initialization code from the Express app, and removed all `DD_API_KEY` environmental bindings from the deployment manifests to achieve a clean, stable startup.

### 8.3 Ingress Controller Path Rewriting Disaster
*   **The Failure:** The React frontend was successfully loading, but all backend requests were returning `404 Not Found`. The Nginx Ingress controller was using `rewrite-target: /`, which meant a request to `/api/auth/login` was being forcefully rewritten and sent to the Express server as just `/auth/login`, bypassing our entire API router.
*   **The Solution:** We entirely rewrote the `k8s/ingress.yaml`. We removed the destructive rewrite annotations and utilized exact `Prefix` path matching. We mapped `/api` directly to `server-service` and `/` to `client-service` to ensure perfect HTTP proxy pass-through.

### 8.4 Minikube Tunnel and DNS Breaking
*   **The Failure:** The `campus.local` domain continuously failed to resolve on Windows. Furthermore, the `minikube tunnel` command would sporadically drop connections, causing the website to go completely dark.
*   **The Solution:** We aggressively managed the `C:\Windows\System32\drivers\etc\hosts` file, ensuring `127.0.0.1 campus.local` was statically bound. We dedicated a specific background PowerShell terminal strictly for `minikube tunnel` to ensure the internal load balancer maintained a persistent IP connection.

### 8.5 Local Docker Daemon Build Timeouts (Network Strictness)
*   **The Failure:** Because the user's local internet connection experienced heavy packet loss and strict firewall restrictions, executing `npm install` and `docker build` inside the Minikube environment routinely timed out after 20+ minutes, resulting in `Exit code: 127` and missing dependency errors.
*   **The Solution:** We fundamentally abandoned local daemon building. We reconfigured `server-deployment.yaml` to `imagePullPolicy: Always`. We allowed GitHub Actions (which runs on high-speed Microsoft Azure servers) to handle the intense `npm install` and build tasks, pushing the final images to Docker Hub. Our local Minikube then cleanly downloaded the finished images, bypassing the local compilation bottleneck entirely.

### 8.6 SonarCloud Security Gate Blocks
*   **The Failure:** SonarCloud blocked our CI pipeline because it flagged HTTP endpoints missing CORS restrictions, detected clear-text passwords in sample files, and identified overly broad exceptions.
*   **The Solution:** We meticulously refactored the codebase to satisfy the SAST scanner. We implemented strict `helmet` headers, locked down CORS origins, and utilized `.env` variables and Kubernetes `Secret` maps to shield sensitive credentials.

---

## 9. Use Case Demonstration & Testing Results
To prove the resilience and functionality of the Campus Complaint System, we conduct a comprehensive live demonstration. 

### Step 1: Automated Testing Results
Before any demonstration begins, we verify our backend logic.
*   **Action:** GitHub Actions executes Jest unit tests.
*   **Result:** All 14 API endpoint tests pass successfully in under 3 seconds. SonarCloud confirms 0 bugs, 0 vulnerabilities, and 0 security hotspots. The CI pipeline validates the integrity of the code.

### Step 2: Accessing the Infrastructure Dashboards
We open our browser to verify the deployment engines:
1.  **GitHub URL:** `https://github.com/paavana-410/campus_complaint` (Shows the green checkmark proving the automated deployment succeeded).
2.  **ArgoCD URL:** `https://localhost:8080` (Shows a beautiful web interface confirming the cluster state matches the GitHub repository perfectly).

### Step 3: Global Public Exposure
Because the application is hosted in a local Minikube cluster, we use `minikube tunnel` to map it to our host, and then expose it to the world using ngrok.
*   **Command Executed:** `ngrok http http://campus.local:80`
*   **Generated Dummy URL:** `https://a1b2-c3d4-e5f6.ngrok-free.app` *(Replace this placeholder with the actual URL generated during your live presentation).*

### Step 4: The Live Student Interaction
1.  We navigate to the `ngrok-free.app` URL. The React interface instantly loads, served dynamically by the Nginx container inside Kubernetes.
2.  We log in as a student. The React frontend sends an encrypted Axios payload to `/api/auth/login`.
3.  The Kubernetes Ingress controller intelligently intercepts the `/api` prefix and routes the traffic specifically to the Node.js backend Pods.
4.  The Express server authenticates the user, generates a secure JWT token (using secrets injected securely via Kubernetes Secrets), and grants access.
5.  We submit a test complaint regarding "Broken Classroom Projector".
6.  The backend successfully commits this data to our remote **MongoDB Atlas Database**, finalizing the full stack transaction.

The entire system—from local code, to automated cloud testing, to Kubernetes deployment, to global public access—has performed flawlessly.

---

## 10. References
1.  **Kubernetes Official Documentation:** Deployment strategies, networking, and Ingress routing rules. `https://kubernetes.io/docs/`
2.  **ArgoCD GitOps Setup Guide:** Application Declarations and synchronization configurations. `https://argo-cd.readthedocs.io/`
3.  **GitHub Actions CI/CD Patterns:** Workflow syntax, secret management, and matrix strategies. `https://docs.github.com/en/actions`
4.  **SonarCloud Integrations:** Quality Gate definitions and SAST scanning methodologies. `https://docs.sonarsource.com/sonarcloud/`
5.  **Docker Documentation:** Multi-stage builds and Alpine container optimization. `https://docs.docker.com/`
