@echo off
chcp 65001 >nul
title ArtAgents Setup
color 0A

echo ============================================
echo   ArtAgents - Erstinstallation


cd /d D:\ArtAgents

REM --- 2. Venv erstellen ---
if exist "D:\ArtAgents\venv\Scripts\activate.bat" (
    echo [OK] Venv bereits vorhanden, überspringe Erstellung.
) else (
    echo.
    echo [2/3] Erstelle Python-Venv mit C:\Python314\python.exe ...
    "C:\Users\Startklar\AppData\Local\Programs\Python\Python312\python.exe" -m venv D:\ArtAgents\agentsvenv
    if errorlevel 1 (
        echo [FEHLER] Venv-Erstellung fehlgeschlagen. Prüfe ob C:\Python314\python.exe existiert.
        pause & exit /b 1
    )
    echo [OK] Venv erstellt.
)

REM --- 3. Requirements installieren ---
echo.
echo [3/3] Installiere Requirements...
call D:\ArtAgents\venv\Scripts\activate.bat
pip install --upgrade pip >nul 2>&1
pip install -r D:\ArtAgents\requirements.txt
if errorlevel 1 (
    echo [FEHLER] Installation fehlgeschlagen.
    pause & exit /b 1
)

echo.
echo ============================================
echo   Setup abgeschlossen!
echo   Starte jetzt: start.bat
echo ============================================
pause
