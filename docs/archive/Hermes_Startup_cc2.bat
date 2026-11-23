@echo off
setlocal EnableExtensions EnableDelayedExpansion

title Hermes Startup - cc2

set "HERMES=%LOCALAPPDATA%\hermes\bin\hermes.exe"
set "LLAMA=%LOCALAPPDATA%\hermes\tools\llamacpp-cuda-11671-win32-x64\llama-server.exe"
set "MODEL=%LOCALAPPDATA%\hermes\models\Qwen3.8-27B-UD-Q4_K_M.gguf"
set "MMPROJ=%LOCALAPPDATA%\hermes\models\assets\mmproj-Qwen3.8-27B-BF16.gguf"
set "WORKSPACE=%USERPROFILE%\Documents\Hermes_Workspace"
set "LOCAL_URL=http://127.0.0.1:8000/v1/models"

if not exist "%HERMES%" (
    echo ERROR: Hermes executable not found:
    echo %HERMES%
    pause
    exit /b 1
)

:MENU
cls
echo.
echo ========================================================
echo                    HERMES STARTUP
echo ========================================================
echo.
echo   1. LOCAL QWEN 3.8-27B
echo   2. GPT-6 LUNA - CHATGPT / CODEX SUBSCRIPTION
echo   3. EXIT
echo.
echo ========================================================
echo.
choice /c 123 /n /m "Select model [1-3]: "
if errorlevel 3 exit /b 0
if errorlevel 2 goto CLOUD
if errorlevel 1 goto LOCAL

:LOCAL
cls
echo.
echo [LOCAL] Checking the Qwen server...

if not exist "%LLAMA%" (
    echo ERROR: llama-server.exe not found:
    echo %LLAMA%
    pause
    exit /b 1
)
if not exist "%MODEL%" (
    echo ERROR: Qwen model file not found:
    echo %MODEL%
    pause
    exit /b 1
)
if not exist "%MMPROJ%" (
    echo ERROR: Qwen mmproj file not found:
    echo %MMPROJ%
    pause
    exit /b 1
)

curl.exe --silent --fail "%LOCAL_URL%" >nul 2>&1
if errorlevel 1 (
    echo No Qwen API response. Checking for an existing llama-server process...
    tasklist /fi "imagename eq llama-server.exe" | find /i "llama-server.exe" >nul
    if not errorlevel 1 (
        echo An existing llama-server process is present, but its API is not responding.
        echo To avoid a duplicate process, startup is stopping here.
        echo Check the existing server process, then run this script again.
        pause
        exit /b 1
    )

    echo Starting Qwen with the previously observed CPU-only settings...
    start "Hermes Local Qwen" /min "%LLAMA%" ^
      --model "%MODEL%" ^
      --mmproj "%MMPROJ%" ^
      --mmproj-device none ^
      --host 127.0.0.1 ^
      --port 8000 ^
      --alias Qwen3.8-27B ^
      --ctx-size 64000 ^
      --parallel 1 ^
      --threads 12 ^
      --threads-batch 12 ^
      --gpu-layers 0 ^
      --cache-type-k f16 ^
      --cache-type-v f16 ^
      --flash-attn off ^
      --spec-type none ^
      --jinja ^
      --no-webui

    echo Waiting for Qwen API (up to 5 minutes)...
    set /a ATTEMPTS=0
    :WAIT_LOCAL
    timeout /t 3 /nobreak >nul
    curl.exe --silent --fail "%LOCAL_URL%" >nul 2>&1
    if not errorlevel 1 goto LOCAL_READY
    set /a ATTEMPTS+=1
    if !ATTEMPTS! GEQ 100 (
        echo ERROR: Qwen did not become ready within 5 minutes.
        echo Check the llama-server window and its output.
        pause
        exit /b 1
    )
    goto WAIT_LOCAL
) else (
    echo Qwen API is already responding. No second server will be started.
)

:LOCAL_READY
echo Qwen API is responding on port 8000.
echo.
echo In the Hermes model selector, choose the saved provider:
echo Local Qwen 3.8-27B
pause
"%HERMES%" model
if errorlevel 1 (
    echo Model selection returned an error.
    pause
    exit /b 1
)
goto START_SERVICES

:CLOUD
cls
echo.
echo In the Hermes model selector, choose:
echo OpenAI - ChatGPT or Codex Subscription
echo Then select your existing logged-in OAuth credential.
echo Do not select OpenAI API key authentication.
echo.
pause
"%HERMES%" model
if errorlevel 1 (
    echo Model selection returned an error.
    pause
    exit /b 1
)
goto START_SERVICES

:START_SERVICES
cls
echo.
echo Ensuring the Hermes gateway is running...
"%HERMES%" gateway ensure
if errorlevel 1 (
    echo WARNING: gateway ensure reported an error.
    echo Check the result with: hermes status
    pause
)

echo.
echo Opening Hermes Web UI...
start "Hermes Web UI" /min "%HERMES%" webapp

if not exist "%WORKSPACE%" (
    echo Workspace folder not found. Creating it...
    mkdir "%WORKSPACE%"
)

echo.
echo Opening Hermes terminal in:
echo %WORKSPACE%
start "Hermes Terminal" "%ComSpec%" /k ""%HERMES%" --in "%WORKSPACE%""

echo.
echo Startup sequence launched.
echo Verify the active model with: hermes status
echo Verify Codex authentication with: hermes auth status openai-codex
echo.
exit /b 0
