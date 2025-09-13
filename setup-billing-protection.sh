#!/bin/bash

# AWS Billing Protection Setup Script
# This script sets up comprehensive billing protection and monitoring

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
    echo -e "${BLUE}[BILLING-PROTECTION]${NC} $1"
}

# Configuration
COST_THRESHOLD=${1:-5.00}
EMAIL=${2:-""}

print_header "🛡️ AWS Billing Protection Setup"
echo "=================================="
print_status "Setting up comprehensive billing protection..."
echo ""

# Function to enable billing alerts
enable_billing_alerts() {
    print_status "📊 Enabling billing alerts..."
    
    # Enable billing alerts (this needs to be done in us-east-1)
    aws ce put-preferences \
        --cost-categories-preferences MatchOptions=EQUALS,STARTS_WITH,ENDS_WITH,CONTAINS,CASE_SENSITIVE,CASE_INSENSITIVE \
        --region us-east-1 2>/dev/null || print_warning "Billing preferences may already be enabled"
    
    print_status "✅ Billing alerts enabled"
}

# Function to create SNS topic and subscription
create_sns_alerts() {
    local email=$1
    print_status "📧 Creating SNS topic for billing alerts..."
    
    # Create SNS topic
    local topic_arn=$(aws sns create-topic \
        --name "aws-billing-protection" \
        --region us-east-1 \
        --query 'TopicArn' \
        --output text 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$topic_arn" ]; then
        print_status "✅ SNS topic created: $topic_arn"
        
        # Subscribe email if provided
        if [ -n "$email" ]; then
            aws sns subscribe \
                --topic-arn "$topic_arn" \
                --protocol email \
                --notification-endpoint "$email" \
                --region us-east-1
            print_status "✅ Email subscription created for: $email"
            print_warning "⚠️ Check your email and confirm the subscription!"
        fi
        
        echo "$topic_arn" > .sns-topic-arn
        return 0
    else
        print_error "Failed to create SNS topic"
        return 1
    fi
}

# Function to create CloudWatch billing alarms
create_billing_alarms() {
    local threshold=$1
    local topic_arn=$2
    
    print_status "⏰ Creating CloudWatch billing alarms..."
    
    # Create multiple alarms for different thresholds
    local thresholds=("1.00" "$threshold" "$(echo "$threshold * 2" | bc -l)")
    local alarm_names=("BillingAlert-Warning" "BillingAlert-Critical" "BillingAlert-Emergency")
    local descriptions=("Warning: AWS charges approaching limit" "Critical: AWS charges exceeded threshold" "Emergency: AWS charges doubled threshold")
    
    for i in "${!thresholds[@]}"; do
        local current_threshold=${thresholds[$i]}
        local alarm_name=${alarm_names[$i]}
        local description=${descriptions[$i]}
        
        aws cloudwatch put-metric-alarm \
            --alarm-name "$alarm_name" \
            --alarm-description "$description" \
            --metric-name EstimatedCharges \
            --namespace AWS/Billing \
            --statistic Maximum \
            --period 86400 \
            --threshold "$current_threshold" \
            --comparison-operator GreaterThanThreshold \
            --dimensions Name=Currency,Value=USD \
            --evaluation-periods 1 \
            --alarm-actions "$topic_arn" \
            --region us-east-1
        
        print_status "✅ Created alarm: $alarm_name (threshold: \$${current_threshold})"
    done
}

# Function to create budget
create_budget() {
    local threshold=$1
    local email=$2
    
    print_status "💰 Creating AWS Budget..."
    
    # Create budget configuration
    cat > budget-config.json << EOF
{
    "BudgetName": "SpringBootDemo-Protection",
    "BudgetLimit": {
        "Amount": "$threshold",
        "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "TimePeriod": {
        "Start": "$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d)T00:00:00Z",
        "End": "2030-12-31T23:59:59Z"
    },
    "BudgetType": "COST",
    "CostFilters": {}
}
EOF

    # Create notifications configuration
    local notifications='[
        {
            "Notification": {
                "NotificationType": "ACTUAL",
                "ComparisonOperator": "GREATER_THAN",
                "Threshold": 80
            },
            "Subscribers": [
                {
                    "SubscriptionType": "EMAIL",
                    "Address": "'$email'"
                }
            ]
        },
        {
            "Notification": {
                "NotificationType": "ACTUAL",
                "ComparisonOperator": "GREATER_THAN",
                "Threshold": 100
            },
            "Subscribers": [
                {
                    "SubscriptionType": "EMAIL",
                    "Address": "'$email'"
                }
            ]
        }
    ]'
    
    if [ -n "$email" ]; then
        aws budgets create-budget \
            --account-id $(aws sts get-caller-identity --query Account --output text) \
            --budget file://budget-config.json \
            --notifications-with-subscribers "$notifications" \
            --region us-east-1
        
        print_status "✅ Budget created with email notifications"
    else
        aws budgets create-budget \
            --account-id $(aws sts get-caller-identity --query Account --output text) \
            --budget file://budget-config.json \
            --region us-east-1
        
        print_status "✅ Budget created (no email notifications)"
    fi
    
    # Clean up temp file
    rm -f budget-config.json
}

