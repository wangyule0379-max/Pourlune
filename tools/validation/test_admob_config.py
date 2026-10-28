"""Ad-mode boundaries: real config selection and native iOS staging guard."""
import base64
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from admob_config import AdConfigError, selection, check_build

ROOT = Path(__file__).resolve().parents[2]


def encoded(defines):
    return ','.join(base64.b64encode(f'{k}={v}'.encode()).decode() for k,v in defines)


class AdConfigTest(unittest.TestCase):
    def test_registration_hash_matches_the_same_bytes_that_were_parsed(self):
        before = self.registration.read_bytes()
        original = Path.read_text
        def concurrent_edit(path, *args, **kwargs):
            text = original(path, *args, **kwargs)
            changed = copy.deepcopy(self.data)
            changed['apps']['ios']['app_id'] = 'ca-app-pub-1111111111111111~3333333333'
            self.registration.write_text(json.dumps(changed))
            return text
        with patch.object(Path, 'read_text', concurrent_edit):
            selected = selection('test', 'ios', 'com.pourlune.app', self.registration)
        self.assertEqual(selected['app_id'], 'ca-app-pub-1111111111111111~1111111111')
        self.assertEqual(selected['registration_sha256'], hashlib.sha256(before).hexdigest())

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.registration = self.root/'ads.json'
        self.data = {'schema':1, 'apps':{
            'ios':{'native_id':'com.pourlune.app','app_id':'ca-app-pub-1111111111111111~1111111111'},
            'android':{'native_id':'com.pourlune.app','app_id':'ca-app-pub-1111111111111111~2222222222'}}}
        self.registration.write_text(json.dumps(self.data))

    def test_owned_apps_keep_exact_platform_sample_units_and_require_matching_identity(self):
        s = selection('test','ios','com.pourlune.app',self.registration)
        self.assertEqual(s['app_id'],'ca-app-pub-1111111111111111~1111111111')
        self.assertEqual(s['rewarded_id'],'ca-app-pub-3940256099942544/1712485313')
        self.assertTrue(s['owned_registration_verified'])
        for mode,platform,native in [('production','ios','com.pourlune.app'),
                                     ('disabled','ios','com.pourlune.app'),
                                     ('test','ios','com.foreign.app')]:
            with self.subTest(mode=mode,native=native),self.assertRaises(AdConfigError):
                selection(mode,platform,native,self.registration)
        for changed in [{'schema':2}, {'apps':{'ios':{'native_id':'com.foreign.app','app_id':self.data['apps']['ios']['app_id']}}}]:
            self.registration.write_text(json.dumps({**self.data,**changed}))
            with self.assertRaises(AdConfigError):selection('test','ios','com.pourlune.app',self.registration)

    def test_production_uses_only_registered_units_and_rejects_build_injection(self):
        app = self.data['apps']['ios']
        app.update(interstitial_id='ca-app-pub-1111111111111111/2222222222',
                   rewarded_id='ca-app-pub-1111111111111111/3333333333')
        self.registration.write_text(json.dumps(self.data))
        selected = selection('production', 'ios', 'com.pourlune.app', self.registration)
        self.assertEqual(selected['interstitial_id'], app['interstitial_id'])
        self.assertEqual(selected['rewarded_id'], app['rewarded_id'])
        defs = [('POURLUNE_AD_MODE', 'production'), ('POURLUNE_AD_PLATFORM', 'ios'),
                ('POURLUNE_AD_NATIVE_ID', 'com.pourlune.app'),
                ('POURLUNE_AD_APP_ID', app['app_id']),
                ('POURLUNE_INTERSTITIAL_ID', app['interstitial_id']),
                ('POURLUNE_REWARDED_ID', app['rewarded_id'])]
        self.assertEqual(check_build('ios', 'com.pourlune.app', app['app_id'],
                                     encoded(defs), self.registration)['mode'], 'production')
        for broken in [defs[:-1], defs[:-1] + [('POURLUNE_REWARDED_ID',
                        'ca-app-pub-3940256099942544/1712485313')]]:
            with self.assertRaises(AdConfigError):
                check_build('ios', 'com.pourlune.app', app['app_id'], encoded(broken), self.registration)
        with self.assertRaises(AdConfigError):
            selection('production', 'ios', 'com.pourlune.app')
        for invalid in ['ca-app-pub-3940256099942544/1712485313',
                        'ca-app-pub-2222222222222222/3333333333', app['interstitial_id']]:
            app['rewarded_id'] = invalid
            self.registration.write_text(json.dumps(self.data))
            with self.assertRaises(AdConfigError):
                selection('production', 'ios', 'com.pourlune.app', self.registration)

    def test_native_build_rejects_platform_identity_appid_duplicates_and_live_unit_injection(self):
        defs=[('POURLUNE_AD_MODE','test'),('POURLUNE_AD_PLATFORM','ios'),
              ('POURLUNE_AD_NATIVE_ID','dev.pourlune.admobValidation'),
              ('POURLUNE_AD_APP_ID','ca-app-pub-3940256099942544~1458002511')]
        good=check_build('ios','dev.pourlune.admobValidation','ca-app-pub-3940256099942544~1458002511',encoded(defs))
        self.assertFalse(good['owned_registration_verified'])
        for platform,native,app,values in [
            ('android','dev.pourlune.admobValidation','ca-app-pub-3940256099942544~1458002511',defs),
            ('ios','dev.pourlune.other','ca-app-pub-3940256099942544~1458002511',defs),
            ('ios','dev.pourlune.admobValidation','ca-app-pub-1111111111111111~1111111111',defs),
            ('ios','dev.pourlune.admobValidation','ca-app-pub-3940256099942544~1458002511',defs+[defs[0]]),
            ('ios','dev.pourlune.admobValidation','ca-app-pub-3940256099942544~1458002511',defs+[('POURLUNE_REWARDED_ID','ca-app-pub-1111111111111111/1111111111')])]:
            with self.subTest(values=values,platform=platform,native=native),self.assertRaises(AdConfigError):
                check_build(platform,native,app,encoded(values))

    def test_ios_native_wrong_app_id_fails_before_replacing_existing_firebase_resource(self):
        product=self.root/'AdQa.app'; product.mkdir()
        marker=product/'.pourlune-firebase.json';marker.write_text('previous-owned-marker')
        env={**os.environ,'SRCROOT':str(ROOT/'app/ios'),'POURLUNE_PYTHON':sys.executable,
             'POURLUNE_FIREBASE_ENV':'none','PRODUCT_BUNDLE_IDENTIFIER':'dev.pourlune.admobValidation',
             'TARGET_BUILD_DIR':str(self.root),'UNLOCALIZED_RESOURCES_FOLDER_PATH':'AdQa.app',
             'POURLUNE_ADMOB_APP_ID':'ca-app-pub-3940256099942544~3347511713',
             'POURLUNE_ADMOB_REGISTRATION':'','DART_DEFINES':''}
        result=subprocess.run(['sh',str(ROOT/'app/ios/Flutter/firebase_config.sh')],env=env,capture_output=True,text=True)
        self.assertNotEqual(result.returncode,0,result.stdout)
        self.assertEqual(marker.read_text(),'previous-owned-marker')

    def test_android_packaged_manifest_rejects_unused_ad_id_and_analytics_ad_id_collection(self):
        # A dependency can reintroduce AD_ID during merging. Check the packaged
        # manifest, not a string in the source manifest or the selected ad mode.
        manifest = self.root / 'AndroidManifest.xml'
        for mode, permission, metadata, expected in [
            ('disabled', True, 'false', 'disabled_android_ad_id_permission'),
            ('disabled', False, 'false', None),
            ('test', True, 'false', None),
            ('disabled', False, 'true', 'android_analytics_ad_id_collection'),
        ]:
            with self.subTest(mode=mode, permission=permission, metadata=metadata):
                permission_xml = ('<uses-permission android:name="com.google.android.gms.permission.AD_ID" />'
                                  if permission else '')
                manifest.write_text(
                    '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
                    + permission_xml + '<application><meta-data '
                    'android:name="google_analytics_adid_collection_enabled" '
                    f'android:value="{metadata}" /></application></manifest>')
                env = {**os.environ, 'DART_DEFINES': encoded([
                    ('POURLUNE_AD_MODE', mode), ('POURLUNE_AD_PLATFORM', 'android'),
                    ('POURLUNE_AD_NATIVE_ID', 'com.pourlune.app'),
                    ('POURLUNE_AD_APP_ID', 'ca-app-pub-3940256099942544~3347511713')])}
                result = subprocess.run([
                    sys.executable, str(ROOT / 'tools/validation/admob_config.py'),
                    '--platform', 'android', '--native-id', 'com.pourlune.app',
                    '--native-app-id', 'ca-app-pub-3940256099942544~3347511713',
                    '--android-manifest', str(manifest),
                ], env=env, capture_output=True, text=True)
                if expected:
                    self.assertEqual(result.returncode, 1, result.stderr)
                    self.assertEqual(json.loads(result.stderr)['code'], expected)
                else:
                    self.assertEqual(result.returncode, 0, result.stderr)


if __name__=='__main__':unittest.main()
