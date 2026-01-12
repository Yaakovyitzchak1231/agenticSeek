#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
REGISTRY=${REGISTRY:-"docker.io"}
USERNAME=${USERNAME:-""}
VERSION=${VERSION:-"latest"}
PLATFORM=${PLATFORM:-"linux/amd64"}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if USERNAME is set
if [ -z "$USERNAME" ]; then
    print_error "USERNAME is not set. Please set it using: export USERNAME=yourusername"
    exit 1
fi

print_info "Building and pushing AgenticSeek images..."
print_info "Registry: $REGISTRY"
print_info "Username: $USERNAME"
print_info "Version: $VERSION"
print_info "Platform: $PLATFORM"

# Build backend image
print_info "Building backend image..."
docker build --platform $PLATFORM \
    -t $REGISTRY/$USERNAME/agenticseeek-backend:$VERSION \
    -f Dockerfile.backend .

# Build frontend image
print_info "Building frontend image..."
docker build --platform $PLATFORM \
    -t $REGISTRY/$USERNAME/agenticseeek-frontend:$VERSION \
    -f frontend/Dockerfile.frontend.prod \
    frontend/

# Tag as latest if version is not latest
if [ "$VERSION" != "latest" ]; then
    print_info "Tagging images as latest..."
    docker tag $REGISTRY/$USERNAME/agenticseeek-backend:$VERSION \
        $REGISTRY/$USERNAME/agenticseeek-backend:latest
    docker tag $REGISTRY/$USERNAME/agenticseeek-frontend:$VERSION \
        $REGISTRY/$USERNAME/agenticseeek-frontend:latest
fi

# Push images
print_info "Pushing backend image..."
docker push $REGISTRY/$USERNAME/agenticseeek-backend:$VERSION

print_info "Pushing frontend image..."
docker push $REGISTRY/$USERNAME/agenticseeek-frontend:$VERSION

if [ "$VERSION" != "latest" ]; then
    print_info "Pushing latest tags..."
    docker push $REGISTRY/$USERNAME/agenticseeek-backend:latest
    docker push $REGISTRY/$USERNAME/agenticseeek-frontend:latest
fi

print_info "Images built and pushed successfully!"
print_info ""
print_info "Next steps:"
print_info "1. Update k8s/04-backend.yaml with: image: $REGISTRY/$USERNAME/agenticseeek-backend:$VERSION"
print_info "2. Update k8s/05-frontend.yaml with: image: $REGISTRY/$USERNAME/agenticseeek-frontend:$VERSION"
print_info "3. Configure secrets in k8s/00-namespace.yaml"
print_info "4. Deploy with: kubectl apply -f k8s/"
