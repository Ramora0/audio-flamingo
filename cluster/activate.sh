#!/usr/bin/env bash
# Activate the AF2 venv and point all HF/torch caches at scratch (NOT HOME).
# Usage:  source cluster/activate.sh
#
# Idempotent: safe to source repeatedly. Leaves you in your current shell.

# --- Paths (cluster-specific; edit if you move things) ---
export AF2_SCRATCH=${AF2_SCRATCH:-/fs/scratch/PAS2836/lees_stuff}
export AF2_VENV=${AF2_VENV:-$AF2_SCRATCH/envs/af2}

# --- Force every cache off HOME ---
export HF_HOME="$AF2_SCRATCH/hf_cache"
export HF_HUB_CACHE="$HF_HOME/hub"
export HF_DATASETS_CACHE="$HF_HOME/datasets"
export TRANSFORMERS_CACHE="$HF_HOME/transformers"
export XDG_CACHE_HOME="$HF_HOME/xdg"
export PIP_CACHE_DIR="$AF2_SCRATCH/pip_cache"
export TMPDIR="$AF2_SCRATCH/tmp"
export HF_HUB_DISABLE_TELEMETRY=1
export HF_HUB_ENABLE_HF_TRANSFER=1

# --- Activate venv ---
if [[ ! -f "$AF2_VENV/bin/activate" ]]; then
    echo "ERROR: venv not found at $AF2_VENV" >&2
    return 1
fi
# shellcheck disable=SC1091
source "$AF2_VENV/bin/activate"

# --- Confirmation ---
echo "AF2 env active:"
echo "  python:  $(which python)  ($(python --version 2>&1))"
echo "  venv:    $AF2_VENV"
echo "  HF_HOME: $HF_HOME"
echo "  data:    $AF2_SCRATCH/wavcaps/"
echo "  ckpts:   $AF2_SCRATCH/checkpoints/af2/"
echo "  runs:    $AF2_SCRATCH/runs/"
