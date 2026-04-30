@echo off
title OpenClaw Enterprise
echo.
echo ╔═══════════════════════════════════════╗
echo ║   OpenClaw Enterprise - Iniciando     ║
echo ╚═══════════════════════════════════════╝
echo.

:: Verificar que exista la configuración
if not exist "%~dp0openclaw.json" (
    echo [ERROR] No se encuentra openclaw.json
    echo Ejecutá primero el configurador GUI.
    pause
    exit /b 1
)

:: Agregar Node.js al PATH
set "PATH=%~dp0deps\nodejs;%PATH%"

:: Agregar OpenClaw al PATH
set "PATH=%~dp0deps\openclaw;%PATH%"

echo [INFO] Iniciando OpenClaw Gateway...
echo [INFO] Puerto: ...
echo [INFO] Logs: %~dp0openclaw.log
echo.

start /B /MIN "" openclaw gateway start --config "%~dp0openclaw.json" > "%~dp0openclaw.log" 2>&1

:: Esperar y verificar
timeout /t 3 /nobreak >nul

rem Verificar PID
if exist "%~dp0openclaw.pid" (
    set /p pid=<"%~dp0openclaw.pid"
    echo [OK] OpenClaw corriendo (PID: %pid%)
) else (
    echo [WARN] No se pudo determinar el estado.
    echo       Revisá los logs: %~dp0openclaw.log
)

echo.
echo Para administrar: abrí el acceso directo del escritorio
echo Para detener:     ejecutá stop-openclaw.bat
echo.
echo Presioná cualquier tecla para cerrar esta ventana...
pause >nul
