# Manual Billing Protection Setup

Since your IAM user has limited permissions, follow these steps to complete the setup:

## 1. Add IAM Permissions

Go to AWS Console → IAM → Users → springboot-demo-user → Add permissions:

### Required Policies:
- **Billing**: `arn:aws:iam::aws:policy/job-function/Billing`
- **SNS**: `arn:aws:iam::aws:policy/AmazonSNSFullAccess`
- **CloudWatch**: `arn:aws:iam::aws:policy/CloudWatchFullAccess`
- **Budgets**: `arn:aws:iam::aws:policy/AWSBudgetsActionsWithAWSResourceControlAccess`

### Or create custom policy:
```json
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
```

## 2. Enable Billing Alerts in AWS Console

1. Go to **AWS Console** → **Billing** → **Billing preferences**
2. Check ✅ **"Receive Billing Alerts"**
3. Click **"Save preferences"**

## 3. Set Up Billing Alerts

### Option A: AWS Console (Recommended)
1. **Billing** → **Budgets** → **Create budget**
2. **Budget type**: Cost budget
3. **Budget name**: SpringBoot-Protection
4. **Amount**: $5.00
5. **Email**: sankalp.313@gmail.com
6. **Thresholds**: 80%, 100%

### Option B: CloudWatch Alarms
1. **CloudWatch** → **Alarms** → **Create alarm**
2. **Metric**: Billing → EstimatedCharges
3. **Threshold**: $5.00
4. **Action**: Send notification to sankalp.313@gmail.com

## 4. Test Your Setup

Run these commands to verify:
```bash
# Check current costs
./aws-cost-monitor.sh

# List running instances
./aws-cost-monitor.sh 5.00 us-east-1 list

# Test emergency shutdown (cancel when prompted)
./emergency-shutdown.sh
```

## 5. What's Already Working

✅ **Automated monitoring** every 6 hours
✅ **Auto-shutdown** when costs exceed $5.00
✅ **Emergency shutdown** script ready
✅ **Cost monitoring** commands working

## Current Protection Status

- **Monitoring**: Every 6 hours automatically
- **Threshold**: $5.00 auto-shutdown
- **Instance**: i-06be8249f6ef53137 (t2.micro)
- **Log file**: /tmp/aws-cost-monitor.log

Your basic protection is active! The manual steps above will add email alerts.
