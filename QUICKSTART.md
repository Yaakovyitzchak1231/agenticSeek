# Quick Start Guide: Deploy AgenticSeek to Cloud

This is a quick start guide to get AgenticSeek running on the cloud in minutes.

## Choose Your Deployment Method

### Option 1: Simple VM Deployment (Recommended for Getting Started)

**Best for**: Small teams, testing, single-server deployments

**Requirements**: A cloud VM with 4GB+ RAM

#### Steps:

1. **Create a VM** on your preferred cloud provider:
   - **AWS**: EC2 instance (t3.medium or larger)
   - **GCP**: Compute Engine instance (e2-medium or larger)
   - **Azure**: Virtual Machine (B2s or larger)
   - **DigitalOcean**: Droplet (4GB or larger)

2. **SSH into your VM** and run:
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker $USER
   newgrp docker
   
   # Clone repository
   git clone https://github.com/Fosowl/agenticSeek.git
   cd agenticSeek
   
   # Configure environment
   cp .env.prod.example .env
   nano .env  # Edit with your settings
   
   # Generate secret key
   export SEARXNG_SECRET_KEY=$(openssl rand -hex 32)
   echo "SEARXNG_SECRET_KEY=$SEARXNG_SECRET_KEY" >> .env
   
   # Deploy
   docker compose -f docker-compose.prod.yml up -d
   ```

3. **Open firewall ports**:
   - Port 3000 (Frontend)
   - Port 7777 (Backend)

4. **Access your application**:
   - Frontend: `http://YOUR_VM_IP:3000`
   - Backend API: `http://YOUR_VM_IP:7777`

5. **Optional: Add SSL with Caddy** (recommended):
   ```bash
   sudo apt install caddy
   
   # Create Caddyfile
   sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
   your-domain.com {
       reverse_proxy localhost:3000
   }
   
   api.your-domain.com {
       reverse_proxy localhost:7777
   }
   EOF
   
   sudo systemctl restart caddy
   ```

---

### Option 2: Kubernetes Deployment (Recommended for Production)

**Best for**: Production deployments, high availability, auto-scaling

**Requirements**: A Kubernetes cluster (GKE, EKS, AKS)

#### Quick Steps:

1. **Clone and build images**:
   ```bash
   git clone https://github.com/Fosowl/agenticSeek.git
   cd agenticSeek
   
   # Build and push to your registry
   export USERNAME=yourusername
   export REGISTRY=docker.io  # or gcr.io, or ECR URL
   ./scripts/build-and-push.sh
   ```

2. **Configure Kubernetes**:
   ```bash
   # Edit secrets
   nano k8s/00-namespace.yaml
   
   # Update image references
   nano k8s/04-backend.yaml  # Change image: line
   nano k8s/05-frontend.yaml # Change image: line
   
   # Update domain
   nano k8s/06-ingress.yaml  # Change host: line
   ```

3. **Deploy**:
   ```bash
   ./scripts/deploy-k8s.sh
   ```

4. **Get external IP**:
   ```bash
   kubectl get ingress -n agenticseeek
   ```

5. **Point your domain** to the ingress IP

---

## Cloud Provider Quick Links

### AWS (Amazon Web Services)

**VM Deployment**:
1. Launch EC2 instance (Ubuntu 22.04, t3.medium)
2. Add security group rules for ports 3000, 7777
3. Follow Option 1 above

**EKS Deployment**:
```bash
eksctl create cluster --name agenticseeek --region us-west-2
# Then follow Option 2 above
```

**Full Guide**: See [DEPLOYMENT.md](./DEPLOYMENT.md#amazon-web-services-eks)

---

### GCP (Google Cloud Platform)

**VM Deployment**:
1. Create Compute Engine instance (Ubuntu 22.04, e2-medium)
2. Add firewall rules for ports 3000, 7777
3. Follow Option 1 above

**GKE Deployment**:
```bash
gcloud container clusters create agenticseeek-cluster \
  --zone us-central1-a --num-nodes 3
# Then follow Option 2 above
```

**Full Guide**: See [DEPLOYMENT.md](./DEPLOYMENT.md#google-cloud-platform-gke)

---

### Azure (Microsoft Azure)

**VM Deployment**:
1. Create Virtual Machine (Ubuntu 22.04, B2s)
2. Add inbound security rules for ports 3000, 7777
3. Follow Option 1 above

**AKS Deployment**:
```bash
az aks create --resource-group agenticseeek-rg \
  --name agenticseeek-cluster --node-count 3
# Then follow Option 2 above
```

**Full Guide**: See [DEPLOYMENT.md](./DEPLOYMENT.md#microsoft-azure-aks)

---

## Essential Configuration

### Environment Variables

Minimum required in `.env`:
```bash
SEARXNG_BASE_URL="http://searxng:8080"
REDIS_BASE_URL="redis://redis:6379/0"
WORK_DIR="/opt/workspace"
SEARXNG_SECRET_KEY="your-random-secret"  # Generate with: openssl rand -hex 32
```

### API Keys (Optional)

Only needed if using cloud LLM providers instead of local models:
```bash
OPENAI_API_KEY="sk-..."
DEEPSEEK_API_KEY="..."
GOOGLE_API_KEY="..."
```

---

## Common Issues

### Problem: Can't access the application
**Solution**: Check firewall rules and ensure ports 3000 and 7777 are open

### Problem: Backend can't connect to services
**Solution**: Ensure all containers are running: `docker ps`

### Problem: Out of memory
**Solution**: Use a VM with at least 4GB RAM, or increase your VM size

---

## Next Steps

1. **Configure your LLM provider** in `config.ini`
2. **Set up monitoring** (optional)
3. **Configure backups** for your workspace data
4. **Set up SSL certificates** for production use
5. **Read the full deployment guide**: [DEPLOYMENT.md](./DEPLOYMENT.md)

---

## Get Help

- 📖 Full documentation: [DEPLOYMENT.md](./DEPLOYMENT.md)
- 💬 Discord: https://discord.gg/8hGDaME3TC
- 🐛 Issues: https://github.com/Fosowl/agenticSeek/issues

---

## Cost Estimates

**VM Deployment (monthly)**:
- AWS EC2 t3.medium: ~$30/month
- GCP e2-medium: ~$25/month
- Azure B2s: ~$30/month
- DigitalOcean 4GB: ~$24/month

**Kubernetes Deployment (monthly)**:
- Small cluster (3 nodes): ~$150-200/month
- Can be reduced with spot/preemptible instances

*Note: Costs are approximate and vary by region and usage*
