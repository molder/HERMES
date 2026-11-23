- **HERMES Performance Optimization — Project Summary**
    
    # **HERMES Performance Optimization — Project Summary**
    
    **Date:** 23 November 2026
    
    **Status:** Baseline investigation in progress
    
    ## **1. System configuration**
    
    | Component | Current configuration |
    | --- | --- |
    | GPU | NVIDIA RTX 5070 Ti, 16 GB |
    | Model | Qwen 27B (reported as Qwen3.8-27B) |
    | Inference engine | llama.cpp / llama-server |
    | Agent | Hermes v0.23.0 |
    | Operating system | Windows |
    | Context | 64,000 tokens |
    | Parallel slots | 1 |
    | CPU threads | 12 |
    | GPU device | CUDA0 |
    | GPU fitting | `--fit on --fit-target 3072` |
    | KV cache | Q8 configuration under investigation |
    
    Some settings still need verification against the actual running process.
    
    ## **2. Current investigation**
    
    Our main question:
    
    **Does Hermes automatically compress its conversation before reaching the 64K context limit?**
    
    Latest recorded llama-server measurements:
    
    | Metric | Value |
    | --- | --- |
    | Prompt | 48,578 |
    | Processed | 6,082 |
    | Cached | 40,084 |
    | Context | 64,000 |
    | Processing | True |
    
    Hermes separately displayed:
    
    - 37.1K / 64K pinned
    - 58% context indicator
    - 6.1K generated/reasoning tokens shown in its terminal
    - 467 seconds reasoning duration
    
    These measurements use different accounting systems. Their relationship remains unresolved.
    
    **No automatic compaction has yet been demonstrated.**
    
    ## **3. Outstanding technical questions**
    
    1. Why are llama-server processing counters frozen?
    2. Does Hermes automatically compact conversations?
    3. What does Hermes's pinned-context indicator represent?
    4. Is the running configuration identical to the startup `.bat`?
    5. How much VRAM is actually available during inference?
    6. Is the GPU doing all the intended model computation?
    7. Does the model support MTP speculative decoding?
    
    ## **4. Optimization strategy**
    
    We identified five areas for improvement:
    
    | Priority | Optimization | Objective |
    | --- | --- | --- |
    | 1 | Flash Attention | Faster prompt processing |
    | 2 | Batch / ubatch tuning | Better prefill performance |
    | 3 | Q8 vs Q4 KV cache | Memory efficiency |
    | 4 | MTP speculative decoding | Faster token generation |
    | 5 | Hermes context compaction | Faster long conversations |
    
    These are proposed experiments, not changes already implemented.
    
    ## **5. New working methodology**
    
    We agreed to stop repeating diagnostics and uncontrolled experiments.
    
    Our process:
    
    1. Establish one permanent baseline.
    2. Preserve all existing evidence.
    3. Change one variable at a time.
    4. Record every experiment.
    5. Compare against the original baseline.
    6. Keep or revert each change.
    7. Preserve the original working startup file.
    
    No simultaneous experiments.
    
    ## **6. Immediate next actions**
    
    Authorized
    
    Read-only investigation.
    
    - [ ]  Allow the existing Hermes request to finish.
    - [ ]  Capture final llama-server `/slots`.
    - [ ]  Capture the last 50 relevant Hermes log lines.
    - [ ]  Inspect context-compaction events.
    - [ ]  Resolve the active PID and command line.
    - [ ]  Resolve the authoritative startup `.bat`.
    - [ ]  Record GPU and VRAM usage.
    - [ ]  Establish permanent baseline B00.
    
    **Do not restart the server, change configuration, or send another Hermes prompt during the current measurement.**
    
    ## **7. Final objective**
    
    Build a faster, stable, reproducible Hermes system for long-running technical and creative work.
    
    The optimization must improve:
    
    - Prompt processing speed.
    - Token generation speed.
    - GPU utilization and memory efficiency.
    - Long-context management.
    - Overall system stability.
    
    **The guiding principle: Measure once. Preserve evidence. Optimize systematically. Never start from zero again.**