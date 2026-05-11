#!/usr/bin/env bash
#SBATCH --job-name=fs-merge
#SBATCH --account=PAS2836
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=03:00:00
#SBATCH --output=/fs/scratch/PAS2836/lees_stuff/wavcaps/_merge_freesound.out
#SBATCH --error=/fs/scratch/PAS2836/lees_stuff/wavcaps/_merge_freesound.err

# Merge FreeSound split-zip parts (.zip + .z01-.z121) into a single zip.
# Output: shards/FreeSound.zip (~650 GB, 1 file). Source parts deleted on success.
# Peak transient: ~1.3 TB (parts + merged). Final: ~650 GB.
#
# Loader (audio_flamingo_2/data/data.py) reads members directly from this zip;
# no extraction needed (avoids 262K small files on scratch).

set -euo pipefail

WAVCAPS=/fs/scratch/PAS2836/lees_stuff/wavcaps
SRC=$WAVCAPS/Zip_files/FreeSound
SHARDS=$WAVCAPS/shards
OUT=$SHARDS/FreeSound.zip

echo "=== START $(date) ==="
echo "scratch free: $(df -h /fs/scratch/PAS2836 | tail -1)"
echo "parts: $(ls $SRC | wc -l) files, $(du -sh $SRC | cut -f1)"

mkdir -p $SHARDS

echo "=== MERGE $(date) ==="
cd $SRC
zip -s 0 FreeSound.zip --out $OUT
echo "merged: $(du -sh $OUT)"

echo "=== VERIFY $(date) ==="
flac_count=$(unzip -l $OUT | awk '$4 ~ /\.flac$/' | wc -l)
echo "flac members: $flac_count"
if [[ "$flac_count" -lt 250000 ]]; then
    echo "ERROR: expected ~262K flacs, got $flac_count" >&2
    exit 1
fi

echo "=== CLEANUP $(date) ==="
rm -rf $SRC
echo "final scratch free: $(df -h /fs/scratch/PAS2836 | tail -1)"
echo "final $OUT: $(du -sh $OUT)"

echo "=== END $(date) ==="
