#!/bin/sh
set -e

# Use PORT from environment, fallback to build-time value
SERVER_PORT=${PORT}

# Set memory configuration based on profile
if [ "${SPRING_PROFILES_ACTIVE}" = "prod" ]; then
    MEM_OPTS="-XX:+UseG1GC -Xms1g -Xmx2g -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/logs"
else
    MEM_OPTS="-XX:+UseG1GC -Xms512m -Xmx1g -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/logs"
fi

# JVM configuration
JAVA_OPTS="${JAVA_OPTS} ${MEM_OPTS} \
    -Djava.security.egd=file:/dev/./urandom \
    -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE:-default} \
    -Dserver.port=${SERVER_PORT} \
    -Dspring.web.resources.static-locations=classpath:/static/ \
    -XX:+ExitOnOutOfMemoryError \
    -XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75"

# Add debug options for dev profile
if [ "${SPRING_PROFILES_ACTIVE}" = "dev" ]; then
    JAVA_OPTS="${JAVA_OPTS} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
fi

# Create log directories if they don't exist
mkdir -p /app/logs/${SPRING_PROFILES_ACTIVE}

# Print effective configuration
echo "Starting application with:"
echo "PORT: ${SERVER_PORT}"
echo "JAVA_OPTS: ${JAVA_OPTS}"
echo "SPRING_PROFILES_ACTIVE: ${SPRING_PROFILES_ACTIVE:-default}"

# Error handling
trap 'echo "Application crashed with exit code $?"; exit 1' ERR

# Start application
exec java ${JAVA_OPTS} -jar app.jar