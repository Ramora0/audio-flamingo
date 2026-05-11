#!/usr/bin/env bash
# Run AF2 training inside an interactive GPU session.
# Sources the AF2 venv + cache env, cd into train/, launches torchrun.
#
# Usage (inside an interactive A100 allocation):
#   bash cluster/run_train.sh <config> [nproc-per-node]
#
# Examples:
#   bash cluster/run_train.sh configs/soundbible-smoke.yaml 1
#   bash cluster/run_train.sh configs/freesound-pretrain.yaml 4
#
# CONFIG is resolved as:
#   1. absolute path, or
#   2. relative to repo root (e.g. "audio_flamingo_2/configs/freesound-pretrain.yaml"), or
#   3. relative to audio_flamingo_2/ (e.g. "configs/freesound-pretrain.yaml")
#
# NPROC defaults to the visible CUDA device count.

set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CONFIG=${1:?config path required (e.g. configs/freesound-pretrain.yaml)}
NPROC=${2:-$(python3 -c "import torch; print(torch.cuda.device_count())" 2>/dev/null || echo 1)}

# Resolve config to an absolute path
for cand in "$CONFIG" "$REPO/$CONFIG" "$REPO/audio_flamingo_2/$CONFIG"; do
    if [[ -f "$cand" ]]; then
        CONFIG_ABS=$(cd "$(dirname "$cand")" && pwd)/$(basename "$cand")
        break
    fi
done
if [[ -z "${CONFIG_ABS:-}" ]]; then
    echo "ERROR: config not found: $CONFIG" >&2
    exit 1
fi

# Activate env (sets HF caches to scratch, sources venv)
source "$REPO/cluster/activate.sh"

cd "$REPO/audio_flamingo_2/train"

echo "=== launch $(date) ==="
echo "  config:  $CONFIG_ABS"
echo "  nproc:   $NPROC"
echo "  cwd:     $(pwd)"
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>/dev/null || echo "  (no GPUs visible — torchrun will fail)"
echo

# torchrun with --standalone handles single-node MASTER_ADDR/PORT rendezvous
exec torchrun --standalone --nproc-per-node="$NPROC" train.py -c "$CONFIG_ABS"
