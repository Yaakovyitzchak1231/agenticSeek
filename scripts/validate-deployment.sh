#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

errors=0
warnings=0

print_header "AgenticSeek Cloud Deployment Validation"

# Check Docker
print_info "Checking Docker..."
if command -v docker &> /dev/null; then
    version=$(docker --version)
    print_success "Docker is installed: $version"
else
    print_error "Docker is not installed"
    errors=$((errors+1))
fi

# Check Docker Compose
print_info "Checking Docker Compose..."
if docker compose version &> /dev/null; then
    version=$(docker compose version)
    print_success "Docker Compose is installed: $version"
elif command -v docker-compose &> /dev/null; then
    version=$(docker-compose --version)
    print_warn "Old docker-compose detected. Consider upgrading to Docker Compose V2"
    warnings=$((warnings+1))
else
    print_error "Docker Compose is not installed"
    errors=$((errors+1))
fi

# Check kubectl
print_info "Checking kubectl..."
if command -v kubectl &> /dev/null; then
    version=$(kubectl version --client --short 2>/dev/null || kubectl version --client)
    print_success "kubectl is installed: $version"
else
    print_warn "kubectl is not installed (only needed for Kubernetes deployment)"
    warnings=$((warnings+1))
fi

# Check if files exist
print_header "Checking Deployment Files"

files=(
    "docker-compose.prod.yml"
    "frontend/Dockerfile.frontend.prod"
    "frontend/nginx.conf"
    "Dockerfile.backend"
    ".env.example"
    ".env.prod.example"
    "DEPLOYMENT.md"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        print_success "$file exists"
    else
        print_error "$file is missing"
        errors=$((errors+1))
    fi
done

# Check k8s directory
print_info "Checking Kubernetes manifests..."
if [ -d "k8s" ]; then
    k8s_files=(
        "k8s/00-namespace.yaml"
        "k8s/01-pvc.yaml"
        "k8s/02-redis.yaml"
        "k8s/03-searxng.yaml"
        "k8s/04-backend.yaml"
        "k8s/05-frontend.yaml"
        "k8s/06-ingress.yaml"
        "k8s/README.md"
    )
    
    for file in "${k8s_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "$file exists"
        else
            print_error "$file is missing"
            errors=$((errors+1))
        fi
    done
else
    print_error "k8s directory is missing"
    errors=$((errors+1))
fi

# Check scripts
print_info "Checking deployment scripts..."
scripts=(
    "scripts/build-and-push.sh"
    "scripts/deploy-k8s.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            print_success "$script exists and is executable"
        else
            print_warn "$script exists but is not executable"
            warnings=$((warnings+1))
        fi
    else
        print_error "$script is missing"
        errors=$((errors+1))
    fi
done

# Validate YAML syntax
print_header "Validating YAML Files"

if command -v python3 &> /dev/null; then
    for yamlfile in k8s/*.yaml docker-compose.prod.yml; do
        if [ -f "$yamlfile" ]; then
            if python3 -c "import yaml; list(yaml.safe_load_all(open('$yamlfile')))" 2>/dev/null; then
                print_success "$yamlfile is valid YAML"
            else
                print_error "$yamlfile has invalid YAML syntax"
                errors=$((errors+1))
            fi
        fi
    done
else
    print_warn "Python3 not available, skipping YAML validation"
    warnings=$((warnings+1))
fi

# Check Docker Compose syntax
print_header "Validating Docker Compose Configuration"

if docker compose -f docker-compose.prod.yml config &> /dev/null; then
    print_success "docker-compose.prod.yml is valid"
else
    print_error "docker-compose.prod.yml has errors"
    errors=$((errors+1))
fi

# Check if .env exists
print_header "Checking Environment Configuration"

if [ -f ".env" ]; then
    print_success ".env file exists"
    
    # Check for required variables
    required_vars=(
        "SEARXNG_BASE_URL"
        "REDIS_BASE_URL"
        "WORK_DIR"
    )
    
    for var in "${required_vars[@]}"; do
        if grep -q "^${var}=" .env; then
            print_success "$var is set in .env"
        else
            print_warn "$var is not set in .env"
            warnings=$((warnings+1))
        fi
    done
else
    print_warn ".env file does not exist. Copy from .env.example or .env.prod.example"
    warnings=$((warnings+1))
fi

# Validate Kubernetes manifests syntax
if command -v kubectl &> /dev/null; then
    print_header "Validating Kubernetes Manifests"
    
    # Check if kubectl can connect to a cluster
    if kubectl cluster-info &> /dev/null; then
        for manifest in k8s/*.yaml; do
            if [ -f "$manifest" ]; then
                if kubectl apply --dry-run=client -f "$manifest" &> /dev/null; then
                    print_success "$manifest is valid"
                else
                    print_error "$manifest has validation errors"
                    errors=$((errors+1))
                fi
            fi
        done
    else
        print_warn "No Kubernetes cluster available for kubectl validation"
        print_info "Kubernetes manifests will be validated for syntax only"
        warnings=$((warnings+1))
    fi
fi

# Summary
print_header "Validation Summary"

echo ""
if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    print_success "All checks passed! Ready for deployment."
    exit 0
elif [ $errors -eq 0 ]; then
    print_warn "Validation completed with $warnings warning(s)."
    echo ""
    print_info "You can proceed with deployment, but review the warnings above."
    exit 0
else
    print_error "Validation failed with $errors error(s) and $warnings warning(s)."
    echo ""
    print_info "Please fix the errors above before deploying."
    exit 1
fi
