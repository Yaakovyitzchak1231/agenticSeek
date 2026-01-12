# Cloud Deployment Guide for AgenticSeek

This guide provides instructions for deploying AgenticSeek to various cloud platforms.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Docker Compose Production Deployment](#docker-compose-production-deployment)
- [Kubernetes Deployment](#kubernetes-deployment)
  - [Google Cloud Platform (GKE)](#google-cloud-platform-gke)
  - [Amazon Web Services (EKS)](#amazon-web-services-eks)
  - [Microsoft Azure (AKS)](#microsoft-azure-aks)
- [Environment Configuration](#environment-configuration)
- [Building and Pushing Docker Images](#building-and-pushing-docker-images)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Docker and Docker Compose installed
- kubectl installed (for Kubernetes deployments)
- Cloud provider CLI tools (gcloud, aws, or az)
- A domain name (optional but recommended for production)
- SSL certificates (can be automated with cert-manager)

## Docker Compose Production Deployment

The simplest way to deploy AgenticSeek to a cloud VM is using Docker Compose.

### 1. Prepare Your Cloud VM

Create a VM instance with:
- **OS**: Ubuntu 20.04 or later
- **RAM**: 4GB minimum (8GB+ recommended)
- **Storage**: 50GB minimum
- **vCPUs**: 2+ cores

### 2. Install Docker and Docker Compose

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 3. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/Fosowl/agenticSeek.git
cd agenticSeek

# Create environment file
cp .env.example .env
nano .env  # Edit with your values
```

### 4. Generate Secrets

Generate a secure random string for SEARXNG_SECRET_KEY:

```bash
# Generate a random secret key
openssl rand -hex 32
```

Add this to your `.env` file:

```bash
SEARXNG_SECRET_KEY="your-generated-secret-here"
```

### 5. Deploy

```bash
# Deploy using production compose file
docker-compose -f docker-compose.prod.yml up -d

# Check logs
docker-compose -f docker-compose.prod.yml logs -f
```

### 6. Configure Firewall

Open the following ports:
- Port 3000 (Frontend)
- Port 7777 (Backend API)
- Port 8080 (SearxNG - optional, only if needed externally)

**GCP Example:**
```bash
gcloud compute firewall-rules create agenticseeek-web \
  --allow tcp:3000,tcp:7777 \
  --source-ranges 0.0.0.0/0 \
  --target-tags agenticseeek
```

**AWS Example:**
```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 7777 \
  --cidr 0.0.0.0/0
```

### 7. Access Your Application

Navigate to `http://YOUR_VM_IP:3000` to access the web interface.

### 8. (Optional) Setup Reverse Proxy with SSL

For production, use Nginx or Caddy as a reverse proxy with SSL:

```bash
# Install Caddy (easiest option)
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# Create Caddyfile
sudo nano /etc/caddy/Caddyfile
```

Example Caddyfile:
```
agenticseeek.yourdomain.com {
    reverse_proxy localhost:3000
}

api.agenticseeek.yourdomain.com {
    reverse_proxy localhost:7777
}
```

```bash
# Restart Caddy
sudo systemctl restart caddy
```

## Kubernetes Deployment

For production-scale deployments, use Kubernetes.

### Google Cloud Platform (GKE)

#### 1. Create GKE Cluster

```bash
# Set your project
gcloud config set project YOUR_PROJECT_ID

# Create cluster
gcloud container clusters create agenticseeek-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type n1-standard-2 \
  --disk-size 50 \
  --enable-autoscaling \
  --min-nodes 2 \
  --max-nodes 5

# Get credentials
gcloud container clusters get-credentials agenticseeek-cluster --zone us-central1-a
```

#### 2. Build and Push Docker Images

```bash
# Configure Docker to use GCR
gcloud auth configure-docker

# Build and tag images
docker build -t gcr.io/YOUR_PROJECT_ID/agenticseeek-backend:latest -f Dockerfile.backend .
docker build -t gcr.io/YOUR_PROJECT_ID/agenticseeek-frontend:latest -f frontend/Dockerfile.frontend.prod frontend/

# Push images
docker push gcr.io/YOUR_PROJECT_ID/agenticseeek-backend:latest
docker push gcr.io/YOUR_PROJECT_ID/agenticseeek-frontend:latest
```

#### 3. Update Kubernetes Manifests

Edit `k8s/04-backend.yaml` and `k8s/05-frontend.yaml` to use your image names:

```yaml
image: gcr.io/YOUR_PROJECT_ID/agenticseeek-backend:latest
```

#### 4. Configure Secrets

```bash
# Edit the secrets file
nano k8s/00-namespace.yaml

# Or create secrets from command line
kubectl create secret generic agenticseeek-secrets \
  --namespace=agenticseeek \
  --from-literal=OPENAI_API_KEY='your-key' \
  --from-literal=DEEPSEEK_API_KEY='your-key' \
  --from-literal=SEARXNG_SECRET_KEY='your-random-secret'
```

#### 5. Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n agenticseeek
kubectl get services -n agenticseeek

# Check logs
kubectl logs -n agenticseeek -l app=backend --tail=100
```

#### 6. Setup Ingress with SSL

```bash
# Install nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Install cert-manager for automatic SSL
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create Let's Encrypt issuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Update your domain in k8s/06-ingress.yaml
nano k8s/06-ingress.yaml

# Apply ingress
kubectl apply -f k8s/06-ingress.yaml

# Get external IP
kubectl get ingress -n agenticseeek
```

### Amazon Web Services (EKS)

#### 1. Create EKS Cluster

```bash
# Install eksctl if not already installed
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Create cluster
eksctl create cluster \
  --name agenticseeek-cluster \
  --region us-west-2 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --managed

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name agenticseeek-cluster
```

#### 2. Build and Push Docker Images

```bash
# Create ECR repositories
aws ecr create-repository --repository-name agenticseeek-backend
aws ecr create-repository --repository-name agenticseeek-frontend

# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com

# Build and tag
docker build -t YOUR_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/agenticseeek-backend:latest -f Dockerfile.backend .
docker build -t YOUR_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/agenticseeek-frontend:latest -f frontend/Dockerfile.frontend.prod frontend/

# Push images
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/agenticseeek-backend:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/agenticseeek-frontend:latest
```

#### 3. Update Kubernetes Manifests

Edit `k8s/04-backend.yaml` and `k8s/05-frontend.yaml`:

```yaml
image: YOUR_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/agenticseeek-backend:latest
```

#### 4. Deploy

```bash
# Apply manifests
kubectl apply -f k8s/

# Install AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=agenticseeek-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Update ingress annotations in k8s/06-ingress.yaml for ALB
# Then apply
kubectl apply -f k8s/06-ingress.yaml
```

### Microsoft Azure (AKS)

#### 1. Create AKS Cluster

```bash
# Create resource group
az group create --name agenticseeek-rg --location eastus

# Create AKS cluster
az aks create \
  --resource-group agenticseeek-rg \
  --name agenticseeek-cluster \
  --node-count 3 \
  --node-vm-size Standard_DS2_v2 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group agenticseeek-rg --name agenticseeek-cluster
```

#### 2. Build and Push Docker Images

```bash
# Create ACR
az acr create --resource-group agenticseeek-rg --name agenticseeekacr --sku Basic

# Attach ACR to AKS
az aks update --resource-group agenticseeek-rg --name agenticseeek-cluster --attach-acr agenticseeekacr

# Login to ACR
az acr login --name agenticseeekacr

# Build and push
az acr build --registry agenticseeekacr --image agenticseeek-backend:latest --file Dockerfile.backend .
az acr build --registry agenticseeekacr --image agenticseeek-frontend:latest --file frontend/Dockerfile.frontend.prod frontend/
```

#### 3. Update Kubernetes Manifests

Edit `k8s/04-backend.yaml` and `k8s/05-frontend.yaml`:

```yaml
image: agenticseeekacr.azurecr.io/agenticseeek-backend:latest
```

#### 4. Deploy

```bash
# Apply manifests
kubectl apply -f k8s/

# Check status
kubectl get pods -n agenticseeek
kubectl get services -n agenticseeek
```

## Environment Configuration

### Required Environment Variables

Edit `k8s/00-namespace.yaml` or your `.env` file:

| Variable | Description | Required |
|----------|-------------|----------|
| SEARXNG_BASE_URL | URL for SearxNG service | Yes |
| REDIS_URL | Redis connection string | Yes |
| WORK_DIR | Working directory path | Yes |
| SEARXNG_SECRET_KEY | Secret key for SearxNG | Yes |
| OPENAI_API_KEY | OpenAI API key | Optional |
| DEEPSEEK_API_KEY | Deepseek API key | Optional |
| GOOGLE_API_KEY | Google API key | Optional |
| ANTHROPIC_API_KEY | Anthropic API key | Optional |

### Generating Secrets

```bash
# Generate random secret
openssl rand -hex 32

# Or use Python
python3 -c "import secrets; print(secrets.token_hex(32))"
```

## Building and Pushing Docker Images

### For Docker Hub

```bash
# Login
docker login

# Build
docker build -t yourusername/agenticseeek-backend:latest -f Dockerfile.backend .
docker build -t yourusername/agenticseeek-frontend:latest -f frontend/Dockerfile.frontend.prod frontend/

# Push
docker push yourusername/agenticseeek-backend:latest
docker push yourusername/agenticseeek-frontend:latest

# Update k8s manifests
# image: yourusername/agenticseeek-backend:latest
```

### Build Script

Create a `build-and-push.sh` script:

```bash
#!/bin/bash
set -e

REGISTRY=${REGISTRY:-"docker.io"}
USERNAME=${USERNAME:-"yourusername"}
VERSION=${VERSION:-"latest"}

# Build images
docker build -t $REGISTRY/$USERNAME/agenticseeek-backend:$VERSION -f Dockerfile.backend .
docker build -t $REGISTRY/$USERNAME/agenticseeek-frontend:$VERSION -f frontend/Dockerfile.frontend.prod frontend/

# Push images
docker push $REGISTRY/$USERNAME/agenticseeek-backend:$VERSION
docker push $REGISTRY/$USERNAME/agenticseeek-frontend:$VERSION

echo "Images built and pushed successfully!"
```

```bash
chmod +x build-and-push.sh
./build-and-push.sh
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n agenticseeek

# Describe pod for events
kubectl describe pod <pod-name> -n agenticseeek

# Check logs
kubectl logs <pod-name> -n agenticseeek
```

### Image Pull Errors

Ensure your cluster has access to your container registry:

**GKE**: Grant GCR access
```bash
kubectl create secret docker-registry gcr-json-key \
  --docker-server=gcr.io \
  --docker-username=_json_key \
  --docker-password="$(cat ~/key.json)" \
  --namespace=agenticseeek
```

**EKS**: Ensure IAM roles are configured
**AKS**: Attach ACR to AKS cluster

### Service Not Accessible

```bash
# Check services
kubectl get svc -n agenticseeek

# Check ingress
kubectl get ingress -n agenticseeek
kubectl describe ingress agenticseeek-ingress -n agenticseeek

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Database Connection Issues

```bash
# Check if Redis is running
kubectl get pods -n agenticseeek -l app=redis

# Test Redis connection from backend pod
kubectl exec -n agenticseeek -it <backend-pod> -- redis-cli -h redis-service ping
```

### Persistent Volume Issues

```bash
# Check PVC status
kubectl get pvc -n agenticseeek

# Describe PVC
kubectl describe pvc <pvc-name> -n agenticseeek
```

Ensure your cloud provider supports the storage class:
- GKE: `standard` or `standard-rwo`
- EKS: `gp2` or `gp3`
- AKS: `default` or `managed-premium`

### Resource Limits

If pods are being evicted or OOMKilled:

```bash
# Check resource usage
kubectl top pods -n agenticseeek

# Adjust limits in deployment manifests
# Edit k8s/04-backend.yaml or k8s/05-frontend.yaml
```

### SSL Certificate Issues

```bash
# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Check certificate status
kubectl get certificate -n agenticseeek

# Describe certificate for issues
kubectl describe certificate <cert-name> -n agenticseeek
```

## Monitoring and Maintenance

### Health Checks

All services have health check endpoints:
- Frontend: `GET /health`
- Backend: `GET /health`
- Redis: `redis-cli ping`
- SearxNG: `GET /healthz`

### Logs

```bash
# Stream logs
kubectl logs -f -n agenticseeek -l app=backend

# Get logs from all replicas
kubectl logs -n agenticseeek -l app=frontend --tail=100

# Export logs
kubectl logs -n agenticseeek <pod-name> > pod-logs.txt
```

### Scaling

```bash
# Scale frontend
kubectl scale deployment frontend -n agenticseeek --replicas=5

# Scale backend
kubectl scale deployment backend -n agenticseeek --replicas=3

# Enable autoscaling
kubectl autoscale deployment backend -n agenticseeek --min=2 --max=10 --cpu-percent=80
```

### Updates

```bash
# Update image
kubectl set image deployment/backend backend=yourimage:newtag -n agenticseeek

# Rollback
kubectl rollout undo deployment/backend -n agenticseeek

# Check rollout status
kubectl rollout status deployment/backend -n agenticseeek
```

## Cost Optimization

### Cloud Provider Recommendations

**GCP GKE**:
- Use preemptible nodes for non-production
- Enable cluster autoscaling
- Use regional clusters for HA

**AWS EKS**:
- Use Spot instances for worker nodes
- Enable cluster autoscaler
- Use Fargate for serverless pods

**Azure AKS**:
- Use Spot VMs
- Enable cluster autoscaler
- Use Azure Container Instances for burst capacity

### Resource Optimization

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n agenticseeek

# Right-size your pods based on actual usage
```

## Security Considerations

1. **Use Secrets Management**: Consider using external secret managers:
   - AWS Secrets Manager
   - GCP Secret Manager
   - Azure Key Vault
   - HashiCorp Vault

2. **Network Policies**: Implement network policies to restrict pod-to-pod communication

3. **RBAC**: Configure proper Role-Based Access Control

4. **Image Scanning**: Scan container images for vulnerabilities

5. **Regular Updates**: Keep Kubernetes and images updated

## Support

For issues and questions:
- GitHub Issues: https://github.com/Fosowl/agenticSeek/issues
- Discord: https://discord.gg/8hGDaME3TC

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
