#!/usr/bin/env python3
"""Convert a WavCaps caption JSON (cvssp/WavCaps) into the AF2 manifest schema.

The same script handles SoundBible and FreeSound — both use the WavCaps schema:
    {"num_captions_per_audio": ..., "data": [{"id": ..., "caption": ..., "duration": ..., ...}, ...]}

AF2's data.py expects:
    {"split": ..., "split_path": ..., "flamingo_task": ..., "total_num": N,
     "data": {"0": {"name": "<file>", "prompt": ..., "output": ..., "duration": ...}, ...}}

Audio file path is resolved as os.path.join(DATA_ROOT, split_path, name).
"""
import argparse
import json
import os
import sys
from pathlib import Path

CAPTIONING_PROMPT = "Caption the input audio."


def load_blacklist(paths):
    """Union of IDs across the given WavCaps blacklist JSONs (skip if not provided)."""
    bad = set()
    for p in paths or []:
        with open(p) as f:
            obj = json.load(f)
        for v in (obj.values() if isinstance(obj, dict) else [obj]):
            if isinstance(v, list):
                bad.update(str(x) for x in v)
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--wavcaps-json", required=True,
                    help="Path to WavCaps caption JSON (e.g. sb_final.json, fsd_final.json)")
    ap.add_argument("--audio-dir", required=True,
                    help="Absolute path to the directory containing the audio files (used to verify existence)")
    ap.add_argument("--split-path", required=True,
                    help="Value for manifest's split_path field (relative to DATA_ROOT)")
    ap.add_argument("--flamingo-task", required=True,
                    help="Task name (e.g. WavCaps-SoundBible-AudioCaptioning)")
    ap.add_argument("--split", default="train")
    ap.add_argument("--ext", default=".flac")
    ap.add_argument("--out", required=True, help="Output manifest JSON path")
    ap.add_argument("--max-duration", type=float, default=None,
                    help="If set, drop entries whose duration exceeds this (seconds)")
    ap.add_argument("--min-duration", type=float, default=0.5,
                    help="Drop entries shorter than this (seconds). Default 0.5.")
    ap.add_argument("--blacklist", nargs="*", default=None,
                    help="Optional WavCaps blacklist JSONs whose IDs to exclude")
    ap.add_argument("--prompt", default=CAPTIONING_PROMPT)
    args = ap.parse_args()

    audio_dir = Path(args.audio_dir)
    if not audio_dir.is_dir():
        sys.exit(f"audio-dir not found: {audio_dir}")

    with open(args.wavcaps_json) as f:
        src = json.load(f)
    rows = src["data"]
    print(f"input: {len(rows)} entries from {args.wavcaps_json}")

    bad_ids = load_blacklist(args.blacklist)
    if bad_ids:
        print(f"blacklist: {len(bad_ids)} ids loaded")

    out_data = {}
    n_missing = n_blacklisted = n_too_short = n_too_long = n_no_caption = 0
    for e in rows:
        sid = str(e["id"])
        if sid in bad_ids:
            n_blacklisted += 1
            continue
        caption = e.get("caption")
        if not caption:
            n_no_caption += 1
            continue
        dur = float(e.get("duration", 0.0))
        if dur < args.min_duration:
            n_too_short += 1
            continue
        if args.max_duration is not None and dur > args.max_duration:
            n_too_long += 1
            continue
        fname = f"{sid}{args.ext}"
        if not (audio_dir / fname).is_file():
            n_missing += 1
            continue
        out_data[str(len(out_data))] = {
            "name": fname,
            "prompt": args.prompt,
            "output": caption,
            "duration": dur,
        }

    manifest = {
        "split": args.split,
        "split_path": args.split_path,
        "flamingo_task": args.flamingo_task,
        "total_num": len(out_data),
        "data": out_data,
    }

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w") as f:
        json.dump(manifest, f)
    print(f"wrote {len(out_data)} entries -> {out_path}")
    print(f"  dropped: missing-on-disk={n_missing}, no-caption={n_no_caption}, "
          f"blacklisted={n_blacklisted}, too-short(<{args.min_duration}s)={n_too_short}, "
          f"too-long(>{args.max_duration}s)={n_too_long}")


if __name__ == "__main__":
    main()
