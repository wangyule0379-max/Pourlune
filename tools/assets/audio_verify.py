#!/usr/bin/env python3
"""Independently decode delivered WAVs and verify the original Nunito copies."""

import hashlib
import json
import math
from pathlib import Path
import struct
import wave

ROOT = Path(__file__).resolve().parents[2]
candidate = ROOT / "docs/design/production-candidates/audio"
manifest = json.loads((candidate / "manifest.json").read_text())
generator = ROOT / manifest["source"]
assert hashlib.sha256(generator.read_bytes()).hexdigest() == manifest["source_sha256"]
for entry in manifest["files"]:
    source = candidate / entry["file"]
    asset = ROOT / "app/assets/audio" / entry["file"]
    data = source.read_bytes()
    assert data == asset.read_bytes(), f"packaging drift: {asset}"
    assert len(data) == entry["bytes"]
    assert hashlib.sha256(data).hexdigest() == entry["sha256"]
    with wave.open(str(asset)) as wav:
        assert (wav.getnchannels(), wav.getsampwidth(), wav.getframerate()) == (1, 2, 44100)
        assert wav.getcomptype() == "NONE"
        assert wav.getnframes() == entry["sample_frames"]
        assert wav.getnframes() / wav.getframerate() == entry["duration_seconds"]
        pcm = struct.unpack(f"<{wav.getnframes()}h", wav.readframes(wav.getnframes()))
    peak = max(abs(x) for x in pcm) / 32768
    rms = math.sqrt(sum(x * x for x in pcm) / len(pcm)) / 32768
    assert 0 < rms < peak < 0.25
    assert pcm[0] == pcm[-1] == 0
    assert abs(20 * math.log10(peak) - entry["sample_peak_dbfs"]) < 0.0001
    assert abs(20 * math.log10(rms) - entry["unweighted_rms_dbfs"]) < 0.0001
    if entry["file"] == "background.wav":
        assert entry["loop_start_frame"] == 0
        assert entry["loop_end_frame_exclusive"] == len(pcm) == 1058400
    print(f"Decoded + verified {asset.relative_to(ROOT)}")

font = ROOT / "docs/design/production-candidates/fonts/nunito"
font_source = json.loads((font / "source.json").read_text())
for entry in font_source["files"]:
    data = (font / entry["file"]).read_bytes()
    assert hashlib.sha256(data).hexdigest() == entry["sha256"]
    assert len(data) == entry["bytes"]
    assert hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest() == entry["git_blob_sha"]
    assert (ROOT / "app/assets/fonts/nunito" / entry["file"]).read_bytes() == data
    print(f"Verified original SHA256 + Git blob + unchanged font copy: {entry['file']}")
assert (ROOT / "app/assets/fonts/nunito/source.json").read_bytes() == (font / "source.json").read_bytes()
print("PASS: 6 PCM assets, 3 original font package files, unchanged source record.")
