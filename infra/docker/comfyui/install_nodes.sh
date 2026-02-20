#!/usr/bin/env bash
set -euo pipefail

NODES_FILE="${1:-/docker/nodes.txt}"
CUSTOM_NODES_DIR="${2:-/opt/ComfyUI/custom_nodes}"

echo "🧩 Installing ComfyUI custom nodes..."
echo " - nodes file: ${NODES_FILE}"
echo " - target dir: ${CUSTOM_NODES_DIR}"

mkdir -p "${CUSTOM_NODES_DIR}"

if [ ! -f "${NODES_FILE}" ]; then
  echo "❌ nodes file not found: ${NODES_FILE}"
  exit 1
fi

# Read nodes.txt line by line
while IFS= read -r line || [ -n "$line" ]; do
  # trim whitespace
  repo="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

  # skip empty lines and comments
  if [ -z "${repo}" ] || [[ "${repo}" == \#* ]]; then
    continue
  fi

  # normalize folder name from repo url
  name="$(basename "${repo}")"
  name="${name%.git}"
  dest="${CUSTOM_NODES_DIR}/${name}"

  if [ -d "${dest}/.git" ]; then
    echo "✅ Already exists, skipping: ${name}"
    continue
  fi

  echo "⬇️  Cloning: ${repo}"
  git clone --depth 1 --recursive "${repo}" "${dest}"

  # Some repos ship python deps. Install if present.
  # We'll install common patterns without being too aggressive.
  reqs=()
  [ -f "${dest}/requirements.txt" ] && reqs+=("${dest}/requirements.txt")

  # also support requirements-*.txt / requirements/*.txt
  for f in "${dest}"/requirements-*.txt "${dest}"/requirements/*.txt; do
    [ -f "$f" ] && reqs+=("$f")
  done

  if [ "${#reqs[@]}" -gt 0 ]; then
    echo "📦 Installing python deps for ${name}:"
    for r in "${reqs[@]}"; do
      echo "   - $(basename "$r")"
      pip install --no-cache-dir -r "$r" || {
        echo "⚠️  Warning: pip deps failed for ${name} ($r). Node may still work."
      }
    done
  fi

done < "${NODES_FILE}"

echo "✅ Custom nodes installed."

