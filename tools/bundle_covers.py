#!/usr/bin/env python3
"""Bundles story covers into <project>/assets/covers/.

  pip install pillow
  python tools/bundle_covers.py --project C:\\path\\to\\arknight_reader

Writes assets/covers/{main,side,vignette}/<chapterId>.webp and
assets/covers/tilt.json (polaroid tilt of each main cover, measured on the
original PNG). Existing .webp files are skipped, so re-running before a
release only adds new chapters."""
import argparse
import io
import json
import math
import sys
import urllib.request
from pathlib import Path

from PIL import Image

INDEX = ("https://cdn.jsdelivr.net/gh/ArknightsAssets/ArknightsGamedata@master/"
         "en/gamedata/excel/story_review_table.json")
RAW = ("https://raw.githubusercontent.com/ArknightsAssets/ArknightsAssets2/"
       "en/assets/dyn/arts/ui/")
CDN = ("https://cdn.jsdelivr.net/gh/ArknightsAssets/ArknightsAssets2@en/"
       "assets/dyn/arts/ui/")


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "bundle-covers"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def rel_path(entry_type, cid, pic):
    pic = (pic or "").strip().lower()
    if entry_type == "MAINLINE":
        return "main", f"mainmission/{cid.lower()}.png"
    if entry_type == "ACTIVITY" and pic:
        return "side", f"storyreview/hubs/activity/{pic}.png"
    if entry_type == "MINI_ACTIVITY" and pic:
        return "vignette", f"storyreview/hubs/mini/storyentrypic/{pic}.png"
    return None


def detect_tilt(img):
    """Port of CoverTilt.detectFromRgba (Theil-Sen fit of the frame's top
    edge). Returns clockwise degrees that level the frame, or None."""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    xs, ys = [], []
    for x in range(int(w * 0.15), int(w * 0.85), 3):
        for y in range(int(h * 0.35)):
            r, g, b, a = px[x, y]
            if a >= 200 and min(r, g, b) >= 225:
                xs.append(x)
                ys.append(y)
                break
    n = len(xs)
    if n < 40:
        return None

    min_sep = w * 0.25
    slopes = []
    for i in range(n):
        for j in range(i + 1, n):
            dx = xs[j] - xs[i]
            if dx >= min_sep:
                slopes.append((ys[j] - ys[i]) / dx)
    if len(slopes) < 20:
        return None
    slopes.sort()
    slope = slopes[len(slopes) // 2]

    residuals = sorted(ys[i] - slope * xs[i] for i in range(n))
    intercept = residuals[n // 2]
    inliers = sum(
        1 for i in range(n)
        if abs(ys[i] - (slope * xs[i] + intercept)) <= 1.5
    )
    if inliers / n < 0.7:
        return None

    degrees = -math.atan(slope) * 180 / math.pi
    return degrees if abs(degrees) <= 3.0 else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", required=True)
    ap.add_argument("--quality", type=int, default=90)
    args = ap.parse_args()

    root = Path(args.project) / "assets" / "covers"
    root.mkdir(parents=True, exist_ok=True)

    tilt_file = root / "tilt.json"
    tilts = json.loads(tilt_file.read_text()) if tilt_file.exists() else {}

    index = json.loads(get(INDEX))
    added = skipped = 0
    not_online = []

    for cid, e in index.items():
        r = rel_path(e.get("entryType", ""), cid, e.get("storyEntryPicId", ""))
        if r is None:
            continue
        folder, rel = r
        out = root / folder / f"{cid}.webp"

        if out.exists():
            skipped += 1
            if folder == "main" and cid not in tilts:
                t = detect_tilt(Image.open(out))
                tilts[cid] = round(t, 3) if t is not None else 0.0
            continue

        data = None
        for base in (RAW, CDN):
            try:
                data = get(base + rel)
                break
            except Exception:
                pass
        if data is None:
            not_online.append(cid)
            continue

        img = Image.open(io.BytesIO(data)).convert("RGBA")
        if folder == "main":
            t = detect_tilt(img)  # measured on the original, before WebP
            tilts[cid] = round(t, 3) if t is not None else 0.0

        out.parent.mkdir(parents=True, exist_ok=True)
        img.save(out, "WEBP", quality=args.quality, method=6)  # keeps alpha
        added += 1
        print("saved", out)

    # Make sure all three folders exist so pubspec's asset folders are valid.
    for folder in ("main", "side", "vignette"):
        (root / folder).mkdir(parents=True, exist_ok=True)

    tilt_file.write_text(json.dumps(tilts, indent=2, sort_keys=True))
    print(f"\nnew: {added}  already present: {skipped}  "
          f"not online: {len(not_online)}")
    if not_online:
        print("no online cover (keep old bundled image):",
              ", ".join(not_online))


if __name__ == "__main__":
    sys.exit(main())