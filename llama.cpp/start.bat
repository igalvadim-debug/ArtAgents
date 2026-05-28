@echo off
chcp 65001 >nul
title ArtAgents Starter mit llama
color 0B

echo ============================================
echo   ArtAgents - Start 
echo ============================================
echo.

REM --- ArtAgents starten via Aktivierung ---
echo [2/2] Starte ArtAgents (Gradio UI)...
cd /d D:\ArtAgents

REM Prüfen, ob das Aktivierungsskript fehlt
if not exist "D:\ArtAgents\agentsvenv\Scripts\activate.bat" goto :FEHLER

:START
REM Ruft das Aktivierungsskript auf und bleibt im selben Prozess
call "D:\ArtAgents\agentsvenv\Scripts\activate.bat"

echo [OK] Umgebung aktiv. Starte Anwendung...
python app.py
goto :END

:FEHLER
echo [FEHLER] Virtuelle Umgebung (activate.bat) fehlt oder ist beschädigt!
echo Bitte führen Sie zuerst das Installationsskript erneut aus.

:END
pause
