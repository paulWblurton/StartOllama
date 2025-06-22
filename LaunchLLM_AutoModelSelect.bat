@echo off
chcp 65001 >nul
REM ================================================================================
REM LaunchLLM_AutoModelSelect.bat – Jaguar Edition Launcher with HTML Dashboard Preview
REM ------------------------------------------------------------------------------
REM How It Works:
REM 1. Locates ollama.exe in your PATH.
REM 2. Calls GenerateModelDashboard.ps1 to generate the HTML dashboard.
REM 3. Opens models_catalog.html in your default browser.
REM 4. Prompts you to enter a model (or variant) to launch.
REM 5. Launches the selected model using "ollama run <model>".
REM ================================================================================
setlocal EnableDelayedExpansion
cd /d %~dp0

set "DEFAULT_MODEL=mistral"
set "OLLAMA_BASE_URL=http://localhost:11434"
set "LOG_FILE=%TEMP%\ollama_launch_log.txt"
set "HTML_DASHBOARD=%TEMP%\models_catalog.html"

echo %date% %time% - Launcher started. > "%LOG_FILE%"

for /f "delims=" %%i in ('where ollama.exe 2^>nul') do (
    set "OLLAMA_EXE=%%i"
    goto :found
)
echo ❌ ollama.exe not found. Make sure it is installed and in your PATH.
pause
exit /b 1
:found

echo Generating model dashboard...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0GenerateModelDashboard.ps1"
if errorlevel 1 (
    echo Failed to generate dashboard.
    pause
    exit /b 1
)

if exist "%HTML_DASHBOARD%" (
    echo Opening dashboard: %HTML_DASHBOARD%
    start "" "%HTML_DASHBOARD%"
) else (
    echo Dashboard file not found.
)

set /p selectedModel="Enter model to launch (e.g., qwen2.5vl or qwen2.5vl:32b): "
if "%selectedModel%"=="" (
    echo No input provided. Using default model: %DEFAULT_MODEL%
    set "selectedModel=%DEFAULT_MODEL%"
)
echo %date% %time% - Selected model: %selectedModel% >> "%LOG_FILE%"

echo Launching model: %selectedModel%
"%OLLAMA_EXE%" run %selectedModel%
echo %date% %time% - Model launched: %selectedModel% >> "%LOG_FILE%"

pause
