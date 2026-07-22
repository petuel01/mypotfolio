#!/bin/bash

# ============================================
# Docker Portfolio Deployment Script
# Deploy mypotfolio using Docker on Debian
# ============================================

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOMAIN="petzeustech.duckdns.org"
CONTAINER_NAME="portfolio-app"
IMAGE_NAME="portfolio:latest"
GITHUB_REPO="https://github.com/petuel01/mypotfolio.git"
APP_DIR="/opt/mypotfolio"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Docker Portfolio Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Domain: ${GREEN}$DOMAIN${NC}"
echo -e "Container: ${GREEN}$CONTAINER_NAME${NC}"
echo -e "App Directory: ${GREEN}$APP_DIR${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Step 1: Update system
echo -e "${YELLOW}[1/7]${NC} Updating Debian packages..."
apt update && apt upgrade -y

# Step 2: Install Docker
echo -e "${YELLOW}[2/7]${NC} Installing Docker..."
if ! command -v docker &> /dev/null; then
    apt install -y docker.io docker-compose git
    systemctl enable docker
    systemctl start docker
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

# Step 3: Create app directory
echo -e "${YELLOW}[3/7]${NC} Setting up application directory..."
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# Step 4: Clone or update repository
echo -e "${YELLOW}[4/7]${NC} Cloning/updating repository..."
if [ -d ".git" ]; then
    echo -e "${YELLOW}Repository exists, pulling latest...${NC}"
    git pull origin main
else
    git clone "$GITHUB_REPO" .
fi

# Step 5: Stop and remove old container (if exists)
echo -e "${YELLOW}[5/7]${NC} Stopping old container (if running)..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Step 6: Build Docker image
echo -e "${YELLOW}[6/7]${NC} Building Docker image..."
docker build -t "$IMAGE_NAME" .

# Step 7: Run Docker container
echo -e "${YELLOW}[7/7]${NC} Starting Docker container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart always \
    -p 80:80 \
    -v "$APP_DIR":/usr/share/nginx/html:ro \
    "$IMAGE_NAME"

echo -e "${GREEN}✓ Container started${NC}"

# Setup auto-update via cron
cat > /usr/local/bin/update-portfolio-docker.sh << 'EOF'
#!/bin/bash
cd /opt/mypotfolio
git pull origin main
docker build -t portfolio:latest .
docker stop portfolio-app 2>/dev/null || true
docker rm portfolio-app 2>/dev/null || true
docker run -d \
    --name portfolio-app \
    --restart always \
    -p 80:80 \
    -v /opt/mypotfolio:/usr/share/nginx/html:ro \
    portfolio:latest
echo "Portfolio updated via Docker at $(date)" >> /var/log/portfolio-docker.log
EOF

chmod +x /usr/local/bin/update-portfolio-docker.sh

# Add to crontab for auto-updates (every 6 hours)
(crontab -l 2>/dev/null | grep -v update-portfolio-docker; echo "0 */6 * * * /usr/local/bin/update-portfolio-docker.sh") | crontab -

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Docker Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Your portfolio is running in Docker!"
echo -e "Access at: ${GREEN}http://$DOMAIN${NC}"
echo ""

echo -e "${YELLOW}Useful Commands:${NC}"
echo "View logs:        ${BLUE}docker logs -f $CONTAINER_NAME${NC}"
echo "Stop container:   ${BLUE}docker stop $CONTAINER_NAME${NC}"
echo "Start container:  ${BLUE}docker start $CONTAINER_NAME${NC}"
echo "Manual update:    ${BLUE}/usr/local/bin/update-portfolio-docker.sh${NC}"
echo "Docker stats:     ${BLUE}docker stats $CONTAINER_NAME${NC}"
echo ""

echo -e "${YELLOW}Container Status:${NC}"
docker ps -a --filter name=$CONTAINER_NAME

echo ""
echo -e "${YELLOW}Testing deployment:${NC}"
sleep 2
curl -I http://localhost/ | head -5

echo ""
echo -e "${YELLOW}Auto-updates:${NC}"
echo "✓ Enabled - runs every 6 hours"
echo "✓ Update log: ${GREEN}/var/log/portfolio-docker.log${NC}"
echo ""
