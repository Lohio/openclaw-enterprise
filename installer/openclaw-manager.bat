@echo off
title OpenClaw Enterprise Manager
echo.
echo ╔═══════════════════════════════════════╗
echo ║   OpenClaw Enterprise - Manager CLI   ║
echo ╚═══════════════════════════════════════╝
echo.

set "PATH=%~dp0deps\nodejs;%PATH%"
set "PATH=%~dp0deps\openclaw;%PATH%"
set "PATH=%~dp0deps\clawhub;%PATH%"

:menu
cls
echo ═══════════════════════════════════════
echo  1) Ver estado de OpenClaw
echo  2) Iniciar OpenClaw
echo  3) Detener OpenClaw
echo  4) Ver logs
echo  5) Instalar skills desde ClawHub
echo  6) Editar configuraciOn
echo  7) Ejecutar OpenClaw en primer plano
echo  0) Salir
echo ═══════════════════════════════════════
echo.
set /p opcion="Opcion: "

if "%opcion%"=="1" goto status
if "%opcion%"=="2" goto start
if "%opcion%"=="3" goto stop
if "%opcion%"=="4" goto logs
if "%opcion%"=="5" goto skills
if "%opcion%"=="6" goto config
if "%opcion%"=="7" goto run
if "%opcion%"=="0" exit /b

:status
echo.
if exist "%~dp0openclaw.pid" (
    set /p pid=<"%~dp0openclaw.pid"
    tasklist /FI "PID eq %pid%" 2>nul | find /I "%pid%" >nul
    if !errorlevel! equ 0 (
        echo [OK] OpenClaw esta CORRIENDO (PID: %pid%)
    ) else (
        echo [WARN] OpenClaw no esta corriendo (PID file exists)
    )
) else (
    echo [WARN] OpenClaw NO esta corriendo
)
echo.
pause
goto menu

:start
call "%~dp0start-openclaw.bat"
echo.
pause
goto menu

:stop
call "%~dp0stop-openclaw.bat"
echo.
pause
goto menu

:logs
echo.
echo Logs (Ctrl+C para salir):
echo.
if exist "%~dp0openclaw.log" (
    type "%~dp0openclaw.log"
) else (
    echo No hay logs aun.
)
echo.
pause
goto menu

:skills
echo.
set /p skill="Nombre del skill a instalar (ej: github): "
if not "%skill%"=="" (
    clawhub install %skill%
    echo.
)
pause
goto menu

:config
echo.
notepad "%~dp0openclaw.json"
goto menu

:run
echo.
openclaw gateway start --config "%~dp0openclaw.json"
echo.
pause
goto menu
