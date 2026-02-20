#!/bin/bash
set -euo pipefail

echo "🚀 Starting CloneWorks ComfyUI + Jupyter Stack..."

COMFY_ROOT="${COMFY_ROOT:-/opt/comfyui}"
WORKSPACE="${WORKSPACE:-/workspace}"
LOGS_DIR="${LOGS_DIR:-/logs}"

COMFY_PORT="${COMFY_PORT:-8188}"
JUPYTER_PORT="${JUPYTER_PORT:-8888}"

mkdir -p "$WORKSPACE"/comfyui/{models,input,output}
mkdir -p "$WORKSPACE"/logs
mkdir -p "$LOGS_DIR"

chmod -R 777 "$WORKSPACE" "$LOGS_DIR" || true

# Show GPU
if command -v nvidia-smi &> /dev/null; then
  echo "✅ GPU detected:"
  nvidia-smi | head -n 3 || true
else
  echo "⚠️ No GPU detected — running in CPU mode."
fi

echo "🧱 Linking ComfyUI persistent dirs..."
mkdir -p "$COMFY_ROOT"

# Ensure ComfyUI has expected dirs, then replace with symlinks to /workspace
replace_with_symlink () {
  local target="$1"
  local linkto="$2"

  if [ -L "$target" ]; then
    if [ "$(readlink "$target")" = "$linkto" ]; then
      return 0
    fi
    rm -f "$target" || true
  elif [ -e "$target" ]; then
    rm -rf "$target" || true
  fi

  ln -sfn "$linkto" "$target"
}

replace_with_symlink "$COMFY_ROOT/models"  "$WORKSPACE/comfyui/models"
replace_with_symlink "$COMFY_ROOT/input"   "$WORKSPACE/comfyui/input"
replace_with_symlink "$COMFY_ROOT/output"  "$WORKSPACE/comfyui/output"

# Optional: if you want custom_nodes persistent instead of baked into the image
# mkdir -p "$WORKSPACE/comfyui/custom_nodes"
# replace_with_symlink "$COMFY_ROOT/custom_nodes" "$WORKSPACE/comfyui/custom_nodes"

echo "📓 Starting JupyterLab (RunPod proxy-safe, no login)..."
pkill -f jupyter-lab 2>/dev/null || true
pkill -f "jupyter lab" 2>/dev/null || true

nohup jupyter lab \
  --ip=0.0.0.0 \
  --port="$JUPYTER_PORT" \
  --no-browser \
  --allow-root \
  --ServerApp.token='' \
  --ServerApp.password='' \
  --ServerApp.root_dir="$WORKSPACE" \
  --ServerApp.allow_remote_access=True \
  --ServerApp.trust_xheaders=True \
  --ServerApp.disable_check_xsrf=True \
  --ServerApp.allow_origin='*' \
  --ContentsManager.allow_hidden=True \
  > "$LOGS_DIR/jupyter.log" 2>&1 &

echo "🎛️ Starting ComfyUI on 0.0.0.0:${COMFY_PORT} ..."
pkill -f "python.*main.py" 2>/dev/null || true

cd "$COMFY_ROOT"

nohup python3 main.py \
  --listen 0.0.0.0 \
  --port "$COMFY_PORT" \
  > "$LOGS_DIR/comfyui.log" 2>&1 &

echo ""
echo "✅ Services launched!"
echo "🔹 ComfyUI:   http://localhost:${COMFY_PORT} (RunPod proxy ${COMFY_PORT})"
echo "🔹 Jupyter:   http://localhost:${JUPYTER_PORT} (RunPod proxy ${JUPYTER_PORT})"
echo "🔹 Logs:      ${LOGS_DIR}"
echo ""

sleep 2
tail -f "$LOGS_DIR"/*.log

