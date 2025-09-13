# Spring Boot AWS Demo

A complete Spring Boot application demonstrating REST API development and automated AWS EC2 deployment.

🚀 **Live Demo**: http://3.85.219.17:8080/api/hello

## Features

- REST API with Spring Boot
- JPA/Hibernate with H2 database
- Spring Boot Actuator for monitoring
- Sample User entity and CRUD operations
- **🎯 Automated AWS EC2 deployment scripts**
- **🔧 One-command deployment to AWS Free Tier**
- **📊 Production-ready with Nginx reverse proxy**
- **🔄 Systemd service with auto-restart**

## API Endpoints

### Hello Endpoints

- `GET /api/hello` - Simple hello message
- `GET /api/hello/{name}` - Personalized hello message
- `GET /api/health` - Health check endpoint

### User Endpoints

- `GET /api/users` - Get all users
- `GET /api/users/{id}` - Get user by ID
- `POST /api/users` - Create new user
- `DELETE /api/users/{id}` - Delete user by ID

### Monitoring Endpoints

- `GET /actuator/health` - Application health
- `GET /actuator/info` - Application info
- `GET /actuator/metrics` - Application metrics

### Development Tools

- `GET /h2-console` - H2 Database Console (development only)

## Prerequisites

- Java 17 or higher
- Maven 3.6 or higher
- Git

## Local Development

1. Clone the repository:

```bash
git clone <repository-url>
cd springboot-aws-demo
```

2. Run the application:

```bash
mvn spring-boot:run
```

3. Access the application:

- API: http://localhost:8080/api/hello
- H2 Console: http://localhost:8080/h2-console
- Actuator: http://localhost:8080/actuator/health

## Building the Application

```bash
mvn clean package
```

This creates a JAR file in the `target/` directory.

## 🚀 AWS EC2 Deployment (FREE!)

Deploy your Spring Boot application to AWS EC2 with just **2 simple commands**:

### ⚡ Quick Start (2 Commands)

```bash
# 1. Create EC2 instance (t2.micro - FREE tier)
./create-ec2-instance.sh

# 2. Deploy your application
./deploy-to-ec2.sh springboot-demo-key.pem YOUR-EC2-IP
```

### 💰 Cost Breakdown

- **EC2 t2.micro**: 750 hours/month FREE (12 months)
- **Storage**: 30 GB EBS FREE (12 months)
- **Data Transfer**: 15 GB/month FREE
- **Total Cost**: **$0** for first year!

### 🎯 What You Get

- ✅ Fully automated EC2 setup
- ✅ Java 17 runtime installed
- ✅ Nginx reverse proxy configured
- ✅ Systemd service (auto-restart)
- ✅ Health monitoring setup
- ✅ Production-ready logging

### 📋 Prerequisites

- AWS CLI installed and configured (`aws configure`)
- AWS account (free tier eligible)

### 📚 Deployment Options

1. **🎯 EC2 Automated (Recommended - FREE):**

   ```bash
   ./create-ec2-instance.sh
   ./deploy-to-ec2.sh springboot-demo-key.pem YOUR-EC2-IP
   ```

2. **🐳 Docker Compose (Local):**

   ```bash
   docker-compose up --build
   ```

3. **☁️ AWS Elastic Beanstalk:**
   ```bash
   eb init springboot-aws-demo --platform java-17
   eb create springboot-aws-demo-prod
   eb deploy
   ```

### 📖 Documentation

- **[EC2 Setup Guide](ec2-setup-guide.md)** - Complete manual setup guide
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - All deployment options
- **[BILLING-PROTECTION.md](BILLING-PROTECTION.md)** - 🛡️ **Cost protection & monitoring**
- **Scripts**: `create-ec2-instance.sh`, `deploy-to-ec2.sh`, `ec2-deployment.sh`

## 🛡️ Billing Protection (IMPORTANT!)

**Protect yourself from unexpected AWS charges:**

### ⚡ Quick Protection Setup

```bash
# Set up complete billing protection (5 minutes)
./setup-billing-protection.sh 5.00 your-email@example.com

# Monitor costs anytime
./aws-cost-monitor.sh

# Emergency stop all services
./emergency-shutdown.sh
```

### 🚨 Auto-Protection Features

- ✅ **Auto-shutdown** when costs exceed $5
- ✅ **Email alerts** at cost thresholds
- ✅ **Monitoring every 6 hours** automatically
- ✅ **Emergency stop** all AWS resources
- ✅ **Free tier usage** tracking

**📖 Complete guide**: [BILLING-PROTECTION.md](BILLING-PROTECTION.md)

## 🌐 Live Application URLs

**Base URL**: http://3.85.219.17:8080

### 🔗 Quick Test Links

- [Hello API](http://3.85.219.17:8080/api/hello) - Simple greeting
- [Hello with Name](http://3.85.219.17:8080/api/hello/YourName) - Personalized greeting
- [All Users](http://3.85.219.17:8080/api/users) - User list
- [Health Check](http://3.85.219.17:8080/actuator/health) - Application status
- [Metrics](http://3.85.219.17:8080/actuator/metrics) - Performance metrics

### 📱 cURL Examples

```bash
# Test the API
curl http://3.85.219.17:8080/api/hello
curl http://3.85.219.17:8080/api/users

# Create a new user
curl -X POST http://3.85.219.17:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"New User","email":"newuser@example.com"}'
```

## 📊 Sample Data

The application initializes with sample users:

- John Doe (john.doe@example.com)
- Jane Smith (jane.smith@example.com)
- Bob Johnson (bob.johnson@example.com)

## ⚙️ Configuration

Application properties can be found in `src/main/resources/application.properties`.

For production deployment, override properties using environment variables or external configuration files.

## 🛠️ Project Structure

```
springboot-aws-demo/
├── src/main/java/com/example/springbootawsdemo/
│   ├── controller/          # REST Controllers
│   ├── entity/             # JPA Entities
│   ├── repository/         # Data Repositories
│   └── config/            # Configuration Classes
├── create-ec2-instance.sh  # AWS EC2 instance creation
├── deploy-to-ec2.sh       # Deployment automation
├── ec2-deployment.sh      # Server-side setup
├── ec2-setup-guide.md     # Manual deployment guide
└── DEPLOYMENT.md          # Complete deployment docs
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
