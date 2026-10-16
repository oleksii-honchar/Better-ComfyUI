---
type: memory
title: "nvcc segfault compiling llama-cpp-python CUDA templates is transient — retry first"
createdAt: "2026-10-16T19:31:00Z"
updatedAt: "2026-10-16T19:31:00Z"
tags: [docker, build, cuda, llama-cpp-python, gotcha]
see_also:
  - "[[0001-fork-update-cycle.runbook]]"
deprecated:
  date: null
  reason: null
  superseded_by: null
---

# Memory: nvcc segfault compiling llama-cpp-python CUDA templates is transient — retry first

## Fact

The Docker build step installing `llama-cpp-python` (CMAKE_ARGS `-DGGML_CUDA=on`) can fail with **nvcc exit 139 / "Segmentation fault (core dumped)"** on a `fattn-mma-f16-instance-*.cu` template instance, with no compiler diagnostic (`ninja: build stopped: subcommand failed`). A plain retry succeeded — the crash is transient, not a code/version problem.

## Context

Hit on 2026-10-16 during the v0.41.2 image build on behemoth.lan. Ruled out version drift (the failing build and the known-good image both resolve `llama_cpp_python==0.3.36`) and OOM (49 GB available, no dmesg OOM entries). The `nvcc warning: Cannot find valid GPU for '-arch=native', default arch is used` on every CUDA TU is **expected** inside `docker build` (no GPU in build containers) and was present in successful builds too.

## Impact

On this failure mode: retry the build once before investigating version pins or CUDA arch flags. If it ever becomes reproducible, the deterministic fix is `CMAKE_ARGS="-DGGML_CUDA=on -DCMAKE_CUDA_ARCHITECTURES=120"` (sm_120 = RTX 5080/Blackwell; CUDA 12.8 supports it) — also strictly better than the default-arch PTX-JIT fallback.
