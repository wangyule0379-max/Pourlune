#!/usr/bin/env python3
"""Reproducible Pourlune originals: stdlib oscillators, no samples/network.

Run from any directory with Python 3.11+: audio_generate.py [--check].
The check recomputes every byte, checks signal bounds and both delivered copies.
"""

import argparse
import hashlib
import io
import json
import math
from pathlib import Path
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[2]
CANDIDATES = ROOT / "docs/design/production-candidates/audio"
ASSETS = ROOT / "app/assets/audio"
RATE = 44100
TAU = math.tau


def hz(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def blank(seconds):
    return [0.0] * round(seconds * RATE)


def tone(out, start, duration, midi, gain, attack=0.008, decay=3.5, bell=False):
    """Analytic damped sinusoid; cosine attack/release avoid hard edges."""
    offset = round(start * RATE)
    length = round(duration * RATE)
    frequency = hz(midi)
    release = min(0.08, duration / 4)
    for i in range(min(length, len(out) - offset)):
        t = i / RATE
        envelope = min(1.0, t / attack) * min(1.0, (duration - t) / release)
        envelope = math.sin(math.pi * envelope / 2) ** 2
        envelope *= math.exp(-decay * t / duration)
        sample = math.sin(TAU * frequency * t)
        sample += (0.18 if bell else 0.10) * math.sin(TAU * frequency * 2 * t)
        if bell:
            sample += 0.06 * math.sin(TAU * frequency * 3 * t) * math.exp(-5 * t)
        out[offset + i] += gain * envelope * sample


def synthesize():
    tracks = {}
    out = tracks["select"] = blank(0.14)
    tone(out, 0, 0.14, 84, 1, bell=True)

    out = tracks["pour"] = blank(0.84)
    rng = random.Random(8008)
    low = 0
    for i in range(len(out)):
        t = i / RATE
        low += 0.075 * (rng.uniform(-1, 1) - low)
        edge = min(1, t / 0.04, (0.84 - t) / 0.08)
        out[i] = low * edge * (0.6 + 0.4 * math.sin(TAU * 8 * t) ** 2)
    for start, note in [(0.06, 64), (0.20, 67), (0.36, 62), (0.53, 69), (0.68, 65)]:
        tone(out, start, 0.15, note, 0.13, attack=0.015)

    out = tracks["error"] = blank(0.28)
    tone(out, 0, 0.15, 64, 0.8)
    tone(out, 0.11, 0.17, 61, 0.8)

    out = tracks["win"] = blank(1.20)
    for start, note in [(0, 72), (0.16, 76), (0.32, 79), (0.51, 84)]:
        tone(out, start, 1.20 - start, note, 0.65, bell=True)

    out = tracks["reveal"] = blank(1.05)
    for start, note in [(0, 84), (0.12, 91), (0.28, 88), (0.43, 96)]:
        tone(out, start, 1.05 - start, note, 0.55, bell=True)

    out = tracks["background"] = blank(24)
    # Eight 4/4 bars at 80 BPM: warm sustained triads and sparse bell replies.
    # All pitches, rhythm and timbre authored here for this project.
    chords = [(48, 55, 64), (45, 55, 60), (41, 57, 64), (43, 57, 62)] * 2
    notes = [72, 79, 76, 72, 69, 76, 72, 67, 69, 76, 72, 77, 74, 69, 67, 74]
    for bar, chord in enumerate(chords):
        for note in chord:
            tone(out, bar * 3, 3, note, 0.36, attack=0.4, decay=1.5)
    for step, note in enumerate(notes):
        tone(out, step * 1.5 + 0.3, 1.2, note, 0.16, attack=0.018, bell=True)
    return tracks


def encode(name, samples):
    peak_target = 0.12 if name == "background" else 0.24
    scale = peak_target / max(abs(x) for x in samples)
    pcm = [round(x * scale * 32767) for x in samples]
    # All one-shots and the whole-file loop finish at exact digital zero.
    pcm[0] = pcm[-1] = 0
    assert max(abs(x) for x in pcm) < 32767, "PCM clipping"
    assert any(x > 0 for x in pcm) and any(x < 0 for x in pcm)
    result = io.BytesIO()
    with wave.open(result, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(struct.pack(f"<{len(pcm)}h", *pcm))
    peak = max(abs(x) for x in pcm) / 32768
    rms = math.sqrt(sum(x * x for x in pcm) / len(pcm)) / 32768
    data = result.getvalue()
    return data, {
        "file": f"{name}.wav",
        "sha256": hashlib.sha256(data).hexdigest(),
        "bytes": len(data),
        "format": "RIFF/WAVE PCM signed 16-bit little-endian mono",
        "sample_rate_hz": RATE,
        "sample_frames": len(pcm),
        "duration_seconds": len(pcm) / RATE,
        "sample_peak_dbfs": round(20 * math.log10(peak), 4),
        "unweighted_rms_dbfs": round(20 * math.log10(rms), 4),
        "first_sample": pcm[0],
        "last_sample": pcm[-1],
        "loop_start_frame": 0 if name == "background" else None,
        "loop_end_frame_exclusive": len(pcm) if name == "background" else None,
        "runtime_linear_gain": 0.45 if name == "background" else 0.65,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    entries = []
    for name, samples in synthesize().items():
        data, entry = encode(name, samples)
        entries.append(entry)
        for directory in [CANDIDATES, ASSETS]:
            path = directory / entry["file"]
            if args.check:
                assert path.read_bytes() == data, f"asset drift: {path}"
            else:
                directory.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
    manifest = {
        "status": "production_candidate; not independent audio acceptance",
        "authored_on": "2026-10-22",
        "authoring": "Codex deterministic synthesis for the Pourlune B03 user-authorized task",
        "source": "tools/assets/audio_generate.py",
        "source_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "third_party_audio_inputs": [],
        "authorization_record": "AUDIO-AUTHORING.md",
        "measurement": "Decoded integer PCM, full-file unweighted RMS and sample peak; not LUFS, true peak, perceived loudness or device sound pressure.",
        "loop_note": "Whole-file 24-second loop with zero endpoints and envelope releases. Native-player gapless behavior and audible seam require device validation.",
        "files": entries,
    }
    data = (json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode()
    path = CANDIDATES / "manifest.json"
    if args.check:
        assert path.read_bytes() == data, "manifest drift"
    else:
        path.write_bytes(data)
    print(f"{'Verified' if args.check else 'Generated'} {len(entries)} originals; two byte-identical copies; PCM bounds/zero endpoints checked.")
    for entry in entries:
        print(f"{entry['file']}: {entry['duration_seconds']:.2f}s, sample peak {entry['sample_peak_dbfs']:.2f} dBFS, unweighted RMS {entry['unweighted_rms_dbfs']:.2f} dBFS")


if __name__ == "__main__":
    main()
