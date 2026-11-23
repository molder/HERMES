@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Hermes Startup Manager v3 TEST (cc2)

REM ============================================================================
REM HERMES_START_routine_v3_TEST.bat
REM Safe, observable startup & diagnostic routine preserving exact paths/args
REM ============================================================================

REM --- 1. CONFIGURATION & PATHS ---
set "WORKSPACE=%USERPROFILE%\Documents\Hermes_Workspace"
set "HERMES_EXE=%LOCALAPPDATA%\hermes\bin\hermes.exe"
set "LLAMA_SERVER=%LOCALAPPDATA%\hermes\tools\llamacpp-cuda-11671-win32-x64\llama-server.exe"
set "MODEL_PATH=%LOCALAPPDATA%\hermes\models\Qwen3.8-27B-UD-Q4_K_M.gguf"
set "MMPROJ_PATH=%LOCALAPPDATA%\hermes\models\assets\mmproj-Qwen3.8-27B-BF16.gguf"

set "SERVER_HOST=127.0.0.1"
set "SERVER_PORT=8000"
set "MODEL_ALIAS=Qwen3.8-27B"
set "CLOUD_PROVIDER=openai-codex"

REM Exact llama-server arguments with --ctx-size 64000 (Hermes minimum 64K):
set "LLAMA_ARGS=--model "%MODEL_PATH%" --mmproj "%MMPROJ_PATH%" --mmproj-device none --host %SERVER_HOST% --port %SERVER_PORT% --alias %MODEL_ALIAS% --parallel 1 --ctx-size 64000 --threads 12 --threads-batch 12 --device CUDA0 --fit on --fit-target 3072 --cache-type-k q8_0 --cache-type-v q8_0 --flash-attn on --spec-type none --jinja --no-webui"

REM Startup timeout: 150 polls * 2s = 300s (5 minutes)
set "MAX_RETRIES=150"
set "POLL_INTERVAL_SEC=2"

REM --- 2. LOGGING & DIAGNOSTIC ARTIFACTS ---
set "SCRIPT_DIR=%~dp0"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "PID_FILE=%LOG_DIR%\hermes_llama_server.pid"
set "STDOUT_LOG=%LOG_DIR%\hermes_llama_stdout.log"
set "STDERR_LOG=%LOG_DIR%\hermes_llama_stderr.log"
set "DIAG_LOG=%LOG_DIR%\hermes_startup_diag.log"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM --- 3. CLI / MENU MODE SELECTION ---
set "ARG1=%~1"
if /I "%ARG1%"=="1" goto :MODE_LOCAL
if /I "%ARG1%"=="LOCAL" goto :MODE_LOCAL
if /I "%ARG1%"=="QWEN" goto :MODE_LOCAL
if /I "%ARG1%"=="2" goto :MODE_CLOUD
if /I "%ARG1%"=="CLOUD" goto :MODE_CLOUD
if /I "%ARG1%"=="CODEX" goto :MODE_CLOUD
if not "%ARG1%"=="" (
    echo [!] Unknown argument "%ARG1%". Usage: %~nx0 [1^|LOCAL^|2^|CLOUD]
    exit /b 1
)

:MENU
cls
echo ========================================================
echo          HERMES STARTUP CONFIGURATION (v3 TEST)
echo ========================================================
echo Please select your provider for this session:
echo.
echo   [1] Local Qwen 3.8-27B (NVIDIA RTX 5070 Ti)
echo   [2] ChatGPT / Codex Subscription (Cloud)
echo   [3] Exit
echo.
set "choice="
set /p "choice=Enter your choice (1-3): "

if "%choice%"=="1" goto :MODE_LOCAL
if "%choice%"=="2" goto :MODE_CLOUD
if "%choice%"=="3" exit /b 0

echo Invalid selection. Please choose 1, 2, or 3.
timeout /t 2 >nul
goto :MENU

REM ============================================================================
:MODE_LOCAL
REM ============================================================================
call :LOG "============================================================"
call :LOG "[MODE] LOCAL (Qwen 3.8-27B on %SERVER_HOST%:%SERVER_PORT%)"
call :LOG "[STEP 1] Performing pre-flight asset checks..."

if not exist "%LLAMA_SERVER%" (
    call :LOG "[FAIL] llama-server.exe not found at: %LLAMA_SERVER%"
    pause
    goto :MENU
)
if not exist "%MODEL_PATH%" (
    call :LOG "[FAIL] Qwen model file not found at: %MODEL_PATH%"
    pause
    goto :MENU
)
if not exist "%MMPROJ_PATH%" (
    call :LOG "[FAIL] Multimodal projector not found at: %MMPROJ_PATH%"
    pause
    goto :MENU
)
call :LOG "[OK] All required local assets verified."

REM --- Check existing listener on port & inspect process identity (NO AUTO-KILL) ---
call :LOG "[STEP 2] Checking port %SERVER_PORT% and inspecting any existing process identity..."
set "PORT_PID="
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":%SERVER_PORT% .*LISTENING"') do (
    set "PORT_PID=%%P"
)

