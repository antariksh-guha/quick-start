@echo off
SETLOCAL EnableDelayedExpansion

REM Parse command line arguments
set "PORT=8081"
set "PROFILE=dev"

:parse_args
if "%~1"=="" goto end_parse
if /i "%~1"=="-p" set "PORT=%~2" & shift & shift & goto parse_args
if /i "%~1"=="-profile" set "PROFILE=%~2" & shift & shift & goto parse_args
shift
goto parse_args
:end_parse

REM Validate inputs
if "%PORT%"=="" (
    echo Port cannot be empty
    exit /b 1
)
if "%PROFILE%"=="" (
    echo Profile cannot be empty
    exit /b 1
)

REM Clean up old containers and images
echo Cleaning up old containers...
docker ps -a | findstr "springboot-app" > nul && docker rm -f springboot-app
echo Cleaning up old images...
docker images | findstr "springboot-app" > nul && docker rmi springboot-app

REM Build with parameters
echo Building application with PORT=%PORT% and PROFILE=%PROFILE%...
docker build ^
    --build-arg PORT=%PORT% ^
    --build-arg SPRING_PROFILES_ACTIVE=%PROFILE% ^
    --build-arg REACT_APP_API_URL=http://localhost:%PORT%/api ^
    -t springboot-app:%PROFILE% ^
    --no-cache .

IF %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    exit /b %ERRORLEVEL%
)

echo Build completed successfully!
echo Run '.\run.bat' or '.\run.bat prod' to start the application.

ENDLOCAL
