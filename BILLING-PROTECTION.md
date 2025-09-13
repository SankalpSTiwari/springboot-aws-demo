# 🛡️ AWS Billing Protection Guide

This guide provides comprehensive protection against unexpected AWS charges with automated monitoring and shutdown capabilities.

## 🚨 Quick Emergency Actions

### Immediate Cost Protection

```bash
# 1. Stop all services immediately
./emergency-shutdown.sh

# 2. Monitor current costs
./aws-cost-monitor.sh

# 3. Check what's still running
./aws-cost-monitor.sh 5.00 us-east-1 list
```

## ⚡ One-Time Setup

### Complete Billing Protection Setup

```bash
# Set up all billing protection (interactive)
./setup-billing-protection.sh

# Or with parameters
./setup-billing-protection.sh 5.00 your-email@example.com
```

This sets up:

- ✅ **Billing alerts** in AWS Console
- ✅ **Email notifications** for cost thresholds
- ✅ **CloudWatch alarms** (Warning, Critical, Emergency)
- ✅ **AWS Budget** with automatic alerts
- ✅ **Automated monitoring** every 6 hours
- ✅ **Auto-shutdown** when costs exceed threshold

## 📊 Cost Monitoring

### Manual Cost Checks

```bash
# Check current costs (default $5 threshold)
./aws-cost-monitor.sh

# Check with custom threshold
./aws-cost-monitor.sh 10.00

# Check free tier usage
./aws-cost-monitor.sh 5.00 us-east-1 free-tier

# List all running instances
./aws-cost-monitor.sh 5.00 us-east-1 list
```

### Automated Monitoring

The setup script creates a cron job that:

- ✅ **Runs every 6 hours**
- ✅ **Checks current costs**
- ✅ **Auto-stops EC2** if threshold exceeded
- ✅ **Logs to** `/tmp/aws-cost-monitor.log`

## 🛑 Emergency Shutdown Options

### 1. Stop All Services (Reversible)

```bash
./emergency-shutdown.sh
```

**What it does:**

- Stops all EC2 instances (can restart later)
- Stops RDS databases
- Deletes load balancers
- Deletes NAT gateways
- Releases unattached Elastic IPs
- Stops ECS services

### 2. Stop Just Your Spring Boot Instance

```bash
./aws-cost-monitor.sh 0.01 us-east-1 stop
```

### 3. Terminate Everything (PERMANENT)

```bash
# This will be created by emergency-shutdown.sh
./complete-termination.sh
```

⚠️ **WARNING**: This permanently deletes ALL resources!

## 💰 Cost Thresholds & Alerts

### Default Protection Levels

- **$1.00** - Warning alert
- **$5.00** - Critical alert + auto-shutdown
- **$10.00** - Emergency alert

### Free Tier Limits

- **EC2**: 750 hours/month (t2.micro)
- **EBS**: 30 GB storage
- **Data Transfer**: 15 GB/month
- **RDS**: 750 hours/month (db.t2.micro)

## 📧 Email Notifications

You'll receive emails for:

- ✅ **80% of budget** reached
- ✅ **100% of budget** exceeded
- ✅ **CloudWatch alarms** triggered
- ✅ **Auto-shutdown** events

## 🔍 Monitoring & Logs

### View Monitoring Logs

```bash
# Real-time monitoring
tail -f /tmp/aws-cost-monitor.log

# Emergency shutdown log
tail -f /tmp/aws-emergency-shutdown.log

# Check cron job status
crontab -l | grep aws-cost-monitor
```

### AWS Console Monitoring

1. **CloudWatch** → Alarms → Billing
2. **Billing** → Budgets
3. **Cost Explorer** → Cost and Usage

## 🛠️ Manual Commands

### Cost Management

```bash
# Check current month costs
aws ce get-cost-and-usage \
  --time-period Start=2025-09-01,End=2025-09-30 \
  --granularity MONTHLY \
  --metrics BlendedCost

# List all running instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,PublicIpAddress]' \
  --output table

# Stop specific instance
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Terminate specific instance (PERMANENT)
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
```

### Billing Alerts

```bash
# Create billing alarm manually
aws cloudwatch put-metric-alarm \
  --alarm-name "BillingAlert" \
  --alarm-description "Alert when charges exceed $5" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 5.0 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD \
  --evaluation-periods 1 \
  --region us-east-1
```

## 🔧 Troubleshooting

### Common Issues

1. **"Access Denied" for billing APIs**

   ```bash
   # Add billing permissions to your user
   aws iam attach-user-policy \
     --user-name your-username \
     --policy-arn arn:aws:iam::aws:policy/job-function/Billing
   ```

2. **Cron job not working**

   ```bash
   # Check cron service
   sudo service cron status

   # Test script manually
   ./aws-cost-monitor.sh 5.00 us-east-1 monitor
   ```

3. **Email notifications not received**
   - Check spam folder
   - Confirm SNS subscription in email
   - Verify email address in AWS Console

### Script Permissions

```bash
# Fix script permissions
chmod +x *.sh

# Check AWS CLI configuration
aws configure list
aws sts get-caller-identity
```

## 📋 Cost Optimization Tips

### Free Tier Best Practices

1. **Use t2.micro instances only**
2. **Stop instances when not needed**
3. **Monitor data transfer usage**
4. **Delete unused EBS volumes**
5. **Clean up old snapshots**

### Regular Maintenance

```bash
# Weekly cost check
./aws-cost-monitor.sh 5.00 us-east-1 monitor

# Monthly cleanup
./aws-cost-monitor.sh 5.00 us-east-1 list
```

## 🚀 Quick Start Checklist

- [ ] Run `./setup-billing-protection.sh your-email@example.com`
- [ ] Confirm email subscription
- [ ] Test monitoring: `./aws-cost-monitor.sh`
- [ ] Verify cron job: `crontab -l`
- [ ] Test emergency shutdown: `./emergency-shutdown.sh` (cancel when prompted)
- [ ] Set up AWS Console billing alerts
- [ ] Add calendar reminder for monthly cost review

## ⚠️ Important Notes

### What Costs Money Even When "Stopped"

- **EBS volumes** (storage charges)
- **Elastic IPs** (if not attached)
- **Snapshots**
- **Load Balancers**
- **NAT Gateways**
- **Data transfer**

### Complete Cost Elimination

To completely avoid ALL charges:

1. **Terminate** (don't just stop) EC2 instances
2. **Delete** all EBS volumes
3. **Delete** all snapshots
4. **Release** all Elastic IPs
5. **Delete** all S3 buckets
6. **Close** AWS account if no longer needed

## 🆘 Emergency Contacts

### If Charges Are Unexpected

1. **AWS Support**: Create a billing support case
2. **AWS Billing**: billing@amazon.com
3. **Emergency shutdown**: `./emergency-shutdown.sh`

### Useful AWS Documentation

- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS Billing and Cost Management](https://docs.aws.amazon.com/awsaccountbilling/)
- [CloudWatch Billing Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html)

---

**🛡️ Your AWS account is now protected against unexpected charges!**

Remember: **Prevention is better than cure** - monitor regularly and stop resources when not needed.