if defined PORT_PID (
    call :LOG "[WARN] Port %SERVER_PORT% is ALREADY bound (LISTENING) by PID !PORT_PID!."
    powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$targetPid = [int]$env:PORT_PID; $p = Get-CimInstance Win32_Process -Filter ('ProcessId = ' + $targetPid) -ErrorAction SilentlyContinue; if ($p) { Write-Output ('[IDENTITY] Name=' + $p.Name + ' | ExecutablePath=' + $p.ExecutablePath + ' | CommandLine=' + $p.CommandLine) } else { Write-Output ('[IDENTITY] Could not query Win32_Process for PID ' + $targetPid) }" >> "%DIAG_LOG%" 2>&1
    call :LOG "[INFO] No duplicate llama-server launched. No process was killed."
    goto :VERIFY_LOCAL_ALIAS
)

REM --- Check existing PID file (NO AUTO-KILL) ---
if exist "%PID_FILE%" (
    set "SAVED_PID="
    set /p "SAVED_PID=" < "%PID_FILE%"
    if defined SAVED_PID (
        call :LOG "[INFO] Found existing PID file (%PID_FILE%) with PID=!SAVED_PID!."
        powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$pidVal = [int]$env:SAVED_PID; $proc = Get-Process -Id $pidVal -ErrorAction SilentlyContinue; if ($proc) { Write-Output ('[WARN] PID ' + $pidVal + ' (' + $proc.ProcessName + ') is still alive without listening on port ' + $env:SERVER_PORT); exit 2 } else { Write-Output ('[INFO] PID ' + $pidVal + ' is no longer running (stale PID file).'); exit 0 }" >> "%DIAG_LOG%" 2>&1
        if errorlevel 2 (
            call :LOG "[ABORT] Existing process PID=!SAVED_PID! is still alive. Refusing duplicate launch and refusing auto-kill."
            pause
            goto :MENU
        )
    )
)

REM --- Launch llama-server via single-line PowerShell ---
call :LOG "[STEP 3] Launching llama-server via PowerShell..."
call :LOG "[INFO] Executable: %LLAMA_SERVER%"
call :LOG "[INFO] Arguments: %LLAMA_ARGS%"
call :LOG "[INFO] STDOUT log: %STDOUT_LOG%"
call :LOG "[INFO] STDERR log: %STDERR_LOG%"

if exist "%PID_FILE%" del /f /q "%PID_FILE%" >nul 2>&1
type nul > "%STDOUT_LOG%"
type nul > "%STDERR_LOG%"

powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try { $wd = Split-Path -Path $env:LLAMA_SERVER -Parent; $p = Start-Process -FilePath $env:LLAMA_SERVER -ArgumentList $env:LLAMA_ARGS -WorkingDirectory $wd -RedirectStandardOutput $env:STDOUT_LOG -RedirectStandardError $env:STDERR_LOG -WindowStyle Minimized -PassThru -ErrorAction Stop; Set-Content -LiteralPath $env:PID_FILE -Value $p.Id -NoNewline; exit 0 } catch { Write-Output ('[PS_LAUNCH_ERR] ' + $_.Exception.Message); exit 1 }" >> "%DIAG_LOG%" 2>&1

if errorlevel 1 (
    call :LOG "[FAIL] PowerShell failed to launch llama-server. See %DIAG_LOG%"
    type "%DIAG_LOG%"
    pause
    goto :MENU
)

set "NEW_PID="
if exist "%PID_FILE%" set /p "NEW_PID=" < "%PID_FILE%"

if "%NEW_PID%"=="" (
    call :LOG "[FAIL] llama-server launched but PID file was empty."
    pause
    goto :MENU
)

call :LOG "[OK] llama-server launched. Captured PID=%NEW_PID% (saved to %PID_FILE%)."

REM --- Poll readiness endpoint, detecting early process exit & timeout ---
call :LOG "[STEP 4] Waiting for http://%SERVER_HOST%:%SERVER_PORT%/v1/models (max %MAX_RETRIES% attempts x %POLL_INTERVAL_SEC%s)..."
set /a "retries=0"

