#!/bin/bash
set -euo pipefail

echo "🚀 Starting CloneWorks AI Toolkit Full Stack..."

# ================================
# 1️⃣  Environment Setup
# ================================
TOOLKIT_ROOT="${TOOLKIT_ROOT:-/opt/ai-toolkit}"
WORKSPACE="${WORKSPACE:-/workspace}"
LOGS_DIR="${LOGS_DIR:-/logs}"

JUPYTER_PORT="${JUPYTER_PORT:-8888}"
UI_PORT="${UI_PORT:-8675}"

export TOOLKIT_ROOT
export PYTHONPATH="$TOOLKIT_ROOT"
export NODE_ENV="${NODE_ENV:-production}"

# Detect GPU
if command -v nvidia-smi &> /dev/null; then
  echo "✅ GPU detected:"
  nvidia-smi | head -n 3 || true
else
  echo "⚠️ No GPU detected — running in CPU mode."
fi

# ================================
# 2️⃣  Persistent Workspace & Links
# ================================
echo "🧱 Setting up persistent workspace and symlinks..."
mkdir -p "$WORKSPACE"/{datasets,models,output,logs}
chmod -R 777 "$WORKSPACE" || true

mkdir -p "$LOGS_DIR"
chmod -R 777 "$LOGS_DIR" || true

# Make toolkit visible in Jupyter under /workspace
ln -sfn "$TOOLKIT_ROOT" "$WORKSPACE/ai-toolkit"

# Replace toolkit dirs with persistent symlinks safely
replace_with_symlink () {
  local target="$1"   # e.g. /opt/ai-toolkit/datasets
  local linkto="$2"   # e.g. /workspace/datasets

  # If target exists as dir/file/link -> remove it (but not if it's already correct)
  if [ -L "$target" ]; then
    # if it's already the correct symlink, do nothing
    if [ "$(readlink "$target")" = "$linkto" ]; then
      return 0
    fi
    rm -f "$target" || true
  elif [ -e "$target" ]; then
    rm -rf "$target" || true
  fi

  ln -sfn "$linkto" "$target"
}

replace_with_symlink "$TOOLKIT_ROOT/datasets" "$WORKSPACE/datasets"
replace_with_symlink "$TOOLKIT_ROOT/output"   "$WORKSPACE/output"

# Link baked WAN noise model if available
if [ -d /models/noise ]; then
  echo "🔗 Linking baked WAN noise model from /models/noise ..."
  mkdir -p "$TOOLKIT_ROOT/models"
  replace_with_symlink "$TOOLKIT_ROOT/models/noise" "/models/noise"
fi

# ================================
# 3️⃣  Backend Initialization
# ================================
echo "⚙️ Ensuring backend (AI Toolkit) permissions..."
chmod +x "$TOOLKIT_ROOT/run.py" 2>/dev/null || true

if [ -f "$TOOLKIT_ROOT/run.py" ]; then
  echo "🧩 Launching AI Toolkit backend..."
  pkill -f "$TOOLKIT_ROOT/run.py" 2>/dev/null || true
  nohup python3 "$TOOLKIT_ROOT/run.py" > "$LOGS_DIR/backend.log" 2>&1 &
else
  echo "⚠️ No backend found at $TOOLKIT_ROOT/run.py — skipping backend start."
fi

# ================================
# 4️⃣  JupyterLab Launch (NO TOKEN)
# ================================
echo "🧠 Starting JupyterLab (no token login)..."
pkill -f "jupyter-lab" 2>/dev/null || true
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

# ================================
# 5️⃣  Next.js UI Launch
# ================================
if [ -d "$TOOLKIT_ROOT/ui" ]; then
  echo "🌐 Launching AI Toolkit UI (Next.js)..."
  cd "$TOOLKIT_ROOT/ui"

  # Sanity: production start needs a build output
  if [ ! -d ".next" ]; then
    echo "⚠️ .next build folder missing → running npm run build ..."
    npm run build > "$LOGS_DIR/next_build.log" 2>&1 || {
      echo "❌ npm build failed — see $LOGS_DIR/next_build.log"
      exit 1
    }
  fi

  # node_modules should exist because dockerfile did npm ci, but keep fallback
  if [ ! -d "node_modules" ]; then
    echo "📦 node_modules missing → npm ci ..."
    npm ci > "$LOGS_DIR/npm_ci.log" 2>&1 || {
      echo "❌ npm ci failed — see $LOGS_DIR/npm_ci.log"
      exit 1
    }
  fi

  # Kill only this UI (avoid nuking unrelated node)
  pkill -f "$TOOLKIT_ROOT/ui.*next" 2>/dev/null || true
  pkill -f "next start" 2>/dev/null || true

  nohup npm run start -- -p "$UI_PORT" > "$LOGS_DIR/next.log" 2>&1 &
else
  echo "⚠️ No UI folder found at $TOOLKIT_ROOT/ui — skipping UI start."
fi

# ================================
# 6️⃣  Feedback & Logs
# ================================
echo ""
echo "✅ CloneWorks stack launched successfully!"
echo "------------------------------------------"
echo "🔹 JupyterLab:      http://localhost:${JUPYTER_PORT}  (RunPod proxy ${JUPYTER_PORT})"
echo "🔹 AI Toolkit UI:   http://localhost:${UI_PORT}  (RunPod proxy ${UI_PORT})"
echo "🔹 Logs:            ${LOGS_DIR}/"
echo "------------------------------------------"
echo ""

sleep 2
echo "📜 Tailing logs (Ctrl+C to stop)..."
tail -f "${LOGS_DIR}"/*.log


