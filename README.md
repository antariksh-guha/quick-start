# Spring Boot and React Application

A full-stack application with Spring Boot backend and React TypeScript frontend.

## Architecture

- Backend: Spring Boot 3.4.0 with Java 17
- Frontend: React with TypeScript
- Containerization: Docker

## Prerequisites

- Java 17
- Node.js 20+
- Docker
- Maven 3.9+

## Quick Start

1. Build the application:
- build.bat

2. Run in development mode
- run-dev.bat

3. Run in production mode
- run-prod.bat

## Environment Configuration

### Development (Port: 8081)

- Profile: dev
- Memory: 512MB - 1GB
- Debug port: 5005

### Production (Port: 8082)

- Profile: prod
- Memory: 1GB - 2GB

## Logging

Logs are stored in:

- Development: logs/dev/
- Production: logs/prod/

## Health Checks

Access health endpoint: /actuator/health

## Contributing

Create feature branch
Make changes
Submit pull request