:WAIT_SERVER
set /a "retries+=1"
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$proc = Get-Process -Id ([int]$env:NEW_PID) -ErrorAction SilentlyContinue; if (-not $proc) { exit 2 }; $uri = 'http://' + $env:SERVER_HOST + ':' + $env:SERVER_PORT + '/v1/models'; try { $r = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"

set "WAIT_RC=%ERRORLEVEL%"

if "%WAIT_RC%"=="0" (
    call :LOG "[OK] llama-server API responded HTTP 200 on attempt %retries%/%MAX_RETRIES%."
    goto :VERIFY_LOCAL_ALIAS
)

if "%WAIT_RC%"=="2" (
    call :LOG "[FAIL] llama-server process PID=%NEW_PID% EXITED prematurely on attempt %retries%/%MAX_RETRIES%!"
    call :LOG "[INFO] --- Last 30 lines of STDERR (%STDERR_LOG%) ---"
    powershell -NoProfile -NonInteractive -Command "if (Test-Path -LiteralPath $env:STDERR_LOG) { Get-Content -LiteralPath $env:STDERR_LOG -Tail 30 }" >> "%DIAG_LOG%" 2>&1
    type "%DIAG_LOG%"
    pause
    goto :MENU
)

if %retries% GEQ %MAX_RETRIES% (
    call :LOG "[FAIL] Startup TIMEOUT after %MAX_RETRIES% attempts (%POLL_INTERVAL_SEC%s each). PID=%NEW_PID% is still running without ready API."
    call :LOG "[INFO] Process was NOT killed. Inspect %STDOUT_LOG% and %STDERR_LOG%."
    pause
    goto :MENU
)

echo     ...attempt %retries%/%MAX_RETRIES%: waiting for Qwen to load into VRAM...
timeout /t %POLL_INTERVAL_SEC% >nul
goto :WAIT_SERVER

REM --- Verify /v1/models returns expected model alias ---
:VERIFY_LOCAL_ALIAS
call :LOG "[STEP 5] Verifying /v1/models contains expected model alias '%MODEL_ALIAS%'..."
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$uri = 'http://' + $env:SERVER_HOST + ':' + $env:SERVER_PORT + '/v1/models'; try { $resp = Invoke-RestMethod -Uri $uri -TimeoutSec 5 -ErrorAction Stop; $ids = @(); if ($resp.data) { $ids += ($resp.data | ForEach-Object { $_.id }) }; if ($resp.models) { $ids += ($resp.models | ForEach-Object { $_.name }) }; $joined = ($ids -join ', '); Write-Output ('[API] Models returned: ' + $joined); if ($ids -contains $env:MODEL_ALIAS) { Write-Output ('[PASS] Model alias ''' + $env:MODEL_ALIAS + ''' confirmed in API response.'); exit 0 } else { Write-Output ('[FAIL] Expected alias ''' + $env:MODEL_ALIAS + ''' NOT found in API response.'); exit 1 } } catch { Write-Output ('[FAIL] /v1/models check failed: ' + $_.Exception.Message); exit 1 }" >> "%DIAG_LOG%" 2>&1

if errorlevel 1 (
    call :LOG "[FAIL] Local API alias verification failed. See %DIAG_LOG%"
    type "%DIAG_LOG%"
    pause
    goto :MENU
)

call :LOG "[STEP 6] Configuring Hermes provider to custom model '%MODEL_ALIAS%'..."
call "%HERMES_EXE%" config set model.provider custom >> "%DIAG_LOG%" 2>&1
if errorlevel 1 (
    call :LOG "[WARN] Failed to set Hermes model provider to custom."
    pause
)
call "%HERMES_EXE%" config set model.default %MODEL_ALIAS% >> "%DIAG_LOG%" 2>&1
if errorlevel 1 (
    call :LOG "[WARN] Failed to set default Hermes model alias to %MODEL_ALIAS%."
    pause
)
goto :LAUNCH_WORKSPACE

REM ============================================================================
:MODE_CLOUD
REM ============================================================================
call :LOG "============================================================"
call :LOG "[MODE] CLOUD (%CLOUD_PROVIDER%)"
call :LOG "[STEP 1] Configuring session for ChatGPT / Codex Subscription..."
call "%HERMES_EXE%" config set model.provider %CLOUD_PROVIDER% >> "%DIAG_LOG%" 2>&1
if errorlevel 1 (
    call :LOG "[WARN] Failed to set Hermes model provider to %CLOUD_PROVIDER%!"
    pause
) else (
    call :LOG "[OK] Provider set to %CLOUD_PROVIDER%. Authentication will be checked after Hermes starts."
)
goto :LAUNCH_WORKSPACE

REM ============================================================================
:LAUNCH_WORKSPACE
REM ============================================================================
call :LOG "[STEP 7] Launching Hermes workspace environment..."
if not exist "%WORKSPACE%" (
    call :LOG "[INFO] Creating missing workspace directory: %WORKSPACE%"
    mkdir "%WORKSPACE%"
)
cd /d "%WORKSPACE%"

if exist "%HERMES_EXE%" (
    call :LOG "[OK] Launching %HERMES_EXE% in workspace %WORKSPACE%."
    start "" "%HERMES_EXE%"
) else (
    call :LOG "[FAIL] CRITICAL ERROR: hermes.exe not found at %HERMES_EXE%"
    pause
    exit /b 1
)

call :LOG "[PASS] Startup sequence completed successfully."
timeout /t 3 >nul
exit /b 0

REM ============================================================================
:LOG
REM ============================================================================
set "MSG=%~1"
for /f "tokens=1-3 delims=." %%a in ("%TIME%") do set "TS=%DATE% %%a"
echo [%TS%] %MSG%
echo [%TS%] %MSG%>> "%DIAG_LOG%"
goto :eof
