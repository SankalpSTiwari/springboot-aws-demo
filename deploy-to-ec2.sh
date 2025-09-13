#!/bin/bash

# Local deployment script to deploy Spring Boot app to EC2
# Run this script from your local machine

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

# Configuration
APP_NAME="springboot-aws-demo"
JAR_NAME="springboot-aws-demo-0.0.1-SNAPSHOT.jar"

print_header "🚀 Spring Boot AWS EC2 Deployment Script"
echo "========================================"

# Check if required parameters are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <key-file.pem> <ec2-ip-address> [profile]"
    echo "Example: $0 my-key.pem 3.15.123.45 default"
    exit 1
fi

KEY_FILE=$1
EC2_IP=$2
AWS_PROFILE=${3:-default}

# Validate key file exists
if [ ! -f "$KEY_FILE" ]; then
    print_error "Key file '$KEY_FILE' not found!"
    exit 1
fi

# Set correct permissions for key file
chmod 400 "$KEY_FILE"

# Step 1: Build the application
print_status "Building Spring Boot application..."
if ! mvn clean package -DskipTests; then
    print_error "Failed to build application"
    exit 1
fi

# Verify JAR file exists
if [ ! -f "target/$JAR_NAME" ]; then
    print_error "JAR file not found in target/ directory"
    exit 1
fi

print_status "✅ Application built successfully"

# Step 2: Test SSH connection
print_status "Testing SSH connection to EC2 instance..."
if ! ssh -i "$KEY_FILE" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$EC2_IP "echo 'SSH connection successful'"; then
    print_error "Cannot connect to EC2 instance. Please check:"
    echo "  - EC2 instance is running"
    echo "  - Security group allows SSH (port 22)"
    echo "  - Key file is correct"
    echo "  - IP address is correct"
    exit 1
fi

print_status "✅ SSH connection successful"

# Step 3: Upload JAR file
print_status "Uploading JAR file to EC2..."
if ! scp -i "$KEY_FILE" -o StrictHostKeyChecking=no "target/$JAR_NAME" ec2-user@$EC2_IP:/home/ec2-user/; then
    print_error "Failed to upload JAR file"
    exit 1
fi

print_status "✅ JAR file uploaded"

# Step 4: Upload deployment script
print_status "Uploading deployment script..."
if ! scp -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-deployment.sh ec2-user@$EC2_IP:/home/ec2-user/; then
    print_error "Failed to upload deployment script"
    exit 1
fi

print_status "✅ Deployment script uploaded"

# Step 5: Run deployment on EC2
print_status "Running deployment on EC2 instance..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@$EC2_IP << 'EOF'
    chmod +x ec2-deployment.sh
    ./ec2-deployment.sh
EOF

# Step 6: Test the deployed application
print_status "Testing deployed application..."
sleep 10  # Give the application time to start

# Test health endpoint
if curl -f -s "http://$EC2_IP:8080/actuator/health" > /dev/null; then
    print_status "✅ Application health check passed"
else
    print_warning "Health check failed, but deployment may still be starting..."
fi

# Test main endpoint
if curl -f -s "http://$EC2_IP:8080/api/hello" > /dev/null; then
    print_status "✅ Main endpoint accessible"
else
    print_warning "Main endpoint not yet accessible, but deployment may still be starting..."
fi

# Step 7: Display access information
print_header "🎉 Deployment Complete!"
echo "========================================"
print_status "Your Spring Boot application is now deployed!"
echo ""
print_status "Access URLs:"
echo "  🌐 Application: http://$EC2_IP:8080"
echo "  🌐 Via Nginx: http://$EC2_IP"
echo "  ❤️  Health Check: http://$EC2_IP:8080/actuator/health"
echo ""
print_status "API Endpoints:"
echo "  📋 Hello: http://$EC2_IP:8080/api/hello"
echo "  👥 Users: http://$EC2_IP:8080/api/users"
echo "  📊 Metrics: http://$EC2_IP:8080/actuator/metrics"
echo ""
print_status "Management Commands (run on EC2):"
echo "  📊 Check status: sudo systemctl status springboot-app"
echo "  📝 View logs: sudo journalctl -u springboot-app -f"
echo "  🔄 Restart: sudo systemctl restart springboot-app"
echo ""
print_status "SSH into EC2: ssh -i $KEY_FILE ec2-user@$EC2_IP"

# Step 8: Optional - open browser
read -p "Would you like to open the application in your browser? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v open &> /dev/null; then
        open "http://$EC2_IP:8080/api/hello"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "http://$EC2_IP:8080/api/hello"
    else
        print_status "Please open http://$EC2_IP:8080/api/hello in your browser"
    fi
fi

print_header "🎊 Happy coding!"
