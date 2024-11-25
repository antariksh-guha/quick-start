@echo off
SETLOCAL EnableDelayedExpansion

REM Clean up old containers and images
echo Cleaning up old containers...
docker ps -a | findstr "springboot-app" > nul && docker rm -f springboot-app
echo Cleaning up old images...
docker images | findstr "springboot-app" > nul && docker rmi springboot-app

REM Set build parameters
set PORT=8081
set PROFILE=dev

REM Build with parameters
echo Building application with PORT=%PORT% and PROFILE=%PROFILE%...
docker build ^
    --build-arg PORT=%PORT% ^
    --build-arg SPRING_PROFILES_ACTIVE=%PROFILE% ^
    -t springboot-app:%PROFILE% ^
    --no-cache .

IF %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    exit /b %ERRORLEVEL%
)

echo Build completed successfully!
echo Run 'run-dev.bat' or 'run-prod.bat' to start the application.

ENDLOCAL
