"""Read-only check of BR02/03 handoff facts. Does not build/install/run/upload."""
from pathlib import Path
import hashlib
import json
import re
import zipfile

ROOT = Path(__file__).resolve().parents[5]
EVIDENCE = Path(__file__).resolve().parent
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
index = json.loads((EVIDENCE / 'artifact-index.json').read_text())
counts = []
for candidate in index['candidates']:
    artifact = Path(candidate['path'])
    assert sha(artifact) == candidate['sha256']
    manifest = Path(candidate['source_manifest'])
    assert sha(manifest) == candidate['source_manifest_sha256']
    sources = json.loads(manifest.read_text())
    assert all(sha(ROOT / name) == digest for name, digest in sources.items())
    assert len(sources) == candidate['source_entries'] == 394
    counts.append(len(sources))
    if candidate['platform'] == 'ios':
        for symbol in candidate['symbols']:
            assert sha(Path(symbol['path'])) == symbol['sha256']
            assert symbol['matches_exported_binary'] is True
    else:
        with zipfile.ZipFile(artifact) as package:
            for symbol in candidate['symbols']:
                assert hashlib.sha256(package.read(symbol['member'])).hexdigest() == symbol['sha256']
                if 'preserved_copy' in symbol:
                    assert sha(Path(symbol['preserved_copy'])) == symbol['sha256']
for config in index['client_config_public_fingerprints']:
    for item in config['files']:
        assert sha(ROOT / 'app/config/firebase/prod' / config['platform'] / item['name']) == item['sha256']
assert not any(index['submit_readiness'].values())
template = json.loads((EVIDENCE.parent / 'BR02/runtime-evidence-template.json').read_text())
assert template['status'] == 'not_executed_blocked'
for section in ['device', 'old_build', 'new_build', 'actual_install_and_upgrade', 'data', 'runtime', 'failure']:
    assert all(value is None for value in template[section].values())
docs = [ROOT / 'docs/development/deliveries' / f'beta-readiness-{phase}.md' for phase in ['BR02', 'BR03']]
docs += list(EVIDENCE.glob('*.md')) + list((EVIDENCE.parent / 'BR02').glob('*.md'))
docs += [ROOT / 'docs/development/dependencies/beta-readiness-user-actions.md']
links = 0
for doc in docs:
    for target in re.findall(r'\]\(([^)]+)\)', doc.read_text()):
        if '://' in target or target.startswith('#'):
            continue
        assert (doc.parent / target.split('#')[0]).exists(), (doc, target)
        links += 1
print(json.dumps({'source_counts': counts, 'artifact_and_symbol_hashes_match': True,
                  'prod_config_fingerprints_match': True, 'relative_links_checked': links,
                  'runtime_template_unexecuted_fields_null': True,
                  'three_paths_not_submit_ready': True,
                  'build_install_run_upload_performed': False}, indent=2))
