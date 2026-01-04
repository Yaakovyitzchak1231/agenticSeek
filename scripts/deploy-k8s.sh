#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

print_header "Deploying AgenticSeek to Kubernetes"

# Create namespace
print_info "Creating namespace..."
kubectl apply -f k8s/00-namespace.yaml

# Wait for namespace to be created
sleep 2

# Create PVCs
print_info "Creating Persistent Volume Claims..."
kubectl apply -f k8s/01-pvc.yaml

# Deploy Redis
print_info "Deploying Redis..."
kubectl apply -f k8s/02-redis.yaml

# Wait for Redis to be ready
print_info "Waiting for Redis to be ready..."
kubectl wait --for=condition=ready pod -l app=redis -n agenticseeek --timeout=120s

# Deploy SearxNG
print_info "Deploying SearxNG..."
kubectl apply -f k8s/03-searxng.yaml

# Wait for SearxNG to be ready
print_info "Waiting for SearxNG to be ready..."
kubectl wait --for=condition=ready pod -l app=searxng -n agenticseeek --timeout=120s

# Deploy Backend
print_info "Deploying Backend..."
kubectl apply -f k8s/04-backend.yaml

# Deploy Frontend
print_info "Deploying Frontend..."
kubectl apply -f k8s/05-frontend.yaml

# Wait for deployments
print_info "Waiting for Backend to be ready..."
kubectl wait --for=condition=available deployment/backend -n agenticseeek --timeout=180s

print_info "Waiting for Frontend to be ready..."
kubectl wait --for=condition=available deployment/frontend -n agenticseeek --timeout=120s

# Deploy Ingress
print_info "Deploying Ingress..."
kubectl apply -f k8s/06-ingress.yaml

print_header "Deployment Complete"

# Show status
print_info "Current status:"
echo ""
kubectl get pods -n agenticseeek
echo ""
kubectl get services -n agenticseeek
echo ""
kubectl get ingress -n agenticseeek

print_info ""
print_info "Useful commands:"
print_info "  - View logs: kubectl logs -n agenticseeek -l app=backend --tail=100"
print_info "  - Check pods: kubectl get pods -n agenticseeek"
print_info "  - Port forward: kubectl port-forward -n agenticseeek svc/frontend-service 3000:80"
print_info "  - Delete deployment: kubectl delete namespace agenticseeek"
