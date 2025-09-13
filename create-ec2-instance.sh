#!/bin/bash

# Script to create EC2 instance for Spring Boot deployment
# This script uses AWS CLI to create a t2.micro instance (free tier)

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
    echo -e "${BLUE}[AWS]${NC} $1"
}

# Configuration
INSTANCE_NAME="springboot-aws-demo"
SECURITY_GROUP_NAME="springboot-demo-sg"
KEY_PAIR_NAME="springboot-demo-key"
INSTANCE_TYPE="t2.micro"
REGION="us-east-1"

print_header "🚀 Creating EC2 Instance for Spring Boot Deployment"
echo "=================================================="

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first:"
    echo "  - macOS: brew install awscli"
    echo "  - Linux: pip install awscli"
    echo "  - Windows: Download from AWS website"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Run 'aws configure' first."
    exit 1
fi

print_status "✅ AWS CLI configured"

# Get the latest Amazon Linux 2023 AMI ID
print_status "Getting latest Amazon Linux 2023 AMI..."
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-*" \
              "Name=architecture,Values=x86_64" \
              "Name=virtualization-type,Values=hvm" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text \
    --region $REGION)

if [ -z "$AMI_ID" ]; then
    print_error "Failed to get AMI ID"
    exit 1
fi

print_status "Using AMI: $AMI_ID"

# Create key pair if it doesn't exist
print_status "Creating key pair..."
if aws ec2 describe-key-pairs --key-names $KEY_PAIR_NAME --region $REGION &> /dev/null; then
    print_warning "Key pair '$KEY_PAIR_NAME' already exists"
else
    aws ec2 create-key-pair \
        --key-name $KEY_PAIR_NAME \
        --query 'KeyMaterial' \
        --output text \
        --region $REGION > ${KEY_PAIR_NAME}.pem
    
    chmod 400 ${KEY_PAIR_NAME}.pem
    print_status "✅ Key pair created: ${KEY_PAIR_NAME}.pem"
fi

# Create security group if it doesn't exist
print_status "Creating security group..."
if aws ec2 describe-security-groups --group-names $SECURITY_GROUP_NAME --region $REGION &> /dev/null; then
    print_warning "Security group '$SECURITY_GROUP_NAME' already exists"
    SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
        --group-names $SECURITY_GROUP_NAME \
        --query 'SecurityGroups[0].GroupId' \
        --output text \
        --region $REGION)
else
    SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        --group-name $SECURITY_GROUP_NAME \
        --description "Security group for Spring Boot demo application" \
        --query 'GroupId' \
        --output text \
        --region $REGION)
    
    # Add inbound rules
    print_status "Configuring security group rules..."
    
    # SSH access
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    # HTTP access
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    # Spring Boot application port
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 8080 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    print_status "✅ Security group created: $SECURITY_GROUP_ID"
fi

# Launch EC2 instance
print_status "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_PAIR_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region $REGION)

print_status "✅ Instance launched: $INSTANCE_ID"

# Wait for instance to be running
print_status "Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text \
    --region $REGION)

# Wait a bit more for SSH to be ready
print_status "Waiting for SSH service to be ready..."
sleep 30

# Test SSH connection
print_status "Testing SSH connection..."
for i in {1..5}; do
    if ssh -i ${KEY_PAIR_NAME}.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP "echo 'SSH ready'" &> /dev/null; then
        print_status "✅ SSH connection successful"
        break
    else
        print_status "SSH not ready, waiting... (attempt $i/5)"
        sleep 10
    fi
done

# Display results
print_header "🎉 EC2 Instance Created Successfully!"
echo "=================================="
print_status "Instance Details:"
echo "  🆔 Instance ID: $INSTANCE_ID"
echo "  🌐 Public IP: $PUBLIC_IP"
echo "  🔑 Key File: ${KEY_PAIR_NAME}.pem"
echo "  🛡️  Security Group: $SECURITY_GROUP_ID"
echo ""
print_status "Next Steps:"
echo "  1. Deploy your application:"
echo "     ./deploy-to-ec2.sh ${KEY_PAIR_NAME}.pem $PUBLIC_IP"
echo ""
echo "  2. SSH into the instance:"
echo "     ssh -i ${KEY_PAIR_NAME}.pem ec2-user@$PUBLIC_IP"
echo ""
echo "  3. Access your app (after deployment):"
echo "     http://$PUBLIC_IP:8080"
echo ""
print_warning "⚠️  Remember to terminate the instance when done to avoid charges:"
echo "     aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION"
echo ""
print_status "💡 Instance will be free for 750 hours/month for the first 12 months"

# Save instance info to file
cat > ec2-instance-info.txt << EOF
EC2 Instance Information
========================
Instance ID: $INSTANCE_ID
Public IP: $PUBLIC_IP
Key File: ${KEY_PAIR_NAME}.pem
Security Group: $SECURITY_GROUP_ID
Region: $REGION
Created: $(date)

SSH Command:
ssh -i ${KEY_PAIR_NAME}.pem ec2-user@$PUBLIC_IP

Deploy Command:
./deploy-to-ec2.sh ${KEY_PAIR_NAME}.pem $PUBLIC_IP

Terminate Command:
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
EOF

print_status "✅ Instance info saved to ec2-instance-info.txt"
