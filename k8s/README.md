# Kubernetes Deployment Manifests

This directory contains Kubernetes manifests for deploying AgenticSeek to a Kubernetes cluster.

## Files Overview

- `00-namespace.yaml` - Creates namespace, ConfigMap, and Secrets
- `01-pvc.yaml` - Persistent Volume Claims for data storage
- `02-redis.yaml` - Redis deployment and service
- `03-searxng.yaml` - SearxNG deployment and service
- `04-backend.yaml` - Backend API deployment and service
- `05-frontend.yaml` - Frontend web UI deployment and service
- `06-ingress.yaml` - Ingress configuration for external access

## Quick Start

### Prerequisites

1. A running Kubernetes cluster (GKE, EKS, AKS, or local)
2. `kubectl` configured to access your cluster
3. Docker images built and pushed to a container registry

### Configuration Steps

1. **Update Secrets** (k8s/00-namespace.yaml):
   ```yaml
   stringData:
     OPENAI_API_KEY: "your-actual-key"
     DEEPSEEK_API_KEY: "your-actual-key"
     SEARXNG_SECRET_KEY: "generate-random-string"
   ```

2. **Update Image References** (k8s/04-backend.yaml & k8s/05-frontend.yaml):
   ```yaml
   image: your-registry/agenticseeek-backend:latest
   ```

3. **Update Domain** (k8s/06-ingress.yaml):
   ```yaml
   host: agenticseeek.yourdomain.com
   ```

4. **Update Storage Class** (k8s/01-pvc.yaml):
   - GKE: `standard` or `standard-rwo`
   - EKS: `gp2` or `gp3`
   - AKS: `default` or `managed-premium`

### Deploy

```bash
# Deploy all resources
kubectl apply -f k8s/

# Or use the deployment script
./scripts/deploy-k8s.sh
```

### Verify Deployment

```bash
# Check all resources
kubectl get all -n agenticseeek

# Check pod status
kubectl get pods -n agenticseeek

# Check logs
kubectl logs -n agenticseeek -l app=backend --tail=100
```

### Access the Application

#### Option 1: Via Ingress (Production)
Configure DNS to point to your ingress IP, then access via:
```
https://agenticseeek.yourdomain.com
```

#### Option 2: Via Port Forward (Testing)
```bash
# Frontend
kubectl port-forward -n agenticseeek svc/frontend-service 3000:80

# Backend
kubectl port-forward -n agenticseeek svc/backend-service 7777:7777

# Access at http://localhost:3000
```

#### Option 3: Via LoadBalancer
Edit services to type `LoadBalancer` instead of `ClusterIP`, then:
```bash
kubectl get svc -n agenticseeek
```

## Resource Requirements

### Minimum Resources
- **Redis**: 256Mi RAM, 100m CPU
- **SearxNG**: 256Mi RAM, 200m CPU
- **Backend**: 1Gi RAM, 500m CPU
- **Frontend**: 128Mi RAM, 100m CPU

### Recommended Resources
- **Redis**: 512Mi RAM, 500m CPU
- **SearxNG**: 1Gi RAM, 1000m CPU
- **Backend**: 4Gi RAM, 2000m CPU
- **Frontend**: 256Mi RAM, 500m CPU

## Scaling

### Manual Scaling
```bash
# Scale frontend
kubectl scale deployment frontend -n agenticseeek --replicas=3

# Scale backend
kubectl scale deployment backend -n agenticseeek --replicas=2
```

### Auto-scaling
```bash
# Create HPA for backend
kubectl autoscale deployment backend -n agenticseeek \
  --min=2 --max=10 --cpu-percent=80

# Create HPA for frontend
kubectl autoscale deployment frontend -n agenticseeek \
  --min=2 --max=5 --cpu-percent=80
```

## Updating

### Rolling Update
```bash
# Update backend image
kubectl set image deployment/backend backend=newimage:tag -n agenticseeek

# Check rollout status
kubectl rollout status deployment/backend -n agenticseeek

# Rollback if needed
kubectl rollout undo deployment/backend -n agenticseeek
```

## Monitoring

### View Logs
```bash
# All backend logs
kubectl logs -n agenticseeek -l app=backend --tail=100

# Follow logs
kubectl logs -n agenticseeek -l app=backend -f

# Specific pod
kubectl logs -n agenticseeek <pod-name>
```

### Check Resource Usage
```bash
# Node usage
kubectl top nodes

# Pod usage
kubectl top pods -n agenticseeek
```

### Events
```bash
# All events in namespace
kubectl get events -n agenticseeek --sort-by='.lastTimestamp'

# Specific resource events
kubectl describe pod <pod-name> -n agenticseeek
```

## Troubleshooting

### Pods Not Starting
```bash
# Check pod status
kubectl get pods -n agenticseeek

# Describe pod for details
kubectl describe pod <pod-name> -n agenticseeek

# Check events
kubectl get events -n agenticseeek --sort-by='.lastTimestamp'
```

### Image Pull Errors
Ensure your cluster has access to your container registry:
```bash
# Create image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password> \
  --namespace=agenticseeek

# Add to deployment spec
# spec:
#   imagePullSecrets:
#   - name: regcred
```

### Database Connection Issues
```bash
# Test Redis connectivity
kubectl run -n agenticseeek redis-test --rm -it --restart=Never \
  --image=redis:alpine -- redis-cli -h redis-service ping
```

### PVC Binding Issues
```bash
# Check PVC status
kubectl get pvc -n agenticseeek

# Describe PVC
kubectl describe pvc <pvc-name> -n agenticseeek

# Check if storage class exists
kubectl get storageclass
```

## Cleanup

```bash
# Delete all resources
kubectl delete namespace agenticseeek

# Or delete individual resources
kubectl delete -f k8s/
```

## Security Best Practices

1. **Use Secrets Management**: Consider external secret managers
   - AWS Secrets Manager
   - GCP Secret Manager
   - Azure Key Vault
   - HashiCorp Vault

2. **Network Policies**: Restrict pod-to-pod communication
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: backend-policy
     namespace: agenticseeek
   spec:
     podSelector:
       matchLabels:
         app: backend
     ingress:
     - from:
       - podSelector:
           matchLabels:
             app: frontend
   ```

3. **RBAC**: Create service accounts with minimal permissions

4. **Pod Security**: Enable pod security policies or admission controllers

5. **Image Scanning**: Scan images for vulnerabilities before deployment

## Support

For more details, see the main [DEPLOYMENT.md](../DEPLOYMENT.md) file.

For issues and questions:
- GitHub Issues: https://github.com/Fosowl/agenticSeek/issues
- Discord: https://discord.gg/8hGDaME3TC