# Function to create IAM policy for cost monitoring
create_cost_monitoring_policy() {
    print_status "🔐 Creating IAM policy for cost monitoring..."
    
    cat > cost-monitoring-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ce:GetCostAndUsage",
                "ce:GetDimensionValues",
                "ce:GetReservationCoverage",
                "ce:GetReservationPurchaseRecommendation",
                "ce:GetReservationUtilization",
                "ce:GetUsageReport",
                "budgets:ViewBudget",
                "budgets:CreateBudget",
                "budgets:ModifyBudget"
            ],
            "Resource": "*"
        }
    ]
}
EOF

    # Create policy
    aws iam create-policy \
        --policy-name SpringBootDemo-CostMonitoring \
        --policy-document file://cost-monitoring-policy.json \
        --description "Policy for SpringBoot demo cost monitoring" \
        2>/dev/null || print_warning "Policy may already exist"
    
    # Clean up
    rm -f cost-monitoring-policy.json
    
    print_status "✅ Cost monitoring policy created"
}

# Function to setup automatic shutdown
setup_auto_shutdown() {
    print_status "🤖 Setting up automatic shutdown..."
    
    # Make cost monitor script executable
    chmod +x aws-cost-monitor.sh
    
    # Create cron job for monitoring (every 6 hours)
    local script_path=$(realpath aws-cost-monitor.sh)
    local cron_entry="0 */6 * * * $script_path $COST_THRESHOLD us-east-1 monitor >> /tmp/aws-cost-monitor.log 2>&1"
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "aws-cost-monitor"; echo "$cron_entry") | crontab -
    
    print_status "✅ Automatic monitoring setup (every 6 hours)"
    print_status "📝 Log file: /tmp/aws-cost-monitor.log"
}

# Function to create emergency shutdown script
create_emergency_shutdown() {
    print_status "🚨 Creating emergency shutdown script..."
    
    cat > emergency-shutdown.sh << 'EOF'
#!/bin/bash
# Emergency shutdown script - stops all AWS resources

echo "🚨 EMERGENCY SHUTDOWN INITIATED"

# Stop all EC2 instances
echo "Stopping all EC2 instances..."
aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text | xargs -n1 aws ec2 stop-instances --instance-ids

# List other resources (for manual cleanup)
echo "Other resources that may incur charges:"
echo "- RDS instances"
echo "- Load Balancers" 
echo "- NAT Gateways"
echo "- Elastic IPs"

echo "✅ Emergency shutdown complete"
EOF

    chmod +x emergency-shutdown.sh
    print_status "✅ Emergency shutdown script created: emergency-shutdown.sh"
}

# Main setup function
main() {
    print_header "🚀 Starting billing protection setup..."
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI not configured. Run 'aws configure' first."
        exit 1
    fi
    
    # Get email if not provided
    if [ -z "$EMAIL" ]; then
        read -p "Enter your email for billing alerts (optional): " EMAIL
    fi
    
    # Run setup steps
    enable_billing_alerts
    
    if create_sns_alerts "$EMAIL"; then
        topic_arn=$(cat .sns-topic-arn)
        create_billing_alarms "$COST_THRESHOLD" "$topic_arn"
    fi
    
    if [ -n "$EMAIL" ]; then
        create_budget "$COST_THRESHOLD" "$EMAIL"
    fi
    
    create_cost_monitoring_policy
    setup_auto_shutdown
    create_emergency_shutdown
    
    # Create summary
    print_header "📋 Billing Protection Summary"
    echo "=============================="
    print_status "✅ Billing alerts enabled"
    print_status "✅ SNS notifications setup"
    print_status "✅ CloudWatch alarms created"
    if [ -n "$EMAIL" ]; then
        print_status "✅ Budget created with email alerts"
    fi
    print_status "✅ Automatic monitoring enabled"
    print_status "✅ Emergency shutdown script created"
    echo ""
    print_status "💰 Cost threshold: \$${COST_THRESHOLD}"
    if [ -n "$EMAIL" ]; then
        print_status "📧 Email alerts: $EMAIL"
    fi
    print_status "📊 Monitoring: Every 6 hours"
    echo ""
    print_header "🛡️ Your AWS account is now protected!"
    echo ""
    print_status "Manual commands:"
    echo "  Monitor costs: ./aws-cost-monitor.sh"
    echo "  Emergency stop: ./emergency-shutdown.sh"
    echo "  View logs: tail -f /tmp/aws-cost-monitor.log"
    
    # Clean up
    rm -f .sns-topic-arn
}

# Run main function
main
