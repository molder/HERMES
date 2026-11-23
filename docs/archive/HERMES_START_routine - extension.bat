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
    echo [i] Local llama-server is active and responding. Skipping server launch.
    goto CONFIG_LOCAL_HERMES
)

:: Check for stale or active loading processes bound to port 8000
netstat -ano | findstr :8000 | findstr /i "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo [!] WARNING: Port 8000 is currently occupied!
    echo     A server may still be loading into VRAM, or a stale process is hanging.
    echo     Wait a few moments and retry, or check Task Manager to kill a hung process.
    pause
    goto MENU
)

echo [+] Starting local llama-server (GPU fitting sequence)...
start "Hermes Llama Server" "%LLAMA_SERVER%" ^
  --model "%MODEL_PATH%" ^
  --mmproj "%MMPROJ_PATH%" ^
  --mmproj-device none ^
  --host 127.0.0.1 ^
  --port 8000 ^
  --alias Qwen3.8-27B ^
  --parallel 1 ^
  --ctx-size 64000 ^
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
    echo     Inspect the "Hermes Llama Server" console window for OOM or fitting errors.
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
echo [+] Setting Hermes provider configuration to local custom model...
call "%HERMES_EXE%" config set model.provider custom >nul 2>&1
if errorlevel 1 (
    echo [!] WARNING: Failed to set Hermes model provider to custom!
    pause
)
call "%HERMES_EXE%" config set model.default Qwen3.8-27B >nul 2>&1
if errorlevel 1 (
    echo [!] WARNING: Failed to set default Hermes model alias!
    pause
)
goto LAUNCH_WORKSPACE

:START_CLOUD
echo.
echo [+] Configuring session for ChatGPT / Codex Subscription...
call "%HERMES_EXE%" config set model.provider openai-codex >nul 2>&1
if errorlevel 1 (
    echo [!] WARNING: Failed to set Hermes model provider to openai-codex!
    pause
) else (
    echo [i] Authentication will be checked after Hermes starts.
)
goto LAUNCH_WORKSPACE

:LAUNCH_WORKSPACE
echo.
echo [+] Launching Hermes workspace environment...
if not exist "%WORKSPACE%" (
    echo [i] Creating missing workspace directory: %WORKSPACE%
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
echo [OK] Startup sequence completed successfully!
timeout /t 3 >nul
exit /b