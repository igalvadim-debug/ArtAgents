@echo off
chcp 65001 >nul
title GGUF ? Ollama Import
color 0E

echo ============================================
echo   GGUF-Modell in Ollama importieren
echo ============================================
echo.

set MODELS_DIR=D:\SillyTavernAiO\KoboldCPP\models
set OLLAMA=C:\Users\Startklar\AppData\Local\Programs\Ollama\ollama.exe

REM --- Modelle auflisten ---
echo Verfügbare GGUF-Modelle in %MODELS_DIR%:
echo.
set idx=0
for %%f in ("%MODELS_DIR%\*.gguf") do (
    set /a idx+=1
    echo   [!idx!] %%~nxf
    set "MODEL_!idx!=%%f"
    set "MODELNAME_!idx!=%%~nf"
)

if %idx%==0 (
    echo Keine .gguf Dateien gefunden in %MODELS_DIR%
    pause & exit /b 1
)

echo.
set /p CHOICE="Nummer eingeben (1-%idx%): "

REM --- Modelfile erstellen und importieren ---
set "SELECTED=!MODEL_%CHOICE%!"
set "SNAME=!MODELNAME_%CHOICE%!"

echo.
echo Importiere: %SELECTED%
echo Als Ollama-Name: %SNAME%
echo.

REM Temporäres Modelfile erstellen
echo FROM "%SELECTED%" > "%TEMP%\Modelfile_tmp"

"%OLLAMA%" create "%SNAME%" -f "%TEMP%\Modelfile_tmp"
if errorlevel 1 (
    echo [FEHLER] Import fehlgeschlagen.
) else (
    echo.
    echo [OK] Modell "%SNAME%" ist jetzt in Ollama verfügbar.
    echo      Jetzt start.bat ausführen und in ArtAgents auswählen.
)

del "%TEMP%\Modelfile_tmp" >nul 2>&1
pause
