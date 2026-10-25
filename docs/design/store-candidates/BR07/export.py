"""Reproduce BR07 local PNG candidates from hash-pinned existing artwork.

No image generation, app writes, screenshots, uploads or rights approval.
Requires Pillow; see README for the existing bundled Python runtime.
"""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import sys

from PIL import Image, ImageDraw, ImageFont, __version__ as pillow_version

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def contain(canvas, source, box):
    """Center an unchanged-aspect source inside a layout rectangle."""
    x, y, width, height = box
    with Image.open(ROOT / source) as original:
        image = original.convert('RGBA')
    scale = min(width / image.width, height / image.height)
    size = (round(image.width * scale), round(image.height * scale))
    image = image.resize(size, Image.Resampling.LANCZOS)
    position = (round(x + (width - size[0]) / 2),
                round(y + (height - size[1]) / 2))
    canvas.alpha_composite(image, position)
    return dict(source=source, layout_box_xywh=list(box),
                drawn_xywh=[*position, *size], aspect_preserved=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=HERE,
                        help='New output filenames only; existing exports are never overwritten')
    args = parser.parse_args()
    layout = json.loads((HERE / 'layout.json').read_text())
    for name, record in layout['inputs'].items():
        if digest(ROOT / name) != record['sha256']:
            raise SystemExit('Source hash changed: ' + name)
    output = args.output.resolve()
    names = [layout['icon']['output'], layout['feature']['output'], 'manifest.json']
    if any((output / name).exists() for name in names):
        raise SystemExit('Refusing to overwrite existing BR07 exports')
    output.mkdir(parents=True, exist_ok=True)

    icon_spec = layout['icon']
    with Image.open(ROOT / icon_spec['source']) as source:
        if source.size != (1024, 1024):
            raise SystemExit('Unexpected icon input geometry')
        icon = source.convert('RGBA').resize(tuple(icon_spec['size']), Image.Resampling.LANCZOS)
    icon.save(output / icon_spec['output'], optimize=True)

    spec = layout['feature']
    with Image.open(ROOT / spec['background']['source']) as background:
        canvas = background.crop(tuple(spec['background']['crop_xyxy'])).convert('RGBA')
    assert canvas.size == tuple(spec['size'])
    scene_x, scene_y, scene_w, scene_h = spec['scene_square_xywh']
    drawn = []
    for layer in spec['layers']:
        if 'normalized_scene_rect' in layer:
            x, y, width, height = layer['normalized_scene_rect']
            box = [scene_x + x * scene_w, scene_y + y * scene_h,
                   width * scene_w, height * scene_h]
        else:
            box = layer['box_xywh']
        drawn.append(dict(id=layer['id'], **contain(canvas, layer['source'], box)))
    text_spec = spec['text']
    font = ImageFont.truetype(str(ROOT / text_spec['source_font']), text_spec['font_size_px'])
    axes = font.get_variation_axes()
    assert len(axes) == 1 and axes[0]['name'] == b'Weight'
    font.set_variation_by_axes([text_spec['font_weight']])
    draw = ImageDraw.Draw(canvas)
    text_bounds = []
    for text, position in zip(text_spec['lines'], text_spec['line_top_left']):
        bounds = draw.textbbox(tuple(position), text, font=font, anchor='lt')
        assert bounds[0] >= 64 and bounds[2] <= 510 and bounds[3] <= 400
        draw.text(tuple(position), text, font=font, fill=tuple(text_spec['fill_rgb']), anchor='lt')
        text_bounds.append(dict(text=text, bbox_xyxy=list(bounds)))
    canvas.convert('RGB').save(output / spec['output'], optimize=True)

    outputs = []
    for name in names[:2]:
        path = output / name
        with Image.open(path) as image:
            outputs.append(dict(file=name, sha256=digest(path), bytes=path.stat().st_size,
                                format=image.format, mode=image.mode, dimensions_px=list(image.size)))
    manifest = dict(status='local-candidate', publication_status='not-approved-for-publication',
                    rights_status='UNCONFIRMED', runtime_screenshot=False,
                    generated_new_art=False,
                    original_rights='Inherited original/reference-derived images remain unconfirmed. Font OFL does not cover artwork.',
                    layout_sha256=digest(HERE / 'layout.json'), script_sha256=digest(Path(__file__)),
                    input_art_version='Existing B03/B03-R01 assets, unchanged in BR06 0.5.0+6',
                    runtime=dict(python=platform.python_version(), pillow=pillow_version),
                    outputs=outputs, drawn_layers=drawn, text=text_spec, text_bounds=text_bounds,
                    restrictions=['Do not upload or publish until commercial rights and final asset review are satisfied.',
                                  'Promotional assembled scene, not actual app screenshot or achieved player progress.',
                                  'This script never captures a screen, operates a device, or changes app/assets.'])
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(dict(status=manifest['status'], rights_status=manifest['rights_status'],
                          outputs=outputs), indent=2))


if __name__ == '__main__':
    main()
