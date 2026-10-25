import json
from pathlib import Path
import tempfile
import unittest

from build_version import BuildError
from ios_release_plugins import release_plugins, verify_no_test_plugin


IMPORT = '''#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif
'''
CALL = '  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];\n'


class ReleasePluginsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.app = Path(self.temp.name)
        self.reg = self.app / 'ios/Runner/GeneratedPluginRegistrant.m'
        self.spm = self.app / 'ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift'
        self.reg.parent.mkdir(parents=True)
        self.spm.parent.mkdir(parents=True)
        self.reg.write_text('#import "GeneratedPluginRegistrant.h"\n' + IMPORT +
                            '  [SqflitePlugin registerWithRegistrar:registry];\n' + CALL)
        self.spm.write_text('let dependencies = [\n'
                            '    .package(name: "sqflite_darwin", path: "../.packages/sqflite"),\n'
                            '    .package(name: "integration_test", path: "../.packages/integration_test"),\n'
                            '    .product(name: "integration-test", package: "integration_test"),\n]\n')
        self.metadata = self.app / '.flutter-plugins-dependencies'
        self.metadata.write_text(json.dumps({'plugins': {'ios': [
            {'name': 'sqflite_darwin', 'dev_dependency': False},
            {'name': 'integration_test', 'dev_dependency': True},
        ]}}))

    def test_archive_scope_excludes_test_channel_and_linkage_then_restores_debug_files(self):
        before = {p: p.read_bytes() for p in (self.reg, self.spm, self.metadata)}
        with release_plugins(self.app) as evidence:
            self.assertNotIn('IntegrationTestPlugin', self.reg.read_text())
            self.assertNotIn('integration_test', self.reg.read_text() + self.spm.read_text())
            self.assertIn('[SqflitePlugin registerWithRegistrar:registry]', self.reg.read_text())
            self.assertIn('.package(name: "sqflite_darwin"', self.spm.read_text())
            self.assertEqual(evidence['excluded_native_dev_plugins'], ['integration_test'])
            self.assertEqual(self.metadata.read_bytes(), before[self.metadata])
        self.assertEqual({p: p.read_bytes() for p in before}, before)

    def test_failure_restores_both_generated_files(self):
        before = {p: p.read_bytes() for p in (self.reg, self.spm)}
        with self.assertRaisesRegex(RuntimeError, 'archive failed'):
            with release_plugins(self.app):
                raise RuntimeError('archive failed')
        self.assertEqual({p: p.read_bytes() for p in before}, before)

    def test_changed_generator_or_new_native_dev_plugin_fails_before_writing(self):
        for change in ('extra_reference', 'missing_import', 'other_dev_plugin'):
            with self.subTest(change=change):
                before_reg = self.reg.read_bytes()
                before_spm = self.spm.read_bytes()
                if change == 'extra_reference':
                    self.spm.write_text(self.spm.read_text() + '// integration_test\n')
                elif change == 'missing_import':
                    self.reg.write_text(self.reg.read_text().replace(IMPORT, ''))
                else:
                    self.metadata.write_text(json.dumps({'plugins': {'ios': [
                        {'name': 'other_debug_plugin', 'dev_dependency': True}]}}))
                expected = (self.reg.read_bytes(), self.spm.read_bytes())
                with self.assertRaises(BuildError):
                    with release_plugins(self.app):
                        self.fail('must reject before archive')
                self.assertEqual((self.reg.read_bytes(), self.spm.read_bytes()), expected)
                self.reg.write_bytes(before_reg)
                self.spm.write_bytes(before_spm)

    def test_real_packaged_binary_guard_rejects_class_or_channel_and_allows_clean_bytes(self):
        runner = self.app / 'Runner'
        for contents in (b'prefix IntegrationTestPlugin suffix', b'plugins.flutter.io/integration_test'):
            runner.write_bytes(contents)
            with self.assertRaisesRegex(BuildError, 'ios_native_test_plugin_packaged'):
                verify_no_test_plugin(runner)
        runner.write_bytes(b'normal native application')
        verify_no_test_plugin(runner)


if __name__ == '__main__':
    unittest.main()
