#!/bin/bash
# Better-ComfyUI entrypoint
#  - creates model directories (including unet_gguf)
#  - installs custom-node requirements
#  - starts ComfyUI respecting the CLI_ARGS env var (e.g. --enable-manager --lowvram)
set -e

echo "Creating model directories..."
for d in checkpoints clip clip_vision configs controlnet diffusers diffusion_models \
         embeddings gligen hypernetworks loras model_patches photomaker style_models \
         text_encoders unet unet_gguf upscale_models vae vae_approx; do
    mkdir -p "/opt/comfyui/models/$d"
done

echo "Installing custom node requirements..."
for req in /opt/comfyui/custom_nodes/*/requirements.txt; do
    [ -f "$req" ] || continue
    node="$(basename "$(dirname "$req")")"
    echo "  - $node"
    /opt/conda/bin/pip install --no-cache-dir -r "$req" \
        || echo "  WARN: failed to install requirements for $node"
done

# Start MCP SSE wrapper as a background managed child (baked into image; no host script needed).
# NOTE: MUST be backgrounded — the launcher runs the mcp-SDK SSE server (long-running);
# a foreground invocation would block the entrypoint and ComfyUI would never start.
if [ -x /mcp-sse-launcher.sh ]; then
    echo "[INFO] Starting MCP SSE wrapper (background)..."
    COMFY_LOCAL_URL=http://127.0.0.1:8188 /mcp-sse-launcher.sh \
        > /tmp/mcp-sse.log 2>&1 &
fi

cd /opt/comfyui
exec /opt/conda/bin/python main.py \
    --port 8188 \
    --listen 0.0.0.0 \
    --disable-auto-launch \
    ${CLI_ARGS} "$@"
