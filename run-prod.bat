@echo off
SETLOCAL EnableDelayedExpansion

REM Check if port 8082 is in use
netstat -ano | findstr :8082 > nul
IF %ERRORLEVEL% EQU 0 (
    echo Port 8082 is already in use
    echo Attempting to find alternative port...
    
    FOR %%P IN (8092,8072,8062,8052) DO (
        netstat -ano | findstr :%%P > nul
        IF !ERRORLEVEL! NEQ 0 (
            set PORT=%%P
            goto :found_port
        )
    )
    echo No available ports found
    exit /b 1
    
    :found_port
    echo Using alternative port: !PORT!
) ELSE (
    set PORT=8082
)

REM Clean up existing container if running
echo Checking for existing container...
docker ps -a | findstr "springboot-app-prod" > nul && docker rm -f springboot-app-prod

REM Create network if it doesn't exist
echo Creating network if not exists...
docker network ls | findstr "app-network" > nul || docker network create app-network

REM Run container with production profile
echo Starting production container on port !PORT!...
docker run -d ^
    --name springboot-app-prod ^
    --network app-network ^
    -p !PORT!:!PORT! ^
    -e PORT=!PORT! ^
    -e SPRING_PROFILES_ACTIVE=prod ^
    -e JAVA_OPTS="-XX:+UseG1GC -Xms1g -Xmx2g -XX:+HeapDumpOnOutOfMemoryError" ^
    -v %cd%/logs:/app/logs ^
    --health-cmd="wget --no-verbose --tries=1 --spider http://localhost:!PORT!/actuator/health || exit 1" ^
    --health-interval=30s ^
    --health-timeout=5s ^
    --health-retries=3 ^
    --memory="2g" ^
    --memory-swap="4g" ^
    --cpu-shares=1024 ^
    --restart always ^
    springboot-app:dev

IF %ERRORLEVEL% NEQ 0 (
    echo Container startup failed!
    exit /b %ERRORLEVEL%
)

echo Waiting for container health check...
timeout /t 10 /nobreak
docker ps | findstr "springboot-app-prod" > nul && (
    echo Production application started successfully!
    echo Access the application at http://localhost:!PORT!
) || (
    echo Container may not be healthy, check logs with: docker logs springboot-app-prod
)

ENDLOCAL