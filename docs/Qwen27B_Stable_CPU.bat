@echo off
setlocal
 title Qwen 27B - Stable CPU Baseline

set "LLAMA=%LOCALAPPDATA%\hermes\tools\llamacpp-cuda-11671-win32-x64\llama-server.exe"
set "MODEL=%LOCALAPPDATA%\hermes\models\Qwen3.8-27B-UD-Q4_K_M.gguf"
set "MMPROJ=%LOCALAPPDATA%\hermes\models\assets\mmproj-Qwen3.8-27B-BF16.gguf"

if not exist "%LLAMA%" (
  echo ERROR: llama-server.exe was not found:
  echo %LLAMA%
  pause
  exit /b 1
)
if not exist "%MODEL%" (
  echo ERROR: Model file was not found:
  echo %MODEL%
  pause
  exit /b 1
)
if not exist "%MMPROJ%" (
  echo ERROR: Vision projector was not found:
  echo %MMPROJ%
  pause
  exit /b 1
)

echo.
echo Starting Qwen3.8-27B - controlled CPU baseline
echo Host: 127.0.0.1
 echo Port: 8000
 echo Context: 64000
 echo Parallel slots: 1
 echo CPU threads: 12 (generation and batch)
 echo Model GPU layers: 0
 echo Vision projector device: CPU
 echo KV cache: F16
 echo Flash Attention: off
 echo Speculative decoding: none
 echo Jinja: on
 echo.
echo Keep this window open while Hermes uses the model.
echo Stop the server with Ctrl+C in this window.
echo.

"%LLAMA%" ^
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

set "EXITCODE=%ERRORLEVEL%"
echo.
echo llama-server exited with code %EXITCODE%.
pause
exit /b %EXITCODE%
