"""Density packaging only: reuse the existing Pourlune wordmark, never redraw it."""
from pathlib import Path
import argparse
import io
import json
import hashlib

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path('app/assets/art/ui/logo.png')
# Same display bounds as KnitArt('logo'); raw source art stays unchanged.
BOUNDS = (15, 23, 1958, 799)
DENSITIES = [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]


def outputs(root):
    source = Image.open(root / SOURCE).convert('RGBA').crop(BOUNDS)
    files = {}
    def encode(image):
        stream = io.BytesIO()
        image.save(stream, format='PNG', optimize=True)
        return stream.getvalue()
    def mark(scale):
        width = round(176 * scale)
        return source.resize((width, round(width * source.height / source.width)), Image.Resampling.LANCZOS)
    for name, scale in DENSITIES:
        folder = Path(f'app/android/app/src/main/res/drawable-{name}')
        wordmark = mark(scale)
        files[folder / 'startup_wordmark.png'] = encode(wordmark)
        icon = Image.new('RGBA', (round(288 * scale),) * 2)
        icon.alpha_composite(wordmark, ((icon.width-wordmark.width)//2, (icon.height-wordmark.height)//2))
        files[folder / 'startup_icon.png'] = encode(icon)
    for scale in [1, 2, 3]:
        suffix = '' if scale == 1 else f'@{scale}x'
        files[Path(f'app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png')] = encode(mark(scale))
    return files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    files = outputs(ROOT)
    drift = []
    for rel, data in files.items():
        path = ROOT / rel
        if args.write:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        elif not path.exists() or path.read_bytes() != data:
            drift.append(str(rel))
    if drift:
        raise SystemExit('Startup asset drift: ' + ', '.join(drift))
    print(json.dumps({'ok': True, 'count': len(files), 'source_sha256': hashlib.sha256((ROOT/SOURCE).read_bytes()).hexdigest(), 'bounds': BOUNDS}))


if __name__ == '__main__':
    main()
