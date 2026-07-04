#!/usr/bin/env bash
#
# capture_scene.sh — render a Godot (AXEL) scene to a PNG headlessly.
#
# Uses a virtual X display (Xvfb) plus Mesa software rendering (llvmpipe /
# lavapipe) so it works on GPU-less machines such as cloud agent VMs. Delegates
# the actual capture to res://tools/capture_scene.gd.
#
# Usage:
#   tools/capture_scene.sh <res://scene.tscn> <output.png> [frames] [WIDTHxHEIGHT]
#
# Examples:
#   tools/capture_scene.sh res://scenes/Main_Menu/0.1_MainMenu.tscn out/menu.png
#   tools/capture_scene.sh res://scenes/Arc_1/1.1_SchoolExterior.tscn shot.png 60 1280x720
#
# Environment overrides:
#   GODOT_BIN   godot binary to use (default: godot on PATH)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_PATH="${REPO_ROOT}/AXEL/axel_project"

SCENE="${1:-}"
OUT="${2:-}"
FRAMES="${3:-30}"
RES="${4:-1280x720}"

if [[ -z "${SCENE}" || -z "${OUT}" ]]; then
  echo "Usage: $0 <res://scene.tscn> <output.png> [frames] [WIDTHxHEIGHT]" >&2
  exit 2
fi

GODOT_BIN="${GODOT_BIN:-godot}"
if ! command -v "${GODOT_BIN}" >/dev/null 2>&1; then
  echo "ERROR: godot binary not found (looked for '${GODOT_BIN}'). Set GODOT_BIN or install Godot 4.6.3." >&2
  exit 1
fi
if ! command -v xvfb-run >/dev/null 2>&1; then
  echo "ERROR: xvfb-run not found. Install xvfb (apt-get install -y xvfb)." >&2
  exit 1
fi

# Resolve the output path to an absolute path so it is written relative to the
# caller's working directory rather than the Godot project root.
OUT_DIR="$(dirname "${OUT}")"
mkdir -p "${OUT_DIR}"
OUT_ABS="$(cd "${OUT_DIR}" && pwd)/$(basename "${OUT}")"

# Force Mesa software rendering so no physical GPU is required.
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe

echo "Capturing ${SCENE} -> ${OUT_ABS} (${RES}, ${FRAMES} frames)"

xvfb-run -a -s "-screen 0 ${RES}x24" \
  "${GODOT_BIN}" --path "${PROJECT_PATH}" \
  --resolution "${RES}" \
  -s res://tools/capture_scene.gd -- "${SCENE}" "${OUT_ABS}" "${FRAMES}"

if [[ -f "${OUT_ABS}" ]]; then
  echo "Saved: ${OUT_ABS}"
else
  echo "ERROR: capture reported success but ${OUT_ABS} is missing." >&2
  exit 1
fi
