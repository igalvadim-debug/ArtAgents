@echo off
setlocal enabledelayedexpansion

:: ============================================
:: Konfiguration
:: ============================================
set "LLAMA_EXE=D:\Llamacpp\llama-b9204-bin-win-cuda-13.1-x64\llama-server.exe"
set "MODELS_DIR=D:\SillyTavernNeurogen\kobold\models"
set "CTX_SIZE=8192"
set "THREADS=8"

:: ============================================
:: Modell-Auswahlmenue
:: ============================================
:menu
cls
echo ============================================
echo      Llama.cpp - Modell Launcher (RTX 5060)
echo ============================================
echo.

set "count=0"
:: Lese alle GGUF-Dateien in ein Array ein
for %%F in ("%MODELS_DIR%\*.gguf") do (
    set /a count+=1
    set "model[!count!]=%%F"
    set "filename[!count!]=%%~nxF"
    
    :: Hole Dateigröße in Bytes (für einfache VRAM-Schätzung)
    set "filesize[!count!]=%%~zF"
    
    echo [!count!] %%~nxF
)

echo.
if %count%==0 (
    echo Keine GGUF-Dateien im Verzeichnis gefunden:
    echo %MODELS_DIR%
    pause
    exit /b
)

set /p "choice=Bitte Nummer waehlen (1-%count%) oder 'q' zum Beenden: "

if /i "%choice%"=="q" exit /b
if "%choice%"=="" goto menu

:: Pruefe ob Auswahl gueltig ist
if not defined model[%choice%] (
    echo Ungueltige Auswahl!
    timeout /t 2 >nul
    goto menu
)

set "SELECTED_MODEL=!model[%choice%]!"
set "SELECTED_NAME=!filename[%choice%]!"
set "SELECTED_SIZE=!filesize[%choice%]!"

:: ============================================
:: Automatische Parameter-Konfiguration
:: ============================================
set "NGL=99"
set "MTP_FLAGS="

:: 1. NGL (Layers) automatisch berechnen anhand der Dateigroesse
:: Da CMD keine sehr grossen Zahlen gut verarbeiten kann, trimmen wir die letzten 6 Stellen (~Megabytes)
set "sizeMB=%SELECTED_SIZE:~0,-6%"
if "%sizeMB%"=="" set "sizeMB=0"

:: Wenn das Modell groesser als ca. 6.5 GB (6500 MB) ist, passen nicht alle Layer in 8GB VRAM (wg. Kontext)
:: Bei 27B/35B reduzieren wir NGL stark.
if %sizeMB% GTR 10000 (
    echo [Info] Grosses Modell erkannt ^(ueber 10GB^). Reduziere GPU-Layers.
    set "NGL=25"
) else if %sizeMB% GTR 6500 (
    echo [Info] Mittleres Modell erkannt. Reduziere GPU-Layers leicht.
    set "NGL=45"
) else (
    echo [Info] Kleines Modell erkannt. Lade alles in den VRAM ^(-ngl 99^).
    set "NGL=99"
)

:: 2. MTP automatisch aktivieren, wenn "MTP" im Dateinamen steht
echo %SELECTED_NAME% | findstr /i "MTP" >nul
if not errorlevel 1 (
    echo [Info] MTP im Dateinamen gefunden. Aktiviere Speculative Decoding.
    set "MTP_FLAGS=--spec-type draft-mtp --spec-draft-n-max 3"
)

echo.
echo ============================================
echo Startkonfiguration:
echo Modell : %SELECTED_NAME%
echo NGL    : %NGL% (GPU Layers)
echo Kontext: %CTX_SIZE%
if defined MTP_FLAGS echo MTP    : Aktiviert
echo ============================================
echo.
echo Starte Server... druecken Sie STRG+C zum Beenden.
echo.

:: ============================================
:: Server Start
:: ============================================
"%LLAMA_EXE%" ^
  --model "%SELECTED_MODEL%" ^
  --host 127.0.0.1 ^
  --port 8080 ^
  --webui-mcp-proxy ^
  -ngl %NGL% ^
  --ctx-size %CTX_SIZE% ^
  --threads %THREADS% ^
  --flash-attn on ^
  %MTP_FLAGS% ^
  --metrics

echo.
echo Server wurde beendet.
pause
goto menu