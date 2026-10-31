"""Independently inspect actual Xcode queued IPA; read-only outside own temporary extraction."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import os
import plistlib
import struct
import subprocess
import tempfile
import zipfile

ROOT = Path('/Volumes/data/App Development/Pourlune')
OUT = ROOT / 'docs/development/evidence/gameplay-polish-testflight-20261026'
META = json.loads((OUT / 'organizer-prepared.json').read_text())
BASE = ROOT / 'build/package-review/0.5.0-15/ios-gameplay-polish-2/Pourlune-0.5.0-15.ipa'
IPA = Path(META['readonly_review_ipa'])
SHA = 'aa25b84dcf09956466f47fd8070f09aa80ac17d56e38fab2a2353edbfa56075e'
checks = {}
details = {}


def check(k, value):
    checks[k] = bool(value)


def hashfile(p):
    with p.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def run(*args):
    return subprocess.run(args, check=True, capture_output=True).stdout


def signature_ranges(data):
    if data[:4] == b'\xcf\xfa\xed\xfe':
        slices = [(0, len(data))]
    elif data[:4] == b'\xca\xfe\xba\xbe':
        count = struct.unpack_from('>I', data, 4)[0]
        slices = [struct.unpack_from('>II', data, 8 + i * 20 + 8) for i in range(count)]
    else:
        raise ValueError('Unexpected Mach-O format')
    ranges = []
    for start, size in slices:
        assert data[start:start + 4] == b'\xcf\xfa\xed\xfe'
        ncmds = struct.unpack_from('<I', data, start + 16)[0]
        cursor = start + 32
        found = 0
        for _ in range(ncmds):
            cmd, cmdsize = struct.unpack_from('<II', data, cursor)
            if cmd == 0x1d:
                offset, length = struct.unpack_from('<II', data, cursor + 8)
                assert offset + length <= size
                ranges.append((start + offset, start + offset + length))
                found += 1
            cursor += cmdsize
        assert found == 1
    return sorted(ranges)


check('three_real_queued_saved_readonly_copies_equal', all(hashfile(Path(META[k])) == SHA
    for k in ['actual_queue_ipa', 'prepared_upload_ipa', 'readonly_review_ipa']))
check('upload_size', IPA.stat().st_size == 95141354)
check('mirror_readonly', IPA.stat().st_mode & 0o222 == 0)
check('base_previously_accepted', hashfile(BASE) == 'fde95b02f7bd0e8c00245f893c9a4a89403ba88d983ebc148410c2c2f5660513'
      and json.loads((OUT / 'package-independent.json').read_text())['passed'])
code_checks = []
with zipfile.ZipFile(BASE) as original, zipfile.ZipFile(IPA) as upload:
    old_names = {n for n in original.namelist() if not n.endswith('/')}
    new_names = {n for n in upload.namelist() if not n.endswith('/')}
    added = sorted(new_names - old_names)
    expected_uuids = {u for x in json.loads((OUT / 'package-independent.json').read_text())['details']['symbols'] for u, arch in x['uuid']}
    check('all_266_original_file_entries_preserved', old_names <= new_names and len(old_names) == 266)
    check('only_four_matching_symbols_added', set(added) == {f'Symbols/{u}.symbols' for u in expected_uuids} and len(added) == 4)
    details['added_symbols'] = [{'path': n, 'bytes': len(upload.read(n)), 'sha256': hashlib.sha256(upload.read(n)).hexdigest()} for n in added]
    check('no_duplicate_upload_entries', len(upload.namelist()) == len(set(upload.namelist())))
    changed = []
    for name in sorted(old_names):
        old, new = original.read(name), upload.read(name)
        if old == new:
            continue
        changed.append(name)
        if name.endswith('/Info.plist'):
            old_info, new_info = plistlib.loads(old), plistlib.loads(new)
            difference = {k: new_info.get(k) for k in set(old_info) | set(new_info) if old_info.get(k) != new_info.get(k)}
            check('only_internal_test_info_flag', difference == {'TFInternalTestingOnly': True})
        elif name.endswith('/embedded.mobileprovision'):
            details['profile_replaced_by_organizer'] = True
        elif name.endswith('/_CodeSignature/CodeResources'):
            check('code_resource_plist_parse', isinstance(plistlib.loads(new), dict))
        else:
            before, after = signature_ranges(old), signature_ranges(new)
            equal_code = len(old) == len(new) and before == after
            last = 0
            for start, end in before:
                equal_code = equal_code and old[last:start] == new[last:start]
                last = end
            equal_code = equal_code and old[last:] == new[last:]
            check('signature_only_' + name, equal_code)
            code_checks.append({'path': name, 'signature_ranges': before, 'all_other_bytes_identical': equal_code})
    check('eleven_expected_changes', len(changed) == 11 and len(code_checks) == 8 and changed == sorted(META['changed_entries']))
    check('native_tests_absent', not any(s in upload.read('Payload/Runner.app/Runner') for s in
                                       [b'IntegrationTestPlugin', b'integration_test']))
    with tempfile.TemporaryDirectory(prefix='pourlune15-organizer-independent-') as tmp:
        for member in upload.infolist():
            path = Path(tmp) / member.filename
            assert path.resolve().is_relative_to(Path(tmp).resolve())
            upload.extract(member, tmp)
            mode = (member.external_attr >> 16) & 0o777
            if mode and not member.is_dir():
                os.chmod(path, mode)
        app = Path(tmp) / 'Payload/Runner.app'
        signature = subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], capture_output=True)
        check('actual_upload_deep_strict_signature', signature.returncode == 0)
        ent = plistlib.loads(run('codesign', '-d', '--entitlements', ':-', str(app)))
        check('distribution_entitlements', ent.get('application-identifier') == 'T7U878Z8H6.com.pourlune.app'
              and ent.get('com.apple.developer.team-identifier') == 'T7U878Z8H6' and ent.get('get-task-allow') is False)
        prefix = str(Path(tmp) / 'public-cert')
        run('codesign', '-d', '--extract-certificates=' + prefix, str(app))
        pin = hashlib.sha1((Path(tmp) / 'public-cert0').read_bytes()).hexdigest().upper()
        check('same_existing_distribution_signer', pin == '13362E4AF31A860FA6B705DB5192AF78613F7A58')
        profile = plistlib.loads(run('security', 'cms', '-D', '-i', str(app / 'embedded.mobileprovision')))
        check('actual_organizer_distribution_profile_valid', profile['TeamIdentifier'] == ['T7U878Z8H6']
              and profile['Entitlements'].get('application-identifier') == 'T7U878Z8H6.com.pourlune.app'
              and profile['Entitlements'].get('get-task-allow') is False
              and profile['ExpirationDate'].replace(tzinfo=timezone.utc) > datetime.now(timezone.utc)
              and not profile.get('ProvisionedDevices') and not profile.get('ProvisionsAllDevices')
              and (Path(tmp) / 'public-cert0').read_bytes() in profile['DeveloperCertificates'])
        details['profile'] = {'uuid': profile['UUID'], 'name': profile.get('Name'), 'created': str(profile.get('CreationDate')), 'expires': str(profile['ExpirationDate']), 'team': profile['TeamIdentifier'], 'signer_sha1': pin}
        archive = BASE.parent / 'ios-export/Runner.xcarchive'
        import re
        def uuid_of(p): return re.findall(r'UUID: ([A-F0-9-]+) \(([^)]+)\)', run('dwarfdump', '--uuid', str(p)).decode())
        syms = []
        for dsym in (archive / 'dSYMs').glob('*.dSYM/Contents/Resources/DWARF/*'):
            binary = app / ('Runner' if dsym.name == 'Runner' else f'Frameworks/{dsym.name}.framework/{dsym.name}')
            values = uuid_of(dsym)
            match = bool(values) and values == uuid_of(binary)
            syms.append({'name':str(dsym.relative_to(archive)), 'uuid':values, 'match':match})
        check('all_actual_upload_dsym_uuids_match', len(syms) == 5 and all(x['match'] for x in syms))
        details['dsyms'] = syms

result = {'checked_at': datetime.now(timezone.utc).isoformat(), 'source': META['source'],
          'upload_sha256': SHA, 'bytes': IPA.stat().st_size, 'checks': checks,
          'changed_entries': changed, 'details': details, 'mach_o_signature_only': code_checks, 'passed': all(checks.values()),
          'meaning': 'Post-upload-start review, not pre-upload gate. Actual queued/saved/read-only IPA match; 8 Mach-O changes checked outside signature blobs; Info internal-only flag, changed distribution profile and 4 Apple Symbols entries separately checked. Runtime/assets/config unchanged if checks pass.',
          'screenshots_viewed': ['organizer-actual-state.png'], 'upload_warning': 'Xcode upload completed with warnings: four third-party SDK dSYMs not supplied. No Firebase symbol upload or runtime production test was performed by this reviewer.'}
(OUT / 'organizer-independent.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({'passed': result['passed'], 'checks': len(checks), 'failed': [k for k, v in checks.items() if not v]}))
raise SystemExit(0 if result['passed'] else 1)
