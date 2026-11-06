"""Install only the fixed private archive supplied by the authorized owner."""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import tarfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("archive", type=Path)
args = parser.parse_args()
manifest = json.loads((root / "sdk-manifest.json").read_text())
data = args.archive.read_bytes()
if len(data) != manifest["archive_bytes"] or hashlib.sha256(data).hexdigest() != manifest["archive_sha256"]:
    raise SystemExit("Private SDK archive hash/size mismatch")
verified = {}
with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as archive:
    members = archive.getmembers()
    if any(not member.isfile() for member in members):
        raise SystemExit("Unexpected SDK archive entry")
    expected = {"package/" + name for name in manifest["files"]}
    if len(members) != len(expected) or {member.name for member in members} != expected:
        raise SystemExit("Unexpected SDK file list")
    for name, digest in manifest["files"].items():
        path = PurePosixPath(name)
        if path.is_absolute() or ".." in path.parts:
            raise SystemExit("Unsafe SDK file path")
        body = archive.extractfile("package/" + name).read()
        if hashlib.sha256(body).hexdigest() != digest:
            raise SystemExit("SDK file hash mismatch: " + name)
        verified[name] = body
destination = root / ".private-dependencies" / "gamemunchies-javascript"
for name, body in verified.items():
    path = destination / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(body)
print("Verified private JavaScript SDK0.3.0; 8 fixed files installed outside source control")
