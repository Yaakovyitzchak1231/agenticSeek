#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Banner
clear
cat << "EOF"
    ___                  __  _      _____           __  
   /   | ____ ____  ____/ /_(_)____/ ___/___  ___  / /__
  / /| |/ __ `/ _ \/ __  / / / ___/\__ \/ _ \/ _ \/ //_/
 / ___ / /_/ /  __/ /_/ / / / /__ ___/ /  __/  __/ ,<   
/_/  |_\__, /\___/\__,_/_/_/\___//____/\___/\___/_/|_|  
      /____/                                             
      
      Quick Cloud Deployment Script
      
EOF

print_header "AgenticSeek Quick Deploy"

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please don't run this script as root"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    print_error "Cannot detect OS"
    exit 1
fi

print_info "Detected OS: $OS"

# Check for required tools
print_header "Checking Prerequisites"

# Check for git
if ! command -v git &> /dev/null; then
    print_info "Installing git..."
    sudo apt-get update -qq
    sudo apt-get install -y git
fi
print_success "Git is available"

# Check for Docker
if ! command -v docker &> /dev/null; then
    print_info "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    print_success "Docker installed"
    print_info "You may need to log out and back in for Docker permissions to take effect"
else
    print_success "Docker is available"
fi

# Check for Docker Compose
if ! docker compose version &> /dev/null; then
    if ! command -v docker-compose &> /dev/null; then
        print_info "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        print_success "Docker Compose installed"
    fi
else
    print_success "Docker Compose is available"
fi

# Clone or update repository
print_header "Setting Up AgenticSeek"

if [ -d "agenticSeek" ]; then
    print_info "AgenticSeek directory exists, updating..."
    cd agenticSeek
    git pull
else
    print_info "Cloning AgenticSeek repository..."
    git clone https://github.com/Fosowl/agenticSeek.git
    cd agenticSeek
fi

print_success "Repository ready"

# Configure environment
print_header "Configuration"

if [ ! -f ".env" ]; then
    print_info "Creating .env file..."
    cp .env.prod.example .env
    
    # Generate secret key
    SECRET_KEY=$(openssl rand -hex 32)
    echo "" >> .env
    echo "SEARXNG_SECRET_KEY=$SECRET_KEY" >> .env
    
    print_success "Environment file created"
    
    # Ask user if they want to add API keys
    echo ""
    read -p "Do you want to add LLM API keys now? (y/N): " add_keys
    if [[ $add_keys =~ ^[Yy]$ ]]; then
        echo ""
        read -p "OpenAI API Key (press Enter to skip): " openai_key
        if [ ! -z "$openai_key" ]; then
            sed -i "s/OPENAI_API_KEY=\"\"/OPENAI_API_KEY=\"$openai_key\"/" .env
        fi
        
        read -p "DeepSeek API Key (press Enter to skip): " deepseek_key
        if [ ! -z "$deepseek_key" ]; then
            sed -i "s/DEEPSEEK_API_KEY=\"\"/DEEPSEEK_API_KEY=\"$deepseek_key\"/" .env
        fi
        
        read -p "Google API Key (press Enter to skip): " google_key
        if [ ! -z "$google_key" ]; then
            sed -i "s/GOOGLE_API_KEY=\"\"/GOOGLE_API_KEY=\"$google_key\"/" .env
        fi
        
        print_success "API keys configured"
    else
        print_info "Skipping API keys - you can run local LLMs with Ollama"
    fi
else
    print_info ".env file already exists, skipping configuration"
fi

# Deploy
print_header "Deploying AgenticSeek"

print_info "Starting services with Docker Compose..."
docker compose -f docker-compose.prod.yml up -d

print_success "Services started!"

# Wait for services to be ready
print_info "Waiting for services to initialize (this may take 2-3 minutes)..."
sleep 10

# Get server IP
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "YOUR_SERVER_IP")

print_header "Deployment Complete! 🎉"

cat << EOF

${GREEN}✓ AgenticSeek is now running!${NC}

${BLUE}Access your application:${NC}
  • Frontend: ${GREEN}http://$SERVER_IP:3000${NC}
  • Backend API: ${GREEN}http://$SERVER_IP:7777${NC}

${BLUE}Next steps:${NC}
  1. Open firewall ports 3000 and 7777 on your cloud provider
  2. Visit http://$SERVER_IP:3000 in your browser
  3. Start chatting with your AI assistant!

${BLUE}Useful commands:${NC}
  • View logs: ${YELLOW}docker compose -f docker-compose.prod.yml logs -f${NC}
  • Stop services: ${YELLOW}docker compose -f docker-compose.prod.yml down${NC}
  • Restart services: ${YELLOW}docker compose -f docker-compose.prod.yml restart${NC}

${BLUE}Configure firewall:${NC}
  • AWS: Add inbound rules for ports 3000, 7777 in Security Group
  • GCP: ${YELLOW}gcloud compute firewall-rules create agenticseeek-web --allow tcp:3000,tcp:7777 --source-ranges 0.0.0.0/0${NC}
  • Azure: Add inbound security rules for ports 3000, 7777

${BLUE}Documentation:${NC}
  • Interface Guide: docs/INTERFACE.md
  • Full Deployment: DEPLOYMENT.md
  • Quick Start: QUICKSTART.md

${BLUE}Need help?${NC}
  • Discord: https://discord.gg/8hGDaME3TC
  • Issues: https://github.com/Fosowl/agenticSeek/issues

EOF

print_info "Tip: For HTTPS with custom domain, see DEPLOYMENT.md for Caddy setup"
