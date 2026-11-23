# Hermes Startup Manager (`startup.bat`) Documentation

This documentation details the execution flow, architectural order, and underlying technical parameters of the `startup.bat` script configured for your Hermes environment.

---

## 1. Execution Order & Pipeline

The startup script enforces a strict sequential workflow to guarantee that dependencies are met before downstream components execute.

```
[1. User Selection Menu]
        │
        ├──► Option 1: Local Qwen 3.8-27B
        │       │
        │       ▼
        │   [2. Pre-Flight Server Check]
        │       ├──► (Already Running) ──┐
        │       │                       │
        │       └──► (Not Running)      │
        │               │               │
        │               ▼               │
        │   [3. Spawn llama-server]     │
        │               │               │
        │               ▼               │
        │   [4. Health Check Loop]      │
        │               │               │
        │               └───────────────┴──► [5. Launch Hermes Workspace]
        │                                             │
        ├──► Option 2: ChatGPT / Cloud                │
        │       │                                     │
        │       └─────────────────────────────────────┘
        │
        └──► Option 3: Exit
```

### Sequence Breakdown

1. **User Provider Choice:** The script displays an interactive prompt allowing manual selection between the local GPU pipeline (`Option 1`) and cloud routing (`Option 2`).
2. **Pre-Flight Endpoint Audit:** Before spawning any process, the script queries `http://127.0.0.1:8000/v1/models` via `curl`. If the endpoint responds with HTTP 200, the script detects an active local instance and skips starting a duplicate server process to prevent port collisions.
3. **`llama-server` Execution (Local Mode Only):** If no active server is detected, `llama-server.exe` launches in a dedicated command window using the tested RTX 5070 Ti allocation parameters.
4. **API Readiness Polling:** The main batch script enters a polling loop, querying the readiness endpoint every 2 seconds until the model and multimodal projector are fully mapped into memory and ready to accept requests.
5. **Workspace Directory & Hermes Initialization:** Once the local API is confirmed ready (or immediately if Cloud mode was selected), the batch script changes working directories to `%USERPROFILE%\Documents\Hermes_Workspace` and executes `%LOCALAPPDATA%\hermes\bin\hermes.exe`.

---

## 2. Technical Parameter Reference

The local server initialization relies on specific runtime flags optimized for the NVIDIA RTX 5070 Ti (16 GB VRAM) and 12-thread host CPU configuration:

| Parameter | Configured Value | Operational Role |
| :--- | :--- | :--- |
| `--model` | `Qwen3.8-27B-UD-Q4_K_M.gguf` | Loads the base 27B quantized model weights. |
| `--mmproj` | `mmproj-Qwen3.8-27B-BF16.gguf` | Enables multimodal (vision/image processing) capability. |
| `--mmproj-device` | `none` | Keeps vision projection handling aligned with host memory rules to prevent VRAM allocation panics. |
| `--host` / `--port` | `127.0.0.1` : `8000` | Exposes standard OpenAI-compatible local endpoints (`/v1/models`, `/v1/chat/completions`). |
| `--alias` | `Qwen3.8-27B` | Standardized model routing alias for client API calls. |
| `--device` | `CUDA0` | Binds primary acceleration to the main NVIDIA GPU. |
| `--fit` | `on` | Enables automatic VRAM layer fitting instead of static `-ngl 99`. |
| `--fit-target` | `3072` | Preserves 3,072 MiB (3 GB) VRAM safety headroom for OS rendering and display outputs. |
| `--threads` / `--threads-batch` | `12` | Allocates 12 CPU core threads for host side-processing and offloaded layers. |
| `--cache-type-k` / `-v` | `f16` | Maintains standard precision for KV attention caches. |
| `--jinja` | *Enabled* | Uses embedded Jinja chat templates for correct Qwen 3.8 prompt formatting. |
| `--no-webui` | *Enabled* | Disables the standalone browser interface to conserve host memory. |

---

## 3. Maintenance & Troubleshooting

* **Customizing Workspace Location:** Edit the `set "WORKSPACE=..."` path at the top of `startup.bat` if your project folder moves.
* **Inspecting Local Logs:** If Qwen fails to load, check the spawned `Hermes Llama Server` console window for `llama_params_fit` errors or CUDA out-of-memory warnings.
* **Forcing a Clean Restart:** If the script reports that the server is already running when it is non-responsive, close the background `llama-server.exe` process via Windows Task Manager before launching `startup.bat`.