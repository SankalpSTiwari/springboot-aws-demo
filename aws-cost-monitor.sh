#!/bin/bash

# AWS Cost Monitoring and Auto-Shutdown Script
# This script monitors AWS costs and automatically stops services if charges exceed threshold

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
    echo -e "${BLUE}[COST-MONITOR]${NC} $1"
}

# Configuration
COST_THRESHOLD=${1:-5.00}  # Default $5 threshold
REGION=${2:-us-east-1}     # Default region
INSTANCE_ID_FILE="ec2-instance-info.txt"

print_header "🛡️ AWS Cost Monitor & Auto-Shutdown"
echo "========================================"
print_status "Cost Threshold: \$${COST_THRESHOLD}"
print_status "Region: ${REGION}"
echo ""

# Function to get current month's costs
get_current_costs() {
    # macOS compatible date commands
    local start_date=$(date -j -f "%Y-%m-%d" "$(date +%Y-%m)-01" +%Y-%m-%d 2>/dev/null || date +%Y-%m-01)
    local end_date=$(date +%Y-%m-%d)
    
    # Removed the print statement to avoid output in subshell
    
    # Get billing data (requires billing permissions)
    local cost_result=$(aws ce get-cost-and-usage \
        --time-period Start=${start_date},End=${end_date} \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --region us-east-1 \
        --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
        --output text 2>/dev/null)
    
    # Return 0 if no result or error
    if [ $? -ne 0 ] || [ -z "$cost_result" ] || [ "$cost_result" = "None" ]; then
        echo "0.00"
    else
        echo "$cost_result"
    fi
}

# Function to get EC2 instance ID from info file
get_instance_id() {
    if [ -f "$INSTANCE_ID_FILE" ]; then
        grep "Instance ID:" "$INSTANCE_ID_FILE" | cut -d' ' -f3
    else
        print_warning "Instance info file not found. Please provide instance ID manually."
        echo ""
    fi
}

# Function to stop EC2 instance
stop_ec2_instance() {
    local instance_id=$1
    if [ -n "$instance_id" ]; then
        print_warning "🛑 STOPPING EC2 instance: $instance_id"
        aws ec2 stop-instances --instance-ids "$instance_id" --region "$REGION"
        print_status "✅ EC2 instance stopped successfully"
    else
        print_error "No instance ID provided"
    fi
}

# Function to terminate EC2 instance (more aggressive)
terminate_ec2_instance() {
    local instance_id=$1
    if [ -n "$instance_id" ]; then
        print_error "🔥 TERMINATING EC2 instance: $instance_id"
        print_warning "This will PERMANENTLY DELETE the instance!"
        read -p "Are you sure you want to terminate? (yes/NO): " confirm
        if [ "$confirm" = "yes" ]; then
            aws ec2 terminate-instances --instance-ids "$instance_id" --region "$REGION"
            print_status "✅ EC2 instance terminated"
        else
            print_status "Termination cancelled"
        fi
    else
        print_error "No instance ID provided"
    fi
}

# Function to list all running instances
list_running_instances() {
    print_status "📋 Listing all running EC2 instances..."
    aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].[InstanceId,InstanceType,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
        --output table \
        --region "$REGION"
}

# Function to get free tier usage
check_free_tier_usage() {
    print_status "📊 Checking Free Tier usage..."
    
    # Get current date range
    local start_date=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d)
    local end_date=$(date +%Y-%m-%d)
    
    # Check EC2 usage (750 hours free per month)
    print_status "EC2 Free Tier Usage:"
    aws ce get-dimension-values \
        --time-period Start=${start_date},End=${end_date} \
        --dimension SERVICE \
        --context COST_AND_USAGE \
        --search-string "Amazon Elastic Compute Cloud" \
        --region us-east-1 \
        --query 'DimensionValues[].Value' \
        --output text 2>/dev/null || print_warning "Unable to fetch free tier data"
}

