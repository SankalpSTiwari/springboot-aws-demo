# Deployment Guide

This guide covers different deployment options for the Spring Boot AWS Demo application.

## Table of Contents

1. [Local Development with Docker](#local-development-with-docker)
2. [AWS Elastic Beanstalk Deployment](#aws-elastic-beanstalk-deployment)
3. [AWS EC2 Deployment](#aws-ec2-deployment)
4. [Docker Registry Deployment](#docker-registry-deployment)
5. [Environment Configuration](#environment-configuration)
6. [Monitoring and Health Checks](#monitoring-and-health-checks)

## Local Development with Docker

### Prerequisites
- Docker and Docker Compose installed
- Java 17+ (for local development)
- Maven 3.6+

### Running with Docker Compose

1. **Start the application:**
   ```bash
   docker-compose up --build
   ```

2. **Access the application:**
   - API: http://localhost:8080/api/hello
   - H2 Console: http://localhost:8080/h2-console
   - Health Check: http://localhost:8080/actuator/health

3. **Stop the application:**
   ```bash
   docker-compose down
   ```

### Running with Production Profile
```bash
docker-compose --profile production up --build
```

## AWS Elastic Beanstalk Deployment

### Prerequisites
- AWS CLI configured
- EB CLI installed (`pip install awsebcli`)
- AWS account with appropriate permissions

### Step 1: Initialize Elastic Beanstalk

1. **Initialize EB application:**
   ```bash
   eb init springboot-aws-demo --platform java-17 --region us-east-1
   ```

2. **Create environment:**
   ```bash
   eb create springboot-aws-demo-prod --instance-type t3.micro
   ```

### Step 2: Configure Environment Variables

Set the following environment variables in EB console or via CLI:

```bash
eb setenv SPRING_PROFILES_ACTIVE=production
eb setenv RDS_HOSTNAME=your-rds-endpoint
eb setenv RDS_USERNAME=springbootuser
eb setenv RDS_PASSWORD=your-secure-password
eb setenv RDS_DB_NAME=springbootdemo
```

### Step 3: Deploy

```bash
eb deploy
```

### Step 4: Open Application

```bash
eb open
```

## AWS EC2 Deployment

### Prerequisites
- AWS CLI configured
- EC2 instance with Java 17 installed
- Security groups configured (ports 22, 80, 443, 8080)

### Step 1: Build and Package

```bash
mvn clean package -DskipTests
```

### Step 2: Upload to EC2

```bash
scp -i your-key.pem target/springboot-aws-demo-0.0.1-SNAPSHOT.jar ec2-user@your-ec2-ip:/home/ec2-user/
```

### Step 3: Run on EC2

```bash
ssh -i your-key.pem ec2-user@your-ec2-ip
java -jar -Dspring.profiles.active=production springboot-aws-demo-0.0.1-SNAPSHOT.jar
```

### Step 4: Set up as Service (Optional)

Create a systemd service file:

```bash
sudo nano /etc/systemd/system/springboot-app.service
```

```ini
[Unit]
Description=Spring Boot Application
After=network.target

[Service]
Type=simple
User=ec2-user
ExecStart=/usr/bin/java -jar -Dspring.profiles.active=production /home/ec2-user/springboot-aws-demo-0.0.1-SNAPSHOT.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl enable springboot-app
sudo systemctl start springboot-app
sudo systemctl status springboot-app
```

## Docker Registry Deployment

### GitHub Container Registry

The application is configured to automatically build and push Docker images to GitHub Container Registry.

1. **Manual build and push:**
   ```bash
   docker build -t ghcr.io/your-username/springboot-aws-demo:latest .
   docker push ghcr.io/your-username/springboot-aws-demo:latest
   ```

2. **Pull and run:**
   ```bash
   docker pull ghcr.io/your-username/springboot-aws-demo:latest
   docker run -p 8080:8080 ghcr.io/your-username/springboot-aws-demo:latest
   ```

### Docker Hub

1. **Build and tag:**
   ```bash
   docker build -t your-username/springboot-aws-demo:latest .
   ```

2. **Push to Docker Hub:**
   ```bash
   docker push your-username/springboot-aws-demo:latest
   ```

## Environment Configuration

### Development Environment
- Uses H2 in-memory database
- H2 console enabled
- Detailed logging enabled
- Actuator endpoints exposed

### Production Environment
- Uses PostgreSQL database
- H2 console disabled
- Optimized logging
- Limited actuator endpoints
- Connection pooling configured

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SPRING_PROFILES_ACTIVE` | Active Spring profile | `default` |
| `RDS_HOSTNAME` | Database hostname | `localhost` |
| `RDS_PORT` | Database port | `5432` |
| `RDS_DB_NAME` | Database name | `springbootdemo` |
| `RDS_USERNAME` | Database username | `springbootuser` |
| `RDS_PASSWORD` | Database password | - |
| `SERVER_PORT` | Application port | `8080` |

## Monitoring and Health Checks

### Health Check Endpoints

- **Application Health:** `GET /actuator/health`
- **Custom Health:** `GET /api/health`
- **Application Info:** `GET /actuator/info`
- **Metrics:** `GET /actuator/metrics`

### Monitoring Setup

1. **CloudWatch (AWS):**
   - Enable CloudWatch agent on EC2
   - Set up custom metrics
   - Configure alarms

2. **Application Insights:**
   - Add Spring Boot Actuator
   - Configure custom health indicators
   - Set up log aggregation

### Logging

- Application logs: `/var/log/springboot-app/`
- Access logs: Configured in nginx
- Error logs: Captured by Spring Boot

## Troubleshooting

### Common Issues

1. **Database Connection Issues:**
   - Check RDS security groups
   - Verify connection string
   - Ensure database is accessible

2. **Port Issues:**
   - Check security group settings
   - Verify application port configuration
   - Ensure no port conflicts

3. **Memory Issues:**
   - Adjust JVM heap size
   - Monitor memory usage
   - Consider instance type upgrade

### Useful Commands

```bash
# Check application logs
eb logs

# SSH into EB instance
eb ssh

# Check application status
curl http://localhost:8080/actuator/health

# View application metrics
curl http://localhost:8080/actuator/metrics
```

## Security Considerations

1. **Database Security:**
   - Use strong passwords
   - Enable encryption in transit
   - Restrict network access

2. **Application Security:**
   - Use HTTPS in production
   - Implement authentication/authorization
   - Regular security updates

3. **Infrastructure Security:**
   - Configure security groups properly
   - Use IAM roles with minimal permissions
   - Enable VPC for network isolation

## Cost Optimization

1. **Instance Sizing:**
   - Start with t3.micro for development
   - Monitor and scale as needed
   - Use reserved instances for production

2. **Database Optimization:**
   - Use appropriate instance class
   - Enable automated backups
   - Monitor storage usage

3. **Monitoring Costs:**
   - Set up billing alerts
   - Monitor resource usage
   - Optimize based on metrics
