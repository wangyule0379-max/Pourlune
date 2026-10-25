"""Describe launch video samples; a color check, never a startup/FPS benchmark."""
from pathlib import Path
import argparse
import json
from PIL import Image, ImageDraw


def inspect(folder, output):
    data = json.loads((folder / 'samples.json').read_text())
    results = []
    for row in data['frames']:
        image = Image.open(folder / row['file']).convert('RGB')
        # Exclude system bars; the old failure occupied the whole app window.
        image = image.crop((round(image.width*.02), round(image.height*.08),
                            round(image.width*.98), round(image.height*.96))).resize((100, 200))
        pixels = list(image.getdata())
        white = sum(min(rgb) >= 240 and max(rgb)-min(rgb) <= 15 for rgb in pixels) / len(pixels)
        blue = sum(abs(r-130) <= 30 and abs(g-223) <= 30 and abs(b-241) <= 30
                   for r,g,b in pixels) / len(pixels)
        results.append({**row, 'white_fraction': round(white, 4), 'blue_fraction': round(blue, 4)})
    report = {key:value for key,value in data.items() if key != 'frames'}
    report.update({'method':'100x200 app-interior sample; white RGB>=240 and channel spread<=15',
                   'white_dominant_threshold': .7, 'performance_claim':False,
                   'white_dominant_samples':[x['requested_seconds'] for x in results if x['white_fraction'] >= .7],
                   'samples':results})
    output.mkdir(parents=True, exist_ok=True)
    (output / 'frame-check.json').write_text(json.dumps(report, indent=2)+'\n')
    selected = results[::4]
    w,h = 156,370
    sheet = Image.new('RGB',(w*10,h*((len(selected)+9)//10)),'#e8dfcf')
    draw = ImageDraw.Draw(sheet)
    for n,row in enumerate(selected):
        image=Image.open(folder/row['file']).convert('RGB');image.thumbnail((150,340))
        x=(n%10)*w+(w-image.width)//2;y=(n//10)*h
        sheet.paste(image,(x,y));draw.text(((n%10)*w+4,y+344),f"{row['requested_seconds']:.1f}s w={row['white_fraction']:.2f}",fill='black')
    sheet.save(output/'launch-frames.jpg',quality=90)
    print(json.dumps({'frames':len(results),'white_dominant_samples':report['white_dominant_samples']}))


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('frames', type=Path)
    parser.add_argument('output', type=Path)
    args=parser.parse_args()
    inspect(args.frames,args.output)
