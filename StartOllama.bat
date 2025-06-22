@echo off
chcp 65001 >nul
REM =======================================================
REM StartOllama.bat – Friendly entry point for the Ollama Toolkit
REM =======================================================

echo 🔧 LAUNCHING OLLAMA TOOLKIT...
echo 📁 Calling internal script: LaunchLLM_AutoModelSelect.bat
echo.

call "%~dp0LaunchLLM_AutoModelSelect.bat"

echo.
echo 🏁 DONE. If Ollama launched successfully, you're ready to go!
pause

