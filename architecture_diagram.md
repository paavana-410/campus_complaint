# Campus Complaint System Architecture

```mermaid
graph TD
    %% Define external actors
    User[Student/Staff User] -->|HTTPS| ngrok
    Developer[Developer] -->|Push Code| GitHub

    %% CI/CD Flow
    subgraph "CI/CD Pipeline (GitHub & ArgoCD)"
        GitHub[GitHub Repository]
        GitHubActions[GitHub Actions]
        SonarCloud[SonarCloud Security Gate]
        DockerHub[Docker Hub Registry]
        ArgoCD[ArgoCD GitOps Controller]

        GitHub -->|.github/workflows| GitHubActions
        GitHubActions -->|SAST Scan| SonarCloud
        GitHubActions -->|Build & Push| DockerHub
        ArgoCD -->|Watch manifests| GitHub
        ArgoCD -->|Pull latest images| DockerHub
    end

    %% Kubernetes Cluster (Minikube)
    subgraph "Local Kubernetes Cluster (Minikube)"
        ngrok[ngrok Public Tunnel] -->|Proxy| Ingress[Nginx Ingress Controller]
        Ingress -->|/api| ServerSvc[Server Service :5000]
        Ingress -->|/| ClientSvc[Client Service :80]

        subgraph "Node.js Backend"
            ServerSvc --> ServerDeployment[Server Pods]
            ServerDeployment --> Mongoose[Mongoose ODM]
        end

        subgraph "React Frontend"
            ClientSvc --> ClientDeployment[Client Pods (Nginx)]
            ClientDeployment -.->|AJAX Request| Ingress
        end
        
        ArgoCD -->|Auto-sync| Ingress
        ArgoCD -->|Auto-sync| ServerDeployment
        ArgoCD -->|Auto-sync| ClientDeployment
    end

    %% Database
    subgraph "Cloud Database"
        MongoDB[(MongoDB Atlas Cluster)]
    end

    %% Connections
    Mongoose <-->|Read/Write Complaints| MongoDB
```
