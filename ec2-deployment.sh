#!/bin/bash

# EC2 Deployment Script for Spring Boot AWS Demo
# This script automates the deployment process on EC2

set -e

echo "🚀 Starting EC2 deployment process..."

# Configuration
APP_NAME="springboot-aws-demo"
JAR_NAME="springboot-aws-demo-0.0.1-SNAPSHOT.jar"
APP_DIR="/home/ec2-user/app"
SERVICE_NAME="springboot-app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Update system packages
print_status "Updating system packages..."
sudo yum update -y

# Step 2: Install Java 17
print_status "Installing Java 17..."
sudo yum install -y java-17-amazon-corretto-headless

# Verify Java installation
java -version
print_status "Java installation completed"

# Step 3: Create application directory
print_status "Creating application directory..."
sudo mkdir -p $APP_DIR
sudo chown ec2-user:ec2-user $APP_DIR

# Step 4: Copy JAR file (assumes it's already uploaded)
if [ -f "/home/ec2-user/$JAR_NAME" ]; then
    print_status "Moving JAR file to application directory..."
    mv "/home/ec2-user/$JAR_NAME" "$APP_DIR/"
else
    print_error "JAR file not found in /home/ec2-user/. Please upload the JAR file first."
    exit 1
fi

# Step 5: Create systemd service file
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=Spring Boot AWS Demo Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/java -jar -Dspring.profiles.active=production -Dserver.port=8080 $APP_DIR/$JAR_NAME
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$APP_NAME

# Environment variables
Environment=SPRING_PROFILES_ACTIVE=production
Environment=SERVER_PORT=8080

[Install]
WantedBy=multi-user.target
EOF

# Step 6: Enable and start the service
print_status "Enabling and starting the service..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Step 7: Check service status
print_status "Checking service status..."
sudo systemctl status $SERVICE_NAME --no-pager

# Step 8: Install and configure nginx (optional reverse proxy)
print_status "Installing and configuring nginx..."
sudo yum install -y nginx

# Create nginx configuration
sudo tee /etc/nginx/conf.d/$APP_NAME.conf > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8080/actuator/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Start nginx
sudo systemctl enable nginx
sudo systemctl start nginx

print_status "✅ Deployment completed successfully!"
print_status "Your application should be accessible at:"
print_status "  - Direct: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
print_status "  - Via Nginx: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
print_status ""
print_status "Service management commands:"
print_status "  - Check status: sudo systemctl status $SERVICE_NAME"
print_status "  - View logs: sudo journalctl -u $SERVICE_NAME -f"
print_status "  - Restart: sudo systemctl restart $SERVICE_NAME"
print_status "  - Stop: sudo systemctl stop $SERVICE_NAME"
