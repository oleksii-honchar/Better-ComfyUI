#!/bin/bash
# Launch comfy-mcp over SSE via the mcp-SDK-based Python SSE wrapper.
# This replaces the legacy mcp-proxy-based launcher.
set -u
echo "[MCP] Starting SSE wrapper on :8189 -> comfy-mcp (stdio)"
exec /opt/conda/bin/python /app/mcp-sse-wrapper.py || { echo "[MCP] FAILED to start SSE wrapper" >&2; exit 1; }
