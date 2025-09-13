# Spring Boot AWS Demo

A simple Spring Boot application demonstrating REST API development and AWS deployment.

## Features

- REST API with Spring Boot
- JPA/Hibernate with H2 database
- Spring Boot Actuator for monitoring
- Sample User entity and CRUD operations
- Ready for AWS deployment

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

## AWS Deployment

This application is configured for deployment on AWS using:
- Docker containerization
- AWS Elastic Beanstalk or EC2
- RDS PostgreSQL for production database
- GitHub Actions for CI/CD

### Quick Start Deployment Options

1. **Docker Compose (Local):**
   ```bash
   docker-compose up --build
   ```

2. **AWS Elastic Beanstalk:**
   ```bash
   eb init springboot-aws-demo --platform java-17
   eb create springboot-aws-demo-prod
   eb deploy
   ```

3. **Docker Registry:**
   ```bash
   docker pull ghcr.io/your-username/springboot-aws-demo:latest
   docker run -p 8080:8080 ghcr.io/your-username/springboot-aws-demo:latest
   ```

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Sample Data

The application initializes with sample users:
- John Doe (john.doe@example.com)
- Jane Smith (jane.smith@example.com)
- Bob Johnson (bob.johnson@example.com)

## Configuration

Application properties can be found in `src/main/resources/application.properties`.

For production deployment, override properties using environment variables or external configuration files.
