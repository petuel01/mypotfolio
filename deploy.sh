#!/bin/bash

# ============================================
# Portfolio Deployment Script
# Deploy mypotfolio to VPS with Nginx & SSL
# ============================================

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="${1:-portfolio.petzeustech.duckdns.org}"
WEB_ROOT="/var/www/mypotfolio"
GITHUB_REPO="https://github.com/petuel01/mypotfolio.git"
EMAIL="your-email@example.com"  # Change this!

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Portfolio Deployment Script${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "Domain: ${GREEN}$DOMAIN${NC}"
echo -e "Web Root: ${GREEN}$WEB_ROOT${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Step 1: Update system
echo -e "${YELLOW}[1/7]${NC} Updating system packages..."
apt update && apt upgrade -y

# Step 2: Install Nginx
echo -e "${YELLOW}[2/7]${NC} Installing Nginx..."
apt install -y nginx git curl

# Step 3: Clone repository
echo -e "${YELLOW}[3/7]${NC} Cloning repository..."
if [ -d "$WEB_ROOT" ]; then
    echo -e "${YELLOW}Directory exists, pulling latest changes...${NC}"
    cd "$WEB_ROOT"
    git pull origin main
else
    git clone "$GITHUB_REPO" "$WEB_ROOT"
    cd "$WEB_ROOT"
fi

# Step 4: Set proper permissions
echo -e "${YELLOW}[4/7]${NC} Setting permissions..."
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

# Step 5: Configure Nginx
echo -e "${YELLOW}[5/7]${NC} Configuring Nginx..."
cat > /etc/nginx/sites-available/portfolio << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    root $WEB_ROOT;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Redirect HTTP to HTTPS (will work after SSL setup)
    location ~ \.html$ {
        add_header Cache-Control "public, max-age=3600";
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo -e "${YELLOW}Testing Nginx configuration...${NC}"
nginx -t

# Step 6: Restart Nginx
echo -e "${YELLOW}[6/7]${NC} Restarting Nginx..."
systemctl restart nginx
systemctl enable nginx

# Step 7: Install SSL Certificate with Certbot
echo -e "${YELLOW}[7/7]${NC} Installing SSL certificate..."
apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
echo -e "${YELLOW}Getting SSL certificate for $DOMAIN...${NC}"
certbot certonly --nginx \
    -d "$DOMAIN" \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --redirect || echo -e "${YELLOW}Note: SSL setup may require manual verification${NC}"

# Update Nginx config for HTTPS
cat > /etc/nginx/sites-available/portfolio << EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    root $WEB_ROOT;
    index index.html;
    
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ \.html$ {
        add_header Cache-Control "public, max-age=3600";
    }
}
EOF

nginx -t
systemctl reload nginx

# Step 8: Setup auto-renewal for SSL
echo -e "${YELLOW}Setting up SSL auto-renewal...${NC}"
systemctl enable certbot.timer
systemctl start certbot.timer

# Step 9: Create update script
echo -e "${YELLOW}Creating auto-update script...${NC}"
cat > /usr/local/bin/update-portfolio.sh << EOF
#!/bin/bash
cd $WEB_ROOT
git pull origin main
chown -R www-data:www-data $WEB_ROOT
echo "Portfolio updated at \$(date)" >> /var/log/portfolio-updates.log
EOF

chmod +x /usr/local/bin/update-portfolio.sh

# Add to crontab for auto-updates (every 6 hours)
(crontab -l 2>/dev/null; echo "0 */6 * * * /usr/local/bin/update-portfolio.sh") | crontab -

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Your portfolio is now live at: ${GREEN}https://$DOMAIN${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Point your DuckDNS domain to this VPS IP"
echo "2. Update DNS settings if needed"
echo "3. Test: ${GREEN}curl https://$DOMAIN${NC}"
echo ""
echo -e "${YELLOW}Auto-updates:${NC}"
echo "✓ Enabled - runs every 6 hours via crontab"
echo "✓ Manual update: ${GREEN}/usr/local/bin/update-portfolio.sh${NC}"
echo ""
echo -e "${YELLOW}SSL Certificate:${NC}"
echo "✓ Auto-renewal enabled via certbot.timer"
echo "✓ Certificate path: ${GREEN}/etc/letsencrypt/live/$DOMAIN/${NC}"
echo ""
echo -e "${YELLOW}Logs:${NC}"
echo "✓ Nginx: ${GREEN}/var/log/nginx/access.log${NC}"
echo "✓ Updates: ${GREEN}/var/log/portfolio-updates.log${NC}"
echo ""
