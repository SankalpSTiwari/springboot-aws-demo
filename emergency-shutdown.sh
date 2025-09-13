#!/bin/bash

# Emergency AWS Shutdown Script
# Immediately stops all AWS resources to prevent charges

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
    echo -e "${BLUE}[EMERGENCY]${NC} $1"
}

print_header "🚨 EMERGENCY AWS SHUTDOWN INITIATED"
echo "===================================="
print_warning "This will stop ALL AWS resources to prevent charges!"
echo ""

# Confirmation prompt
read -p "Are you sure you want to proceed? (type 'SHUTDOWN' to confirm): " confirm
if [ "$confirm" != "SHUTDOWN" ]; then
    print_status "Emergency shutdown cancelled."
    exit 0
fi

echo ""
print_header "🛑 Shutting down AWS resources..."

# Function to stop all EC2 instances
stop_ec2_instances() {
    print_status "Stopping all EC2 instances..."
    
    # Get all running instances
    local running_instances=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text)
    
    if [ -n "$running_instances" ]; then
        echo "$running_instances" | xargs -n1 aws ec2 stop-instances --instance-ids
        print_status "✅ Stopped EC2 instances: $running_instances"
    else
        print_status "No running EC2 instances found"
    fi
}

# Function to stop RDS instances
stop_rds_instances() {
    print_status "Stopping all RDS instances..."
    
    local rds_instances=$(aws rds describe-db-instances \
        --query 'DBInstances[?DBInstanceStatus==`available`].DBInstanceIdentifier' \
        --output text)
    
    if [ -n "$rds_instances" ]; then
        for instance in $rds_instances; do
            aws rds stop-db-instance --db-instance-identifier "$instance" || true
        done
        print_status "✅ Stopped RDS instances: $rds_instances"
    else
        print_status "No running RDS instances found"
    fi
}

# Function to delete load balancers
delete_load_balancers() {
    print_status "Deleting load balancers..."
    
    # ALB/NLB
    local albs=$(aws elbv2 describe-load-balancers \
        --query 'LoadBalancers[].LoadBalancerArn' \
        --output text)
    
    if [ -n "$albs" ]; then
        for alb in $albs; do
            aws elbv2 delete-load-balancer --load-balancer-arn "$alb" || true
        done
        print_status "✅ Deleted Application/Network Load Balancers"
    fi
    
    # Classic Load Balancers
    local clbs=$(aws elb describe-load-balancers \
        --query 'LoadBalancerDescriptions[].LoadBalancerName' \
        --output text)
    
    if [ -n "$clbs" ]; then
        for clb in $clbs; do
            aws elb delete-load-balancer --load-balancer-name "$clb" || true
        done
        print_status "✅ Deleted Classic Load Balancers"
    fi
}

# Function to delete NAT gateways
delete_nat_gateways() {
    print_status "Deleting NAT gateways..."
    
    local nat_gateways=$(aws ec2 describe-nat-gateways \
        --filter "Name=state,Values=available" \
        --query 'NatGateways[].NatGatewayId' \
        --output text)
    
    if [ -n "$nat_gateways" ]; then
        for nat in $nat_gateways; do
            aws ec2 delete-nat-gateway --nat-gateway-id "$nat" || true
        done
        print_status "✅ Deleted NAT gateways: $nat_gateways"
    else
        print_status "No NAT gateways found"
    fi
}

# Function to release Elastic IPs
release_elastic_ips() {
    print_status "Releasing unattached Elastic IPs..."
    
    local eips=$(aws ec2 describe-addresses \
        --query 'Addresses[?AssociationId==null].AllocationId' \
        --output text)
    
    if [ -n "$eips" ]; then
        for eip in $eips; do
            aws ec2 release-address --allocation-id "$eip" || true
        done
        print_status "✅ Released Elastic IPs: $eips"
    else
        print_status "No unattached Elastic IPs found"
    fi
}

