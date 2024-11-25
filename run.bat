@echo off
SETLOCAL EnableDelayedExpansion

REM Parse profile argument
set "PROFILE=dev"
if "%1"=="prod" set "PROFILE=prod"

REM Set profile-specific defaults
if "%PROFILE%"=="dev" (
    set "DEFAULT_PORT=8081"
    set "ALT_PORTS=8091,8071,8061,8051"
    set "MEMORY_OPTS=-Xms512m -Xmx1024m"
    set "RESTART_POLICY=unless-stopped"
) else (
    set "DEFAULT_PORT=8082"
    set "ALT_PORTS=8092,8072,8062,8052"
    set "MEMORY_OPTS=-XX:+UseG1GC -Xms1g -Xmx2g -XX:+HeapDumpOnOutOfMemoryError"
    set "RESTART_POLICY=always"
)

REM Check if default port is in use
netstat -ano | findstr :%DEFAULT_PORT% > nul
IF %ERRORLEVEL% EQU 0 (
    echo Port %DEFAULT_PORT% is already in use
    echo Attempting to find alternative port...
    
    FOR %%P IN (%ALT_PORTS%) DO (
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
    set PORT=%DEFAULT_PORT%
)

REM Clean up existing container if running
echo Checking for existing container...
docker ps -a | findstr "springboot-app-%PROFILE%" > nul && docker rm -f springboot-app-%PROFILE%

REM Create network if it doesn't exist
echo Creating network if not exists...
docker network ls | findstr "app-network" > nul || docker network create app-network

REM Run container with specified profile
echo Starting %PROFILE% container on port !PORT!...
docker run -d ^
    --name springboot-app-%PROFILE% ^
    --network app-network ^
    -p !PORT!:!PORT! ^
    -e PORT=!PORT! ^
    -e SPRING_PROFILES_ACTIVE=%PROFILE% ^
    -e JAVA_OPTS="%MEMORY_OPTS%" ^
    -v %cd%/logs:/app/logs ^
    --health-cmd="wget --no-verbose --tries=1 --spider http://localhost:!PORT!/actuator/health || exit 1" ^
    --health-interval=30s ^
    --health-timeout=5s ^
    --health-retries=3 ^
    --restart %RESTART_POLICY% ^
    springboot-app:%PROFILE%

IF %ERRORLEVEL% NEQ 0 (
    echo Container startup failed!
    exit /b %ERRORLEVEL%
)

echo Waiting for container health check...
timeout /t 10 /nobreak
docker ps | findstr "springboot-app-%PROFILE%" > nul && (
    echo Application started successfully!
    echo Access the application at http://localhost:!PORT!
) || (
    echo Container may not be healthy, check logs with: docker logs springboot-app-%PROFILE%
)

ENDLOCAL