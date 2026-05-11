#!/usr/bin/env bash
#SBATCH --job-name=fs-extract
#SBATCH --account=PAS2836
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --output=/fs/scratch/PAS2836/lees_stuff/wavcaps/_extract_freesound.out
#SBATCH --error=/fs/scratch/PAS2836/lees_stuff/wavcaps/_extract_freesound.err

# Merge split FreeSound zip parts, extract, flatten to audio/FreeSound/, delete intermediates.
# Peak transient disk: ~1.95 TB (zip parts + merged.zip + extracted flacs). Scratch has 1.4 PB.

set -euo pipefail

WAVCAPS=/fs/scratch/PAS2836/lees_stuff/wavcaps
ZIPS=$WAVCAPS/Zip_files/FreeSound
MERGED=$WAVCAPS/Zip_files/FreeSound_merged.zip
TMP=$WAVCAPS/_extract_tmp
OUT=$WAVCAPS/audio/FreeSound

echo "=== START $(date) ==="
echo "scratch free: $(df -h /fs/scratch/PAS2836 | tail -1)"
echo "zip parts: $(ls $ZIPS | wc -l) files, $(du -sh $ZIPS | cut -f1)"

# 1. Merge split zip
echo "=== MERGE $(date) ==="
cd $ZIPS
zip -s 0 FreeSound.zip --out $MERGED
echo "merged: $(du -sh $MERGED)"

# 2. Extract to tmp
echo "=== UNZIP $(date) ==="
mkdir -p $TMP
unzip -q $MERGED -d $TMP
echo "extracted: $(du -sh $TMP)"
echo "flac count: $(find $TMP -name '*.flac' | wc -l)"

# 3. Flatten — move all .flac under tmp to audio/FreeSound/
echo "=== FLATTEN $(date) ==="
mkdir -p $OUT
find $TMP -name '*.flac' -exec mv -t $OUT {} +
echo "flattened: $(ls $OUT | wc -l) flacs in $OUT"
echo "audio size: $(du -sh $OUT)"

# 4. Cleanup
echo "=== CLEANUP $(date) ==="
rm -rf $TMP $MERGED $ZIPS
echo "final scratch free: $(df -h /fs/scratch/PAS2836 | tail -1)"

echo "=== END $(date) ==="