# Function to set up billing alerts
setup_billing_alerts() {
    local threshold=$1
    print_status "⚠️ Setting up billing alert for $${threshold}..."
    
    # Create SNS topic for billing alerts
    local topic_arn=$(aws sns create-topic \
        --name "aws-billing-alert" \
        --region us-east-1 \
        --query 'TopicArn' \
        --output text 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$topic_arn" ]; then
        print_status "✅ SNS topic created: $topic_arn"
        
        # Subscribe email to topic (you'll need to confirm)
        read -p "Enter your email for billing alerts: " email
        if [ -n "$email" ]; then
            aws sns subscribe \
                --topic-arn "$topic_arn" \
                --protocol email \
                --notification-endpoint "$email" \
                --region us-east-1
            print_status "✅ Email subscription created (check your email to confirm)"
        fi
        
        # Create CloudWatch alarm
        aws cloudwatch put-metric-alarm \
            --alarm-name "BillingAlert" \
            --alarm-description "Alert when AWS charges exceed threshold" \
            --metric-name EstimatedCharges \
            --namespace AWS/Billing \
            --statistic Maximum \
            --period 86400 \
            --threshold "$threshold" \
            --comparison-operator GreaterThanThreshold \
            --dimensions Name=Currency,Value=USD \
            --evaluation-periods 1 \
            --alarm-actions "$topic_arn" \
            --region us-east-1
        
        print_status "✅ CloudWatch billing alarm created"
    else
        print_error "Failed to create SNS topic"
    fi
}

# Main monitoring function
monitor_costs() {
    print_header "💰 Current AWS Costs"
    
    # Get current costs (suppress the "Checking costs" message in subshell)
    current_cost=$(get_current_costs 2>/dev/null)
    
    # Show what period we're checking
    local start_date=$(date -j -f "%Y-%m-%d" "$(date +%Y-%m)-01" +%Y-%m-%d 2>/dev/null || date +%Y-%m-01)
    local end_date=$(date +%Y-%m-%d)
    print_status "Checking period: ${start_date} to ${end_date}"
    
    if [ "$current_cost" != "0" ] && [ "$current_cost" != "0.00" ] && [ -n "$current_cost" ]; then
        print_status "Current month charges: \$${current_cost}"
        
        # Compare with threshold (using bc for floating point comparison)
        if command -v bc &> /dev/null; then
            if (( $(echo "$current_cost > $COST_THRESHOLD" | bc -l) )); then
                print_error "🚨 COST ALERT: Charges (\$${current_cost}) exceed threshold (\$${COST_THRESHOLD})!"
                
                # Get instance ID
                instance_id=$(get_instance_id)
                
                if [ -n "$instance_id" ]; then
                    print_warning "Auto-stopping EC2 instance to prevent further charges..."
                    stop_ec2_instance "$instance_id"
                    
                    # Send notification
                    echo "AWS Cost Alert: Charges exceeded \$${COST_THRESHOLD}. EC2 instance $instance_id has been stopped." | \
                        mail -s "AWS Cost Alert - Services Stopped" ${USER}@$(hostname) 2>/dev/null || true
                else
                    print_warning "No instance ID found. Please stop services manually."
                fi
                
                return 1
            else
                print_status "✅ Costs are within threshold (\$${current_cost} < \$${COST_THRESHOLD})"
            fi
        else
            print_warning "bc not available for cost comparison. Install with: brew install bc"
            # Fallback comparison without bc
            if [ "$(echo "$current_cost" | cut -d'.' -f1)" -gt "$(echo "$COST_THRESHOLD" | cut -d'.' -f1)" ]; then
                print_error "🚨 COST ALERT: Charges (\$${current_cost}) may exceed threshold (\$${COST_THRESHOLD})!"
                print_warning "Install 'bc' for accurate cost comparison: brew install bc"
            else
                print_status "✅ Costs appear to be within threshold (rough comparison)"
            fi
        fi
    else
        print_status "✅ No charges detected this month (or billing data unavailable)"
        print_status "💡 Note: Billing data may take 24-48 hours to appear"
    fi
    
    return 0
}

# Function to create a cron job for monitoring
setup_cron_monitoring() {
    local script_path=$(realpath "$0")
    local cron_entry="0 */6 * * * $script_path $COST_THRESHOLD $REGION >> /tmp/aws-cost-monitor.log 2>&1"
    
    print_status "Setting up cron job for automated monitoring..."
    
    # Add to crontab (check every 6 hours)
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
    
    print_status "✅ Cron job added - monitoring every 6 hours"
    print_status "Log file: /tmp/aws-cost-monitor.log"
}

# Command line options
case "${3:-monitor}" in
    "monitor")
        monitor_costs
        ;;
    "setup-alerts")
        setup_billing_alerts "$COST_THRESHOLD"
        ;;
    "setup-cron")
        setup_cron_monitoring
        ;;
    "list")
        list_running_instances
        ;;
    "stop")
        instance_id=$(get_instance_id)
        stop_ec2_instance "$instance_id"
        ;;
    "terminate")
        instance_id=$(get_instance_id)
        terminate_ec2_instance "$instance_id"
        ;;
    "free-tier")
        check_free_tier_usage
        ;;
    *)
        echo "Usage: $0 [THRESHOLD] [REGION] [ACTION]"
        echo ""
        echo "THRESHOLD: Cost threshold in USD (default: 5.00)"
        echo "REGION: AWS region (default: us-east-1)"
        echo "ACTION: monitor|setup-alerts|setup-cron|list|stop|terminate|free-tier"
        echo ""
        echo "Examples:"
        echo "  $0                           # Monitor with \$5 threshold"
        echo "  $0 10.00                     # Monitor with \$10 threshold"
        echo "  $0 5.00 us-east-1 setup-alerts  # Set up billing alerts"
        echo "  $0 5.00 us-east-1 setup-cron    # Set up automated monitoring"
        echo "  $0 5.00 us-east-1 list          # List running instances"
        echo "  $0 5.00 us-east-1 stop          # Stop EC2 instance"
        echo "  $0 5.00 us-east-1 terminate     # Terminate EC2 instance"
        echo "  $0 5.00 us-east-1 free-tier     # Check free tier usage"
        ;;
esac

print_header "🛡️ Cost monitoring complete!"