# Function to stop ECS services
stop_ecs_services() {
    print_status "Stopping ECS services..."
    
    local clusters=$(aws ecs list-clusters --query 'clusterArns[]' --output text)
    
    for cluster in $clusters; do
        local services=$(aws ecs list-services \
            --cluster "$cluster" \
            --query 'serviceArns[]' \
            --output text)
        
        for service in $services; do
            aws ecs update-service \
                --cluster "$cluster" \
                --service "$service" \
                --desired-count 0 || true
        done
    done
    
    print_status "✅ Stopped ECS services"
}

# Function to terminate Lambda functions (can't stop, but list them)
list_lambda_functions() {
    print_status "Listing Lambda functions (manual cleanup needed)..."
    
    local functions=$(aws lambda list-functions \
        --query 'Functions[].FunctionName' \
        --output text)
    
    if [ -n "$functions" ]; then
        print_warning "Lambda functions found (delete manually if needed): $functions"
    else
        print_status "No Lambda functions found"
    fi
}

# Function to show cost-generating resources
show_cost_resources() {
    print_header "💰 Resources that may still generate costs:"
    echo "============================================="
    print_warning "The following resources may continue to generate charges:"
    echo "  - Stopped EC2 instances (EBS storage charges)"
    echo "  - EBS volumes and snapshots"
    echo "  - S3 buckets and objects"
    echo "  - Route 53 hosted zones"
    echo "  - CloudWatch logs retention"
    echo "  - Data transfer charges"
    echo ""
    print_warning "To completely avoid charges, you may need to:"
    echo "  - Terminate (not just stop) EC2 instances"
    echo "  - Delete EBS volumes and snapshots"
    echo "  - Empty and delete S3 buckets"
    echo "  - Delete CloudWatch log groups"
}

# Function to create termination script
create_termination_script() {
    print_status "Creating complete termination script..."
    
    cat > complete-termination.sh << 'EOF'
#!/bin/bash
# Complete AWS Resource Termination Script
# WARNING: This will PERMANENTLY DELETE all resources

echo "🔥 COMPLETE AWS RESOURCE TERMINATION"
echo "WARNING: This will PERMANENTLY DELETE all resources!"
read -p "Type 'DELETE EVERYTHING' to confirm: " confirm

if [ "$confirm" != "DELETE EVERYTHING" ]; then
    echo "Termination cancelled."
    exit 0
fi

# Terminate all EC2 instances
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text | \
    xargs -n1 aws ec2 terminate-instances --instance-ids

# Delete all EBS volumes
aws ec2 describe-volumes --query 'Volumes[].VolumeId' --output text | \
    xargs -n1 aws ec2 delete-volume --volume-id

# Delete all snapshots
aws ec2 describe-snapshots --owner-ids self --query 'Snapshots[].SnapshotId' --output text | \
    xargs -n1 aws ec2 delete-snapshot --snapshot-id

echo "✅ Complete termination initiated"
EOF

    chmod +x complete-termination.sh
    print_status "✅ Created complete-termination.sh for permanent deletion"
}

# Main execution
main() {
    # Stop compute resources
    stop_ec2_instances
    stop_rds_instances
    stop_ecs_services
    
    # Delete networking resources
    delete_load_balancers
    delete_nat_gateways
    release_elastic_ips
    
    # List other resources
    list_lambda_functions
    
    # Create additional scripts
    create_termination_script
    
    # Show summary
    echo ""
    print_header "🛑 Emergency shutdown complete!"
    echo "================================"
    print_status "✅ All compute resources stopped"
    print_status "✅ Networking resources deleted"
    print_status "✅ Elastic IPs released"
    echo ""
    
    show_cost_resources
    
    echo ""
    print_status "📋 Next steps:"
    echo "  1. Monitor your AWS billing for 24-48 hours"
    echo "  2. Check AWS console for any remaining resources"
    echo "  3. Use complete-termination.sh if you want to delete everything permanently"
    echo "  4. Consider closing AWS account if no longer needed"
    echo ""
    print_header "💡 Emergency shutdown completed successfully!"
}

# Execute main function
main

# Log the shutdown
echo "$(date): Emergency shutdown executed" >> /tmp/aws-emergency-shutdown.log
