@echo off
setlocal EnableDelayedExpansion

:: ==========================================
:: CONFIGURATION & PATHS
:: ==========================================
set "WORKSPACE=%USERPROFILE%\Documents\Hermes_Workspace"
set "HERMES_EXE=%LOCALAPPDATA%\hermes\bin\hermes.exe"
set "LLAMA_SERVER=%LOCALAPPDATA%\hermes\tools\llamacpp-cuda-11671-win32-x64\llama-server.exe"
set "MODEL_PATH=%LOCALAPPDATA%\hermes\models\Qwen3.8-27B-UD-Q4_K_M.gguf"
set "MMPROJ_PATH=%LOCALAPPDATA%\hermes\models\assets\mmproj-Qwen3.8-27B-BF16.gguf"

title Hermes Startup Manager

:MENU
cls
echo ========================================================
echo               HERMES STARTUP CONFIGURATION
echo ========================================================
echo Please select your provider for this session:
echo.
echo   [1] Local Qwen 3.8-27B (NVIDIA RTX 5070 Ti)
echo   [2] ChatGPT / Codex Subscription
echo   [3] Exit
echo.
set /p "choice=Enter your choice (1-3): "

if "%choice%"=="1" goto START_QWEN
if "%choice%"=="2" goto START_CLOUD
if "%choice%"=="3" exit /b

echo Invalid selection. Please choose 1, 2, or 3.
timeout /t 2 >nul
goto MENU

:START_QWEN
echo.
echo [+] Checking if local llama-server is already responding...
curl -s http://127.0.0.1:8000/v1/models >nul 2>&1
if %errorlevel% equ 0 (
    echo [i] Local llama-server is already running. Skipping server startup.
    goto LAUNCH_WORKSPACE
)

echo [+] Starting local llama-server with verified configuration...
if not exist "%LLAMA_SERVER%" (
    echo [!] ERROR: llama-server.exe not found at:
    echo     %LLAMA_SERVER%
    pause
    goto MENU
)

:: Start llama-server in a new separate command window
start "Hermes Llama Server" "%LLAMA_SERVER%" ^
  --model "%MODEL_PATH%" ^
  --mmproj "%MMPROJ_PATH%" ^
  --mmproj-device none ^
  --host 127.0.0.1 ^
  --port 8000 ^
  --alias Qwen3.8-27B ^
  --parallel 1 ^
  --fit-ctx 65536 ^
  --threads 12 ^
  --threads-batch 12 ^
  --device CUDA0 ^
  --fit on ^
  --fit-target 3072 ^
  --cache-type-k f16 ^
  --cache-type-v f16 ^
  --flash-attn off ^
  --spec-type none ^
  --jinja ^
  --no-webui

echo [+] Waiting for API readiness endpoint (http://127.0.0.1:8000/v1/models)...
:WAIT_SERVER
timeout /t 2 >nul
curl -s http://127.0.0.1:8000/v1/models >nul 2>&1
if %errorlevel% neq 0 (
    echo     ...still waiting for Qwen server to load into VRAM...
    goto WAIT_SERVER
)
echo [OK] Local Qwen API is ready!
goto LAUNCH_WORKSPACE

:START_CLOUD
echo.
echo [+] Configuring session for ChatGPT / Codex Subscription...
:: Add any environment variables or flags needed for cloud routing here if applicable
goto LAUNCH_WORKSPACE

:LAUNCH_WORKSPACE
echo.
echo [+] Launching Hermes environment and workspace...
if exist "%WORKSPACE%" (
    cd /d "%WORKSPACE%"
) else (
    echo [i] Workspace directory not found, skipping directory change.
)

if exist "%HERMES_EXE%" (
    start "" "%HERMES_EXE%"
) else (
    echo [!] Warning: hermes.exe not found at %HERMES_EXE%
)

echo.
echo [OK] Startup sequence complete. Enjoy your session!
timeout /t 3 >nul
exit /b