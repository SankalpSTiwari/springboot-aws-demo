#!/bin/bash

# Simplified Billing Protection Setup
# Works with basic IAM permissions

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
    echo -e "${BLUE}[PROTECTION]${NC} $1"
}

EMAIL=${1:-"sankalp.313@gmail.com"}
THRESHOLD=${2:-"5.00"}

print_header "🛡️ Simplified Billing Protection Setup"
echo "========================================"
print_status "Email: $EMAIL"
print_status "Threshold: \$${THRESHOLD}"
echo ""

# Step 1: Set up automated cost monitoring
print_status "⚙️ Setting up automated cost monitoring..."
chmod +x aws-cost-monitor.sh

# Create cron job
SCRIPT_PATH=$(realpath aws-cost-monitor.sh)
CRON_ENTRY="0 */6 * * * $SCRIPT_PATH $THRESHOLD us-east-1 monitor >> /tmp/aws-cost-monitor.log 2>&1"

# Add to crontab (remove existing first)
(crontab -l 2>/dev/null | grep -v "aws-cost-monitor" || true; echo "$CRON_ENTRY") | crontab -

print_status "✅ Automated monitoring setup (every 6 hours)"

# Step 2: Test current setup
print_status "🧪 Testing cost monitoring..."
./aws-cost-monitor.sh $THRESHOLD us-east-1 monitor

# Step 3: Create manual setup instructions
print_status "📝 Creating manual setup guide..."

cat > manual-billing-setup.md << EOF
# Manual Billing Protection Setup

Since your IAM user has limited permissions, follow these steps to complete the setup:

## 1. Add IAM Permissions

Go to AWS Console → IAM → Users → springboot-demo-user → Add permissions:

### Required Policies:
- **Billing**: \`arn:aws:iam::aws:policy/job-function/Billing\`
- **SNS**: \`arn:aws:iam::aws:policy/AmazonSNSFullAccess\`
- **CloudWatch**: \`arn:aws:iam::aws:policy/CloudWatchFullAccess\`
- **Budgets**: \`arn:aws:iam::aws:policy/AWSBudgetsActionsWithAWSResourceControlAccess\`

### Or create custom policy:
\`\`\`json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:*",
                "cloudwatch:*",
                "budgets:*",
                "ce:*"
            ],
            "Resource": "*"
        }
    ]
}
\`\`\`

## 2. Enable Billing Alerts in AWS Console

1. Go to **AWS Console** → **Billing** → **Billing preferences**
2. Check ✅ **"Receive Billing Alerts"**
3. Click **"Save preferences"**

## 3. Set Up Billing Alerts

### Option A: AWS Console (Recommended)
1. **Billing** → **Budgets** → **Create budget**
2. **Budget type**: Cost budget
3. **Budget name**: SpringBoot-Protection
4. **Amount**: \$${THRESHOLD}
5. **Email**: $EMAIL
6. **Thresholds**: 80%, 100%

### Option B: CloudWatch Alarms
1. **CloudWatch** → **Alarms** → **Create alarm**
2. **Metric**: Billing → EstimatedCharges
3. **Threshold**: \$${THRESHOLD}
4. **Action**: Send notification to $EMAIL

## 4. Test Your Setup

Run these commands to verify:
\`\`\`bash
# Check current costs
./aws-cost-monitor.sh

# List running instances
./aws-cost-monitor.sh $THRESHOLD us-east-1 list

# Test emergency shutdown (cancel when prompted)
./emergency-shutdown.sh
\`\`\`

## 5. What's Already Working

✅ **Automated monitoring** every 6 hours
✅ **Auto-shutdown** when costs exceed \$${THRESHOLD}
✅ **Emergency shutdown** script ready
✅ **Cost monitoring** commands working

## Current Protection Status

- **Monitoring**: Every 6 hours automatically
- **Threshold**: \$${THRESHOLD} auto-shutdown
- **Instance**: i-06be8249f6ef53137 (t2.micro)
- **Log file**: /tmp/aws-cost-monitor.log

Your basic protection is active! The manual steps above will add email alerts.
EOF

print_status "✅ Manual setup guide created: manual-billing-setup.md"

# Step 4: Show current status
print_header "📊 Current Protection Status"
echo "============================="
print_status "✅ Automated cost monitoring: Every 6 hours"
print_status "✅ Auto-shutdown threshold: \$${THRESHOLD}"
print_status "✅ Emergency shutdown: ./emergency-shutdown.sh"
print_status "✅ Instance monitoring: EC2 t2.micro"
print_status "✅ Log file: /tmp/aws-cost-monitor.log"
echo ""

print_header "🎯 Next Steps"
echo "=============="
print_status "1. Follow manual-billing-setup.md for email alerts"
print_status "2. Test monitoring: ./aws-cost-monitor.sh"
print_status "3. Check logs: tail -f /tmp/aws-cost-monitor.log"
echo ""

print_header "🛡️ Your AWS account has basic protection!"
print_warning "⚠️  For complete protection, follow the manual setup guide."

# Step 5: Create quick test script
cat > test-protection.sh << 'EOF'
#!/bin/bash
echo "🧪 Testing AWS Cost Protection"
echo "=============================="

echo "1. Current costs:"
./aws-cost-monitor.sh 5.00 us-east-1 monitor

echo ""
echo "2. Running instances:"
./aws-cost-monitor.sh 5.00 us-east-1 list

echo ""
echo "3. Cron job status:"
crontab -l | grep aws-cost-monitor || echo "No cron job found"

echo ""
echo "4. Log file:"
if [ -f /tmp/aws-cost-monitor.log ]; then
    echo "Log exists - last 5 lines:"
    tail -5 /tmp/aws-cost-monitor.log
else
    echo "No log file yet (will be created on first run)"
fi

echo ""
echo "✅ Protection test complete!"
EOF

chmod +x test-protection.sh
print_status "✅ Test script created: ./test-protection.sh"

echo ""
print_header "🎊 Basic billing protection is now active!"
