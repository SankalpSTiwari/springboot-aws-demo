# AWS EC2 Free Tier Deployment Guide

This guide will help you deploy your Spring Boot application to AWS EC2 using the free tier resources.

## Prerequisites

- AWS Account (with free tier eligibility)
- AWS CLI installed and configured
- Your application JAR file built locally

## Step 1: Launch EC2 Instance (Free Tier)

### Using AWS Console

1. **Login to AWS Console** and navigate to EC2 Dashboard

2. **Launch Instance:**

   - Click "Launch Instance"
   - **Name:** `springboot-aws-demo`
   - **AMI:** Amazon Linux 2023 AMI (Free tier eligible)
   - **Instance Type:** t2.micro (Free tier eligible)
   - **Key Pair:** Create a new key pair or use existing
     - Download the `.pem` file and keep it secure
   - **Network Settings:**
     - Allow SSH traffic from your IP
     - Allow HTTP traffic from internet
     - Allow HTTPS traffic from internet (optional)

3. **Configure Security Group:**

   ```
   Type        Protocol    Port Range    Source
   SSH         TCP         22           Your IP/0.0.0.0/0
   HTTP        TCP         80           0.0.0.0/0
   Custom TCP  TCP         8080         0.0.0.0/0
   ```

4. **Launch Instance**

### Using AWS CLI (Alternative)

```bash
# Create security group
aws ec2 create-security-group \
    --group-name springboot-demo-sg \
    --description "Security group for Spring Boot demo"

# Add inbound rules
aws ec2 authorize-security-group-ingress \
    --group-name springboot-demo-sg \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name springboot-demo-sg \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name springboot-demo-sg \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0

# Launch instance
aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --count 1 \
    --instance-type t2.micro \
    --key-name your-key-pair \
    --security-groups springboot-demo-sg
```

## Step 2: Build and Prepare Application

1. **Build the JAR file locally:**

   ```bash
   cd /Users/sankalptiwari/Desktop/my_projects/springboot-aws-demo
   mvn clean package -DskipTests
   ```

2. **Verify JAR file exists:**
   ```bash
   ls -la target/springboot-aws-demo-0.0.1-SNAPSHOT.jar
   ```

## Step 3: Deploy to EC2

1. **Get your EC2 instance public IP:**

   - From AWS Console → EC2 → Instances
   - Note the "Public IPv4 address"

2. **Upload JAR file to EC2:**

   ```bash
   # Replace with your key file and EC2 IP
   scp -i your-key.pem target/springboot-aws-demo-0.0.1-SNAPSHOT.jar ec2-user@YOUR-EC2-IP:/home/ec2-user/
   ```

3. **Upload deployment script:**

   ```bash
   scp -i your-key.pem ec2-deployment.sh ec2-user@YOUR-EC2-IP:/home/ec2-user/
   ```

4. **Connect to EC2 and run deployment:**

   ```bash
   # SSH into EC2
   ssh -i your-key.pem ec2-user@YOUR-EC2-IP

   # Make script executable and run
   chmod +x ec2-deployment.sh
   ./ec2-deployment.sh
   ```

## Step 4: Access Your Application

After successful deployment, your application will be available at:

- **Direct Access:** `http://YOUR-EC2-IP:8080`
- **Via Nginx:** `http://YOUR-EC2-IP`

### Test Endpoints:

```bash
# Health check
curl http://YOUR-EC2-IP/actuator/health

# Hello endpoint
curl http://YOUR-EC2-IP/api/hello

# Get all users
curl http://YOUR-EC2-IP/api/users
```

## Step 5: Monitoring and Management

### Service Management Commands:

```bash
# Check application status
sudo systemctl status springboot-app

# View application logs
sudo journalctl -u springboot-app -f

# Restart application
sudo systemctl restart springboot-app

# Stop application
sudo systemctl stop springboot-app
```

### System Monitoring:

```bash
# Check system resources
top
htop  # if installed
df -h  # disk usage
free -h  # memory usage
```

## Cost Optimization Tips

1. **Use Free Tier Limits:**

   - t2.micro instance: 750 hours/month (free for 12 months)
   - 30 GB EBS storage (free for 12 months)
   - 15 GB data transfer out (free for 12 months)

2. **Monitor Usage:**

   - Set up billing alerts
   - Use AWS Cost Explorer
   - Monitor CloudWatch metrics

3. **Stop Instance When Not Needed:**

   ```bash
   # Stop instance (saves compute costs)
   aws ec2 stop-instances --instance-ids i-your-instance-id

   # Start instance when needed
   aws ec2 start-instances --instance-ids i-your-instance-id
   ```

## Troubleshooting

### Common Issues:

1. **Application won't start:**

   ```bash
   # Check Java version
   java -version

   # Check service logs
   sudo journalctl -u springboot-app -n 50
   ```

2. **Can't access from browser:**

   - Verify security group allows port 8080 and 80
   - Check if application is running: `sudo systemctl status springboot-app`
   - Verify nginx is running: `sudo systemctl status nginx`

3. **Out of memory:**
   - Modify JVM options in service file:
     ```
     ExecStart=/usr/bin/java -Xmx400m -Xms200m -jar ...
     ```

### Useful Commands:

```bash
# Check open ports
sudo netstat -tlnp

# Check application process
ps aux | grep java

# Monitor system resources
watch -n 1 'free -h && df -h'
```

## Security Best Practices

1. **Restrict SSH Access:**

   - Use your specific IP instead of 0.0.0.0/0 for SSH

2. **Regular Updates:**

   ```bash
   sudo yum update -y
   ```

3. **Firewall Configuration:**

   ```bash
   # Enable firewall
   sudo systemctl enable firewalld
   sudo systemctl start firewalld

   # Allow specific ports
   sudo firewall-cmd --permanent --add-port=80/tcp
   sudo firewall-cmd --permanent --add-port=8080/tcp
   sudo firewall-cmd --reload
   ```

4. **SSL Certificate (Optional):**
   - Use Let's Encrypt for free SSL certificates
   - Configure nginx with HTTPS

## Next Steps

1. **Set up monitoring** with CloudWatch
2. **Configure automated backups**
3. **Set up CI/CD pipeline** for automated deployments
4. **Consider using Application Load Balancer** for high availability
5. **Set up RDS database** for production data persistence

## Support

If you encounter issues:

1. Check the deployment logs
2. Verify security group settings
3. Ensure the JAR file is properly uploaded
4. Check AWS free tier limits

---

**Note:** This setup uses the H2 in-memory database for simplicity. For production use, consider setting up RDS PostgreSQL (also available in free tier with limitations).
