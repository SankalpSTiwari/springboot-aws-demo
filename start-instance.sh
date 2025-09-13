#!/bin/bash
echo "🚀 Starting EC2 Instance..."
aws ec2 start-instances --instance-ids i-06be8249f6ef53137 --region us-east-1

echo "⏳ Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids i-06be8249f6ef53137 --region us-east-1

echo "📊 Getting instance details..."
NEW_IP=$(aws ec2 describe-instances --instance-ids i-06be8249f6ef53137 --region us-east-1 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "✅ Instance is running!"
echo "🌐 New IP Address: $NEW_IP"
echo "🔗 Application URL: http://$NEW_IP:8080/api/hello"

echo "⏳ Waiting for application to start..."
sleep 30

echo "🧪 Testing application..."
curl -s "http://$NEW_IP:8080/api/hello" && echo "" && echo "✅ Application is ready!"
