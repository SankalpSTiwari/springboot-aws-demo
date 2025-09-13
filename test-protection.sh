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
