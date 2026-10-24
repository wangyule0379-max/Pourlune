"""Exclude the known native test plugin only during a manual App Store archive.

Flutter 3.47.2 still includes iOS dev plugins in release registrants/SPM
(flutter/flutter#163874). Run after normal Flutter generation, never patch SDKs,
and restore generated inputs so the next dedicated QA build keeps its runner.
"""
from contextlib import contextmanager
import hashlib
import json

from build_version import BuildError


IMPORT = '''#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif
'''
CALL = '  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];\n'


def verify_no_test_plugin(binary):
    data = binary.read_bytes()
    if any(marker in data for marker in (b'IntegrationTestPlugin', b'integration_test')):
        raise BuildError('ios_native_test_plugin_packaged')


@contextmanager
def release_plugins(app):
    metadata = json.loads((app / '.flutter-plugins-dependencies').read_text())
    dev = sorted(p['name'] for p in metadata['plugins']['ios'] if p.get('dev_dependency'))
    if dev != ['integration_test']:
        raise BuildError('ios_release_dev_plugins_changed')
    registrant = app / 'ios/Runner/GeneratedPluginRegistrant.m'
    package = app / 'ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift'
    originals = {p: p.read_bytes() for p in (registrant, package)}
    reg = originals[registrant].decode()
    spm = originals[package].decode()
    if reg.count(IMPORT) != 1 or reg.count(CALL) != 1:
        raise BuildError('ios_release_registrant_format_changed')
    reg = reg.replace(IMPORT, '').replace(CALL, '')
    lines = spm.splitlines(keepends=True)
    excluded = [line for line in lines if 'integration_test' in line]
    if (len(excluded) != 2
            or sum('.package(name: "integration_test", path:' in line for line in excluded) != 1
            or sum('.product(name: "integration-test", package: "integration_test")' in line
                   for line in excluded) != 1):
        raise BuildError('ios_release_spm_format_changed')
    spm = ''.join(line for line in lines if line not in excluded)
    prepared = {registrant: reg.encode(), package: spm.encode()}
    if any(marker in data for data in prepared.values()
           for marker in (b'integration_test', b'IntegrationTestPlugin')):
        raise BuildError('ios_release_test_reference_remains')
    evidence = {'excluded_native_dev_plugins': dev, 'generated_inputs': {
        str(p.relative_to(app)): {
            'before_sha256': hashlib.sha256(originals[p]).hexdigest(),
            'archive_sha256': hashlib.sha256(data).hexdigest(),
        } for p, data in prepared.items()}}
    try:
        for p, data in prepared.items():
            p.write_bytes(data)
        yield evidence
    finally:
        for p, data in originals.items():
            p.write_bytes(data)
