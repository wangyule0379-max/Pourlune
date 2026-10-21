"""Deterministic platform-size exports; no compositing or semantic edits."""
from pathlib import Path
import hashlib
import json
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'docs/design/production-candidates/runtime/icons/brand-source.png'
def main():
    image=Image.open(SOURCE).convert('RGB')
    ios=ROOT/'app/ios/Runner/Assets.xcassets/AppIcon.appiconset'
    outputs={}
    for spec in json.loads((ios/'Contents.json').read_text())['images']:
        outputs[ios/spec['filename']]=round(float(spec['size'].split('x')[0])*float(spec['scale'][:-1]))
    for density,size in zip(['mdpi','hdpi','xhdpi','xxhdpi','xxxhdpi'],[48,72,96,144,192]):
        outputs[ROOT/f'app/android/app/src/main/res/mipmap-{density}/ic_launcher.png']=size
    rows=[]
    for path,size in outputs.items():
        image.resize((size,size),Image.Resampling.LANCZOS).save(path)
        rows.append(dict(path=str(path.relative_to(ROOT)),size=[size,size],mode='RGB',sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    report=dict(source=str(SOURCE.relative_to(ROOT)),source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),method='Pillow LANCZOS square resize; RGB conversion removes opaque alpha only; no semantic image editing',rights='ImageGen candidate derived from supplied visual reference; underlying reference commercial rights unconfirmed',outputs=rows)
    (ROOT/'docs/development/evidence/B03/platform-icons.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
