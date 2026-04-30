@echo off
title OpenClaw Enterprise - Deteniendo
echo.
echo ╔═══════════════════════════════════════╗
echo ║   OpenClaw Enterprise - Deteniendo    ║
echo ╚═══════════════════════════════════════╝
echo.

if not exist "%~dp0openclaw.pid" (
    echo OpenClaw no está corriendo.
    goto :end
)

set /p pid=<"%~dp0openclaw.pid"
echo [INFO] Deteniendo OpenClaw (PID: %pid%)...
taskkill /F /PID %pid% >nul 2>&1

if exist "%~dp0openclaw.pid" del "%~dp0openclaw.pid"
echo [OK] OpenClaw detenido.

:end
echo.
pause
