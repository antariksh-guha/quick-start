# Frontend build stage
FROM node:20-alpine AS frontend-builder
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ ./
RUN npm run build

# Backend build stage
FROM maven:3.9.9-eclipse-temurin-17-alpine AS backend-builder
WORKDIR /build
COPY backend/pom.xml .
COPY backend/src ./src
# Copy frontend build output to backend static resources
COPY --from=frontend-builder /frontend/build ./src/main/resources/static/
RUN mvn clean package -DskipTests

# Run stage
FROM eclipse-temurin:17-jre-alpine

ARG PORT=8080
ENV SERVER_PORT=${PORT}

ARG PROFILE=dev
ENV SPRING_PROFILES_ACTIVE=${PROFILE}

WORKDIR /app

# Security patches and cleanup
RUN apk update && \
    apk upgrade && \
    apk add --no-cache curl && \
    rm -rf /var/cache/apk/*

# Add non-root user and setup directories
RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup && \
    mkdir -p /app/logs/dev /app/logs/prod && \
    chown -R appuser:appgroup /app && \
    chmod -R 755 /app/logs

USER appuser

# Copy application files
COPY --from=backend-builder --chown=appuser:appgroup /build/target/application-DEV-SNAPSHOT.jar app.jar
COPY --chown=appuser:appgroup docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75"

EXPOSE ${SERVER_PORT}

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:${SERVER_PORT}/actuator/health || exit 1

ENTRYPOINT ["./docker-entrypoint.sh"]