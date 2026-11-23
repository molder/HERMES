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

title Hermes Startup Manager (cc2)

:MENU
cls
echo ========================================================
echo               HERMES STARTUP CONFIGURATION
echo ========================================================
echo Please select your provider for this session:
echo.
echo   [1] Local Qwen 3.8-27B (NVIDIA RTX 5070 Ti)
echo   [2] ChatGPT / Codex Subscription (Cloud)
echo   [3] Exit
echo.
set "choice="
set /p "choice=Enter your choice (1-3): "

if "%choice%"=="1" goto START_QWEN
if "%choice%"=="2" goto START_CLOUD
if "%choice%"=="3" exit /b

echo Invalid selection. Please choose 1, 2, or 3.
timeout /t 2 >nul
goto MENU

:START_QWEN
echo.
echo [+] Performing pre-flight asset checks...
if not exist "%LLAMA_SERVER%" (
    echo [!] ERROR: llama-server.exe not found at:
    echo     %LLAMA_SERVER%
    pause
    goto MENU
)
if not exist "%MODEL_PATH%" (
    echo [!] ERROR: Qwen model file not found at:
    echo     %MODEL_PATH%
    pause
    goto MENU
)
if not exist "%MMPROJ_PATH%" (
    echo [!] ERROR: Multimodal projector not found at:
    echo     %MMPROJ_PATH%
    pause
    goto MENU
)

echo [+] Checking if local llama-server API is already responding...
curl -s --fail http://127.0.0.1:8000/v1/models >nul 2>&1
if %errorlevel% equ 0 (
    echo [i] Local llama-server is already active and responding. Skipping server startup.
    goto CONFIG_LOCAL_HERMES
)

:: Check for stale or hung processes bound to port 8000
netstat -ano | findstr :8000 | findstr /i "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo [!] WARNING: Port 8000 is occupied by a stale or unresponsive process!
    echo     Please check Task Manager, terminate the hanging server, and retry.
    pause
    goto MENU
)

echo [+] Starting local llama-server with verified CUDA parameters...
start "Hermes Llama Server" "%LLAMA_SERVER%" ^
  --model "%MODEL_PATH%" ^
  --mmproj "%MMPROJ_PATH%" ^
  --mmproj-device none ^
  --host 127.0.0.1 ^
  --port 8000 ^
  --alias Qwen3.8-27B ^
  --parallel 1 ^
  --ctx-size 65536 ^
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
set /a "retries=0"
:WAIT_SERVER
set /a "retries+=1"
if %retries% gtr 150 (
    echo.
    echo [!] ERROR: llama-server failed to become ready within 5 minutes.
    echo     Please inspect the "Hermes Llama Server" console window for OOM or fitting errors.
    pause
    goto MENU
)
timeout /t 2 >nul
curl -s --fail http://127.0.0.1:8000/v1/models >nul 2>&1
if %errorlevel% neq 0 (
    echo     ...attempt %retries%/150: waiting for Qwen to load into VRAM...
    goto WAIT_SERVER
)
echo [OK] Local Qwen API is ready!

:CONFIG_LOCAL_HERMES
echo [+] Configuring Hermes profile for Local Qwen...
call "%HERMES_EXE%" model set local-qwen >nul 2>&1
goto LAUNCH_WORKSPACE

:START_CLOUD
echo.
echo [+] Configuring session for ChatGPT / Codex Subscription...
call "%HERMES_EXE%" model set openai-codex >nul 2>&1
echo [i] Note: Ensure your OpenAI API key or auth status is active (`hermes auth status openai-codex`).
goto LAUNCH_WORKSPACE

:LAUNCH_WORKSPACE
echo.
echo [+] Launching Hermes workspace and client...
if not exist "%WORKSPACE%" (
    echo [i] Workspace directory missing. Creating: %WORKSPACE%
    mkdir "%WORKSPACE%"
)
cd /d "%WORKSPACE%"

if exist "%HERMES_EXE%" (
    start "" "%HERMES_EXE%"
) else (
    echo [!] CRITICAL ERROR: hermes.exe not found at %HERMES_EXE%
    pause
    exit /b
)

echo.
echo [OK] Startup sequence completed successfully. Enjoy your session!
timeout /t 3 >nul
exit /b